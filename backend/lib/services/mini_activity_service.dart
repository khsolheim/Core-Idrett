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
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('activity_templates', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'type': type,
      'default_points': defaultPoints,
    });

    return ActivityTemplate(
      id: id,
      teamId: teamId,
      name: name,
      type: type,
      defaultPoints: defaultPoints,
      createdAt: DateTime.now(),
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
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('mini_activities', {
      'id': id,
      'instance_id': instanceId,
      'template_id': templateId,
      'name': name,
      'type': type,
      'num_teams': numTeams,
    });

    return MiniActivity(
      id: id,
      instanceId: instanceId,
      templateId: templateId,
      name: name,
      type: type,
      numTeams: numTeams,
      createdAt: DateTime.now(),
    );
  }

  Future<List<Map<String, dynamic>>> getMiniActivitiesForInstance(String instanceId) async {
    // Get mini-activities
    final miniActivities = await _db.client.select(
      'mini_activities',
      filters: {'instance_id': 'eq.$instanceId'},
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
        'id': ma['id'],
        'instance_id': ma['instance_id'],
        'template_id': ma['template_id'],
        'name': ma['name'],
        'type': ma['type'],
        'division_method': ma['division_method'],
        'num_teams': ma['num_teams'] ?? 2,
        'created_at': ma['created_at'],
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

    return {
      'id': miniActivity['id'],
      'instance_id': miniActivity['instance_id'],
      'template_id': miniActivity['template_id'],
      'name': miniActivity['name'],
      'type': miniActivity['type'],
      'division_method': miniActivity['division_method'],
      'num_teams': miniActivity['num_teams'] ?? 2,
      'created_at': miniActivity['created_at'],
      'teams': teams,
      'participants': individualParticipants,
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

    // Get activity instance
    final instanceResult = await _db.client.select(
      'activity_instances',
      filters: {'id': 'eq.${miniActivity['instance_id']}'},
    );

    if (instanceResult.isEmpty) return;
    final instance = instanceResult.first;

    // Get activity to find team_id
    final activityResult = await _db.client.select(
      'activities',
      filters: {'id': 'eq.${instance['activity_id']}'},
    );

    if (activityResult.isEmpty) return;
    final teamId = activityResult.first['team_id'] as String;

    // Get team settings
    final settingsResult = await _db.client.select(
      'team_settings',
      filters: {'team_id': 'eq.$teamId'},
    );

    int winPoints = 3;
    int drawPoints = 1;
    int lossPoints = 0;

    if (settingsResult.isNotEmpty) {
      final settings = settingsResult.first;
      winPoints = settings['win_points'] as int? ?? 3;
      drawPoints = settings['draw_points'] as int? ?? 1;
      lossPoints = settings['loss_points'] as int? ?? 0;
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
}

class _ParticipantData {
  final String userId;
  final double sortValue;

  _ParticipantData({required this.userId, required this.sortValue});
}
