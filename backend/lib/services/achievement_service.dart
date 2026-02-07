import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/achievement.dart';

/// Service for managing achievements and tracking progress
class AchievementService {
  final Database _db;
  final _uuid = const Uuid();

  AchievementService(this._db);

  // ============ ACHIEVEMENT DEFINITIONS ============

  /// Get all achievement definitions for a team (including global)
  Future<List<AchievementDefinition>> getDefinitions(
    String teamId, {
    bool includeGlobal = true,
    bool activeOnly = true,
    AchievementCategory? category,
  }) async {
    // Get team-specific achievements
    final teamFilters = <String, String>{'team_id': 'eq.$teamId'};
    if (activeOnly) teamFilters['is_active'] = 'eq.true';
    if (category != null) teamFilters['category'] = 'eq.${category.value}';

    final teamResult = await _db.client.select(
      'achievement_definitions',
      filters: teamFilters,
      order: 'tier.asc,name.asc',
    );

    List<Map<String, dynamic>> globalResult = [];
    if (includeGlobal) {
      // Get global achievements
      final globalFilters = <String, String>{'team_id': 'is.null'};
      if (activeOnly) globalFilters['is_active'] = 'eq.true';
      if (category != null) globalFilters['category'] = 'eq.${category.value}';

      globalResult = await _db.client.select(
        'achievement_definitions',
        filters: globalFilters,
        order: 'tier.asc,name.asc',
      );
    }

    final combined = [...globalResult, ...teamResult];
    return combined.map((row) => AchievementDefinition.fromJson(row)).toList();
  }

  /// Get a definition by ID
  Future<AchievementDefinition?> getDefinitionById(String definitionId) async {
    final result = await _db.client.select(
      'achievement_definitions',
      filters: {'id': 'eq.$definitionId'},
    );

    if (result.isEmpty) return null;
    return AchievementDefinition.fromJson(result.first);
  }

  /// Get a definition by code
  Future<AchievementDefinition?> getDefinitionByCode(
    String code, {
    String? teamId,
  }) async {
    final filters = <String, String>{'code': 'eq.$code'};
    if (teamId != null) {
      filters['team_id'] = 'eq.$teamId';
    } else {
      filters['team_id'] = 'is.null';
    }

    final result = await _db.client.select(
      'achievement_definitions',
      filters: filters,
    );

    if (result.isEmpty) return null;
    return AchievementDefinition.fromJson(result.first);
  }

  /// Create a new achievement definition
  Future<AchievementDefinition> createDefinition({
    String? teamId,
    required String code,
    required String name,
    String? description,
    String? icon,
    String? color,
    AchievementTier tier = AchievementTier.bronze,
    required AchievementCategory category,
    required AchievementCriteria criteria,
    int bonusPoints = 0,
    bool isActive = true,
    bool isSecret = false,
    bool isRepeatable = false,
    int? repeatCooldownDays,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.client.insert('achievement_definitions', {
      'id': id,
      'team_id': teamId,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'tier': tier.value,
      'category': category.value,
      'criteria': jsonEncode(criteria.toJson()),
      'bonus_points': bonusPoints,
      'is_active': isActive,
      'is_secret': isSecret,
      'is_repeatable': isRepeatable,
      'repeat_cooldown_days': repeatCooldownDays,
    });

    return AchievementDefinition(
      id: id,
      teamId: teamId,
      code: code,
      name: name,
      description: description,
      icon: icon,
      color: color,
      tier: tier,
      category: category,
      criteria: criteria,
      bonusPoints: bonusPoints,
      isActive: isActive,
      isSecret: isSecret,
      isRepeatable: isRepeatable,
      repeatCooldownDays: repeatCooldownDays,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update an achievement definition
  Future<AchievementDefinition?> updateDefinition({
    required String definitionId,
    String? name,
    String? description,
    String? icon,
    String? color,
    AchievementTier? tier,
    AchievementCriteria? criteria,
    int? bonusPoints,
    bool? isActive,
    bool? isSecret,
    bool? isRepeatable,
    int? repeatCooldownDays,
    bool clearDescription = false,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (clearDescription) {
      updates['description'] = null;
    } else if (description != null) {
      updates['description'] = description;
    }
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (tier != null) updates['tier'] = tier.value;
    if (criteria != null) updates['criteria'] = jsonEncode(criteria.toJson());
    if (bonusPoints != null) updates['bonus_points'] = bonusPoints;
    if (isActive != null) updates['is_active'] = isActive;
    if (isSecret != null) updates['is_secret'] = isSecret;
    if (isRepeatable != null) updates['is_repeatable'] = isRepeatable;
    if (repeatCooldownDays != null) {
      updates['repeat_cooldown_days'] = repeatCooldownDays;
    }

    await _db.client.update(
      'achievement_definitions',
      updates,
      filters: {'id': 'eq.$definitionId'},
    );

    return getDefinitionById(definitionId);
  }

  /// Delete an achievement definition
  Future<void> deleteDefinition(String definitionId) async {
    await _db.client.delete(
      'achievement_definitions',
      filters: {'id': 'eq.$definitionId'},
    );
  }

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

    final definition = await getDefinitionById(achievementId);
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

  // ============ ACHIEVEMENT PROGRESS ============

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

  // ============ ACHIEVEMENT CHECKING ============

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
    final definitions = await getDefinitions(teamId);

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
        final achievement = await awardAchievement(
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

  /// Get team ID for a definition (for authorization checks)
  Future<String?> getTeamIdForDefinition(String definitionId) async {
    final result = await _db.client.select(
      'achievement_definitions',
      select: 'team_id',
      filters: {'id': 'eq.$definitionId'},
    );

    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
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
    final progress = await getUserProgress(
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
}
