import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/mini_activity.dart';
import '../../helpers/parsing_helpers.dart';

/// Service for team division algorithms (random, ranked, age, gmo, cup)
class MiniActivityDivisionAlgorithmService {
  final Database _db;
  final _uuid = const Uuid();
  final _random = Random();

  MiniActivityDivisionAlgorithmService(this._db);

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
    // Remove duplicates from participant list
    final uniqueParticipantIds = participantUserIds.toSet().toList();

    // Validate that all user IDs exist (skip for manual mode with no participants)
    if (method != 'manual' && uniqueParticipantIds.isNotEmpty) {
      final existingUsers = await _db.client.select(
        'users',
        select: 'id',
        filters: {'id': 'in.(${uniqueParticipantIds.join(',')})'},
      );
      final existingUserIds = existingUsers.map((u) => safeString(u, 'id')).toSet();
      final invalidIds = uniqueParticipantIds.where((id) => !existingUserIds.contains(id)).toList();

      if (invalidIds.isNotEmpty) {
        throw ArgumentError('Ugyldige bruker-IDer: ${invalidIds.join(", ")}');
      }
    }

    // Update mini-activity with division method and number of teams
    await _db.client.update(
      'mini_activities',
      {
        'division_method': method,
      },
      filters: {'id': 'eq.$miniActivityId'},
    );

    // Delete existing participants and teams first (to allow re-division)
    await _db.client.delete(
      'mini_activity_participants',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );
    await _db.client.delete(
      'mini_activity_teams',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
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
          'user_id': 'in.(${uniqueParticipantIds.join(',')})',
        },
      );

      final ratingMap = <String, double>{};
      for (final r in ratings) {
        ratingMap[safeString(r, 'user_id')] = safeDouble(r, 'rating');
      }

      for (final userId in uniqueParticipantIds) {
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
        filters: {'id': 'in.(${uniqueParticipantIds.join(',')})'},
      );

      final birthDateMap = <String, DateTime?>{};
      for (final u in users) {
        final birthDateStr = safeStringNullable(u, 'birth_date');
        birthDateMap[safeString(u, 'id')] = birthDateStr != null
            ? DateTime.tryParse(birthDateStr)
            : null;
      }

      // Sort value: days since birth (higher = older)
      final now = DateTime.now();
      for (final userId in uniqueParticipantIds) {
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
      participants = uniqueParticipantIds
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
}

class _ParticipantData {
  final String userId;
  final double sortValue;

  _ParticipantData({required this.userId, required this.sortValue});
}
