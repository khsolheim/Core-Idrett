/// Team Points Configuration models
/// For configuring point values, weights, and visibility per team/season

import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

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

  factory TeamPointsConfig.fromJson(Map<String, dynamic> row) {
    return TeamPointsConfig(
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      seasonId: safeStringNullable(row, 'season_id'),
      trainingPoints: safeInt(row, 'training_points', defaultValue: 1),
      matchPoints: safeInt(row, 'match_points', defaultValue: 2),
      socialPoints: safeInt(row, 'social_points', defaultValue: 1),
      trainingWeight: safeDouble(row, 'training_weight', defaultValue: 1.0),
      matchWeight: safeDouble(row, 'match_weight', defaultValue: 1.5),
      socialWeight: safeDouble(row, 'social_weight', defaultValue: 0.5),
      competitionWeight: safeDouble(row, 'competition_weight', defaultValue: 1.0),
      miniActivityDistribution:
          safeString(row, 'mini_activity_distribution', defaultValue: 'top_three'),
      autoAwardAttendance: safeBool(row, 'auto_award_attendance', defaultValue: true),
      visibility: safeString(row, 'visibility', defaultValue: 'all'),
      allowOptOut: safeBool(row, 'allow_opt_out', defaultValue: false),
      requireAbsenceReason: safeBool(row, 'require_absence_reason', defaultValue: false),
      requireAbsenceApproval: safeBool(row, 'require_absence_approval', defaultValue: false),
      excludeValidAbsenceFromPercentage:
          safeBool(row, 'exclude_valid_absence_from_percentage', defaultValue: true),
      newPlayerStartMode: safeString(row, 'new_player_start_mode', defaultValue: 'from_join'),
      createdAt: requireDateTime(row, 'created_at'),
      updatedAt: requireDateTime(row, 'updated_at'),
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
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      userId: safeString(row, 'user_id'),
      instanceId: safeString(row, 'instance_id'),
      seasonId: safeStringNullable(row, 'season_id'),
      activityType: safeString(row, 'activity_type'),
      basePoints: safeInt(row, 'base_points', defaultValue: 0),
      weightedPoints: safeDouble(row, 'weighted_points', defaultValue: 0.0),
      awardedAt: requireDateTime(row, 'awarded_at'),
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
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      userId: safeString(row, 'user_id'),
      seasonId: safeStringNullable(row, 'season_id'),
      points: safeInt(row, 'points'),
      adjustmentType: safeString(row, 'adjustment_type'),
      reason: safeString(row, 'reason'),
      createdBy: safeString(row, 'created_by'),
      createdAt: requireDateTime(row, 'created_at'),
      userName: safeStringNullable(row, 'user_name'),
      userAvatarUrl: safeStringNullable(row, 'user_avatar_url'),
      createdByName: safeStringNullable(row, 'created_by_name'),
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
