// Tournament Models
// Tasks: BM-024 to BM-035

// BM-025: Tournament type enum
enum TournamentType {
  singleElimination,
  doubleElimination,
  groupPlay,
  groupKnockout;

  String get value {
    switch (this) {
      case TournamentType.singleElimination:
        return 'single_elimination';
      case TournamentType.doubleElimination:
        return 'double_elimination';
      case TournamentType.groupPlay:
        return 'group_play';
      case TournamentType.groupKnockout:
        return 'group_knockout';
    }
  }

  static TournamentType fromString(String value) {
    switch (value) {
      case 'single_elimination':
        return TournamentType.singleElimination;
      case 'double_elimination':
        return TournamentType.doubleElimination;
      case 'group_play':
        return TournamentType.groupPlay;
      case 'group_knockout':
        return TournamentType.groupKnockout;
      default:
        throw ArgumentError('Unknown tournament type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case TournamentType.singleElimination:
        return 'Utslagsturnering';
      case TournamentType.doubleElimination:
        return 'Dobbel utslagsturnering';
      case TournamentType.groupPlay:
        return 'Gruppespill';
      case TournamentType.groupKnockout:
        return 'Gruppespill + Sluttspill';
    }
  }
}

enum TournamentStatus {
  setup,
  inProgress,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case TournamentStatus.setup:
        return 'setup';
      case TournamentStatus.inProgress:
        return 'in_progress';
      case TournamentStatus.completed:
        return 'completed';
      case TournamentStatus.cancelled:
        return 'cancelled';
    }
  }

  static TournamentStatus fromString(String value) {
    switch (value) {
      case 'setup':
        return TournamentStatus.setup;
      case 'in_progress':
        return TournamentStatus.inProgress;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      default:
        throw ArgumentError('Unknown tournament status: $value');
    }
  }
}

enum SeedingMethod {
  random,
  ranked,
  manual;

  String get value => name;

  static SeedingMethod fromString(String value) {
    switch (value) {
      case 'random':
        return SeedingMethod.random;
      case 'ranked':
        return SeedingMethod.ranked;
      case 'manual':
        return SeedingMethod.manual;
      default:
        throw ArgumentError('Unknown seeding method: $value');
    }
  }
}

enum RoundType {
  winners,
  losers,
  bronze,
  final_;

  String get value {
    switch (this) {
      case RoundType.winners:
        return 'winners';
      case RoundType.losers:
        return 'losers';
      case RoundType.bronze:
        return 'bronze';
      case RoundType.final_:
        return 'final';
    }
  }

  static RoundType fromString(String value) {
    switch (value) {
      case 'winners':
        return RoundType.winners;
      case 'losers':
        return RoundType.losers;
      case 'bronze':
        return RoundType.bronze;
      case 'final':
        return RoundType.final_;
      default:
        throw ArgumentError('Unknown round type: $value');
    }
  }
}

enum MatchStatus {
  pending,
  inProgress,
  completed,
  walkover,
  cancelled;

  String get value {
    switch (this) {
      case MatchStatus.pending:
        return 'pending';
      case MatchStatus.inProgress:
        return 'in_progress';
      case MatchStatus.completed:
        return 'completed';
      case MatchStatus.walkover:
        return 'walkover';
      case MatchStatus.cancelled:
        return 'cancelled';
    }
  }

  static MatchStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return MatchStatus.pending;
      case 'in_progress':
        return MatchStatus.inProgress;
      case 'completed':
        return MatchStatus.completed;
      case 'walkover':
        return MatchStatus.walkover;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        throw ArgumentError('Unknown match status: $value');
    }
  }
}

// BM-024: Tournament model
class Tournament {
  final String id;
  final String miniActivityId;
  final TournamentType tournamentType;
  final int bestOf;
  final bool bronzeFinal;
  final SeedingMethod seedingMethod;
  final int? maxParticipants;
  final TournamentStatus status;
  final DateTime createdAt;

  Tournament({
    required this.id,
    required this.miniActivityId,
    required this.tournamentType,
    this.bestOf = 1,
    this.bronzeFinal = false,
    this.seedingMethod = SeedingMethod.random,
    this.maxParticipants,
    this.status = TournamentStatus.setup,
    required this.createdAt,
  });

  factory Tournament.fromRow(Map<String, dynamic> row) {
    return Tournament(
      id: row['id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      tournamentType: TournamentType.fromString(row['tournament_type'] as String),
      bestOf: row['best_of'] as int? ?? 1,
      bronzeFinal: row['bronze_final'] as bool? ?? false,
      seedingMethod: SeedingMethod.fromString(row['seeding_method'] as String? ?? 'random'),
      maxParticipants: row['max_participants'] as int?,
      status: TournamentStatus.fromString(row['status'] as String? ?? 'setup'),
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'tournament_type': tournamentType.value,
      'best_of': bestOf,
      'bronze_final': bronzeFinal,
      'seeding_method': seedingMethod.value,
      'max_participants': maxParticipants,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// BM-026: Tournament round model
class TournamentRound {
  final String id;
  final String tournamentId;
  final int roundNumber;
  final String? roundName;
  final RoundType roundType;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final DateTime createdAt;

  TournamentRound({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    this.roundName,
    this.roundType = RoundType.winners,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    required this.createdAt,
  });

  factory TournamentRound.fromRow(Map<String, dynamic> row) {
    return TournamentRound(
      id: row['id'] as String,
      tournamentId: row['tournament_id'] as String,
      roundNumber: row['round_number'] as int,
      roundName: row['round_name'] as String?,
      roundType: RoundType.fromString(row['round_type'] as String? ?? 'winners'),
      status: MatchStatus.fromString(row['status'] as String? ?? 'pending'),
      scheduledTime: row['scheduled_time'] as DateTime?,
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'round_number': roundNumber,
      'round_name': roundName,
      'round_type': roundType.value,
      'status': status.value,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// BM-027: Tournament match model
class TournamentMatch {
  final String id;
  final String tournamentId;
  final String roundId;
  final int bracketPosition;
  final String? teamAId;
  final String? teamBId;
  final String? winnerId;
  final int? teamAScore;
  final int? teamBScore;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final int matchOrder;
  final String? winnerGoesToMatchId;
  final String? loserGoesToMatchId;
  final bool isWalkover;
  final String? walkoverReason;
  final DateTime createdAt;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.roundId,
    required this.bracketPosition,
    this.teamAId,
    this.teamBId,
    this.winnerId,
    this.teamAScore,
    this.teamBScore,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    this.matchOrder = 0,
    this.winnerGoesToMatchId,
    this.loserGoesToMatchId,
    this.isWalkover = false,
    this.walkoverReason,
    required this.createdAt,
  });

  factory TournamentMatch.fromRow(Map<String, dynamic> row) {
    return TournamentMatch(
      id: row['id'] as String,
      tournamentId: row['tournament_id'] as String,
      roundId: row['round_id'] as String,
      bracketPosition: row['bracket_position'] as int,
      teamAId: row['team_a_id'] as String?,
      teamBId: row['team_b_id'] as String?,
      winnerId: row['winner_id'] as String?,
      teamAScore: row['team_a_score'] as int?,
      teamBScore: row['team_b_score'] as int?,
      status: MatchStatus.fromString(row['status'] as String? ?? 'pending'),
      scheduledTime: row['scheduled_time'] as DateTime?,
      matchOrder: row['match_order'] as int? ?? 0,
      winnerGoesToMatchId: row['winner_goes_to_match_id'] as String?,
      loserGoesToMatchId: row['loser_goes_to_match_id'] as String?,
      isWalkover: row['is_walkover'] as bool? ?? false,
      walkoverReason: row['walkover_reason'] as String?,
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'round_id': roundId,
      'bracket_position': bracketPosition,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'winner_id': winnerId,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'status': status.value,
      'scheduled_time': scheduledTime?.toIso8601String(),
      'match_order': matchOrder,
      'winner_goes_to_match_id': winnerGoesToMatchId,
      'loser_goes_to_match_id': loserGoesToMatchId,
      'is_walkover': isWalkover,
      'walkover_reason': walkoverReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get hasTeams => teamAId != null && teamBId != null;
  bool get isCompleted => status == MatchStatus.completed || status == MatchStatus.walkover;
  bool get isDraw => teamAScore != null && teamBScore != null && teamAScore == teamBScore;
}

// BM-028: Match game model for best-of series
class MatchGame {
  final String id;
  final String matchId;
  final int gameNumber;
  final int teamAScore;
  final int teamBScore;
  final String? winnerId;
  final MatchStatus status;
  final DateTime createdAt;

  MatchGame({
    required this.id,
    required this.matchId,
    required this.gameNumber,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.winnerId,
    this.status = MatchStatus.pending,
    required this.createdAt,
  });

  factory MatchGame.fromRow(Map<String, dynamic> row) {
    return MatchGame(
      id: row['id'] as String,
      matchId: row['match_id'] as String,
      gameNumber: row['game_number'] as int,
      teamAScore: row['team_a_score'] as int? ?? 0,
      teamBScore: row['team_b_score'] as int? ?? 0,
      winnerId: row['winner_id'] as String?,
      status: MatchStatus.fromString(row['status'] as String? ?? 'pending'),
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'game_number': gameNumber,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'winner_id': winnerId,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

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

  factory TournamentGroup.fromRow(Map<String, dynamic> row) {
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

  factory GroupStanding.fromRow(Map<String, dynamic> row) {
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

  factory GroupMatch.fromRow(Map<String, dynamic> row) {
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

  factory QualificationRound.fromRow(Map<String, dynamic> row) {
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

  factory QualificationResult.fromRow(Map<String, dynamic> row) {
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
