import 'dart:math';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/mini_activity.dart';

class MiniActivityService {
  final Database _db;
  final _uuid = const Uuid();
  final _random = Random();

  MiniActivityService(this._db);

  // ============ TEMPLATES ============

  Future<List<ActivityTemplate>> getTemplatesForTeam(String teamId) async {
    final result = await _db.client.select(
      'activity_templates',
      filters: {'team_id': 'eq.$teamId'},
      order: 'name.asc',
    );
    return result.map((row) => ActivityTemplate.fromRow(row)).toList();
  }

  Future<ActivityTemplate> createTemplate({
    required String teamId,
    required String name,
    required String type,
    int defaultPoints = 1,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    int winPoints = 3,
    int drawPoints = 1,
    int lossPoints = 0,
    String? leaderboardId,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('activity_templates', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'type': type,
      'default_points': defaultPoints,
      'description': description,
      'instructions': instructions,
      'sport_type': sportType,
      'suggested_rules': suggestedRules,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      'leaderboard_id': leaderboardId,
    });

    return ActivityTemplate(
      id: id,
      teamId: teamId,
      name: name,
      type: type,
      defaultPoints: defaultPoints,
      createdAt: DateTime.now(),
      description: description,
      instructions: instructions,
      sportType: sportType,
      suggestedRules: suggestedRules,
      winPoints: winPoints,
      drawPoints: drawPoints,
      lossPoints: lossPoints,
      leaderboardId: leaderboardId,
    );
  }

  Future<ActivityTemplate?> updateTemplate({
    required String templateId,
    String? name,
    String? type,
    int? defaultPoints,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    bool? isFavorite,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (defaultPoints != null) updates['default_points'] = defaultPoints;
    if (description != null) updates['description'] = description;
    if (instructions != null) updates['instructions'] = instructions;
    if (sportType != null) updates['sport_type'] = sportType;
    if (suggestedRules != null) updates['suggested_rules'] = suggestedRules;
    if (isFavorite != null) updates['is_favorite'] = isFavorite;
    if (winPoints != null) updates['win_points'] = winPoints;
    if (drawPoints != null) updates['draw_points'] = drawPoints;
    if (lossPoints != null) updates['loss_points'] = lossPoints;
    if (leaderboardId != null) updates['leaderboard_id'] = leaderboardId;

    if (updates.isEmpty) return null;

    await _db.client.update(
      'activity_templates',
      updates,
      filters: {'id': 'eq.$templateId'},
    );

    final result = await _db.client.select(
      'activity_templates',
      filters: {'id': 'eq.$templateId'},
    );

    if (result.isEmpty) return null;
    return ActivityTemplate.fromRow(result.first);
  }

  Future<void> toggleTemplateFavorite(String templateId) async {
    final result = await _db.client.select(
      'activity_templates',
      select: 'is_favorite',
      filters: {'id': 'eq.$templateId'},
    );

    if (result.isEmpty) return;
    final currentFavorite = result.first['is_favorite'] as bool? ?? false;

    await _db.client.update(
      'activity_templates',
      {'is_favorite': !currentFavorite},
      filters: {'id': 'eq.$templateId'},
    );
  }

  Future<String?> getTeamIdForTemplate(String templateId) async {
    final result = await _db.client.select(
      'activity_templates',
      select: 'team_id',
      filters: {'id': 'eq.$templateId'},
    );
    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
  }

  Future<void> deleteTemplate(String templateId) async {
    await _db.client.delete(
      'activity_templates',
      filters: {'id': 'eq.$templateId'},
    );
  }

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
      'num_teams': numTeams,
      'description': description,
      'max_participants': maxParticipants,
      'enable_leaderboard': enableLeaderboard,
      'leaderboard_id': leaderboardId,
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

  // BS-002: Create standalone mini-activity (not linked to activity instance)
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
      'num_teams': numTeams,
      'description': description,
      'max_participants': maxParticipants,
      'enable_leaderboard': enableLeaderboard,
      'leaderboard_id': leaderboardId,
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

  // BS-001: Update mini-activity
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
    if (leaderboardId != null) updates['leaderboard_id'] = leaderboardId;
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
    return MiniActivity.fromRow(result.first);
  }

  // BS-003: Reset team division
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
      {'division_method': null, 'num_teams': 2},
      filters: {'id': 'eq.$miniActivityId'},
    );
  }

  // BS-004: Add late participant to existing team
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

  // BS-005: Award adjustment (bonus/penalty)
  Future<MiniActivityAdjustment> awardAdjustment({
    required String miniActivityId,
    String? teamId,
    String? userId,
    required int points,
    String? reason,
    required String createdBy,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('mini_activity_adjustments', {
      'id': id,
      'mini_activity_id': miniActivityId,
      'team_id': teamId,
      'user_id': userId,
      'points': points,
      'reason': reason,
      'created_by': createdBy,
    });

    return MiniActivityAdjustment(
      id: id,
      miniActivityId: miniActivityId,
      teamId: teamId,
      userId: userId,
      points: points,
      reason: reason,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  // BS-006: Get adjustments for mini-activity
  Future<List<MiniActivityAdjustment>> getAdjustments(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activity_adjustments',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'created_at.desc',
    );
    return result.map((row) => MiniActivityAdjustment.fromRow(row)).toList();
  }

  // BS-007: Duplicate mini-activity
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

    final original = MiniActivity.fromRow(result.first);
    final id = _uuid.v4();

    await _db.client.insert('mini_activities', {
      'id': id,
      'instance_id': newInstanceId ?? original.instanceId,
      'team_id': newTeamId ?? original.teamId,
      'template_id': original.templateId,
      'name': newName ?? '${original.name} (kopi)',
      'type': original.type,
      'num_teams': original.numTeams,
      'description': original.description,
      'max_participants': original.maxParticipants,
      'enable_leaderboard': original.enableLeaderboard,
      'leaderboard_id': original.leaderboardId,
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

  // BS-008: Archive mini-activity
  Future<void> archiveMiniActivity(String miniActivityId) async {
    await _db.client.update(
      'mini_activities',
      {'archived_at': DateTime.now().toIso8601String()},
      filters: {'id': 'eq.$miniActivityId'},
    );
  }

  // Unarchive mini-activity
  Future<void> unarchiveMiniActivity(String miniActivityId) async {
    await _db.client.update(
      'mini_activities',
      {'archived_at': null},
      filters: {'id': 'eq.$miniActivityId'},
    );
  }

  // BS-009: Get standalone mini-activities for team
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

    final teamCounts = <String, int>{};
    for (final t in teams) {
      final id = t['mini_activity_id'] as String;
      teamCounts[id] = (teamCounts[id] ?? 0) + 1;
    }

    // Get participant counts
    final participants = await _db.client.select(
      'mini_activity_participants',
      select: 'mini_activity_id',
      filters: {'mini_activity_id': 'in.(${miniActivityIds.join(',')})'},
    );

    final participantCounts = <String, int>{};
    for (final p in participants) {
      final id = p['mini_activity_id'] as String;
      participantCounts[id] = (participantCounts[id] ?? 0) + 1;
    }

    return miniActivities.map((ma) {
      final id = ma['id'] as String;
      return {
        ...ma,
        'team_count': teamCounts[id] ?? 0,
        'participant_count': participantCounts[id] ?? 0,
      };
    }).toList();
  }

  // BS-010: Update team name
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

  // Get mini-activity by ID
  Future<MiniActivity?> getMiniActivityById(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );

    if (result.isEmpty) return null;
    return MiniActivity.fromRow(result.first);
  }

  Future<List<Map<String, dynamic>>> getMiniActivitiesForInstance(String instanceId) async {
    // Get mini-activities
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

    final teamCounts = <String, int>{};
    for (final t in teams) {
      final id = t['mini_activity_id'] as String;
      teamCounts[id] = (teamCounts[id] ?? 0) + 1;
    }

    // Get participant counts
    final participants = await _db.client.select(
      'mini_activity_participants',
      select: 'mini_activity_id',
      filters: {'mini_activity_id': 'in.(${miniActivityIds.join(',')})'},
    );

    final participantCounts = <String, int>{};
    for (final p in participants) {
      final id = p['mini_activity_id'] as String;
      participantCounts[id] = (participantCounts[id] ?? 0) + 1;
    }

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
    // Get mini-activity
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

    // Get user info
    final userIds = allParticipants.map((p) => p['user_id'] as String).toSet().toList();
    final users = userIds.isNotEmpty
        ? await _db.client.select(
            'users',
            select: 'id,name,avatar_url',
            filters: {'id': 'in.(${userIds.join(',')})'},
          )
        : <Map<String, dynamic>>[];

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

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

    // For individual activities, get participants directly
    List<Map<String, dynamic>> individualParticipants = [];
    if (miniActivity['type'] == 'individual') {
      final participantsResult = await _db.client.select(
        'mini_activity_participants',
        filters: {'mini_activity_id': 'eq.$miniActivityId'},
        order: 'points.desc',
      );

      final indUserIds = participantsResult.map((p) => p['user_id'] as String).toSet().toList();
      final indUsers = indUserIds.isNotEmpty
          ? await _db.client.select(
              'users',
              select: 'id,name,avatar_url',
              filters: {'id': 'in.(${indUserIds.join(',')})'},
            )
          : <Map<String, dynamic>>[];

      final indUserMap = <String, Map<String, dynamic>>{};
      for (final u in indUsers) {
        indUserMap[u['id'] as String] = u;
      }

      individualParticipants = participantsResult.map((p) {
        final user = indUserMap[p['user_id']] ?? {};
        return {
          'id': p['id'],
          'user_id': p['user_id'],
          'points': p['points'],
          'user_name': user['name'],
          'user_avatar_url': user['avatar_url'],
        };
      }).toList();
    }

    // Get adjustments
    final adjustments = await getAdjustments(miniActivityId);

    return {
      ...miniActivity,
      'teams': teams,
      'participants': individualParticipants,
      'adjustments': adjustments.map((a) => a.toJson()).toList(),
    };
  }

  // ============ TEAM DIVISION ============

  /// Divide participants into teams using various methods:
  /// - 'random': Random shuffle, round-robin distribution
  /// - 'ranked': Snake draft based on player ratings
  /// - 'age': Sort by age, round-robin distribution
  /// - 'gmo': "Gamle mot Unge" - oldest half vs youngest half
  /// - 'cup': Fair distribution for multiple teams (snake draft by rating)
  /// - 'manual': Teams created manually (no auto-distribution)
  Future<List<MiniActivityTeam>> divideTeams({
    required String miniActivityId,
    required String method, // 'random', 'ranked', 'age', 'gmo', 'cup', 'manual'
    required int numberOfTeams,
    required List<String> participantUserIds,
    String teamId = '', // For getting ratings/ages
  }) async {
    // Update mini-activity with division method and number of teams
    await _db.client.update(
      'mini_activities',
      {
        'division_method': method,
        'num_teams': numberOfTeams,
      },
      filters: {'id': 'eq.$miniActivityId'},
    );

    // For manual, just create empty teams
    if (method == 'manual') {
      final teams = <MiniActivityTeam>[];
      final teamNames = _generateTeamNames(numberOfTeams);

      for (int i = 0; i < numberOfTeams; i++) {
        final newTeamId = _uuid.v4();
        await _db.client.insert('mini_activity_teams', {
          'id': newTeamId,
          'mini_activity_id': miniActivityId,
          'name': teamNames[i],
        });
        teams.add(MiniActivityTeam(
          id: newTeamId,
          miniActivityId: miniActivityId,
          name: teamNames[i],
        ));
      }
      return teams;
    }

    // Get participant data based on method
    List<_ParticipantData> participants = [];

    if ((method == 'ranked' || method == 'cup') && teamId.isNotEmpty) {
      // Get ratings for ranked/cup methods
      final ratings = await _db.client.select(
        'player_ratings',
        select: 'user_id,rating',
        filters: {
          'team_id': 'eq.$teamId',
          'user_id': 'in.(${participantUserIds.join(',')})',
        },
      );

      final ratingMap = <String, double>{};
      for (final r in ratings) {
        ratingMap[r['user_id'] as String] = (r['rating'] as num).toDouble();
      }

      for (final userId in participantUserIds) {
        participants.add(_ParticipantData(
          userId: userId,
          sortValue: ratingMap[userId] ?? 1000.0,
        ));
      }
    } else if ((method == 'age' || method == 'gmo') && teamId.isNotEmpty) {
      // Get birth dates for age-based methods
      final users = await _db.client.select(
        'users',
        select: 'id,birth_date',
        filters: {'id': 'in.(${participantUserIds.join(',')})'},
      );

      final birthDateMap = <String, DateTime?>{};
      for (final u in users) {
        final birthDateStr = u['birth_date'] as String?;
        birthDateMap[u['id'] as String] = birthDateStr != null
            ? DateTime.tryParse(birthDateStr)
            : null;
      }

      // Sort value: days since birth (higher = older)
      final now = DateTime.now();
      for (final userId in participantUserIds) {
        final birthDate = birthDateMap[userId];
        final daysOld = birthDate != null
            ? now.difference(birthDate).inDays.toDouble()
            : 10000.0; // Default for unknown age (middle-ish)
        participants.add(_ParticipantData(
          userId: userId,
          sortValue: daysOld,
        ));
      }
    } else {
      // For random, use random values
      participants = participantUserIds
          .map((id) => _ParticipantData(userId: id, sortValue: _random.nextDouble()))
          .toList();
    }

    // Sort participants based on method
    switch (method) {
      case 'ranked':
      case 'cup':
        // Sort by rating descending (best first)
        participants.sort((a, b) => b.sortValue.compareTo(a.sortValue));
        break;
      case 'age':
        // Sort by age descending (oldest first)
        participants.sort((a, b) => b.sortValue.compareTo(a.sortValue));
        break;
      case 'gmo':
        // Sort by age descending (oldest first)
        participants.sort((a, b) => b.sortValue.compareTo(a.sortValue));
        break;
      case 'random':
      default:
        participants.shuffle(_random);
        break;
    }

    // Create teams with appropriate names
    final teams = <MiniActivityTeam>[];
    List<String> teamNames;

    if (method == 'gmo' && numberOfTeams == 2) {
      teamNames = ['Gamle', 'Unge'];
    } else {
      teamNames = _generateTeamNames(numberOfTeams);
    }

    for (int i = 0; i < numberOfTeams; i++) {
      final newTeamId = _uuid.v4();
      await _db.client.insert('mini_activity_teams', {
        'id': newTeamId,
        'mini_activity_id': miniActivityId,
        'name': teamNames[i],
      });
      teams.add(MiniActivityTeam(
        id: newTeamId,
        miniActivityId: miniActivityId,
        name: teamNames[i],
      ));
    }

    // Distribute participants to teams based on method
    switch (method) {
      case 'gmo':
        // GMO: Split in half - oldest to first team, youngest to second
        final midpoint = participants.length ~/ 2;
        for (int i = 0; i < participants.length; i++) {
          final teamIndex = i < midpoint ? 0 : (numberOfTeams > 1 ? 1 : 0);
          await _addParticipantToTeam(
            miniActivityId: miniActivityId,
            teamId: teams[teamIndex].id,
            userId: participants[i].userId,
          );
        }
        break;

      case 'ranked':
      case 'cup':
        // Snake draft for fair distribution
        int teamIndex = 0;
        int direction = 1;
        for (final participant in participants) {
          await _addParticipantToTeam(
            miniActivityId: miniActivityId,
            teamId: teams[teamIndex].id,
            userId: participant.userId,
          );

          teamIndex += direction;
          if (teamIndex >= numberOfTeams) {
            teamIndex = numberOfTeams - 1;
            direction = -1;
          } else if (teamIndex < 0) {
            teamIndex = 0;
            direction = 1;
          }
        }
        break;

      case 'age':
      case 'random':
      default:
        // Round robin distribution
        for (int i = 0; i < participants.length; i++) {
          final teamIndex = i % numberOfTeams;
          await _addParticipantToTeam(
            miniActivityId: miniActivityId,
            teamId: teams[teamIndex].id,
            userId: participants[i].userId,
          );
        }
        break;
    }

    return teams;
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

  Future<void> _addParticipantToTeam({
    required String miniActivityId,
    required String teamId,
    required String userId,
  }) async {
    // Check for existing participant
    final existing = await _db.client.select(
      'mini_activity_participants',
      filters: {
        'mini_activity_id': 'eq.$miniActivityId',
        'user_id': 'eq.$userId',
      },
    );

    if (existing.isNotEmpty) {
      // Update existing
      await _db.client.update(
        'mini_activity_participants',
        {'mini_team_id': teamId},
        filters: {
          'mini_activity_id': 'eq.$miniActivityId',
          'user_id': 'eq.$userId',
        },
      );
    } else {
      // Insert new
      await _db.client.insert('mini_activity_participants', {
        'id': _uuid.v4(),
        'mini_team_id': teamId,
        'mini_activity_id': miniActivityId,
        'user_id': userId,
        'points': 0,
      });
    }
  }

  List<String> _generateTeamNames(int count) {
    const colors = ['Rød', 'Blå', 'Grønn', 'Gul', 'Oransje', 'Lilla', 'Rosa', 'Hvit'];
    if (count <= colors.length) {
      return colors.sublist(0, count);
    }
    return List.generate(count, (i) => 'Lag ${i + 1}');
  }

  // ============ HANDICAPS ============

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
        id: existing.first['id'] as String,
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

  Future<List<MiniActivityHandicap>> getHandicaps(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activity_handicaps',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );
    return result.map((row) => MiniActivityHandicap.fromRow(row)).toList();
  }

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

  // ============ SCORES ============

  Future<void> recordTeamScore({
    required String teamId,
    required int score,
  }) async {
    await _db.client.update(
      'mini_activity_teams',
      {'final_score': score},
      filters: {'id': 'eq.$teamId'},
    );
  }

  Future<void> recordParticipantPoints({
    required String participantId,
    required int points,
  }) async {
    await _db.client.update(
      'mini_activity_participants',
      {'points': points},
      filters: {'id': 'eq.$participantId'},
    );
  }

  Future<void> recordMultipleScores({
    required String miniActivityId,
    required Map<String, int> teamScores, // teamId -> score
    required Map<String, int> participantPoints, // participantId -> points
  }) async {
    // Update team scores
    for (final entry in teamScores.entries) {
      await recordTeamScore(teamId: entry.key, score: entry.value);
    }

    // Update participant points
    for (final entry in participantPoints.entries) {
      await recordParticipantPoints(participantId: entry.key, points: entry.value);
    }

    // Calculate and award points based on team results
    await _awardPointsBasedOnResults(miniActivityId);
  }

  Future<void> _awardPointsBasedOnResults(String miniActivityId) async {
    // Get mini-activity
    final miniResult = await _db.client.select(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );

    if (miniResult.isEmpty) return;
    final miniActivity = miniResult.first;

    // Use activity-specific point values if set
    int winPoints = miniActivity['win_points'] as int? ?? 3;
    int drawPoints = miniActivity['draw_points'] as int? ?? 1;
    int lossPoints = miniActivity['loss_points'] as int? ?? 0;

    // If no activity-specific values, try team settings
    if (miniActivity['instance_id'] != null) {
      // Get activity instance
      final instanceResult = await _db.client.select(
        'activity_instances',
        filters: {'id': 'eq.${miniActivity['instance_id']}'},
      );

      if (instanceResult.isNotEmpty) {
        final instance = instanceResult.first;

        // Get activity to find team_id
        final activityResult = await _db.client.select(
          'activities',
          filters: {'id': 'eq.${instance['activity_id']}'},
        );

        if (activityResult.isNotEmpty) {
          final teamId = activityResult.first['team_id'] as String;

          // Get team settings
          final settingsResult = await _db.client.select(
            'team_settings',
            filters: {'team_id': 'eq.$teamId'},
          );

          if (settingsResult.isNotEmpty) {
            final settings = settingsResult.first;
            winPoints = settings['win_points'] as int? ?? winPoints;
            drawPoints = settings['draw_points'] as int? ?? drawPoints;
            lossPoints = settings['loss_points'] as int? ?? lossPoints;
          }
        }
      }
    }

    // Get teams with scores
    final teamsResult = await _db.client.select(
      'mini_activity_teams',
      select: 'id,final_score',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'final_score.desc',
    );

    final teamsWithScores = teamsResult.where((t) => t['final_score'] != null).toList();
    if (teamsWithScores.isEmpty) return;

    final highestScore = teamsWithScores.first['final_score'] as int;
    final lowestScore = teamsWithScores.last['final_score'] as int;

    for (final team in teamsWithScores) {
      final score = team['final_score'] as int;
      final teamDbId = team['id'] as String;

      int pointsToAward;
      if (score == highestScore && score == lowestScore) {
        // All teams have same score - draw
        pointsToAward = drawPoints;
      } else if (score == highestScore) {
        pointsToAward = winPoints;
      } else if (score == lowestScore) {
        pointsToAward = lossPoints;
      } else {
        pointsToAward = drawPoints;
      }

      // Get participants in this team and award points
      final teamParticipants = await _db.client.select(
        'mini_activity_participants',
        filters: {'mini_team_id': 'eq.$teamDbId'},
      );

      for (final p in teamParticipants) {
        final currentPoints = (p['points'] as int?) ?? 0;
        await _db.client.update(
          'mini_activity_participants',
          {'points': currentPoints + pointsToAward},
          filters: {'id': 'eq.${p['id']}'},
        );
      }
    }
  }

  Future<void> deleteMiniActivity(String miniActivityId) async {
    await _db.client.delete(
      'mini_activities',
      filters: {'id': 'eq.$miniActivityId'},
    );
  }

  // Delete adjustment
  Future<void> deleteAdjustment(String adjustmentId) async {
    await _db.client.delete(
      'mini_activity_adjustments',
      filters: {'id': 'eq.$adjustmentId'},
    );
  }

  // Get team by ID
  Future<MiniActivityTeam?> getTeamById(String teamId) async {
    final result = await _db.client.select(
      'mini_activity_teams',
      filters: {'id': 'eq.$teamId'},
    );

    if (result.isEmpty) return null;
    return MiniActivityTeam.fromRow(result.first);
  }

  // Get teams for mini-activity
  Future<List<MiniActivityTeam>> getTeamsForMiniActivity(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activity_teams',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'name.asc',
    );
    return result.map((row) => MiniActivityTeam.fromRow(row)).toList();
  }

  // Remove participant from activity
  Future<void> removeParticipant(String participantId) async {
    await _db.client.delete(
      'mini_activity_participants',
      filters: {'id': 'eq.$participantId'},
    );
  }
}

class _ParticipantData {
  final String userId;
  final double sortValue;

  _ParticipantData({required this.userId, required this.sortValue});
}
