import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/achievement.dart';
import 'achievement_definition_service.dart';
import 'achievement_service.dart';

/// Service for tracking achievement progress and checking/awarding achievements
class AchievementProgressService {
  final Database _db;
  final AchievementDefinitionService _definitionService;
  final AchievementService _achievementService;
  final _uuid = const Uuid();

  AchievementProgressService(
    this._db,
    this._definitionService,
    this._achievementService,
  );

  /// Get progress towards achievements for a user
  Future<List<AchievementProgress>> getUserProgress(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final filters = <String, String>{'user_id': 'eq.$userId'};
    if (teamId != null) filters['team_id'] = 'eq.$teamId';
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'v_achievement_progress_detail',
      filters: filters,
      order: 'progress_percent.desc',
    );

    return result.map((row) => AchievementProgress.fromJson(row)).toList();
  }

  /// Update progress for an achievement
  Future<AchievementProgress> updateProgress({
    required String userId,
    required String achievementId,
    required String teamId,
    String? seasonId,
    required int currentValue,
    required int targetValue,
  }) async {
    // Check for existing progress
    final filters = <String, String>{
      'user_id': 'eq.$userId',
      'achievement_id': 'eq.$achievementId',
      'team_id': 'eq.$teamId',
    };
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final existing = await _db.client.select(
      'achievement_progress',
      filters: filters,
    );

    final now = DateTime.now();

    if (existing.isNotEmpty) {
      await _db.client.update(
        'achievement_progress',
        {
          'current_value': currentValue,
          'target_value': targetValue,
          'last_contribution_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        filters: {'id': 'eq.${existing.first['id']}'},
      );

      final progressPercent =
          (currentValue / targetValue * 100).clamp(0.0, 100.0);

      return AchievementProgress(
        id: existing.first['id'] as String,
        userId: userId,
        achievementId: achievementId,
        teamId: teamId,
        seasonId: seasonId,
        currentValue: currentValue,
        targetValue: targetValue,
        progressPercent: progressPercent,
        lastContributionAt: now,
        updatedAt: now,
      );
    }

    final id = _uuid.v4();

    await _db.client.insert('achievement_progress', {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'team_id': teamId,
      'season_id': seasonId,
      'current_value': currentValue,
      'target_value': targetValue,
      'last_contribution_at': now.toIso8601String(),
    });

    final progressPercent = (currentValue / targetValue * 100).clamp(0.0, 100.0);

    return AchievementProgress(
      id: id,
      userId: userId,
      achievementId: achievementId,
      teamId: teamId,
      seasonId: seasonId,
      currentValue: currentValue,
      targetValue: targetValue,
      progressPercent: progressPercent,
      lastContributionAt: now,
      updatedAt: now,
    );
  }

  /// Check and award eligible achievements for a user
  /// Returns list of newly awarded achievements
  Future<List<UserAchievement>> checkAndAwardAchievements(
    String userId,
    String teamId, {
    String? seasonId,
    Map<String, dynamic>? context,
  }) async {
    final awarded = <UserAchievement>[];

    // Get all applicable definitions
    final definitions = await _definitionService.getDefinitions(teamId);

    // Get user's current stats
    final stats = await _getUserStats(userId, teamId, seasonId: seasonId);

    // Batch fetch all existing user achievements to avoid N+1
    final existingFilters = <String, String>{
      'user_id': 'eq.$userId',
    };
    if (seasonId != null) existingFilters['season_id'] = 'eq.$seasonId';

    final allExisting = await _db.client.select(
      'user_achievements',
      filters: existingFilters,
    );
    final existingMap = <String, UserAchievement>{};
    for (final e in allExisting) {
      final ua = UserAchievement.fromJson(e);
      existingMap[ua.achievementId] = ua;
    }

    for (final definition in definitions) {
      // Check if already earned (and not repeatable)
      final existing = existingMap[definition.id];

      if (existing != null && !definition.isRepeatable) continue;

      // Check cooldown for repeatable achievements
      if (existing != null && definition.isRepeatable) {
        if (definition.repeatCooldownDays != null) {
          final daysSinceEarned =
              DateTime.now().difference(existing.lastEarnedAt).inDays;
          if (daysSinceEarned < definition.repeatCooldownDays!) continue;
        }
      }

      // Check criteria
      final meetsRequirements =
          _checkCriteria(definition.criteria, stats, context);

      if (meetsRequirements) {
        final achievement = await _achievementService.awardAchievement(
          userId: userId,
          achievementId: definition.id,
          teamId: teamId,
          seasonId: seasonId,
          triggerReference: context,
        );
        awarded.add(achievement);
      } else if (definition.criteria.threshold != null) {
        // Update progress for threshold-based achievements
        final currentValue = _getCurrentValueForCriteria(
          definition.criteria,
          stats,
        );
        if (currentValue != null) {
          await updateProgress(
            userId: userId,
            achievementId: definition.id,
            teamId: teamId,
            seasonId: seasonId,
            currentValue: currentValue,
            targetValue: definition.criteria.threshold!,
          );
        }
      }
    }

    return awarded;
  }

  /// Get user stats for achievement checking
  Future<Map<String, dynamic>> _getUserStats(
    String userId,
    String teamId, {
    String? seasonId,
  }) async {
    // Get attendance stats
    final attendanceResult = await _db.client.select(
      'v_user_attendance',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );

    // Get mini-activity stats
    final miniActivityFilters = <String, String>{
      'user_id': 'eq.$userId',
      'team_id': 'eq.$teamId',
    };
    if (seasonId != null) miniActivityFilters['season_id'] = 'eq.$seasonId';

    final miniStatsResult = await _db.client.select(
      'mini_activity_player_stats',
      filters: miniActivityFilters,
    );

    // Get leaderboard points
    final leaderboardFilters = <String, String>{'team_id': 'eq.$teamId'};
    if (seasonId != null) leaderboardFilters['season_id'] = 'eq.$seasonId';

    final leaderboards = await _db.client.select(
      'leaderboards',
      filters: {...leaderboardFilters, 'is_main': 'eq.true'},
    );

    int totalPoints = 0;
    if (leaderboards.isNotEmpty) {
      final entries = await _db.client.select(
        'leaderboard_entries',
        filters: {
          'leaderboard_id': 'eq.${leaderboards.first['id']}',
          'user_id': 'eq.$userId',
        },
      );
      if (entries.isNotEmpty) {
        totalPoints = entries.first['points'] as int? ?? 0;
      }
    }

    // Get attendance streak
    final streakResult = await _db.client.select(
      'season_user_stats',
      select: 'current_attendance_streak,best_attendance_streak',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );

    final attendance = attendanceResult.isNotEmpty ? attendanceResult.first : {};
    final miniStats = miniStatsResult.isNotEmpty ? miniStatsResult.first : {};
    final streaks = streakResult.isNotEmpty ? streakResult.first : {};

    return {
      'total_attended': attendance['total_attended'] ?? 0,
      'total_possible': attendance['total_possible'] ?? 0,
      'attendance_rate': attendance['attendance_rate'] ?? 0.0,
      'training_attended': attendance['training_attended'] ?? 0,
      'match_attended': attendance['match_attended'] ?? 0,
      'social_attended': attendance['social_attended'] ?? 0,
      'total_wins': miniStats['total_wins'] ?? 0,
      'total_points': totalPoints,
      'first_place_count': miniStats['first_place_count'] ?? 0,
      'current_attendance_streak': streaks['current_attendance_streak'] ?? 0,
      'best_attendance_streak': streaks['best_attendance_streak'] ?? 0,
    };
  }

  /// Check if criteria is met
  bool _checkCriteria(
    AchievementCriteria criteria,
    Map<String, dynamic> stats,
    Map<String, dynamic>? context,
  ) {
    switch (criteria.type) {
      case AchievementCriteriaType.attendanceStreak:
        final currentStreak = stats['current_attendance_streak'] as int? ?? 0;
        return currentStreak >= (criteria.threshold ?? 0);

      case AchievementCriteriaType.totalPoints:
        final points = stats['total_points'] as int? ?? 0;
        return points >= (criteria.threshold ?? 0);

      case AchievementCriteriaType.attendanceRate:
        final rate = (stats['attendance_rate'] as num?)?.toDouble() ?? 0.0;
        return rate >= (criteria.threshold ?? 0);

      case AchievementCriteriaType.miniActivityWins:
        final wins = stats['total_wins'] as int? ?? 0;
        return wins >= (criteria.threshold ?? 0);

      case AchievementCriteriaType.firstPlaceCount:
        final count = stats['first_place_count'] as int? ?? 0;
        return count >= (criteria.threshold ?? 0);

      case AchievementCriteriaType.socialAttendance:
        final attended = stats['social_attended'] as int? ?? 0;
        return attended >= (criteria.threshold ?? 0);

      case AchievementCriteriaType.firstAttendance:
        final total = stats['total_attended'] as int? ?? 0;
        return total >= 1;

      case AchievementCriteriaType.totalAttendance:
        final total = stats['total_attended'] as int? ?? 0;
        return total >= (criteria.threshold ?? 0);
    }
  }

  /// Get current value for threshold-based criteria
  int? _getCurrentValueForCriteria(
    AchievementCriteria criteria,
    Map<String, dynamic> stats,
  ) {
    switch (criteria.type) {
      case AchievementCriteriaType.attendanceStreak:
        return stats['current_attendance_streak'] as int?;
      case AchievementCriteriaType.totalPoints:
        return stats['total_points'] as int?;
      case AchievementCriteriaType.attendanceRate:
        return (stats['attendance_rate'] as num?)?.toInt();
      case AchievementCriteriaType.miniActivityWins:
        return stats['total_wins'] as int?;
      case AchievementCriteriaType.firstPlaceCount:
        return stats['first_place_count'] as int?;
      case AchievementCriteriaType.socialAttendance:
        return stats['social_attended'] as int?;
      case AchievementCriteriaType.totalAttendance:
        return stats['total_attended'] as int?;
      case AchievementCriteriaType.firstAttendance:
        return (stats['total_attended'] as int? ?? 0) >= 1 ? 1 : 0;
    }
  }
}
