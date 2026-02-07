import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../helpers/collection_helpers.dart';
import '../models/mini_activity.dart';
import 'user_service.dart';

class MiniActivityService {
  final Database _db;
  final UserService _userService;
  final _uuid = const Uuid();

  MiniActivityService(this._db, this._userService);

  // ============ MINI-ACTIVITIES ============

  Future<MiniActivity> createMiniActivity({
    required String instanceId,
    String? templateId,
    required String name,
    required String type,
    int numTeams = 2,
    String? description,
    int? maxParticipants,
    bool enableLeaderboard = true,
    String? leaderboardId,
    int winPoints = 3,
    int drawPoints = 1,
    int lossPoints = 0,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('mini_activities', {
      'id': id,
      'instance_id': instanceId,
      'template_id': templateId,
      'name': name,
      'type': type,
      'description': description,
      'max_participants': maxParticipants,
      'enable_leaderboard': enableLeaderboard,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
    });

    return MiniActivity(
      id: id,
      instanceId: instanceId,
      templateId: templateId,
      name: name,
      type: type,
      numTeams: numTeams,
      createdAt: DateTime.now(),
      description: description,
      maxParticipants: maxParticipants,
      enableLeaderboard: enableLeaderboard,
      leaderboardId: leaderboardId,
      winPoints: winPoints,
      drawPoints: drawPoints,
      lossPoints: lossPoints,
    );
  }

  Future<MiniActivity> createStandaloneMiniActivity({
    required String teamId,
    String? templateId,
    required String name,
    required String type,
    int numTeams = 2,
    String? description,
    int? maxParticipants,
    bool enableLeaderboard = true,
    String? leaderboardId,
    int winPoints = 3,
    int drawPoints = 1,
    int lossPoints = 0,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('mini_activities', {
      'id': id,
      'team_id': teamId,
      'template_id': templateId,
      'name': name,
      'type': type,
      'description': description,
      'max_participants': maxParticipants,
      'enable_leaderboard': enableLeaderboard,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
    });

    return MiniActivity(
      id: id,
      teamId: teamId,
      templateId: templateId,
      name: name,
      type: type,
      numTeams: numTeams,
      createdAt: DateTime.now(),
      description: description,
      maxParticipants: maxParticipants,
      enableLeaderboard: enableLeaderboard,
      leaderboardId: leaderboardId,
      winPoints: winPoints,
      drawPoints: drawPoints,
      lossPoints: lossPoints,
    );
  }

  Future<MiniActivity?> updateMiniActivity({
    required String miniActivityId,
    String? name,
    String? description,
    int? maxParticipants,
    bool? enableLeaderboard,
    String? leaderboardId,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    bool? handicapEnabled,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (maxParticipants != null) updates['max_participants'] = maxParticipants;
    if (enableLeaderboard != null) updates['enable_leaderboard'] = enableLeaderboard;
    if (winPoints != null) updates['win_points'] = winPoints;
    if (drawPoints != null) updates['draw_points'] = drawPoints;
    if (lossPoints != null) updates['loss_points'] = lossPoints;
    if (handicapEnabled != null) updates['handicap_enabled'] = handicapEnabled;

    if (updates.isEmpty) return null;

    await _db.client.update(
      'mini_activities',
      updates,
      filters: {'id': 'eq.$miniActivityId'},
    );

    final result = await _db.client.select(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );

    if (result.isEmpty) return null;
    return MiniActivity.fromJson(result.first);
  }

  Future<MiniActivity> duplicateMiniActivity({
    required String miniActivityId,
    String? newInstanceId,
    String? newTeamId,
    String? newName,
  }) async {
    final result = await _db.client.select(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );

    if (result.isEmpty) {
      throw Exception('Mini-activity not found');
    }

    final original = MiniActivity.fromJson(result.first);
    final id = _uuid.v4();

    await _db.client.insert('mini_activities', {
      'id': id,
      'instance_id': newInstanceId ?? original.instanceId,
      'team_id': newTeamId ?? original.teamId,
      'template_id': original.templateId,
      'name': newName ?? '${original.name} (kopi)',
      'type': original.type,
      'description': original.description,
      'max_participants': original.maxParticipants,
      'enable_leaderboard': original.enableLeaderboard,
      'win_points': original.winPoints,
      'draw_points': original.drawPoints,
      'loss_points': original.lossPoints,
      'handicap_enabled': original.handicapEnabled,
    });

    return MiniActivity(
      id: id,
      instanceId: newInstanceId ?? original.instanceId,
      teamId: newTeamId ?? original.teamId,
      templateId: original.templateId,
      name: newName ?? '${original.name} (kopi)',
      type: original.type,
      numTeams: original.numTeams,
      createdAt: DateTime.now(),
      description: original.description,
      maxParticipants: original.maxParticipants,
      enableLeaderboard: original.enableLeaderboard,
      leaderboardId: original.leaderboardId,
      winPoints: original.winPoints,
      drawPoints: original.drawPoints,
      lossPoints: original.lossPoints,
      handicapEnabled: original.handicapEnabled,
    );
  }

  Future<void> archiveMiniActivity(String miniActivityId) async {
    await _db.client.update(
      'mini_activities',
      {'archived_at': DateTime.now().toIso8601String()},
      filters: {'id': 'eq.$miniActivityId'},
    );
  }

  Future<void> unarchiveMiniActivity(String miniActivityId) async {
    await _db.client.update(
      'mini_activities',
      {'archived_at': null},
      filters: {'id': 'eq.$miniActivityId'},
    );
  }

  Future<List<Map<String, dynamic>>> getStandaloneMiniActivitiesForTeam(
    String teamId, {
    bool includeArchived = false,
  }) async {
    final filters = <String, String>{
      'team_id': 'eq.$teamId',
    };

    if (!includeArchived) {
      filters['archived_at'] = 'is.null';
    }

    final miniActivities = await _db.client.select(
      'mini_activities',
      filters: filters,
      order: 'created_at.desc',
    );

    if (miniActivities.isEmpty) return [];

    final miniActivityIds = miniActivities.map((m) => m['id'] as String).toList();

    // Get team counts
    final teams = await _db.client.select(
      'mini_activity_teams',
      select: 'mini_activity_id',
      filters: {'mini_activity_id': 'in.(${miniActivityIds.join(',')})'},
    );

    final teamCounts = groupByCount(teams, 'mini_activity_id');

    // Get participant counts
    final participants = await _db.client.select(
      'mini_activity_participants',
      select: 'mini_activity_id',
      filters: {'mini_activity_id': 'in.(${miniActivityIds.join(',')})'},
    );

    final participantCounts = groupByCount(participants, 'mini_activity_id');

    return miniActivities.map((ma) {
      final id = ma['id'] as String;
      return {
        ...ma,
        'team_count': teamCounts[id] ?? 0,
        'participant_count': participantCounts[id] ?? 0,
      };
    }).toList();
  }

  Future<MiniActivity?> getMiniActivityById(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );

    if (result.isEmpty) return null;
    return MiniActivity.fromJson(result.first);
  }

  Future<List<Map<String, dynamic>>> getMiniActivitiesForInstance(String instanceId) async {
    final miniActivities = await _db.client.select(
      'mini_activities',
      filters: {
        'instance_id': 'eq.$instanceId',
        'archived_at': 'is.null',
      },
      order: 'created_at.asc',
    );

    if (miniActivities.isEmpty) return [];

    final miniActivityIds = miniActivities.map((m) => m['id'] as String).toList();

    // Get team counts
    final teams = await _db.client.select(
      'mini_activity_teams',
      select: 'mini_activity_id',
      filters: {'mini_activity_id': 'in.(${miniActivityIds.join(',')})'},
    );

    final teamCounts = groupByCount(teams, 'mini_activity_id');

    // Get participant counts
    final participants = await _db.client.select(
      'mini_activity_participants',
      select: 'mini_activity_id',
      filters: {'mini_activity_id': 'in.(${miniActivityIds.join(',')})'},
    );

    final participantCounts = groupByCount(participants, 'mini_activity_id');

    return miniActivities.map((ma) {
      final id = ma['id'] as String;
      return {
        ...ma,
        'team_count': teamCounts[id] ?? 0,
        'participant_count': participantCounts[id] ?? 0,
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getMiniActivityDetail(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );

    if (result.isEmpty) return null;
    final miniActivity = result.first;

    // Get teams
    final teamsResult = await _db.client.select(
      'mini_activity_teams',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'name.asc',
    );

    // Get participants for teams
    final teamIds = teamsResult.map((t) => t['id'] as String).toList();
    final allParticipants = teamIds.isNotEmpty
        ? await _db.client.select(
            'mini_activity_participants',
            filters: {'mini_team_id': 'in.(${teamIds.join(',')})'},
          )
        : <Map<String, dynamic>>[];

    // For individual activities, get participants directly
    List<Map<String, dynamic>> individualParticipantsResult = [];
    if (miniActivity['type'] == 'individual') {
      individualParticipantsResult = await _db.client.select(
        'mini_activity_participants',
        filters: {'mini_activity_id': 'eq.$miniActivityId'},
        order: 'points.desc',
      );
    }

    // Batch fetch ALL user info in one query
    final allUserIds = <String>{
      ...allParticipants.map((p) => p['user_id'] as String),
      ...individualParticipantsResult.map((p) => p['user_id'] as String),
    }.toList();

    final userMap = await _userService.getUserMap(allUserIds);

    // Build teams with participants
    final teams = teamsResult.map((t) {
      final teamParticipants = allParticipants
          .where((p) => p['mini_team_id'] == t['id'])
          .map((p) {
        final user = userMap[p['user_id']] ?? {};
        return {
          'id': p['id'],
          'user_id': p['user_id'],
          'points': p['points'],
          'user_name': user['name'],
          'user_avatar_url': user['avatar_url'],
        };
      }).toList();

      return {
        'id': t['id'],
        'name': t['name'],
        'final_score': t['final_score'],
        'participants': teamParticipants,
      };
    }).toList();

    // Build individual participants list using the shared userMap
    final individualParticipants = individualParticipantsResult.map((p) {
      final user = userMap[p['user_id']] ?? {};
      return {
        'id': p['id'],
        'user_id': p['user_id'],
        'points': p['points'],
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
      };
    }).toList();

    // Get adjustments
    final adjustmentsResult = await _db.client.select(
      'mini_activity_adjustments',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'created_at.desc',
    );
    final adjustments = adjustmentsResult
        .map((row) => MiniActivityAdjustment.fromJson(row))
        .toList();

    return {
      ...miniActivity,
      'teams': teams,
      'participants': individualParticipants,
      'adjustments': adjustments.map((a) => a.toJson()).toList(),
    };
  }

  Future<void> deleteMiniActivity(String miniActivityId) async {
    await _db.client.delete(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );
  }

  Future<List<Map<String, dynamic>>> getHistory({
    required String teamId,
    String? templateId,
    int limit = 20,
  }) async {
    final filters = <String, String>{
      'team_id': 'eq.$teamId',
    };

    if (templateId != null) {
      filters['template_id'] = 'eq.$templateId';
    }

    final miniActivities = await _db.client.select(
      'mini_activities',
      filters: filters,
      order: 'created_at.desc',
    );

    if (miniActivities.isEmpty) return [];

    // Batch fetch ALL teams for all mini-activities in one query
    final allMaIds = miniActivities.map((m) => m['id'] as String).toList();
    final allTeams = await _db.client.select(
      'mini_activity_teams',
      filters: {'mini_activity_id': 'in.(${allMaIds.join(",")})'},
      order: 'name.asc',
    );

    // Group teams by mini_activity_id
    final teamsByMa = <String, List<Map<String, dynamic>>>{};
    for (final t in allTeams) {
      final maId = t['mini_activity_id'] as String;
      teamsByMa.putIfAbsent(maId, () => []).add(t);
    }

    final result = <Map<String, dynamic>>[];

    for (final ma in miniActivities) {
      final miniActivityId = ma['id'] as String;
      final teams = teamsByMa[miniActivityId] ?? [];

      final hasResult = teams.any((t) => t['final_score'] != null) ||
          ma['winner_team_id'] != null;

      if (hasResult) {
        result.add({
          'id': ma['id'],
          'name': ma['name'],
          'created_at': ma['created_at'],
          'winner_team_id': ma['winner_team_id'],
          'teams': teams.map((t) => {
            'id': t['id'],
            'name': t['name'],
            'final_score': t['final_score'],
          }).toList(),
        });
      }

      if (result.length >= limit) break;
    }

    return result;
  }
}
