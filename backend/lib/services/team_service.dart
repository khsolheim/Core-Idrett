import 'dart:math';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/team.dart';

class TeamService {
  final Database _db;
  final _uuid = const Uuid();

  TeamService(this._db);

  Future<List<Map<String, dynamic>>> getTeamsForUser(String userId) async {
    // Get team memberships for user
    final memberships = await _db.client.select(
      'team_members',
      select: 'team_id,role',
      filters: {'user_id': 'eq.$userId'},
    );

    if (memberships.isEmpty) return [];

    // Get team IDs
    final teamIds = memberships.map((m) => m['team_id'] as String).toList();

    // Get teams
    final teams = await _db.client.select(
      'teams',
      filters: {'id': 'in.(${teamIds.join(',')})'},
      order: 'name.asc',
    );

    // Create lookup for roles
    final roleMap = <String, String>{};
    for (final m in memberships) {
      roleMap[m['team_id'] as String] = m['role'] as String;
    }

    return teams.map((t) {
      return {
        'id': t['id'],
        'name': t['name'],
        'sport': t['sport'],
        'invite_code': t['invite_code'],
        'created_at': t['created_at'],
        'user_role': roleMap[t['id']],
      };
    }).toList();
  }

  Future<Team> createTeam({
    required String name,
    String? sport,
    required String creatorId,
  }) async {
    final id = _uuid.v4();
    final inviteCode = _generateInviteCode();

    final result = await _db.client.insert('teams', {
      'id': id,
      'name': name,
      'sport': sport,
      'invite_code': inviteCode,
    });

    // Add creator as admin
    await _db.client.insert('team_members', {
      'id': _uuid.v4(),
      'user_id': creatorId,
      'team_id': id,
      'role': 'admin',
    });

    final row = result.first;
    return Team(
      id: row['id'] as String,
      name: row['name'] as String,
      sport: row['sport'] as String?,
      inviteCode: row['invite_code'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<Map<String, dynamic>?> getTeamById(String teamId, String userId) async {
    // Check if user is member
    final membership = await _db.client.select(
      'team_members',
      select: 'role',
      filters: {
        'team_id': 'eq.$teamId',
        'user_id': 'eq.$userId',
      },
    );

    if (membership.isEmpty) return null;

    // Get team
    final teams = await _db.client.select(
      'teams',
      filters: {'id': 'eq.$teamId'},
    );

    if (teams.isEmpty) return null;

    final team = teams.first;
    return {
      'id': team['id'],
      'name': team['name'],
      'sport': team['sport'],
      'invite_code': team['invite_code'],
      'created_at': team['created_at'],
      'user_role': membership.first['role'],
    };
  }

  Future<List<Map<String, dynamic>>> getTeamMembers(String teamId) async {
    // Get memberships
    final memberships = await _db.client.select(
      'team_members',
      filters: {'team_id': 'eq.$teamId'},
      order: 'role.asc',
    );

    if (memberships.isEmpty) return [];

    // Get user IDs
    final userIds = memberships.map((m) => m['user_id'] as String).toList();

    // Get users
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    // Create user lookup
    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    return memberships.map((m) {
      final user = userMap[m['user_id']] ?? {};
      return {
        'id': m['id'],
        'user_id': m['user_id'],
        'team_id': m['team_id'],
        'role': m['role'],
        'joined_at': m['joined_at'],
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
      };
    }).toList();
  }

  Future<String> regenerateInviteCode(String teamId) async {
    final inviteCode = _generateInviteCode();
    await _db.client.update(
      'teams',
      {'invite_code': inviteCode},
      filters: {'id': 'eq.$teamId'},
    );
    return inviteCode;
  }

  Future<void> updateMemberRole(String memberId, String role) async {
    await _db.client.update(
      'team_members',
      {'role': role},
      filters: {'id': 'eq.$memberId'},
    );
  }

  Future<Map<String, dynamic>?> updateTeam({
    required String teamId,
    String? name,
    String? sport,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (sport != null) updates['sport'] = sport;

    if (updates.isEmpty) return null;

    final result = await _db.client.update(
      'teams',
      updates,
      filters: {'id': 'eq.$teamId'},
      select: '*',
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<Map<String, dynamic>> getTeamSettings(String teamId) async {
    final result = await _db.client.select(
      'team_settings',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (result.isEmpty) {
      // Return default settings
      return {
        'team_id': teamId,
        'attendance_points': 1,
        'win_points': 3,
        'draw_points': 1,
        'loss_points': 0,
      };
    }

    return result.first;
  }

  Future<Map<String, dynamic>> updateTeamSettings({
    required String teamId,
    int? attendancePoints,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
  }) async {
    // Check if settings exist
    final existing = await _db.client.select(
      'team_settings',
      filters: {'team_id': 'eq.$teamId'},
    );

    final settings = <String, dynamic>{};
    if (attendancePoints != null) settings['attendance_points'] = attendancePoints;
    if (winPoints != null) settings['win_points'] = winPoints;
    if (drawPoints != null) settings['draw_points'] = drawPoints;
    if (lossPoints != null) settings['loss_points'] = lossPoints;

    if (existing.isEmpty) {
      // Insert new settings
      settings['id'] = _uuid.v4();
      settings['team_id'] = teamId;
      await _db.client.insert('team_settings', settings);
    } else {
      // Update existing settings
      await _db.client.update(
        'team_settings',
        settings,
        filters: {'team_id': 'eq.$teamId'},
      );
    }

    return getTeamSettings(teamId);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
