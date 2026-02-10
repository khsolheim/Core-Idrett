// Core points configuration and attendance models

import 'points_config_enums.dart';
import 'package:equatable/equatable.dart';

/// Team-specific points configuration
class TeamPointsConfig extends Equatable {
  final String id;
  final String teamId;
  final String? seasonId;
  final int trainingPoints;
  final int matchPoints;
  final int socialPoints;
  final double trainingWeight;
  final double matchWeight;
  final double socialWeight;
  final double competitionWeight;
  final MiniActivityDistribution miniActivityDistribution;
  final bool autoAwardAttendance;
  final LeaderboardVisibility visibility;
  final bool allowOptOut;
  final bool requireAbsenceReason;
  final bool requireAbsenceApproval;
  final bool excludeValidAbsenceFromPercentage;
  final NewPlayerStartMode newPlayerStartMode;
  final DateTime createdAt;
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
    this.miniActivityDistribution = MiniActivityDistribution.topThree,
    this.autoAwardAttendance = true,
    this.visibility = LeaderboardVisibility.all,
    this.allowOptOut = false,
    this.requireAbsenceReason = false,
    this.requireAbsenceApproval = false,
    this.excludeValidAbsenceFromPercentage = true,
    this.newPlayerStartMode = NewPlayerStartMode.fromJoin,
    required this.createdAt,
  });

  factory TeamPointsConfig.fromJson(Map<String, dynamic> json) {
    return
  TeamPointsConfig(
      id: json['id'],
      teamId: json['team_id'],
      seasonId: json['season_id'],
      trainingPoints: json['training_points'] ?? 1,
      matchPoints: json['match_points'] ?? 2,
      socialPoints: json['social_points'] ?? 1,
      trainingWeight: (json['training_weight'] as num?)?.toDouble() ?? 1.0,
      matchWeight: (json['match_weight'] as num?)?.toDouble() ?? 1.5,
      socialWeight: (json['social_weight'] as num?)?.toDouble() ?? 0.5,
      competitionWeight: (json['competition_weight'] as num?)?.toDouble() ?? 1.0,
      miniActivityDistribution: MiniActivityDistribution.fromString(
        json['mini_activity_distribution'] ?? 'top_three',
      ),
      autoAwardAttendance: json['auto_award_attendance'] ?? true,
      visibility: LeaderboardVisibility.fromString(json['visibility'] ?? 'all'),
      allowOptOut: json['allow_opt_out'] ?? false,
      requireAbsenceReason: json['require_absence_reason'] ?? false,
      requireAbsenceApproval: json['require_absence_approval'] ?? false,
      excludeValidAbsenceFromPercentage:
          json['exclude_valid_absence_from_percentage'] ?? true,
      newPlayerStartMode: NewPlayerStartMode.fromString(
        json['new_player_start_mode'] ?? 'from_join',
      ),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
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
        'mini_activity_distribution': miniActivityDistribution.toJsonString(),
        'auto_award_attendance': autoAwardAttendance,
        'visibility': visibility.toJsonString(),
        'allow_opt_out': allowOptOut,
        'require_absence_reason': requireAbsenceReason,
        'require_absence_approval': requireAbsenceApproval,
        'exclude_valid_absence_from_percentage': excludeValidAbsenceFromPercentage,
        'new_player_start_mode': newPlayerStartMode.toJsonString(),
        'created_at': createdAt.toIso8601String(),
      };

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
    MiniActivityDistribution? miniActivityDistribution,
    bool? autoAwardAttendance,
    LeaderboardVisibility? visibility,
    bool? allowOptOut,
    bool? requireAbsenceReason,
    bool? requireAbsenceApproval,
    bool? excludeValidAbsenceFromPercentage,
    NewPlayerStartMode? newPlayerStartMode,
    DateTime? createdAt,
  }) {
    return
  TeamPointsConfig(
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
    );
  }


  @override
  List<Object?> get props => [id, teamId, seasonId, trainingPoints, matchPoints, socialPoints, trainingWeight, matchWeight, socialWeight, competitionWeight, miniActivityDistribution, autoAwardAttendance, visibility, allowOptOut, requireAbsenceReason, requireAbsenceApproval, excludeValidAbsenceFromPercentage, newPlayerStartMode, createdAt];
}

/// Individual attendance points record
class AttendancePoints extends Equatable {
  final String id;
  final String teamId;
  final String userId;
  final String instanceId;
  final String? seasonId;
  final String activityType;
  final int basePoints;
  final double weightedPoints;
  final DateTime createdAt;

  // Joined fields
  final String? userName;
  final String? userAvatarUrl;
  final String? activityName;
  final DateTime? activityDate;
  const AttendancePoints({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.instanceId,
    this.seasonId,
    required this.activityType,
    this.basePoints = 0,
    this.weightedPoints = 0.0,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
    this.activityName,
    this.activityDate,
  });

  factory AttendancePoints.fromJson(Map<String, dynamic> json) {
    return
  AttendancePoints(
      id: json['id'],
      teamId: json['team_id'],
      userId: json['user_id'],
      instanceId: json['instance_id'],
      seasonId: json['season_id'],
      activityType: json['activity_type'] ?? 'training',
      basePoints: json['base_points'] ?? 0,
      weightedPoints: (json['weighted_points'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      activityName: json['activity_name'],
      activityDate: json['activity_date'] != null
          ? DateTime.parse(json['activity_date'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'user_id': userId,
        'instance_id': instanceId,
        'season_id': seasonId,
        'activity_type': activityType,
        'base_points': basePoints,
        'weighted_points': weightedPoints,
        'created_at': createdAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'activity_name': activityName,
        'activity_date': activityDate?.toIso8601String(),
      };


  @override
  List<Object?> get props => [id, teamId, userId, instanceId, seasonId, activityType, basePoints, weightedPoints, createdAt, userName, userAvatarUrl, activityName, activityDate];
}

/// User attendance statistics summary
class UserAttendanceStats extends Equatable {
  final String userId;
  final String teamId;
  final int totalPoints;
  final double totalWeightedPoints;
  final int trainingAttended;
  final int trainingPossible;
  final int matchAttended;
  final int matchPossible;
  final int socialAttended;
  final int socialPossible;
  final double attendanceRate;
  final int? currentStreak;

  // Points breakdown by category
  final int trainingPoints;
  final int matchPoints;
  final int socialPoints;
  final int competitionPoints;
  final int bonusPoints;
  const UserAttendanceStats({
    required this.userId,
    required this.teamId,
    this.totalPoints = 0,
    this.totalWeightedPoints = 0.0,
    this.trainingAttended = 0,
    this.trainingPossible = 0,
    this.matchAttended = 0,
    this.matchPossible = 0,
    this.socialAttended = 0,
    this.socialPossible = 0,
    this.attendanceRate = 0.0,
    this.currentStreak,
    this.trainingPoints = 0,
    this.matchPoints = 0,
    this.socialPoints = 0,
    this.competitionPoints = 0,
    this.bonusPoints = 0,
  });

  int get totalAttended => trainingAttended + matchAttended + socialAttended;
  int get totalPossible => trainingPossible + matchPossible + socialPossible;

  double get trainingRate =>
      trainingPossible > 0 ? trainingAttended / trainingPossible * 100 : 0.0;
  double get matchRate =>
      matchPossible > 0 ? matchAttended / matchPossible * 100 : 0.0;
  double get socialRate =>
      socialPossible > 0 ? socialAttended / socialPossible * 100 : 0.0;

  factory UserAttendanceStats.fromJson(Map<String, dynamic> json) {
    return
  UserAttendanceStats(
      userId: json['user_id'],
      teamId: json['team_id'],
      totalPoints: json['total_points'] ?? 0,
      totalWeightedPoints:
          (json['total_weighted_points'] as num?)?.toDouble() ?? 0.0,
      trainingAttended: json['training_attended'] ?? 0,
      trainingPossible: json['training_possible'] ?? 0,
      matchAttended: json['match_attended'] ?? 0,
      matchPossible: json['match_possible'] ?? 0,
      socialAttended: json['social_attended'] ?? 0,
      socialPossible: json['social_possible'] ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['current_streak'],
      trainingPoints: json['training_points'] ?? 0,
      matchPoints: json['match_points'] ?? 0,
      socialPoints: json['social_points'] ?? 0,
      competitionPoints: json['competition_points'] ?? 0,
      bonusPoints: json['bonus_points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'team_id': teamId,
        'total_points': totalPoints,
        'total_weighted_points': totalWeightedPoints,
        'training_attended': trainingAttended,
        'training_possible': trainingPossible,
        'match_attended': matchAttended,
        'match_possible': matchPossible,
        'social_attended': socialAttended,
        'social_possible': socialPossible,
        'attendance_rate': attendanceRate,
        'current_streak': currentStreak,
        'training_points': trainingPoints,
        'match_points': matchPoints,
        'social_points': socialPoints,
        'competition_points': competitionPoints,
        'bonus_points': bonusPoints,
      };


  @override
  List<Object?> get props => [userId, teamId, totalPoints, totalWeightedPoints, trainingAttended, trainingPossible, matchAttended, matchPossible, socialAttended, socialPossible, attendanceRate, currentStreak, trainingPoints, matchPoints, socialPoints, competitionPoints, bonusPoints];
}
