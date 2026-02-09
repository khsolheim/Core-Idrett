/// Achievement definition models
/// Badges and achievements for player recognition

import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

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
class AchievementCriteria extends Equatable {
  final AchievementCriteriaType type;
  final int? threshold;
  final String? period; // 'season', 'month', 'all_time'

  const AchievementCriteria({
    required this.type,
    this.threshold,
    this.period,
  });

  @override
  List<Object?> get props => [type, threshold, period];

  factory AchievementCriteria.fromJson(Map<String, dynamic> json) {
    return AchievementCriteria(
      type: AchievementCriteriaType.fromString(safeString(json, 'type')),
      threshold: safeIntNullable(json, 'threshold'),
      period: safeStringNullable(json, 'period'),
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
class AchievementDefinition extends Equatable {
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

  const AchievementDefinition({
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

  @override
  List<Object?> get props => [
        id,
        teamId,
        code,
        name,
        description,
        icon,
        color,
        tier,
        category,
        criteria,
        bonusPoints,
        isActive,
        isSecret,
        isRepeatable,
        repeatCooldownDays,
        createdAt,
        updatedAt,
      ];

  factory AchievementDefinition.fromJson(Map<String, dynamic> row) {
    final criteriaJson = row['criteria'];
    Map<String, dynamic> criteriaMap;
    if (criteriaJson is String) {
      criteriaMap = jsonDecode(criteriaJson) as Map<String, dynamic>;
    } else {
      criteriaMap = safeMap(row, 'criteria');
    }

    return AchievementDefinition(
      id: safeString(row, 'id'),
      teamId: safeStringNullable(row, 'team_id'),
      code: safeString(row, 'code'),
      name: safeString(row, 'name'),
      description: safeStringNullable(row, 'description'),
      icon: safeStringNullable(row, 'icon'),
      color: safeStringNullable(row, 'color'),
      tier: AchievementTier.fromString(safeString(row, 'tier', defaultValue: 'bronze')),
      category: AchievementCategory.fromString(safeString(row, 'category')),
      criteria: AchievementCriteria.fromJson(criteriaMap),
      bonusPoints: safeInt(row, 'bonus_points', defaultValue: 0),
      isActive: safeBool(row, 'is_active', defaultValue: true),
      isSecret: safeBool(row, 'is_secret', defaultValue: false),
      isRepeatable: safeBool(row, 'is_repeatable', defaultValue: false),
      repeatCooldownDays: safeIntNullable(row, 'repeat_cooldown_days'),
      createdAt: requireDateTime(row, 'created_at'),
      updatedAt: requireDateTime(row, 'updated_at'),
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
