import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/mini_activity.dart';
import '../models/mini_activity_statistics.dart';
import 'leaderboard_service.dart';
import 'season_service.dart';

class MiniActivityResultService {
  final Database _db;
  final LeaderboardService _leaderboardService;
  final SeasonService _seasonService;
  final _uuid = const Uuid();

  MiniActivityResultService(this._db, this._leaderboardService, this._seasonService);

  // BS-005: Award adjustment (bonus/penalty)
  Future<MiniActivityAdjustment> awardAdjustment({
    required String miniActivityId,
    String? teamId,
    String? userId,
    required int points,
    String? reason,
    required String createdBy,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('mini_activity_adjustments', {
      'id': id,
      'mini_activity_id': miniActivityId,
      'team_id': teamId,
      'user_id': userId,
      'points': points,
      'reason': reason,
      'created_by': createdBy,
    });

    return MiniActivityAdjustment(
      id: id,
      miniActivityId: miniActivityId,
      teamId: teamId,
      userId: userId,
      points: points,
      reason: reason,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  // BS-006: Get adjustments for mini-activity
  Future<List<MiniActivityAdjustment>> getAdjustments(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activity_adjustments',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'created_at.desc',
    );
    return result.map((row) => MiniActivityAdjustment.fromJson(row)).toList();
  }

  Future<void> recordTeamScore({
    required String teamId,
    required int score,
  }) async {
    await _db.client.update(
      'mini_activity_teams',
      {'final_score': score},
      filters: {'id': 'eq.$teamId'},
    );
  }

  Future<void> recordParticipantPoints({
    required String participantId,
    required int points,
  }) async {
    await _db.client.update(
      'mini_activity_participants',
      {'points': points},
      filters: {'id': 'eq.$participantId'},
    );
  }

  Future<void> recordMultipleScores({
    required String miniActivityId,
    required Map<String, int> teamScores, // teamId -> score
    required Map<String, int> participantPoints, // participantId -> points
    bool addToLeaderboard = false,
  }) async {
    // Update team scores
    for (final entry in teamScores.entries) {
      await recordTeamScore(teamId: entry.key, score: entry.value);
    }

    // Update participant points
    for (final entry in participantPoints.entries) {
      await recordParticipantPoints(participantId: entry.key, points: entry.value);
    }

    // Calculate and award points based on team results
    await _awardPointsBasedOnResults(miniActivityId, addToMainLeaderboard: addToLeaderboard);
  }

  Future<void> _awardPointsBasedOnResults(String miniActivityId, {bool addToMainLeaderboard = false}) async {
    // Get mini-activity
    final miniResult = await _db.client.select(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );

    if (miniResult.isEmpty) return;
    final miniActivity = miniResult.first;
    final miniActivityName = miniActivity['name'] as String? ?? 'Mini-aktivitet';

    // Use activity-specific point values if set
    int winPoints = miniActivity['win_points'] as int? ?? 3;
    int drawPoints = miniActivity['draw_points'] as int? ?? 1;
    int lossPoints = miniActivity['loss_points'] as int? ?? 0;

    // Resolve teamId: directly from mini-activity, or via instance -> activity chain
    String? teamId;
    if (miniActivity['team_id'] != null) {
      teamId = miniActivity['team_id'] as String;
    } else if (miniActivity['instance_id'] != null) {
      teamId = await _resolveTeamIdFromInstance(miniActivity['instance_id'] as String);
    }

    // If we have a teamId, try team settings for default point values
    if (teamId != null) {
      final settingsResult = await _db.client.select(
        'team_settings',
        filters: {'team_id': 'eq.$teamId'},
      );

      if (settingsResult.isNotEmpty) {
        final settings = settingsResult.first;
        winPoints = settings['win_points'] as int? ?? winPoints;
        drawPoints = settings['draw_points'] as int? ?? drawPoints;
        lossPoints = settings['loss_points'] as int? ?? lossPoints;
      }
    }

    // Get main leaderboard if we should add to it
    String? mainLeaderboardId;
    if (addToMainLeaderboard && teamId != null) {
      final activeSeason = await _seasonService.getActiveSeason(teamId);
      if (activeSeason != null) {
        final mainLeaderboard = await _leaderboardService.getMainLeaderboard(teamId);
        mainLeaderboardId = mainLeaderboard?.id;
      }
    }

    // Get teams with scores
    final teamsResult = await _db.client.select(
      'mini_activity_teams',
      select: 'id,final_score',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'final_score.desc',
    );

    final teamsWithScores = teamsResult.where((t) => t['final_score'] != null).toList();
    if (teamsWithScores.isEmpty) return;

    final highestScore = teamsWithScores.first['final_score'] as int;
    final lowestScore = teamsWithScores.last['final_score'] as int;

    for (final team in teamsWithScores) {
      final score = team['final_score'] as int;
      final teamDbId = team['id'] as String;

      int pointsToAward;
      String resultDescription;
      if (score == highestScore && score == lowestScore) {
        // All teams have same score - draw
        pointsToAward = drawPoints;
        resultDescription = 'Uavgjort';
      } else if (score == highestScore) {
        pointsToAward = winPoints;
        resultDescription = 'Seier';
      } else if (score == lowestScore) {
        pointsToAward = lossPoints;
        resultDescription = 'Tap';
      } else {
        pointsToAward = drawPoints;
        resultDescription = 'Uavgjort';
      }

      // Get participants in this team and award points
      final teamParticipants = await _db.client.select(
        'mini_activity_participants',
        filters: {'mini_team_id': 'eq.$teamDbId'},
      );

      for (final p in teamParticipants) {
        final userId = p['user_id'] as String;

        // Update mini-activity participant points
        final currentPoints = (p['points'] as int?) ?? 0;
        await _db.client.update(
          'mini_activity_participants',
          {'points': currentPoints + pointsToAward},
          filters: {'id': 'eq.${p['id']}'},
        );

        // Also add to main leaderboard if configured
        if (mainLeaderboardId != null && pointsToAward > 0) {
          // Check if points were already awarded for this mini-activity
          final alreadyAwarded = await _leaderboardService.hasPointsForSource(
            userId: userId,
            sourceType: PointSourceType.miniActivity,
            sourceId: miniActivityId,
          );

          if (!alreadyAwarded) {
            await _leaderboardService.addPointsWithSource(
              leaderboardId: mainLeaderboardId,
              userId: userId,
              points: pointsToAward,
              sourceType: PointSourceType.miniActivity,
              sourceId: miniActivityId,
              description: '$resultDescription i $miniActivityName',
            );
          }
        }
      }
    }
  }

  // Delete adjustment
  Future<void> deleteAdjustment(String adjustmentId) async {
    await _db.client.delete(
      'mini_activity_adjustments',
      filters: {'id': 'eq.$adjustmentId'},
    );
  }

  /// Mark a winner manually (without requiring score input)
  /// winnerTeamId can be null for a draw
  Future<void> setWinner({
    required String miniActivityId,
    String? winnerTeamId,
    bool addToLeaderboard = false,
  }) async {
    // Get mini-activity for point values
    final miniResult = await _db.client.select(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );
    if (miniResult.isEmpty) return;

    final miniActivity = miniResult.first;
    final winPoints = miniActivity['win_points'] as int? ?? 3;
    final drawPoints = miniActivity['draw_points'] as int? ?? 1;
    final lossPoints = miniActivity['loss_points'] as int? ?? 0;
    final miniActivityName = miniActivity['name'] as String? ?? 'Mini-aktivitet';

    // Get all teams
    final teams = await _db.client.select(
      'mini_activity_teams',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );

    // Update winner_team_id on mini_activity
    await _db.client.update(
      'mini_activities',
      {'winner_team_id': winnerTeamId},
      filters: {'id': 'eq.$miniActivityId'},
    );

    // For draws, set final_score on all teams so hasResult returns true in frontend
    if (winnerTeamId == null) {
      for (final team in teams) {
        await _db.client.update(
          'mini_activity_teams',
          {'final_score': 0},
          filters: {'id': 'eq.${team['id']}'},
        );
      }
    }

    // Award points to participants if addToLeaderboard is true
    if (addToLeaderboard) {
      // Get team_id for main leaderboard lookup
      final teamId = await _getTeamIdForMiniActivity(miniActivityId);
      String? mainLeaderboardId;

      if (teamId != null) {
        // Get active season and main leaderboard
        final activeSeason = await _seasonService.getActiveSeason(teamId);
        if (activeSeason != null) {
          final mainLeaderboard = await _leaderboardService.getMainLeaderboard(teamId);
          mainLeaderboardId = mainLeaderboard?.id;
        }
      }

      for (final team in teams) {
        final teamDbId = team['id'] as String;
        final isWinner = teamDbId == winnerTeamId;
        final isDraw = winnerTeamId == null;

        int pointsToAward;
        String resultDescription;
        if (isDraw) {
          pointsToAward = drawPoints;
          resultDescription = 'Uavgjort';
        } else if (isWinner) {
          pointsToAward = winPoints;
          resultDescription = 'Seier';
        } else {
          pointsToAward = lossPoints;
          resultDescription = 'Tap';
        }

        // Get participants in this team and award points
        final teamParticipants = await _db.client.select(
          'mini_activity_participants',
          filters: {'mini_team_id': 'eq.$teamDbId'},
        );

        for (final p in teamParticipants) {
          final userId = p['user_id'] as String;

          // Update mini-activity participant points
          final currentPoints = (p['points'] as int?) ?? 0;
          await _db.client.update(
            'mini_activity_participants',
            {'points': currentPoints + pointsToAward},
            filters: {'id': 'eq.${p['id']}'},
          );

          // Also add to main leaderboard if we have one
          if (mainLeaderboardId != null && pointsToAward > 0) {
            // Check if points were already awarded for this mini-activity
            final alreadyAwarded = await _leaderboardService.hasPointsForSource(
              userId: userId,
              sourceType: PointSourceType.miniActivity,
              sourceId: miniActivityId,
            );

            if (!alreadyAwarded) {
              await _leaderboardService.addPointsWithSource(
                leaderboardId: mainLeaderboardId,
                userId: userId,
                points: pointsToAward,
                sourceType: PointSourceType.miniActivity,
                sourceId: miniActivityId,
                description: '$resultDescription i $miniActivityName',
              );
            }
          }
        }
      }
    }
  }

  /// Resolve team_id from an activity instance by looking up instance -> activity -> team
  Future<String?> _resolveTeamIdFromInstance(String instanceId) async {
    final instanceResult = await _db.client.select(
      'activity_instances',
      select: 'activity_id',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instanceResult.isEmpty) return null;
    final activityId = instanceResult.first['activity_id'] as String;

    final activityResult = await _db.client.select(
      'activities',
      select: 'team_id',
      filters: {'id': 'eq.$activityId'},
    );

    if (activityResult.isEmpty) return null;
    return activityResult.first['team_id'] as String?;
  }

  /// Get team_id for a mini-activity (looks up via team_id field or instance chain)
  Future<String?> _getTeamIdForMiniActivity(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activities',
      select: 'team_id,instance_id',
      filters: {'id': 'eq.$miniActivityId'},
    );

    if (result.isEmpty) return null;
    final miniActivity = result.first;

    // First check if team_id is set directly (standalone mini-activity)
    if (miniActivity['team_id'] != null) {
      return miniActivity['team_id'] as String;
    }

    // Otherwise, look up through instance -> activity -> team
    final instanceId = miniActivity['instance_id'] as String?;
    if (instanceId == null) return null;

    return _resolveTeamIdFromInstance(instanceId);
  }

  /// Clear the result of a mini-activity (reset scores and winner)
  Future<void> clearResult(String miniActivityId) async {
    // Reset winner_team_id on mini_activity
    await _db.client.update(
      'mini_activities',
      {'winner_team_id': null},
      filters: {'id': 'eq.$miniActivityId'},
    );

    // Reset all team scores to null
    await _db.client.update(
      'mini_activity_teams',
      {'final_score': null},
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );

    // Reset all participant points to 0
    await _db.client.update(
      'mini_activity_participants',
      {'points': 0},
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );
  }
}
