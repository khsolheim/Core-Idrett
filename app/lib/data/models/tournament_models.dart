// Core tournament and bracket models
// Tournament, TournamentRound, TournamentMatch, MatchGame

import 'tournament_enums.dart';
import 'tournament_group_models.dart';

/// Main Tournament class
class Tournament {
  final String id;
  final String miniActivityId;
  final TournamentType tournamentType;
  final TournamentStatus status;
  final int bestOf;
  final bool bronzeFinal;
  final SeedingMethod seedingMethod;
  final int? maxParticipants;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Nested data (loaded separately)
  final List<TournamentRound>? rounds;
  final List<TournamentGroup>? groups;

  Tournament({
    required this.id,
    required this.miniActivityId,
    required this.tournamentType,
    this.status = TournamentStatus.draft,
    this.bestOf = 1,
    this.bronzeFinal = false,
    this.seedingMethod = SeedingMethod.random,
    this.maxParticipants,
    required this.createdAt,
    this.updatedAt,
    this.rounds,
    this.groups,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      miniActivityId: json['mini_activity_id'] as String,
      tournamentType: TournamentType.fromString(json['tournament_type'] as String? ?? 'single_elimination'),
      status: TournamentStatus.fromString(json['status'] as String? ?? 'draft'),
      bestOf: json['best_of'] as int? ?? 1,
      bronzeFinal: json['bronze_final'] as bool? ?? false,
      seedingMethod: SeedingMethod.fromString(json['seeding_method'] as String? ?? 'random'),
      maxParticipants: json['max_participants'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      rounds: json['rounds'] != null
          ? (json['rounds'] as List).map((r) => TournamentRound.fromJson(r as Map<String, dynamic>)).toList()
          : null,
      groups: json['groups'] != null
          ? (json['groups'] as List).map((g) => TournamentGroup.fromJson(g as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'tournament_type': tournamentType.toJson(),
      'status': status.toJson(),
      'best_of': bestOf,
      'bronze_final': bronzeFinal,
      'seeding_method': seedingMethod.toJson(),
      'max_participants': maxParticipants,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (rounds != null) 'rounds': rounds!.map((r) => r.toJson()).toList(),
      if (groups != null) 'groups': groups!.map((g) => g.toJson()).toList(),
    };
  }

  Tournament copyWith({
    String? id,
    String? miniActivityId,
    TournamentType? tournamentType,
    TournamentStatus? status,
    int? bestOf,
    bool? bronzeFinal,
    SeedingMethod? seedingMethod,
    int? maxParticipants,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TournamentRound>? rounds,
    List<TournamentGroup>? groups,
  }) {
    return Tournament(
      id: id ?? this.id,
      miniActivityId: miniActivityId ?? this.miniActivityId,
      tournamentType: tournamentType ?? this.tournamentType,
      status: status ?? this.status,
      bestOf: bestOf ?? this.bestOf,
      bronzeFinal: bronzeFinal ?? this.bronzeFinal,
      seedingMethod: seedingMethod ?? this.seedingMethod,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rounds: rounds ?? this.rounds,
      groups: groups ?? this.groups,
    );
  }

  bool get isElimination =>
      tournamentType == TournamentType.singleElimination ||
      tournamentType == TournamentType.doubleElimination;

  bool get hasGroups =>
      tournamentType == TournamentType.groupPlay ||
      tournamentType == TournamentType.groupKnockout;
}

/// Tournament round within a bracket
class TournamentRound {
  final String id;
  final String tournamentId;
  final int roundNumber;
  final String roundName;
  final RoundType roundType;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final DateTime createdAt;

  // Nested data
  final List<TournamentMatch>? matches;

  TournamentRound({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    required this.roundName,
    this.roundType = RoundType.winners,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    required this.createdAt,
    this.matches,
  });

  factory TournamentRound.fromJson(Map<String, dynamic> json) {
    return TournamentRound(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      roundNumber: json['round_number'] as int,
      roundName: json['round_name'] as String,
      roundType: RoundType.fromString(json['round_type'] as String? ?? 'winners'),
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      scheduledTime: json['scheduled_time'] != null ? DateTime.parse(json['scheduled_time'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      matches: json['matches'] != null
          ? (json['matches'] as List).map((m) => TournamentMatch.fromJson(m as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'round_number': roundNumber,
      'round_name': roundName,
      'round_type': roundType.toJson(),
      'status': status.toJson(),
      'scheduled_time': scheduledTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (matches != null) 'matches': matches!.map((m) => m.toJson()).toList(),
    };
  }

  TournamentRound copyWith({
    String? id,
    String? tournamentId,
    int? roundNumber,
    String? roundName,
    RoundType? roundType,
    MatchStatus? status,
    DateTime? scheduledTime,
    DateTime? createdAt,
    List<TournamentMatch>? matches,
  }) {
    return TournamentRound(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      roundNumber: roundNumber ?? this.roundNumber,
      roundName: roundName ?? this.roundName,
      roundType: roundType ?? this.roundType,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
      matches: matches ?? this.matches,
    );
  }
}

/// A single match in a tournament
class TournamentMatch {
  final String id;
  final String tournamentId;
  final String? roundId;
  final int bracketPosition;
  final String? teamAId;
  final String? teamBId;
  final String? winnerId;
  final int teamAScore;
  final int teamBScore;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final int matchOrder;
  final String? winnerGoesToMatchId;
  final String? loserGoesToMatchId;
  final bool isWalkover;
  final String? walkoverReason;
  final DateTime createdAt;

  // Nested data
  final List<MatchGame>? games;
  final String? teamAName;
  final String? teamBName;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    this.roundId,
    this.bracketPosition = 0,
    this.teamAId,
    this.teamBId,
    this.winnerId,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    this.matchOrder = 0,
    this.winnerGoesToMatchId,
    this.loserGoesToMatchId,
    this.isWalkover = false,
    this.walkoverReason,
    required this.createdAt,
    this.games,
    this.teamAName,
    this.teamBName,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      roundId: json['round_id'] as String?,
      bracketPosition: json['bracket_position'] as int? ?? 0,
      teamAId: json['team_a_id'] as String?,
      teamBId: json['team_b_id'] as String?,
      winnerId: json['winner_id'] as String?,
      teamAScore: json['team_a_score'] as int? ?? 0,
      teamBScore: json['team_b_score'] as int? ?? 0,
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      scheduledTime: json['scheduled_time'] != null ? DateTime.parse(json['scheduled_time'] as String) : null,
      matchOrder: json['match_order'] as int? ?? 0,
      winnerGoesToMatchId: json['winner_goes_to_match_id'] as String?,
      loserGoesToMatchId: json['loser_goes_to_match_id'] as String?,
      isWalkover: json['is_walkover'] as bool? ?? false,
      walkoverReason: json['walkover_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      games: json['games'] != null
          ? (json['games'] as List).map((g) => MatchGame.fromJson(g as Map<String, dynamic>)).toList()
          : null,
      teamAName: json['team_a_name'] as String?,
      teamBName: json['team_b_name'] as String?,
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
      'status': status.toJson(),
      'scheduled_time': scheduledTime?.toIso8601String(),
      'match_order': matchOrder,
      'winner_goes_to_match_id': winnerGoesToMatchId,
      'loser_goes_to_match_id': loserGoesToMatchId,
      'is_walkover': isWalkover,
      'walkover_reason': walkoverReason,
      'created_at': createdAt.toIso8601String(),
      if (games != null) 'games': games!.map((g) => g.toJson()).toList(),
      'team_a_name': teamAName,
      'team_b_name': teamBName,
    };
  }

  TournamentMatch copyWith({
    String? id,
    String? tournamentId,
    String? roundId,
    int? bracketPosition,
    String? teamAId,
    String? teamBId,
    String? winnerId,
    int? teamAScore,
    int? teamBScore,
    MatchStatus? status,
    DateTime? scheduledTime,
    int? matchOrder,
    String? winnerGoesToMatchId,
    String? loserGoesToMatchId,
    bool? isWalkover,
    String? walkoverReason,
    DateTime? createdAt,
    List<MatchGame>? games,
    String? teamAName,
    String? teamBName,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      roundId: roundId ?? this.roundId,
      bracketPosition: bracketPosition ?? this.bracketPosition,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      winnerId: winnerId ?? this.winnerId,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      matchOrder: matchOrder ?? this.matchOrder,
      winnerGoesToMatchId: winnerGoesToMatchId ?? this.winnerGoesToMatchId,
      loserGoesToMatchId: loserGoesToMatchId ?? this.loserGoesToMatchId,
      isWalkover: isWalkover ?? this.isWalkover,
      walkoverReason: walkoverReason ?? this.walkoverReason,
      createdAt: createdAt ?? this.createdAt,
      games: games ?? this.games,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
    );
  }

  bool get hasTeams => teamAId != null && teamBId != null;
  bool get isComplete => status == MatchStatus.completed || status == MatchStatus.walkover;
  String get scoreDisplay => '$teamAScore - $teamBScore';
}

/// Individual game within a best-of series match
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

  factory MatchGame.fromJson(Map<String, dynamic> json) {
    return MatchGame(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      gameNumber: json['game_number'] as int,
      teamAScore: json['team_a_score'] as int? ?? 0,
      teamBScore: json['team_b_score'] as int? ?? 0,
      winnerId: json['winner_id'] as String?,
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
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
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  MatchGame copyWith({
    String? id,
    String? matchId,
    int? gameNumber,
    int? teamAScore,
    int? teamBScore,
    String? winnerId,
    MatchStatus? status,
    DateTime? createdAt,
  }) {
    return MatchGame(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      gameNumber: gameNumber ?? this.gameNumber,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      winnerId: winnerId ?? this.winnerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isComplete => status == MatchStatus.completed;
  String get scoreDisplay => '$teamAScore - $teamBScore';
}
