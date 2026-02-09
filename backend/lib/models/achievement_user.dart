import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';
import 'achievement_definition.dart';

/// User achievement (awarded achievement)
class UserAchievement extends Equatable {
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

  const UserAchievement({
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

  @override
  List<Object?> get props => [
        id,
        userId,
        achievementId,
        teamId,
        seasonId,
        pointsAwarded,
        awardedAt,
        timesEarned,
        lastEarnedAt,
        triggerReference,
        achievementCode,
        achievementName,
        achievementDescription,
        achievementIcon,
        achievementTier,
        achievementCategory,
        userName,
        teamName,
      ];

  factory UserAchievement.fromJson(Map<String, dynamic> row) {
    return UserAchievement(
      id: safeString(row, 'id'),
      userId: safeString(row, 'user_id'),
      achievementId: safeString(row, 'achievement_id'),
      teamId: safeString(row, 'team_id'),
      seasonId: safeStringNullable(row, 'season_id'),
      pointsAwarded: safeInt(row, 'points_awarded', defaultValue: 0),
      awardedAt: requireDateTime(row, 'awarded_at'),
      timesEarned: safeInt(row, 'times_earned', defaultValue: 1),
      lastEarnedAt: safeDateTimeNullable(row, 'last_earned_at') ??
          requireDateTime(row, 'awarded_at'),
      triggerReference: safeMapNullable(row, 'trigger_reference'),
      // Joined fields from view
      achievementCode: safeStringNullable(row, 'code'),
      achievementName: safeStringNullable(row, 'achievement_name'),
      achievementDescription: safeStringNullable(row, 'description'),
      achievementIcon: safeStringNullable(row, 'icon'),
      achievementTier: safeStringNullable(row, 'tier') != null
          ? AchievementTier.fromString(safeString(row, 'tier'))
          : null,
      achievementCategory: safeStringNullable(row, 'category') != null
          ? AchievementCategory.fromString(safeString(row, 'category'))
          : null,
      userName: safeStringNullable(row, 'user_name'),
      teamName: safeStringNullable(row, 'team_name'),
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
class AchievementProgress extends Equatable {
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

  const AchievementProgress({
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

  @override
  List<Object?> get props => [
        id,
        userId,
        achievementId,
        teamId,
        seasonId,
        currentValue,
        targetValue,
        progressPercent,
        lastContributionAt,
        updatedAt,
        achievementCode,
        achievementName,
        achievementIcon,
        achievementTier,
      ];

  factory AchievementProgress.fromJson(Map<String, dynamic> row) {
    return AchievementProgress(
      id: safeString(row, 'id'),
      userId: safeString(row, 'user_id'),
      achievementId: safeString(row, 'achievement_id'),
      teamId: safeString(row, 'team_id'),
      seasonId: safeStringNullable(row, 'season_id'),
      currentValue: safeInt(row, 'current_value', defaultValue: 0),
      targetValue: safeInt(row, 'target_value'),
      progressPercent: safeDouble(row, 'progress_percent', defaultValue: 0.0),
      lastContributionAt: safeDateTimeNullable(row, 'last_contribution_at'),
      updatedAt: requireDateTime(row, 'updated_at'),
      // Joined fields
      achievementCode: safeStringNullable(row, 'code'),
      achievementName: safeStringNullable(row, 'achievement_name'),
      achievementIcon: safeStringNullable(row, 'icon'),
      achievementTier: safeStringNullable(row, 'tier') != null
          ? AchievementTier.fromString(safeString(row, 'tier'))
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
