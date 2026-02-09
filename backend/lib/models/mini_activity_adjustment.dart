import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

// Adjustment model (BM-013 to BM-015)
class MiniActivityAdjustment extends Equatable {
  final String id;
  final String miniActivityId;
  final String? teamId;
  final String? userId;
  final int points;
  final String? reason;
  final String createdBy;
  final DateTime createdAt;

  const MiniActivityAdjustment({
    required this.id,
    required this.miniActivityId,
    this.teamId,
    this.userId,
    required this.points,
    this.reason,
    required this.createdBy,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        miniActivityId,
        teamId,
        userId,
        points,
        reason,
        createdBy,
        createdAt,
      ];

  factory MiniActivityAdjustment.fromJson(Map<String, dynamic> row) {
    return MiniActivityAdjustment(
      id: safeString(row, 'id'),
      miniActivityId: safeString(row, 'mini_activity_id'),
      teamId: safeStringNullable(row, 'team_id'),
      userId: safeStringNullable(row, 'user_id'),
      points: safeInt(row, 'points'),
      reason: safeStringNullable(row, 'reason'),
      createdBy: safeString(row, 'created_by'),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'team_id': teamId,
      'user_id': userId,
      'points': points,
      'reason': reason,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isTeamAdjustment => teamId != null;
  bool get isUserAdjustment => userId != null;
  bool get isBonus => points > 0;
  bool get isPenalty => points < 0;
}

// Handicap model (BM-016)
class MiniActivityHandicap extends Equatable {
  final String id;
  final String miniActivityId;
  final String userId;
  final double handicapValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MiniActivityHandicap({
    required this.id,
    required this.miniActivityId,
    required this.userId,
    required this.handicapValue,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        miniActivityId,
        userId,
        handicapValue,
        createdAt,
        updatedAt,
      ];

  factory MiniActivityHandicap.fromJson(Map<String, dynamic> row) {
    return MiniActivityHandicap(
      id: safeString(row, 'id'),
      miniActivityId: safeString(row, 'mini_activity_id'),
      userId: safeString(row, 'user_id'),
      handicapValue: safeDouble(row, 'handicap_value'),
      createdAt: requireDateTime(row, 'created_at'),
      updatedAt: requireDateTime(row, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'user_id': userId,
      'handicap_value': handicapValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
