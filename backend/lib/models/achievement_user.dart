import 'achievement_definition.dart';

/// User achievement (awarded achievement)
class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final String teamId;
  final String? seasonId;
  final int pointsAwarded;
  final DateTime awardedAt;
  final int timesEarned;
  final DateTime lastEarnedAt;
  final Map<String, dynamic>? triggerReference;

  // Joined fields
  final String? achievementCode;
  final String? achievementName;
  final String? achievementDescription;
  final String? achievementIcon;
  final AchievementTier? achievementTier;
  final AchievementCategory? achievementCategory;
  final String? userName;
  final String? teamName;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.teamId,
    this.seasonId,
    this.pointsAwarded = 0,
    required this.awardedAt,
    this.timesEarned = 1,
    required this.lastEarnedAt,
    this.triggerReference,
    this.achievementCode,
    this.achievementName,
    this.achievementDescription,
    this.achievementIcon,
    this.achievementTier,
    this.achievementCategory,
    this.userName,
    this.teamName,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> row) {
    return UserAchievement(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      achievementId: row['achievement_id'] as String,
      teamId: row['team_id'] as String,
      seasonId: row['season_id'] as String?,
      pointsAwarded: row['points_awarded'] as int? ?? 0,
      awardedAt: DateTime.parse(row['awarded_at'] as String),
      timesEarned: row['times_earned'] as int? ?? 1,
      lastEarnedAt: DateTime.parse(
          row['last_earned_at'] as String? ?? row['awarded_at'] as String),
      triggerReference: row['trigger_reference'] as Map<String, dynamic>?,
      // Joined fields from view
      achievementCode: row['code'] as String?,
      achievementName: row['achievement_name'] as String?,
      achievementDescription: row['description'] as String?,
      achievementIcon: row['icon'] as String?,
      achievementTier: row['tier'] != null
          ? AchievementTier.fromString(row['tier'] as String)
          : null,
      achievementCategory: row['category'] != null
          ? AchievementCategory.fromString(row['category'] as String)
          : null,
      userName: row['user_name'] as String?,
      teamName: row['team_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'team_id': teamId,
      'season_id': seasonId,
      'points_awarded': pointsAwarded,
      'awarded_at': awardedAt.toIso8601String(),
      'times_earned': timesEarned,
      'last_earned_at': lastEarnedAt.toIso8601String(),
      'trigger_reference': triggerReference,
      if (achievementCode != null) 'code': achievementCode,
      if (achievementName != null) 'achievement_name': achievementName,
      if (achievementDescription != null) 'description': achievementDescription,
      if (achievementIcon != null) 'icon': achievementIcon,
      if (achievementTier != null) 'tier': achievementTier!.value,
      if (achievementCategory != null) 'category': achievementCategory!.value,
      if (userName != null) 'user_name': userName,
      if (teamName != null) 'team_name': teamName,
    };
  }
}

/// Achievement progress (towards earning an achievement)
class AchievementProgress {
  final String id;
  final String userId;
  final String achievementId;
  final String teamId;
  final String? seasonId;
  final int currentValue;
  final int targetValue;
  final double progressPercent;
  final DateTime? lastContributionAt;
  final DateTime updatedAt;

  // Joined fields
  final String? achievementCode;
  final String? achievementName;
  final String? achievementIcon;
  final AchievementTier? achievementTier;

  AchievementProgress({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.teamId,
    this.seasonId,
    this.currentValue = 0,
    required this.targetValue,
    required this.progressPercent,
    this.lastContributionAt,
    required this.updatedAt,
    this.achievementCode,
    this.achievementName,
    this.achievementIcon,
    this.achievementTier,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> row) {
    return AchievementProgress(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      achievementId: row['achievement_id'] as String,
      teamId: row['team_id'] as String,
      seasonId: row['season_id'] as String?,
      currentValue: row['current_value'] as int? ?? 0,
      targetValue: row['target_value'] as int,
      progressPercent: (row['progress_percent'] as num?)?.toDouble() ?? 0.0,
      lastContributionAt: row['last_contribution_at'] != null
          ? DateTime.parse(row['last_contribution_at'] as String)
          : null,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      // Joined fields
      achievementCode: row['code'] as String?,
      achievementName: row['achievement_name'] as String?,
      achievementIcon: row['icon'] as String?,
      achievementTier: row['tier'] != null
          ? AchievementTier.fromString(row['tier'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'team_id': teamId,
      'season_id': seasonId,
      'current_value': currentValue,
      'target_value': targetValue,
      'progress_percent': progressPercent,
      'last_contribution_at': lastContributionAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (achievementCode != null) 'code': achievementCode,
      if (achievementName != null) 'achievement_name': achievementName,
      if (achievementIcon != null) 'icon': achievementIcon,
      if (achievementTier != null) 'tier': achievementTier!.value,
    };
  }

  bool get isComplete => currentValue >= targetValue;
  bool get isNearComplete => progressPercent >= 75;
}
