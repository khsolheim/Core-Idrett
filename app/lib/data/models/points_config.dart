/// Leaderboard category types for filtering
enum LeaderboardCategory {
  total,
  attendance,
  competition,
  training,
  match,
  social;

  static LeaderboardCategory fromString(String value) {
    return LeaderboardCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LeaderboardCategory.total,
    );
  }
}

/// Points distribution mode for mini-activities
enum MiniActivityDistribution {
  winnerOnly,
  topThree,
  allParticipants;

  static MiniActivityDistribution fromString(String value) {
    switch (value) {
      case 'winner_only':
        return MiniActivityDistribution.winnerOnly;
      case 'top_three':
        return MiniActivityDistribution.topThree;
      case 'all_participants':
        return MiniActivityDistribution.allParticipants;
      default:
        return MiniActivityDistribution.topThree;
    }
  }

  String toJsonString() {
    switch (this) {
      case MiniActivityDistribution.winnerOnly:
        return 'winner_only';
      case MiniActivityDistribution.topThree:
        return 'top_three';
      case MiniActivityDistribution.allParticipants:
        return 'all_participants';
    }
  }
}

/// Visibility mode for leaderboards
enum LeaderboardVisibility {
  all,
  rankingOnly,
  ownOnly;

  static LeaderboardVisibility fromString(String value) {
    switch (value) {
      case 'all':
        return LeaderboardVisibility.all;
      case 'ranking_only':
        return LeaderboardVisibility.rankingOnly;
      case 'own_only':
        return LeaderboardVisibility.ownOnly;
      default:
        return LeaderboardVisibility.all;
    }
  }

  String toJsonString() {
    switch (this) {
      case LeaderboardVisibility.all:
        return 'all';
      case LeaderboardVisibility.rankingOnly:
        return 'ranking_only';
      case LeaderboardVisibility.ownOnly:
        return 'own_only';
    }
  }
}

/// Mode for how new players start in the points system
enum NewPlayerStartMode {
  fromJoin,
  wholeSeason,
  adminChooses;

  static NewPlayerStartMode fromString(String value) {
    switch (value) {
      case 'from_join':
        return NewPlayerStartMode.fromJoin;
      case 'full_season':
        return NewPlayerStartMode.wholeSeason;
      case 'admin_choice':
        return NewPlayerStartMode.adminChooses;
      default:
        return NewPlayerStartMode.fromJoin;
    }
  }

  String toJsonString() {
    switch (this) {
      case NewPlayerStartMode.fromJoin:
        return 'from_join';
      case NewPlayerStartMode.wholeSeason:
        return 'full_season';
      case NewPlayerStartMode.adminChooses:
        return 'admin_choice';
    }
  }
}

/// Team-specific points configuration
class TeamPointsConfig {
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

  TeamPointsConfig({
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
    return TeamPointsConfig(
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
    );
  }
}

/// Individual attendance points record
class AttendancePoints {
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

  AttendancePoints({
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
    return AttendancePoints(
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
}

/// User attendance statistics summary
class UserAttendanceStats {
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

  UserAttendanceStats({
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
    return UserAttendanceStats(
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
}

/// Ranked leaderboard entry with extended fields
class RankedLeaderboardEntry {
  final String id;
  final String leaderboardId;
  final String userId;
  final int points;
  final int rank;
  final double? attendanceRate;
  final int? currentStreak;
  final bool optedOut;
  final String? trend;
  final int? rankChange;
  final DateTime updatedAt;

  // Joined fields
  final String? userName;
  final String? userAvatarUrl;

  RankedLeaderboardEntry({
    required this.id,
    required this.leaderboardId,
    required this.userId,
    required this.points,
    required this.rank,
    this.attendanceRate,
    this.currentStreak,
    this.optedOut = false,
    this.trend,
    this.rankChange,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  bool get isUp => trend == 'up';
  bool get isDown => trend == 'down';
  bool get isStable => trend == 'stable' || trend == null;

  factory RankedLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return RankedLeaderboardEntry(
      id: json['id'],
      leaderboardId: json['leaderboard_id'],
      userId: json['user_id'],
      points: json['points'] ?? 0,
      rank: json['rank'] ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble(),
      currentStreak: json['current_streak'],
      optedOut: json['opted_out'] ?? false,
      trend: json['trend'],
      rankChange: json['rank_change'],
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leaderboard_id': leaderboardId,
        'user_id': userId,
        'points': points,
        'rank': rank,
        'attendance_rate': attendanceRate,
        'current_streak': currentStreak,
        'opted_out': optedOut,
        'trend': trend,
        'rank_change': rankChange,
        'updated_at': updatedAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
      };
}

/// Monthly statistics for a user
class MonthlyUserStats {
  final String id;
  final String teamId;
  final String userId;
  final int year;
  final int month;
  final int trainingAttended;
  final int trainingPossible;
  final int matchAttended;
  final int matchPossible;
  final int socialAttended;
  final int socialPossible;
  final int attendancePoints;
  final int competitionPoints;
  final int bonusPoints;
  final int penaltyPoints;
  final double? attendanceRate;
  final DateTime updatedAt;

  MonthlyUserStats({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.year,
    required this.month,
    this.trainingAttended = 0,
    this.trainingPossible = 0,
    this.matchAttended = 0,
    this.matchPossible = 0,
    this.socialAttended = 0,
    this.socialPossible = 0,
    this.attendancePoints = 0,
    this.competitionPoints = 0,
    this.bonusPoints = 0,
    this.penaltyPoints = 0,
    this.attendanceRate,
    required this.updatedAt,
  });

  int get totalPoints =>
      attendancePoints + competitionPoints + bonusPoints - penaltyPoints;

  factory MonthlyUserStats.fromJson(Map<String, dynamic> json) {
    return MonthlyUserStats(
      id: json['id'],
      teamId: json['team_id'],
      userId: json['user_id'],
      year: json['year'],
      month: json['month'],
      trainingAttended: json['training_attended'] ?? 0,
      trainingPossible: json['training_possible'] ?? 0,
      matchAttended: json['match_attended'] ?? 0,
      matchPossible: json['match_possible'] ?? 0,
      socialAttended: json['social_attended'] ?? 0,
      socialPossible: json['social_possible'] ?? 0,
      attendancePoints: json['attendance_points'] ?? 0,
      competitionPoints: json['competition_points'] ?? 0,
      bonusPoints: json['bonus_points'] ?? 0,
      penaltyPoints: json['penalty_points'] ?? 0,
      attendanceRate: (json['attendance_rate'] as num?)?.toDouble(),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'user_id': userId,
        'year': year,
        'month': month,
        'training_attended': trainingAttended,
        'training_possible': trainingPossible,
        'match_attended': matchAttended,
        'match_possible': matchPossible,
        'social_attended': socialAttended,
        'social_possible': socialPossible,
        'attendance_points': attendancePoints,
        'competition_points': competitionPoints,
        'bonus_points': bonusPoints,
        'penalty_points': penaltyPoints,
        'attendance_rate': attendanceRate,
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Adjustment type for manual point adjustments
enum AdjustmentType {
  bonus,
  penalty,
  correction;

  static AdjustmentType fromString(String value) {
    return AdjustmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdjustmentType.bonus,
    );
  }

  String toJsonString() => name;

  String get displayName {
    switch (this) {
      case AdjustmentType.bonus:
        return 'Bonus';
      case AdjustmentType.penalty:
        return 'Straff';
      case AdjustmentType.correction:
        return 'Korreksjon';
    }
  }
}

/// Manual point adjustment by admin (bonus, penalty, correction)
class ManualPointAdjustment {
  final String id;
  final String teamId;
  final String userId;
  final String? seasonId;
  final int points;
  final AdjustmentType adjustmentType;
  final String reason;
  final String createdBy;
  final DateTime createdAt;

  // Joined fields
  final String? userName;
  final String? userAvatarUrl;
  final String? createdByName;

  ManualPointAdjustment({
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

  factory ManualPointAdjustment.fromJson(Map<String, dynamic> json) {
    return ManualPointAdjustment(
      id: json['id'],
      teamId: json['team_id'],
      userId: json['user_id'],
      seasonId: json['season_id'],
      points: json['points'],
      adjustmentType: AdjustmentType.fromString(json['adjustment_type']),
      reason: json['reason'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      createdByName: json['created_by_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'user_id': userId,
        'season_id': seasonId,
        'points': points,
        'adjustment_type': adjustmentType.toJsonString(),
        'reason': reason,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'created_by_name': createdByName,
      };

  /// Whether this adjustment adds or removes points
  bool get isPositive => points >= 0;
}
