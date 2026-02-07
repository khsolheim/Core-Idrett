import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/achievement.dart';
import 'achievement_definition_service.dart';

/// Service for user achievement queries, awarding, and team stats
class AchievementService {
  final Database _db;
  final AchievementDefinitionService _definitionService;
  final _uuid = const Uuid();

  AchievementService(this._db, this._definitionService);

  // ============ USER ACHIEVEMENTS ============

  /// Get achievements earned by a user
  Future<List<UserAchievement>> getUserAchievements(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final filters = <String, String>{'user_id': 'eq.$userId'};
    if (teamId != null) filters['team_id'] = 'eq.$teamId';
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'v_user_achievements_detail',
      filters: filters,
      order: 'awarded_at.desc',
    );

    return result.map((row) => UserAchievement.fromJson(row)).toList();
  }

  /// Get a user achievement by ID
  Future<UserAchievement?> getUserAchievementById(String userAchievementId) async {
    final result = await _db.client.select(
      'user_achievements',
      filters: {'id': 'eq.$userAchievementId'},
    );

    if (result.isEmpty) return null;
    return UserAchievement.fromJson(result.first);
  }

  /// Check if user has earned a specific achievement
  Future<UserAchievement?> getUserAchievementForDefinition(
    String userId,
    String achievementId, {
    String? teamId,
    String? seasonId,
  }) async {
    final filters = <String, String>{
      'user_id': 'eq.$userId',
      'achievement_id': 'eq.$achievementId',
    };
    if (teamId != null) filters['team_id'] = 'eq.$teamId';
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'user_achievements',
      filters: filters,
    );

    if (result.isEmpty) return null;
    return UserAchievement.fromJson(result.first);
  }

  /// Award an achievement to a user
  Future<UserAchievement> awardAchievement({
    required String userId,
    required String achievementId,
    required String teamId,
    String? seasonId,
    int? pointsAwarded,
    Map<String, dynamic>? triggerReference,
  }) async {
    // Check if already earned
    final existing = await getUserAchievementForDefinition(
      userId,
      achievementId,
      teamId: teamId,
      seasonId: seasonId,
    );

    final definition = await _definitionService.getDefinitionById(achievementId);
    final points = pointsAwarded ?? definition?.bonusPoints ?? 0;
    final now = DateTime.now();

    if (existing != null) {
      if (definition?.isRepeatable ?? false) {
        // Update times earned
        await _db.client.update(
          'user_achievements',
          {
            'times_earned': existing.timesEarned + 1,
            'last_earned_at': now.toIso8601String(),
            'points_awarded': existing.pointsAwarded + points,
          },
          filters: {'id': 'eq.${existing.id}'},
        );

        return UserAchievement(
          id: existing.id,
          userId: userId,
          achievementId: achievementId,
          teamId: teamId,
          seasonId: seasonId,
          pointsAwarded: existing.pointsAwarded + points,
          awardedAt: existing.awardedAt,
          timesEarned: existing.timesEarned + 1,
          lastEarnedAt: now,
          triggerReference: triggerReference,
        );
      }
      return existing; // Already earned and not repeatable
    }

    final id = _uuid.v4();

    await _db.client.insert('user_achievements', {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'team_id': teamId,
      'season_id': seasonId,
      'points_awarded': points,
      'trigger_reference':
          triggerReference != null ? jsonEncode(triggerReference) : null,
    });

    return UserAchievement(
      id: id,
      userId: userId,
      achievementId: achievementId,
      teamId: teamId,
      seasonId: seasonId,
      pointsAwarded: points,
      awardedAt: now,
      timesEarned: 1,
      lastEarnedAt: now,
      triggerReference: triggerReference,
    );
  }

  /// Get recent achievements earned by team members
  Future<List<UserAchievement>> getTeamRecentAchievements(
    String teamId, {
    String? seasonId,
    int limit = 10,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'v_user_achievements_detail',
      filters: filters,
      order: 'awarded_at.desc',
      limit: limit,
    );

    return result.map((row) => UserAchievement.fromJson(row)).toList();
  }

  /// Get achievement counts for a team (by tier)
  Future<Map<String, int>> getTeamAchievementCounts(
    String teamId, {
    String? seasonId,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'v_user_achievements_detail',
      filters: filters,
    );

    final counts = <String, int>{
      'bronze': 0,
      'silver': 0,
      'gold': 0,
      'platinum': 0,
      'total': 0,
    };

    for (final row in result) {
      final tier = row['tier'] as String? ?? 'bronze';
      counts[tier] = (counts[tier] ?? 0) + 1;
      counts['total'] = (counts['total'] ?? 0) + 1;
    }

    return counts;
  }

  /// Get a summary of user's achievements
  Future<Map<String, dynamic>> getUserAchievementsSummary(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    // Get all achievements
    final achievements = await getUserAchievements(
      userId,
      teamId: teamId,
      seasonId: seasonId,
    );

    // Count by tier
    int bronzeCount = 0;
    int silverCount = 0;
    int goldCount = 0;
    int platinumCount = 0;
    int totalBonusPoints = 0;

    for (final achievement in achievements) {
      totalBonusPoints += achievement.pointsAwarded;
      switch (achievement.achievementTier) {
        case AchievementTier.bronze:
          bronzeCount++;
          break;
        case AchievementTier.silver:
          silverCount++;
          break;
        case AchievementTier.gold:
          goldCount++;
          break;
        case AchievementTier.platinum:
          platinumCount++;
          break;
        case null:
          break;
      }
    }

    // Get recent achievements (last 5)
    final recentAchievements = achievements.take(5).toList();

    // Get progress
    final progress = await _getUserProgress(
      userId,
      teamId: teamId,
      seasonId: seasonId,
    );

    // Filter to in-progress achievements
    final inProgress = progress.where((p) => p.progressPercent < 1.0).toList();

    return {
      'user_id': userId,
      'total_achievements': achievements.length,
      'bronze_count': bronzeCount,
      'silver_count': silverCount,
      'gold_count': goldCount,
      'platinum_count': platinumCount,
      'total_bonus_points': totalBonusPoints,
      'recent_achievements': recentAchievements.map((a) => a.toJson()).toList(),
      'in_progress': inProgress.map((p) => p.toJson()).toList(),
    };
  }

  /// Get progress towards achievements for a user (used by getUserAchievementsSummary)
  Future<List<AchievementProgress>> _getUserProgress(
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
}
