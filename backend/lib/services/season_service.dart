import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/season.dart';

class SeasonService {
  final Database _db;
  final _uuid = const Uuid();

  SeasonService(this._db);

  /// Get all seasons for a team
  Future<List<Season>> getSeasonsForTeam(String teamId) async {
    final result = await _db.client.select(
      'seasons',
      filters: {'team_id': 'eq.$teamId'},
      order: 'start_date.desc.nullslast,created_at.desc',
    );

    return result.map((row) => Season.fromJson(row)).toList();
  }

  /// Get the active season for a team
  Future<Season?> getActiveSeason(String teamId) async {
    final result = await _db.client.select(
      'seasons',
      filters: {
        'team_id': 'eq.$teamId',
        'is_active': 'eq.true',
      },
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Season.fromJson(result.first);
  }

  /// Get a season by ID
  Future<Season?> getSeasonById(String seasonId) async {
    final result = await _db.client.select(
      'seasons',
      filters: {'id': 'eq.$seasonId'},
    );

    if (result.isEmpty) return null;
    return Season.fromJson(result.first);
  }

  /// Create a new season
  Future<Season> createSeason({
    required String teamId,
    required String name,
    DateTime? startDate,
    DateTime? endDate,
    bool setActive = false,
  }) async {
    final id = _uuid.v4();

    // If setActive is true, deactivate other seasons first
    if (setActive) {
      await _db.client.update(
        'seasons',
        {'is_active': false},
        filters: {'team_id': 'eq.$teamId'},
      );
    }

    await _db.client.insert('seasons', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_active': setActive,
    });

    return Season(
      id: id,
      teamId: teamId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      isActive: setActive,
      createdAt: DateTime.now(),
    );
  }

  /// Update a season
  Future<Season?> updateSeason({
    required String seasonId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (clearStartDate) {
      updates['start_date'] = null;
    } else if (startDate != null) {
      updates['start_date'] = startDate.toIso8601String().split('T').first;
    }
    if (clearEndDate) {
      updates['end_date'] = null;
    } else if (endDate != null) {
      updates['end_date'] = endDate.toIso8601String().split('T').first;
    }

    if (updates.isEmpty) {
      return getSeasonById(seasonId);
    }

    await _db.client.update(
      'seasons',
      updates,
      filters: {'id': 'eq.$seasonId'},
    );

    return getSeasonById(seasonId);
  }

  /// Set a season as active (deactivates others)
  Future<void> setActiveSeason(String teamId, String seasonId) async {
    // Deactivate all seasons for this team
    await _db.client.update(
      'seasons',
      {'is_active': false},
      filters: {'team_id': 'eq.$teamId'},
    );

    // Activate the specified season
    await _db.client.update(
      'seasons',
      {'is_active': true},
      filters: {'id': 'eq.$seasonId'},
    );
  }

  /// Delete a season (only if not active and has no linked data)
  Future<bool> deleteSeason(String seasonId) async {
    // Check if season is active
    final season = await getSeasonById(seasonId);
    if (season == null) return false;
    if (season.isActive) return false;

    // Check for linked activity instances
    final instances = await _db.client.select(
      'activity_instances',
      select: 'id',
      filters: {'season_id': 'eq.$seasonId'},
      limit: 1,
    );

    if (instances.isNotEmpty) return false;

    // Check for linked leaderboards
    final leaderboards = await _db.client.select(
      'leaderboards',
      select: 'id',
      filters: {'season_id': 'eq.$seasonId'},
      limit: 1,
    );

    if (leaderboards.isNotEmpty) return false;

    await _db.client.delete(
      'seasons',
      filters: {'id': 'eq.$seasonId'},
    );

    return true;
  }

  /// Create a new season and archive the current one
  Future<Season> startNewSeason({
    required String teamId,
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Deactivate all current seasons
    await _db.client.update(
      'seasons',
      {'is_active': false},
      filters: {'team_id': 'eq.$teamId'},
    );

    // Create the new season as active
    return createSeason(
      teamId: teamId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      setActive: true,
    );
  }

  /// Get team ID for a season (for authorization checks)
  Future<String?> getTeamIdForSeason(String seasonId) async {
    final result = await _db.client.select(
      'seasons',
      select: 'team_id',
      filters: {'id': 'eq.$seasonId'},
    );

    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
  }
}
