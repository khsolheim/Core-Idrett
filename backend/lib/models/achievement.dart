/// Achievement models
/// Badges and achievements for player recognition

import 'dart:convert';

/// Achievement tier
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum;

  String get value {
    switch (this) {
      case AchievementTier.bronze:
        return 'bronze';
      case AchievementTier.silver:
        return 'silver';
      case AchievementTier.gold:
        return 'gold';
      case AchievementTier.platinum:
        return 'platinum';
    }
  }

  static AchievementTier fromString(String value) {
    switch (value) {
      case 'bronze':
        return AchievementTier.bronze;
      case 'silver':
        return AchievementTier.silver;
      case 'gold':
        return AchievementTier.gold;
      case 'platinum':
        return AchievementTier.platinum;
      default:
        return AchievementTier.bronze;
    }
  }

  int get order {
    switch (this) {
      case AchievementTier.bronze:
        return 1;
      case AchievementTier.silver:
        return 2;
      case AchievementTier.gold:
        return 3;
      case AchievementTier.platinum:
        return 4;
    }
  }
}

/// Achievement category
enum AchievementCategory {
  attendance,
  competition,
  milestone,
  streak,
  social,
  special;

  String get value {
    switch (this) {
      case AchievementCategory.attendance:
        return 'attendance';
      case AchievementCategory.competition:
        return 'competition';
      case AchievementCategory.milestone:
        return 'milestone';
      case AchievementCategory.streak:
        return 'streak';
      case AchievementCategory.social:
        return 'social';
      case AchievementCategory.special:
        return 'special';
    }
  }

  static AchievementCategory fromString(String value) {
    switch (value) {
      case 'attendance':
        return AchievementCategory.attendance;
      case 'competition':
        return AchievementCategory.competition;
      case 'milestone':
        return AchievementCategory.milestone;
      case 'streak':
        return AchievementCategory.streak;
      case 'social':
        return AchievementCategory.social;
      case 'special':
        return AchievementCategory.special;
      default:
        return AchievementCategory.special;
    }
  }

  String get displayName {
    switch (this) {
      case AchievementCategory.attendance:
        return 'Oppmøte';
      case AchievementCategory.competition:
        return 'Konkurranse';
      case AchievementCategory.milestone:
        return 'Milepæl';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.social:
        return 'Sosialt';
      case AchievementCategory.special:
        return 'Spesielt';
    }
  }
}

/// Achievement criteria types
enum AchievementCriteriaType {
  attendanceStreak,
  totalPoints,
  attendanceRate,
  miniActivityWins,
  firstPlaceCount,
  socialAttendance,
  firstAttendance,
  totalAttendance;

  String get value {
    switch (this) {
      case AchievementCriteriaType.attendanceStreak:
        return 'attendance_streak';
      case AchievementCriteriaType.totalPoints:
        return 'total_points';
      case AchievementCriteriaType.attendanceRate:
        return 'attendance_rate';
      case AchievementCriteriaType.miniActivityWins:
        return 'mini_activity_wins';
      case AchievementCriteriaType.firstPlaceCount:
        return 'first_place_count';
      case AchievementCriteriaType.socialAttendance:
        return 'social_attendance';
      case AchievementCriteriaType.firstAttendance:
        return 'first_attendance';
      case AchievementCriteriaType.totalAttendance:
        return 'total_attendance';
    }
  }

  static AchievementCriteriaType fromString(String value) {
    switch (value) {
      case 'attendance_streak':
        return AchievementCriteriaType.attendanceStreak;
      case 'total_points':
        return AchievementCriteriaType.totalPoints;
      case 'attendance_rate':
        return AchievementCriteriaType.attendanceRate;
      case 'mini_activity_wins':
        return AchievementCriteriaType.miniActivityWins;
      case 'first_place_count':
        return AchievementCriteriaType.firstPlaceCount;
      case 'social_attendance':
        return AchievementCriteriaType.socialAttendance;
      case 'first_attendance':
        return AchievementCriteriaType.firstAttendance;
      case 'total_attendance':
        return AchievementCriteriaType.totalAttendance;
      default:
        throw ArgumentError('Unknown criteria type: $value');
    }
  }
}

/// Achievement criteria
class AchievementCriteria {
  final AchievementCriteriaType type;
  final int? threshold;
  final String? period; // 'season', 'month', 'all_time'

  AchievementCriteria({
    required this.type,
    this.threshold,
    this.period,
  });

  factory AchievementCriteria.fromJson(Map<String, dynamic> json) {
    return AchievementCriteria(
      type: AchievementCriteriaType.fromString(json['type'] as String),
      threshold: json['threshold'] as int?,
      period: json['period'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      if (threshold != null) 'threshold': threshold,
      if (period != null) 'period': period,
    };
  }
}

/// Achievement definition
class AchievementDefinition {
  final String id;
  final String? teamId; // null = global
  final String code;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final AchievementTier tier;
  final AchievementCategory category;
  final AchievementCriteria criteria;
  final int bonusPoints;
  final bool isActive;
  final bool isSecret;
  final bool isRepeatable;
  final int? repeatCooldownDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  AchievementDefinition({
    required this.id,
    this.teamId,
    required this.code,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.tier = AchievementTier.bronze,
    required this.category,
    required this.criteria,
    this.bonusPoints = 0,
    this.isActive = true,
    this.isSecret = false,
    this.isRepeatable = false,
    this.repeatCooldownDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AchievementDefinition.fromRow(Map<String, dynamic> row) {
    final criteriaJson = row['criteria'];
    Map<String, dynamic> criteriaMap;
    if (criteriaJson is String) {
      criteriaMap = jsonDecode(criteriaJson) as Map<String, dynamic>;
    } else {
      criteriaMap = criteriaJson as Map<String, dynamic>;
    }

    return AchievementDefinition(
      id: row['id'] as String,
      teamId: row['team_id'] as String?,
      code: row['code'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      icon: row['icon'] as String?,
      color: row['color'] as String?,
      tier: AchievementTier.fromString(row['tier'] as String? ?? 'bronze'),
      category:
          AchievementCategory.fromString(row['category'] as String),
      criteria: AchievementCriteria.fromJson(criteriaMap),
      bonusPoints: row['bonus_points'] as int? ?? 0,
      isActive: row['is_active'] as bool? ?? true,
      isSecret: row['is_secret'] as bool? ?? false,
      isRepeatable: row['is_repeatable'] as bool? ?? false,
      repeatCooldownDays: row['repeat_cooldown_days'] as int?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'tier': tier.value,
      'category': category.value,
      'category_display': category.displayName,
      'criteria': criteria.toJson(),
      'bonus_points': bonusPoints,
      'is_active': isActive,
      'is_secret': isSecret,
      'is_repeatable': isRepeatable,
      'repeat_cooldown_days': repeatCooldownDays,
      'is_global': teamId == null,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isGlobal => teamId == null;
}

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

  factory UserAchievement.fromRow(Map<String, dynamic> row) {
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

  factory AchievementProgress.fromRow(Map<String, dynamic> row) {
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
