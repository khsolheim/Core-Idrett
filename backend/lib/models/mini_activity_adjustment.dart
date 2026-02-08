import 'package:equatable/equatable.dart';

// Helper to parse DateTime from database (may come as String or DateTime)
DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

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
      id: row['id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      teamId: row['team_id'] as String?,
      userId: row['user_id'] as String?,
      points: row['points'] as int,
      reason: row['reason'] as String?,
      createdBy: row['created_by'] as String,
      createdAt: _parseDateTime(row['created_at']),
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
      id: row['id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      userId: row['user_id'] as String,
      handicapValue: (row['handicap_value'] as num).toDouble(),
      createdAt: _parseDateTime(row['created_at']),
      updatedAt: _parseDateTime(row['updated_at']),
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
