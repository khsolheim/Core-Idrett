import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/tournament.dart';
import '../../helpers/parsing_helpers.dart';

class TournamentCrudService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentCrudService(this._db);

  // ============ TOURNAMENT CRUD ============

  Future<Tournament> createTournament({
    required String miniActivityId,
    required TournamentType tournamentType,
    int bestOf = 1,
    bool bronzeFinal = false,
    SeedingMethod seedingMethod = SeedingMethod.random,
    int? maxParticipants,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('tournaments', {
      'id': id,
      'mini_activity_id': miniActivityId,
      'tournament_type': tournamentType.value,
      'best_of': bestOf,
      'bronze_final': bronzeFinal,
      'seeding_method': seedingMethod.value,
      'max_participants': maxParticipants,
      'status': 'setup',
    });

    return Tournament(
      id: id,
      miniActivityId: miniActivityId,
      tournamentType: tournamentType,
      bestOf: bestOf,
      bronzeFinal: bronzeFinal,
      seedingMethod: seedingMethod,
      maxParticipants: maxParticipants,
      status: TournamentStatus.setup,
      createdAt: DateTime.now(),
    );
  }

  Future<Tournament?> getTournamentById(String tournamentId) async {
    final result = await _db.client.select(
      'tournaments',
      filters: {'id': 'eq.$tournamentId'},
    );
    if (result.isEmpty) return null;
    return Tournament.fromJson(result.first);
  }

  Future<Tournament?> getTournamentForMiniActivity(String miniActivityId) async {
    final result = await _db.client.select(
      'tournaments',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );
    if (result.isEmpty) return null;
    return Tournament.fromJson(result.first);
  }

  /// Get the team_id for a tournament by looking up the mini_activity's team_id.
  Future<String?> getTeamIdForTournament(String tournamentId) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) return null;
    // mini_activities has team_id
    final result = await _db.client.select(
      'mini_activities',
      select: 'team_id',
      filters: {'id': 'eq.${tournament.miniActivityId}'},
    );
    if (result.isEmpty) return null;
    return safeStringNullable(result.first, 'team_id');
  }

  /// Get the team_id for a mini_activity.
  Future<String?> getTeamIdForMiniActivity(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activities',
      select: 'team_id',
      filters: {'id': 'eq.$miniActivityId'},
    );
    if (result.isEmpty) return null;
    return safeStringNullable(result.first, 'team_id');
  }

  Future<void> updateTournamentStatus(String tournamentId, TournamentStatus status) async {
    await _db.client.update(
      'tournaments',
      {'status': status.value},
      filters: {'id': 'eq.$tournamentId'},
    );
  }

  Future<Tournament> updateTournament({
    required String tournamentId,
    int? bestOf,
    bool? bronzeFinal,
    TournamentStatus? status,
    SeedingMethod? seedingMethod,
    int? maxParticipants,
  }) async {
    final updates = <String, dynamic>{};
    if (bestOf != null) updates['best_of'] = bestOf;
    if (bronzeFinal != null) updates['bronze_final'] = bronzeFinal;
    if (status != null) updates['status'] = status.value;
    if (seedingMethod != null) updates['seeding_method'] = seedingMethod.value;
    if (maxParticipants != null) updates['max_participants'] = maxParticipants;

    if (updates.isNotEmpty) {
      await _db.client.update(
        'tournaments',
        updates,
        filters: {'id': 'eq.$tournamentId'},
      );
    }

    final result = await _db.client.select(
      'tournaments',
      filters: {'id': 'eq.$tournamentId'},
    );
    return Tournament.fromJson(result.first);
  }

  Future<void> deleteTournament(String tournamentId) async {
    await _db.client.delete(
      'tournaments',
      filters: {'id': 'eq.$tournamentId'},
    );
  }
}
