import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';
import 'tournament_match.dart';

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

// BM-026: Tournament round model
class TournamentRound extends Equatable {
  final String id;
  final String tournamentId;
  final int roundNumber;
  final String? roundName;
  final RoundType roundType;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final DateTime createdAt;

  const TournamentRound({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    this.roundName,
    this.roundType = RoundType.winners,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        roundNumber,
        roundName,
        roundType,
        status,
        scheduledTime,
        createdAt,
      ];

  factory TournamentRound.fromJson(Map<String, dynamic> row) {
    return TournamentRound(
      id: safeString(row, 'id'),
      tournamentId: safeString(row, 'tournament_id'),
      roundNumber: safeInt(row, 'round_number'),
      roundName: safeStringNullable(row, 'round_name'),
      roundType: RoundType.fromString(safeString(row, 'round_type', defaultValue: 'winners')),
      status: MatchStatus.fromString(safeString(row, 'status', defaultValue: 'pending')),
      scheduledTime: safeDateTimeNullable(row, 'scheduled_time'),
      createdAt: requireDateTime(row, 'created_at'),
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
