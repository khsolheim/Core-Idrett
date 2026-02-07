import 'tournament_match.dart';

// BM-029: Tournament group model
class TournamentGroup {
  final String id;
  final String tournamentId;
  final String name;
  final int advanceCount;
  final int sortOrder;
  final DateTime createdAt;

  TournamentGroup({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.advanceCount = 2,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory TournamentGroup.fromJson(Map<String, dynamic> row) {
    return TournamentGroup(
      id: row['id'] as String,
      tournamentId: row['tournament_id'] as String,
      name: row['name'] as String,
      advanceCount: row['advance_count'] as int? ?? 2,
      sortOrder: row['sort_order'] as int? ?? 0,
      createdAt: row['created_at'] as DateTime,
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
class GroupStanding {
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

  GroupStanding({
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

  int get goalDifference => goalsFor - goalsAgainst;

  factory GroupStanding.fromJson(Map<String, dynamic> row) {
    return GroupStanding(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      teamId: row['team_id'] as String,
      played: row['played'] as int? ?? 0,
      won: row['won'] as int? ?? 0,
      drawn: row['drawn'] as int? ?? 0,
      lost: row['lost'] as int? ?? 0,
      goalsFor: row['goals_for'] as int? ?? 0,
      goalsAgainst: row['goals_against'] as int? ?? 0,
      points: row['points'] as int? ?? 0,
      position: row['position'] as int?,
      updatedAt: row['updated_at'] as DateTime,
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
class GroupMatch {
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

  GroupMatch({
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

  factory GroupMatch.fromJson(Map<String, dynamic> row) {
    return GroupMatch(
      id: row['id'] as String,
      groupId: row['group_id'] as String,
      teamAId: row['team_a_id'] as String,
      teamBId: row['team_b_id'] as String,
      teamAScore: row['team_a_score'] as int?,
      teamBScore: row['team_b_score'] as int?,
      status: MatchStatus.fromString(row['status'] as String? ?? 'pending'),
      scheduledTime: row['scheduled_time'] as DateTime?,
      matchOrder: row['match_order'] as int? ?? 0,
      createdAt: row['created_at'] as DateTime,
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
class QualificationRound {
  final String id;
  final String tournamentId;
  final String name;
  final int advanceCount;
  final String sortDirection; // 'asc' or 'desc'
  final DateTime createdAt;

  QualificationRound({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.advanceCount = 8,
    this.sortDirection = 'desc',
    required this.createdAt,
  });

  factory QualificationRound.fromJson(Map<String, dynamic> row) {
    return QualificationRound(
      id: row['id'] as String,
      tournamentId: row['tournament_id'] as String,
      name: row['name'] as String,
      advanceCount: row['advance_count'] as int? ?? 8,
      sortDirection: row['sort_direction'] as String? ?? 'desc',
      createdAt: row['created_at'] as DateTime,
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
class QualificationResult {
  final String id;
  final String qualificationRoundId;
  final String userId;
  final double resultValue;
  final bool advanced;
  final int? rank;
  final DateTime createdAt;

  QualificationResult({
    required this.id,
    required this.qualificationRoundId,
    required this.userId,
    required this.resultValue,
    this.advanced = false,
    this.rank,
    required this.createdAt,
  });

  factory QualificationResult.fromJson(Map<String, dynamic> row) {
    return QualificationResult(
      id: row['id'] as String,
      qualificationRoundId: row['qualification_round_id'] as String,
      userId: row['user_id'] as String,
      resultValue: (row['result_value'] as num).toDouble(),
      advanced: row['advanced'] as bool? ?? false,
      rank: row['rank'] as int?,
      createdAt: row['created_at'] as DateTime,
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
