// Leaderboard, monthly stats, and manual adjustment models for points system

import 'points_config_enums.dart';
import 'package:equatable/equatable.dart';

/// Ranked leaderboard entry with extended fields
class RankedLeaderboardEntry extends Equatable {
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
  const RankedLeaderboardEntry({
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
    return
  RankedLeaderboardEntry(
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


  @override
  List<Object?> get props => [id, leaderboardId, userId, points, rank, attendanceRate, currentStreak, optedOut, trend, rankChange, updatedAt, userName, userAvatarUrl];
}

/// Monthly statistics for a user
class MonthlyUserStats extends Equatable {
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
  const MonthlyUserStats({
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
    return
  MonthlyUserStats(
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


  @override
  List<Object?> get props => [id, teamId, userId, year, month, trainingAttended, trainingPossible, matchAttended, matchPossible, socialAttended, socialPossible, attendancePoints, competitionPoints, bonusPoints, penaltyPoints, attendanceRate, updatedAt];
}

/// Manual point adjustment by admin (bonus, penalty, correction)
class ManualPointAdjustment extends Equatable {
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

  factory ManualPointAdjustment.fromJson(Map<String, dynamic> json) {
    return
  ManualPointAdjustment(
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


  @override
  List<Object?> get props => [id, teamId, userId, seasonId, points, adjustmentType, reason, createdBy, createdAt, userName, userAvatarUrl, createdByName];
}
