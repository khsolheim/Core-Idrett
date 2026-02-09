import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/mini_activity.dart';
import '../../helpers/parsing_helpers.dart';

/// Service for team CRUD, participant management, and handicaps
class MiniActivityDivisionManagementService {
  final Database _db;
  final _uuid = const Uuid();

  MiniActivityDivisionManagementService(this._db);

  // ============ TEAM DIVISION MANAGEMENT ============

  /// Reset team division - delete all teams and participants
  Future<void> resetTeamDivision(String miniActivityId) async {
    // Delete all participants
    await _db.client.delete(
      'mini_activity_participants',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );

    // Delete all teams
    await _db.client.delete(
      'mini_activity_teams',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );

    // Reset division method
    await _db.client.update(
      'mini_activities',
      {'division_method': null},
      filters: {'id': 'eq.$miniActivityId'},
    );
  }

  /// Add late participant to existing team
  Future<MiniActivityParticipant> addLateParticipant({
    required String miniActivityId,
    required String teamId,
    required String userId,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('mini_activity_participants', {
      'id': id,
      'mini_activity_id': miniActivityId,
      'mini_team_id': teamId,
      'user_id': userId,
      'points': 0,
    });

    return MiniActivityParticipant(
      id: id,
      miniActivityId: miniActivityId,
      miniTeamId: teamId,
      userId: userId,
      points: 0,
    );
  }

  /// Update team name
  Future<void> updateTeamName({
    required String teamId,
    required String newName,
  }) async {
    await _db.client.update(
      'mini_activity_teams',
      {'name': newName},
      filters: {'id': 'eq.$teamId'},
    );
  }

  /// Move a participant to a different team (for manual adjustments)
  Future<void> moveParticipantToTeam({
    required String participantId,
    required String newTeamId,
  }) async {
    await _db.client.update(
      'mini_activity_participants',
      {'mini_team_id': newTeamId},
      filters: {'id': 'eq.$participantId'},
    );
  }

  // ============ TEAM QUERIES ============

  /// Get team by ID
  Future<MiniActivityTeam?> getTeamById(String teamId) async {
    final result = await _db.client.select(
      'mini_activity_teams',
      filters: {'id': 'eq.$teamId'},
    );

    if (result.isEmpty) return null;
    return MiniActivityTeam.fromJson(result.first);
  }

  /// Get teams for mini-activity
  Future<List<MiniActivityTeam>> getTeamsForMiniActivity(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activity_teams',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'name.asc',
    );
    return result.map((row) => MiniActivityTeam.fromJson(row)).toList();
  }

  /// Remove participant from activity
  Future<void> removeParticipant(String participantId) async {
    await _db.client.delete(
      'mini_activity_participants',
      filters: {'id': 'eq.$participantId'},
    );
  }

  /// Delete a single team from a mini-activity
  /// Optionally moves participants to another team or removes them
  Future<void> deleteTeam({
    required String miniActivityId,
    required String teamId,
    String? moveParticipantsToTeamId,
  }) async {
    if (moveParticipantsToTeamId != null) {
      // Move participants to the target team
      await _db.client.update(
        'mini_activity_participants',
        {'mini_team_id': moveParticipantsToTeamId},
        filters: {'mini_team_id': 'eq.$teamId'},
      );
    } else {
      // Delete participants from this team
      await _db.client.delete(
        'mini_activity_participants',
        filters: {'mini_team_id': 'eq.$teamId'},
      );
    }

    // Delete the team
    await _db.client.delete(
      'mini_activity_teams',
      filters: {'id': 'eq.$teamId'},
    );
  }

  /// Create a new empty team for a mini-activity
  Future<MiniActivityTeam> createTeam({
    required String miniActivityId,
    required String name,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('mini_activity_teams', {
      'id': id,
      'mini_activity_id': miniActivityId,
      'name': name,
    });

    return MiniActivityTeam(
      id: id,
      miniActivityId: miniActivityId,
      name: name,
    );
  }

  // ============ HANDICAPS ============

  /// Set or update handicap for a user in a mini-activity
  Future<MiniActivityHandicap> setHandicap({
    required String miniActivityId,
    required String userId,
    required double handicapValue,
  }) async {
    // Check for existing handicap
    final existing = await _db.client.select(
      'mini_activity_handicaps',
      filters: {
        'mini_activity_id': 'eq.$miniActivityId',
        'user_id': 'eq.$userId',
      },
    );

    if (existing.isNotEmpty) {
      await _db.client.update(
        'mini_activity_handicaps',
        {
          'handicap_value': handicapValue,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {
          'mini_activity_id': 'eq.$miniActivityId',
          'user_id': 'eq.$userId',
        },
      );

      return MiniActivityHandicap(
        id: safeString(existing.first, 'id'),
        miniActivityId: miniActivityId,
        userId: userId,
        handicapValue: handicapValue,
        createdAt: existing.first['created_at'] as DateTime,
        updatedAt: DateTime.now(),
      );
    }

    final id = _uuid.v4();
    await _db.client.insert('mini_activity_handicaps', {
      'id': id,
      'mini_activity_id': miniActivityId,
      'user_id': userId,
      'handicap_value': handicapValue,
    });

    return MiniActivityHandicap(
      id: id,
      miniActivityId: miniActivityId,
      userId: userId,
      handicapValue: handicapValue,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get all handicaps for a mini-activity
  Future<List<MiniActivityHandicap>> getHandicaps(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activity_handicaps',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );
    return result.map((row) => MiniActivityHandicap.fromJson(row)).toList();
  }

  /// Remove handicap for a user in a mini-activity
  Future<void> removeHandicap({
    required String miniActivityId,
    required String userId,
  }) async {
    await _db.client.delete(
      'mini_activity_handicaps',
      filters: {
        'mini_activity_id': 'eq.$miniActivityId',
        'user_id': 'eq.$userId',
      },
    );
  }
}
