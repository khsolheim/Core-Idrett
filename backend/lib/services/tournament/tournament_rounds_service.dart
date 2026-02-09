import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/tournament.dart';

class TournamentRoundsService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentRoundsService(this._db);

  // ============ ROUNDS ============

  Future<TournamentRound> createRound({
    required String tournamentId,
    required int roundNumber,
    String? roundName,
    RoundType roundType = RoundType.winners,
    DateTime? scheduledTime,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('tournament_rounds', {
      'id': id,
      'tournament_id': tournamentId,
      'round_number': roundNumber,
      'round_name': roundName,
      'round_type': roundType.value,
      'status': 'pending',
      'scheduled_time': scheduledTime?.toIso8601String(),
    });

    return TournamentRound(
      id: id,
      tournamentId: tournamentId,
      roundNumber: roundNumber,
      roundName: roundName,
      roundType: roundType,
      status: MatchStatus.pending,
      scheduledTime: scheduledTime,
      createdAt: DateTime.now(),
    );
  }

  Future<List<TournamentRound>> getRoundsForTournament(String tournamentId) async {
    final result = await _db.client.select(
      'tournament_rounds',
      filters: {'tournament_id': 'eq.$tournamentId'},
      order: 'round_number.asc',
    );
    return result.map((row) => TournamentRound.fromJson(row)).toList();
  }

  Future<void> updateRoundStatus(String roundId, MatchStatus status) async {
    await _db.client.update(
      'tournament_rounds',
      {'status': status.value},
      filters: {'id': 'eq.$roundId'},
    );
  }

  Future<TournamentRound> updateRound({
    required String roundId,
    String? roundName,
    TournamentStatus? status,
    DateTime? scheduledTime,
  }) async {
    final updates = <String, dynamic>{};
    if (roundName != null) updates['round_name'] = roundName;
    if (status != null) updates['status'] = status.value;
    if (scheduledTime != null) updates['scheduled_time'] = scheduledTime.toIso8601String();

    if (updates.isNotEmpty) {
      await _db.client.update(
        'tournament_rounds',
        updates,
        filters: {'id': 'eq.$roundId'},
      );
    }

    final result = await _db.client.select(
      'tournament_rounds',
      filters: {'id': 'eq.$roundId'},
    );
    return TournamentRound.fromJson(result.first);
  }
}
