import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

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

// BM-027: Tournament match model
class TournamentMatch extends Equatable {
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

  const TournamentMatch({
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

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        roundId,
        bracketPosition,
        teamAId,
        teamBId,
        winnerId,
        teamAScore,
        teamBScore,
        status,
        scheduledTime,
        matchOrder,
        winnerGoesToMatchId,
        loserGoesToMatchId,
        isWalkover,
        walkoverReason,
        createdAt,
      ];

  factory TournamentMatch.fromJson(Map<String, dynamic> row) {
    return TournamentMatch(
      id: safeString(row, 'id'),
      tournamentId: safeString(row, 'tournament_id'),
      roundId: safeString(row, 'round_id'),
      bracketPosition: safeInt(row, 'bracket_position'),
      teamAId: safeStringNullable(row, 'team_a_id'),
      teamBId: safeStringNullable(row, 'team_b_id'),
      winnerId: safeStringNullable(row, 'winner_id'),
      teamAScore: safeIntNullable(row, 'team_a_score'),
      teamBScore: safeIntNullable(row, 'team_b_score'),
      status: MatchStatus.fromString(safeString(row, 'status', defaultValue: 'pending')),
      scheduledTime: safeDateTimeNullable(row, 'scheduled_time'),
      matchOrder: safeInt(row, 'match_order', defaultValue: 0),
      winnerGoesToMatchId: safeStringNullable(row, 'winner_goes_to_match_id'),
      loserGoesToMatchId: safeStringNullable(row, 'loser_goes_to_match_id'),
      isWalkover: safeBool(row, 'is_walkover', defaultValue: false),
      walkoverReason: safeStringNullable(row, 'walkover_reason'),
      createdAt: requireDateTime(row, 'created_at'),
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
class MatchGame extends Equatable {
  final String id;
  final String matchId;
  final int gameNumber;
  final int teamAScore;
  final int teamBScore;
  final String? winnerId;
  final MatchStatus status;
  final DateTime createdAt;

  const MatchGame({
    required this.id,
    required this.matchId,
    required this.gameNumber,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.winnerId,
    this.status = MatchStatus.pending,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        matchId,
        gameNumber,
        teamAScore,
        teamBScore,
        winnerId,
        status,
        createdAt,
      ];

  factory MatchGame.fromJson(Map<String, dynamic> row) {
    return MatchGame(
      id: safeString(row, 'id'),
      matchId: safeString(row, 'match_id'),
      gameNumber: safeInt(row, 'game_number'),
      teamAScore: safeInt(row, 'team_a_score', defaultValue: 0),
      teamBScore: safeInt(row, 'team_b_score', defaultValue: 0),
      winnerId: safeStringNullable(row, 'winner_id'),
      status: MatchStatus.fromString(safeString(row, 'status', defaultValue: 'pending')),
      createdAt: requireDateTime(row, 'created_at'),
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
