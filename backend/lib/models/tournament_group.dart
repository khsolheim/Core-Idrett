import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';
import 'tournament_match.dart';

// BM-029: Tournament group model
class TournamentGroup extends Equatable {
  final String id;
  final String tournamentId;
  final String name;
  final int advanceCount;
  final int sortOrder;
  final DateTime createdAt;

  const TournamentGroup({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.advanceCount = 2,
    this.sortOrder = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, tournamentId, name, advanceCount, sortOrder, createdAt];

  factory TournamentGroup.fromJson(Map<String, dynamic> row) {
    return TournamentGroup(
      id: safeString(row, 'id'),
      tournamentId: safeString(row, 'tournament_id'),
      name: safeString(row, 'name'),
      advanceCount: safeInt(row, 'advance_count', defaultValue: 2),
      sortOrder: safeInt(row, 'sort_order', defaultValue: 0),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'name': name,
      'advance_count': advanceCount,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// BM-030: Group standing model
class GroupStanding extends Equatable {
  final String id;
  final String groupId;
  final String teamId;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final int? position;
  final DateTime updatedAt;

  const GroupStanding({
    required this.id,
    required this.groupId,
    required this.teamId,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
    this.position,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        teamId,
        played,
        won,
        drawn,
        lost,
        goalsFor,
        goalsAgainst,
        points,
        position,
        updatedAt,
      ];

  int get goalDifference => goalsFor - goalsAgainst;

  factory GroupStanding.fromJson(Map<String, dynamic> row) {
    return GroupStanding(
      id: safeString(row, 'id'),
      groupId: safeString(row, 'group_id'),
      teamId: safeString(row, 'team_id'),
      played: safeInt(row, 'played', defaultValue: 0),
      won: safeInt(row, 'won', defaultValue: 0),
      drawn: safeInt(row, 'drawn', defaultValue: 0),
      lost: safeInt(row, 'lost', defaultValue: 0),
      goalsFor: safeInt(row, 'goals_for', defaultValue: 0),
      goalsAgainst: safeInt(row, 'goals_against', defaultValue: 0),
      points: safeInt(row, 'points', defaultValue: 0),
      position: safeIntNullable(row, 'position'),
      updatedAt: requireDateTime(row, 'updated_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'team_id': teamId,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goals_for': goalsFor,
      'goals_against': goalsAgainst,
      'goal_difference': goalDifference,
      'points': points,
      'position': position,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// BM-031: Group match model
class GroupMatch extends Equatable {
  final String id;
  final String groupId;
  final String teamAId;
  final String teamBId;
  final int? teamAScore;
  final int? teamBScore;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final int matchOrder;
  final DateTime createdAt;

  const GroupMatch({
    required this.id,
    required this.groupId,
    required this.teamAId,
    required this.teamBId,
    this.teamAScore,
    this.teamBScore,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    this.matchOrder = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        groupId,
        teamAId,
        teamBId,
        teamAScore,
        teamBScore,
        status,
        scheduledTime,
        matchOrder,
        createdAt,
      ];

  factory GroupMatch.fromJson(Map<String, dynamic> row) {
    return GroupMatch(
      id: safeString(row, 'id'),
      groupId: safeString(row, 'group_id'),
      teamAId: safeString(row, 'team_a_id'),
      teamBId: safeString(row, 'team_b_id'),
      teamAScore: safeIntNullable(row, 'team_a_score'),
      teamBScore: safeIntNullable(row, 'team_b_score'),
      status: MatchStatus.fromString(safeString(row, 'status', defaultValue: 'pending')),
      scheduledTime: safeDateTimeNullable(row, 'scheduled_time'),
      matchOrder: safeInt(row, 'match_order', defaultValue: 0),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'status': status.value,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'match_order': matchOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isCompleted => status == MatchStatus.completed;
  bool get isDraw => teamAScore != null && teamBScore != null && teamAScore == teamBScore;
}

// BM-032: Qualification round model
class QualificationRound extends Equatable {
  final String id;
  final String tournamentId;
  final String name;
  final int advanceCount;
  final String sortDirection; // 'asc' or 'desc'
  final DateTime createdAt;

  const QualificationRound({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.advanceCount = 8,
    this.sortDirection = 'desc',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, tournamentId, name, advanceCount, sortDirection, createdAt];

  factory QualificationRound.fromJson(Map<String, dynamic> row) {
    return QualificationRound(
      id: safeString(row, 'id'),
      tournamentId: safeString(row, 'tournament_id'),
      name: safeString(row, 'name'),
      advanceCount: safeInt(row, 'advance_count', defaultValue: 8),
      sortDirection: safeString(row, 'sort_direction', defaultValue: 'desc'),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'name': name,
      'advance_count': advanceCount,
      'sort_direction': sortDirection,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get sortDescending => sortDirection == 'desc';
}

// BM-033: Qualification result model
class QualificationResult extends Equatable {
  final String id;
  final String qualificationRoundId;
  final String userId;
  final double resultValue;
  final bool advanced;
  final int? rank;
  final DateTime createdAt;

  const QualificationResult({
    required this.id,
    required this.qualificationRoundId,
    required this.userId,
    required this.resultValue,
    this.advanced = false,
    this.rank,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        qualificationRoundId,
        userId,
        resultValue,
        advanced,
        rank,
        createdAt,
      ];

  factory QualificationResult.fromJson(Map<String, dynamic> row) {
    return QualificationResult(
      id: safeString(row, 'id'),
      qualificationRoundId: safeString(row, 'qualification_round_id'),
      userId: safeString(row, 'user_id'),
      resultValue: safeDouble(row, 'result_value'),
      advanced: safeBool(row, 'advanced', defaultValue: false),
      rank: safeIntNullable(row, 'rank'),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qualification_round_id': qualificationRoundId,
      'user_id': userId,
      'result_value': resultValue,
      'advanced': advanced,
      'rank': rank,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
