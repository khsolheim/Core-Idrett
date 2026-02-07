/// Achievement tier levels
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum;

  static AchievementTier fromString(String value) {
    return AchievementTier.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AchievementTier.bronze,
    );
  }

  String get displayName {
    switch (this) {
      case AchievementTier.bronze:
        return 'Bronse';
      case AchievementTier.silver:
        return 'Sølv';
      case AchievementTier.gold:
        return 'Gull';
      case AchievementTier.platinum:
        return 'Platina';
    }
  }

  String get emoji {
    switch (this) {
      case AchievementTier.bronze:
        return '🥉';
      case AchievementTier.silver:
        return '🥈';
      case AchievementTier.gold:
        return '🥇';
      case AchievementTier.platinum:
        return '💎';
    }
  }
}

/// Achievement category types
enum AchievementCategory {
  attendance,
  competition,
  milestone,
  streak,
  social,
  special;

  static AchievementCategory fromString(String value) {
    return AchievementCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AchievementCategory.milestone,
    );
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
        return 'Serie';
      case AchievementCategory.social:
        return 'Sosialt';
      case AchievementCategory.special:
        return 'Spesielt';
    }
  }

  String get icon {
    switch (this) {
      case AchievementCategory.attendance:
        return '✓';
      case AchievementCategory.competition:
        return '🏆';
      case AchievementCategory.milestone:
        return '🎯';
      case AchievementCategory.streak:
        return '🔥';
      case AchievementCategory.social:
        return '🤝';
      case AchievementCategory.special:
        return '⭐';
    }
  }
}

/// Types of criteria for awarding achievements
enum AchievementCriteriaType {
  attendanceStreak,
  attendanceTotal,
  attendanceRate,
  pointsTotal,
  miniActivityWins,
  perfectAttendance,
  socialEvents,
  custom;

  static AchievementCriteriaType fromString(String value) {
    switch (value) {
      case 'attendance_streak':
        return AchievementCriteriaType.attendanceStreak;
      case 'attendance_total':
        return AchievementCriteriaType.attendanceTotal;
      case 'attendance_rate':
        return AchievementCriteriaType.attendanceRate;
      case 'points_total':
        return AchievementCriteriaType.pointsTotal;
      case 'mini_activity_wins':
        return AchievementCriteriaType.miniActivityWins;
      case 'perfect_attendance':
        return AchievementCriteriaType.perfectAttendance;
      case 'social_events':
        return AchievementCriteriaType.socialEvents;
      case 'custom':
        return AchievementCriteriaType.custom;
      default:
        return AchievementCriteriaType.custom;
    }
  }

  String toJsonString() {
    switch (this) {
      case AchievementCriteriaType.attendanceStreak:
        return 'attendance_streak';
      case AchievementCriteriaType.attendanceTotal:
        return 'attendance_total';
      case AchievementCriteriaType.attendanceRate:
        return 'attendance_rate';
      case AchievementCriteriaType.pointsTotal:
        return 'points_total';
      case AchievementCriteriaType.miniActivityWins:
        return 'mini_activity_wins';
      case AchievementCriteriaType.perfectAttendance:
        return 'perfect_attendance';
      case AchievementCriteriaType.socialEvents:
        return 'social_events';
      case AchievementCriteriaType.custom:
        return 'custom';
    }
  }
}

/// Criteria for awarding an achievement
class AchievementCriteria {
  final AchievementCriteriaType type;
  final int? threshold;
  final double? percentage;
  final String? activityType;
  final String? timeframe;
  final Map<String, dynamic>? customData;

  AchievementCriteria({
    required this.type,
    this.threshold,
    this.percentage,
    this.activityType,
    this.timeframe,
    this.customData,
  });

  factory AchievementCriteria.fromJson(Map<String, dynamic> json) {
    return AchievementCriteria(
      type: AchievementCriteriaType.fromString(json['type'] ?? 'custom'),
      threshold: json['threshold'],
      percentage: (json['percentage'] as num?)?.toDouble(),
      activityType: json['activity_type'],
      timeframe: json['timeframe'],
      customData: json['custom_data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toJsonString(),
        if (threshold != null) 'threshold': threshold,
        if (percentage != null) 'percentage': percentage,
        if (activityType != null) 'activity_type': activityType,
        if (timeframe != null) 'timeframe': timeframe,
        if (customData != null) 'custom_data': customData,
      };

  AchievementCriteria copyWith({
    AchievementCriteriaType? type,
    int? threshold,
    double? percentage,
    String? activityType,
    String? timeframe,
    Map<String, dynamic>? customData,
  }) {
    return AchievementCriteria(
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      percentage: percentage ?? this.percentage,
      activityType: activityType ?? this.activityType,
      timeframe: timeframe ?? this.timeframe,
      customData: customData ?? this.customData,
    );
  }
}
