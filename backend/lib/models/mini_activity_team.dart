import 'package:equatable/equatable.dart';

class MiniActivityTeam extends Equatable {
  final String id;
  final String miniActivityId;
  final String? name;
  final int? finalScore;

  const MiniActivityTeam({
    required this.id,
    required this.miniActivityId,
    this.name,
    this.finalScore,
  });

  @override
  List<Object?> get props => [id, miniActivityId, name, finalScore];

  factory MiniActivityTeam.fromJson(Map<String, dynamic> row) {
    return MiniActivityTeam(
      id: row['id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      name: row['name'] as String?,
      finalScore: row['final_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'name': name,
      'final_score': finalScore,
    };
  }

  MiniActivityTeam copyWith({
    String? id,
    String? miniActivityId,
    String? name,
    int? finalScore,
  }) {
    return MiniActivityTeam(
      id: id ?? this.id,
      miniActivityId: miniActivityId ?? this.miniActivityId,
      name: name ?? this.name,
      finalScore: finalScore ?? this.finalScore,
    );
  }
}

class MiniActivityParticipant extends Equatable {
  final String id;
  final String? miniTeamId;
  final String miniActivityId;
  final String userId;
  final int points;

  const MiniActivityParticipant({
    required this.id,
    this.miniTeamId,
    required this.miniActivityId,
    required this.userId,
    required this.points,
  });

  @override
  List<Object?> get props => [id, miniTeamId, miniActivityId, userId, points];

  factory MiniActivityParticipant.fromJson(Map<String, dynamic> row) {
    return MiniActivityParticipant(
      id: row['id'] as String,
      miniTeamId: row['mini_team_id'] as String?,
      miniActivityId: row['mini_activity_id'] as String,
      userId: row['user_id'] as String,
      points: row['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_team_id': miniTeamId,
      'mini_activity_id': miniActivityId,
      'user_id': userId,
      'points': points,
    };
  }

  MiniActivityParticipant copyWith({
    String? id,
    String? miniTeamId,
    String? miniActivityId,
    String? userId,
    int? points,
  }) {
    return MiniActivityParticipant(
      id: id ?? this.id,
      miniTeamId: miniTeamId ?? this.miniTeamId,
      miniActivityId: miniActivityId ?? this.miniActivityId,
      userId: userId ?? this.userId,
      points: points ?? this.points,
    );
  }
}
