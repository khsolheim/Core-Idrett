/// Team Points Configuration models
/// For configuring point values, weights, and visibility per team/season

import 'package:equatable/equatable.dart';

/// Configuration for team point system
class TeamPointsConfig extends Equatable {
  final String id;
  final String teamId;
  final String? seasonId;

  // Attendance points per activity type
  final int trainingPoints;
  final int matchPoints;
  final int socialPoints;

  // Weight multipliers
  final double trainingWeight;
  final double matchWeight;
  final double socialWeight;
  final double competitionWeight;

  // Mini-activity default distribution
  final String miniActivityDistribution;

  // Settings
  final bool autoAwardAttendance;
  final String visibility;
  final bool allowOptOut;

  // Absence handling
  final bool requireAbsenceReason;
  final bool requireAbsenceApproval;
  final bool excludeValidAbsenceFromPercentage;

  // New player handling
  final String newPlayerStartMode;

  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamPointsConfig({
    required this.id,
    required this.teamId,
    this.seasonId,
    this.trainingPoints = 1,
    this.matchPoints = 2,
    this.socialPoints = 1,
    this.trainingWeight = 1.0,
    this.matchWeight = 1.5,
    this.socialWeight = 0.5,
    this.competitionWeight = 1.0,
    this.miniActivityDistribution = 'top_three',
    this.autoAwardAttendance = true,
    this.visibility = 'all',
    this.allowOptOut = false,
    this.requireAbsenceReason = false,
    this.requireAbsenceApproval = false,
    this.excludeValidAbsenceFromPercentage = true,
    this.newPlayerStartMode = 'from_join',
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        seasonId,
        trainingPoints,
        matchPoints,
        socialPoints,
        trainingWeight,
        matchWeight,
        socialWeight,
        competitionWeight,
        miniActivityDistribution,
        autoAwardAttendance,
        visibility,
        allowOptOut,
        requireAbsenceReason,
        requireAbsenceApproval,
        excludeValidAbsenceFromPercentage,
        newPlayerStartMode,
        createdAt,
        updatedAt,
      ];

  static double _parseDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  factory TeamPointsConfig.fromJson(Map<String, dynamic> row) {
    return TeamPointsConfig(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      seasonId: row['season_id'] as String?,
      trainingPoints: row['training_points'] as int? ?? 1,
      matchPoints: row['match_points'] as int? ?? 2,
      socialPoints: row['social_points'] as int? ?? 1,
      trainingWeight: _parseDouble(row['training_weight'], 1.0),
      matchWeight: _parseDouble(row['match_weight'], 1.5),
      socialWeight: _parseDouble(row['social_weight'], 0.5),
      competitionWeight: _parseDouble(row['competition_weight'], 1.0),
      miniActivityDistribution:
          row['mini_activity_distribution'] as String? ?? 'top_three',
      autoAwardAttendance: row['auto_award_attendance'] as bool? ?? true,
      visibility: row['visibility'] as String? ?? 'all',
      allowOptOut: row['allow_opt_out'] as bool? ?? false,
      requireAbsenceReason: row['require_absence_reason'] as bool? ?? false,
      requireAbsenceApproval: row['require_absence_approval'] as bool? ?? false,
      excludeValidAbsenceFromPercentage:
          row['exclude_valid_absence_from_percentage'] as bool? ?? true,
      newPlayerStartMode: row['new_player_start_mode'] as String? ?? 'from_join',
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'season_id': seasonId,
      'training_points': trainingPoints,
      'match_points': matchPoints,
      'social_points': socialPoints,
      'training_weight': trainingWeight,
      'match_weight': matchWeight,
      'social_weight': socialWeight,
      'competition_weight': competitionWeight,
      'mini_activity_distribution': miniActivityDistribution,
      'auto_award_attendance': autoAwardAttendance,
      'visibility': visibility,
      'allow_opt_out': allowOptOut,
      'require_absence_reason': requireAbsenceReason,
      'require_absence_approval': requireAbsenceApproval,
      'exclude_valid_absence_from_percentage': excludeValidAbsenceFromPercentage,
      'new_player_start_mode': newPlayerStartMode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Calculate weighted points for an activity type
  double getWeightedPoints(String activityType) {
    switch (activityType) {
      case 'training':
        return trainingPoints * trainingWeight;
      case 'match':
        return matchPoints * matchWeight;
      case 'social':
        return socialPoints * socialWeight;
      default:
        return 1.0;
    }
  }

  /// Get base points for an activity type
  int getBasePoints(String activityType) {
    switch (activityType) {
      case 'training':
        return trainingPoints;
      case 'match':
        return matchPoints;
      case 'social':
        return socialPoints;
      default:
        return 1;
    }
  }

  TeamPointsConfig copyWith({
    String? id,
    String? teamId,
    String? seasonId,
    int? trainingPoints,
    int? matchPoints,
    int? socialPoints,
    double? trainingWeight,
    double? matchWeight,
    double? socialWeight,
    double? competitionWeight,
    String? miniActivityDistribution,
    bool? autoAwardAttendance,
    String? visibility,
    bool? allowOptOut,
    bool? requireAbsenceReason,
    bool? requireAbsenceApproval,
    bool? excludeValidAbsenceFromPercentage,
    String? newPlayerStartMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamPointsConfig(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      seasonId: seasonId ?? this.seasonId,
      trainingPoints: trainingPoints ?? this.trainingPoints,
      matchPoints: matchPoints ?? this.matchPoints,
      socialPoints: socialPoints ?? this.socialPoints,
      trainingWeight: trainingWeight ?? this.trainingWeight,
      matchWeight: matchWeight ?? this.matchWeight,
      socialWeight: socialWeight ?? this.socialWeight,
      competitionWeight: competitionWeight ?? this.competitionWeight,
      miniActivityDistribution:
          miniActivityDistribution ?? this.miniActivityDistribution,
      autoAwardAttendance: autoAwardAttendance ?? this.autoAwardAttendance,
      visibility: visibility ?? this.visibility,
      allowOptOut: allowOptOut ?? this.allowOptOut,
      requireAbsenceReason: requireAbsenceReason ?? this.requireAbsenceReason,
      requireAbsenceApproval:
          requireAbsenceApproval ?? this.requireAbsenceApproval,
      excludeValidAbsenceFromPercentage: excludeValidAbsenceFromPercentage ??
          this.excludeValidAbsenceFromPercentage,
      newPlayerStartMode: newPlayerStartMode ?? this.newPlayerStartMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Tracked attendance points per activity instance
class AttendancePoints extends Equatable {
  final String id;
  final String teamId;
  final String userId;
  final String instanceId;
  final String? seasonId;
  final String activityType;
  final int basePoints;
  final double weightedPoints;
  final DateTime awardedAt;

  const AttendancePoints({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.instanceId,
    this.seasonId,
    required this.activityType,
    required this.basePoints,
    required this.weightedPoints,
    required this.awardedAt,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        userId,
        instanceId,
        seasonId,
        activityType,
        basePoints,
        weightedPoints,
        awardedAt,
      ];

  factory AttendancePoints.fromJson(Map<String, dynamic> row) {
    return AttendancePoints(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      userId: row['user_id'] as String,
      instanceId: row['instance_id'] as String,
      seasonId: row['season_id'] as String?,
      activityType: row['activity_type'] as String,
      basePoints: row['base_points'] as int? ?? 0,
      weightedPoints: (row['weighted_points'] as num?)?.toDouble() ?? 0.0,
      awardedAt: DateTime.parse(row['awarded_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'instance_id': instanceId,
      'season_id': seasonId,
      'activity_type': activityType,
      'base_points': basePoints,
      'weighted_points': weightedPoints,
      'awarded_at': awardedAt.toIso8601String(),
    };
  }
}

/// Manual point adjustment by admin (bonus, penalty, correction)
class ManualPointAdjustment extends Equatable {
  final String id;
  final String teamId;
  final String userId;
  final String? seasonId;
  final int points;
  final String adjustmentType;
  final String reason;
  final String createdBy;
  final DateTime createdAt;

  // Joined fields from view
  final String? userName;
  final String? userAvatarUrl;
  final String? createdByName;

  const ManualPointAdjustment({
    required this.id,
    required this.teamId,
    required this.userId,
    this.seasonId,
    required this.points,
    required this.adjustmentType,
    required this.reason,
    required this.createdBy,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
    this.createdByName,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        userId,
        seasonId,
        points,
        adjustmentType,
        reason,
        createdBy,
        createdAt,
        userName,
        userAvatarUrl,
        createdByName,
      ];

  factory ManualPointAdjustment.fromJson(Map<String, dynamic> row) {
    return ManualPointAdjustment(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      userId: row['user_id'] as String,
      seasonId: row['season_id'] as String?,
      points: row['points'] as int,
      adjustmentType: row['adjustment_type'] as String,
      reason: row['reason'] as String,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      userName: row['user_name'] as String?,
      userAvatarUrl: row['user_avatar_url'] as String?,
      createdByName: row['created_by_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'season_id': seasonId,
      'points': points,
      'adjustment_type': adjustmentType,
      'reason': reason,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'created_by_name': createdByName,
    };
  }
}
