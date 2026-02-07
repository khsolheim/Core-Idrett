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

  factory TournamentRound.fromJson(Map<String, dynamic> row) {
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
