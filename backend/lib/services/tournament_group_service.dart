import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/tournament.dart';
import '../helpers/parsing_helpers.dart';

class TournamentGroupService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentGroupService(this._db);

  // ============ GROUPS ============

  Future<TournamentGroup> createGroup({
    required String tournamentId,
    required String name,
    int advanceCount = 2,
    int sortOrder = 0,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('tournament_groups', {
      'id': id,
      'tournament_id': tournamentId,
      'name': name,
      'advance_count': advanceCount,
      'sort_order': sortOrder,
    });

    return TournamentGroup(
      id: id,
      tournamentId: tournamentId,
      name: name,
      advanceCount: advanceCount,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
  }

  Future<List<TournamentGroup>> getGroupsForTournament(String tournamentId) async {
    final result = await _db.client.select(
      'tournament_groups',
      filters: {'tournament_id': 'eq.$tournamentId'},
      order: 'sort_order.asc',
    );
    return result.map((row) => TournamentGroup.fromJson(row)).toList();
  }

  Future<TournamentGroup> updateGroup({
    required String groupId,
    String? name,
    int? advanceCount,
    int? sortOrder,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (advanceCount != null) updates['advance_count'] = advanceCount;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    if (updates.isNotEmpty) {
      await _db.client.update(
        'tournament_groups',
        updates,
        filters: {'id': 'eq.$groupId'},
      );
    }

    final result = await _db.client.select(
      'tournament_groups',
      filters: {'id': 'eq.$groupId'},
    );
    return TournamentGroup.fromJson(result.first);
  }

  Future<void> deleteGroup(String groupId) async {
    // Delete group standings first
    await _db.client.delete(
      'group_standings',
      filters: {'group_id': 'eq.$groupId'},
    );
    // Delete group matches
    await _db.client.delete(
      'group_matches',
      filters: {'group_id': 'eq.$groupId'},
    );
    // Delete group
    await _db.client.delete(
      'tournament_groups',
      filters: {'id': 'eq.$groupId'},
    );
  }

  Future<void> addTeamToGroup({
    required String groupId,
    required String teamId,
  }) async {
    await _db.client.insert('group_standings', {
      'id': _uuid.v4(),
      'group_id': groupId,
      'team_id': teamId,
      'played': 0,
      'won': 0,
      'drawn': 0,
      'lost': 0,
      'goals_for': 0,
      'goals_against': 0,
      'points': 0,
    });
  }

  Future<List<GroupStanding>> getGroupStandings(String groupId) async {
    final result = await _db.client.select(
      'group_standings',
      filters: {'group_id': 'eq.$groupId'},
      order: 'points.desc,goals_for.desc',
    );
    return result.map((row) => GroupStanding.fromJson(row)).toList();
  }

  Future<void> updateGroupStanding({
    required String groupId,
    required String teamId,
    required int goalsFor,
    required int goalsAgainst,
    required bool won,
    required bool drawn,
    required bool lost,
    required int pointsAwarded,
  }) async {
    // Get current standing
    final current = await _db.client.select(
      'group_standings',
      filters: {
        'group_id': 'eq.$groupId',
        'team_id': 'eq.$teamId',
      },
    );

    if (current.isEmpty) return;
    final standing = current.first;

    await _db.client.update(
      'group_standings',
      {
        'played': (safeInt(standing, 'played')) + 1,
        'won': (safeInt(standing, 'won')) + (won ? 1 : 0),
        'drawn': (safeInt(standing, 'drawn')) + (drawn ? 1 : 0),
        'lost': (safeInt(standing, 'lost')) + (lost ? 1 : 0),
        'goals_for': (safeInt(standing, 'goals_for')) + goalsFor,
        'goals_against': (safeInt(standing, 'goals_against')) + goalsAgainst,
        'points': (safeInt(standing, 'points')) + pointsAwarded,
        'updated_at': DateTime.now().toIso8601String(),
      },
      filters: {
        'group_id': 'eq.$groupId',
        'team_id': 'eq.$teamId',
      },
    );
  }

  // ============ GROUP MATCHES ============

  Future<GroupMatch> createGroupMatch({
    required String groupId,
    required String teamAId,
    required String teamBId,
    DateTime? scheduledTime,
    int matchOrder = 0,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('group_matches', {
      'id': id,
      'group_id': groupId,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'status': 'pending',
      'scheduled_time': scheduledTime?.toIso8601String(),
      'match_order': matchOrder,
    });

    return GroupMatch(
      id: id,
      groupId: groupId,
      teamAId: teamAId,
      teamBId: teamBId,
      status: MatchStatus.pending,
      scheduledTime: scheduledTime,
      matchOrder: matchOrder,
      createdAt: DateTime.now(),
    );
  }

  Future<List<GroupMatch>> getGroupMatches(String groupId) async {
    final result = await _db.client.select(
      'group_matches',
      filters: {'group_id': 'eq.$groupId'},
      order: 'match_order.asc',
    );
    return result.map((row) => GroupMatch.fromJson(row)).toList();
  }

  Future<GroupMatch> updateGroupMatch({
    required String matchId,
    int? teamAScore,
    int? teamBScore,
    MatchStatus? status,
    DateTime? scheduledTime,
  }) async {
    final updates = <String, dynamic>{};
    if (teamAScore != null) updates['team_a_score'] = teamAScore;
    if (teamBScore != null) updates['team_b_score'] = teamBScore;
    if (status != null) updates['status'] = status.value;
    if (scheduledTime != null) updates['scheduled_time'] = scheduledTime.toIso8601String();

    if (updates.isNotEmpty) {
      await _db.client.update(
        'group_matches',
        updates,
        filters: {'id': 'eq.$matchId'},
      );
    }

    final result = await _db.client.select(
      'group_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return GroupMatch.fromJson(result.first);
  }

  Future<GroupMatch> completeGroupMatch({
    required String matchId,
    required int teamAScore,
    required int teamBScore,
  }) async {
    // Record the result (which updates standings)
    await recordGroupMatchResult(
      matchId: matchId,
      teamAScore: teamAScore,
      teamBScore: teamBScore,
    );

    final result = await _db.client.select(
      'group_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return GroupMatch.fromJson(result.first);
  }

  Future<void> recordGroupMatchResult({
    required String matchId,
    required int teamAScore,
    required int teamBScore,
  }) async {
    // Get match details
    final matchResult = await _db.client.select(
      'group_matches',
      filters: {'id': 'eq.$matchId'},
    );
    if (matchResult.isEmpty) return;
    final match = matchResult.first;

    await _db.client.update(
      'group_matches',
      {
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        'status': 'completed',
      },
      filters: {'id': 'eq.$matchId'},
    );

    // Update standings
    final groupId = safeString(match, 'group_id');
    final teamAId = safeString(match, 'team_a_id');
    final teamBId = safeString(match, 'team_b_id');

    if (teamAScore > teamBScore) {
      // Team A wins
      await updateGroupStanding(
        groupId: groupId,
        teamId: teamAId,
        goalsFor: teamAScore,
        goalsAgainst: teamBScore,
        won: true,
        drawn: false,
        lost: false,
        pointsAwarded: 3,
      );
      await updateGroupStanding(
        groupId: groupId,
        teamId: teamBId,
        goalsFor: teamBScore,
        goalsAgainst: teamAScore,
        won: false,
        drawn: false,
        lost: true,
        pointsAwarded: 0,
      );
    } else if (teamBScore > teamAScore) {
      // Team B wins
      await updateGroupStanding(
        groupId: groupId,
        teamId: teamAId,
        goalsFor: teamAScore,
        goalsAgainst: teamBScore,
        won: false,
        drawn: false,
        lost: true,
        pointsAwarded: 0,
      );
      await updateGroupStanding(
        groupId: groupId,
        teamId: teamBId,
        goalsFor: teamBScore,
        goalsAgainst: teamAScore,
        won: true,
        drawn: false,
        lost: false,
        pointsAwarded: 3,
      );
    } else {
      // Draw
      await updateGroupStanding(
        groupId: groupId,
        teamId: teamAId,
        goalsFor: teamAScore,
        goalsAgainst: teamBScore,
        won: false,
        drawn: true,
        lost: false,
        pointsAwarded: 1,
      );
      await updateGroupStanding(
        groupId: groupId,
        teamId: teamBId,
        goalsFor: teamBScore,
        goalsAgainst: teamAScore,
        won: false,
        drawn: true,
        lost: false,
        pointsAwarded: 1,
      );
    }
  }

  // ============ QUALIFICATION ============

  Future<List<QualificationRound>> getQualificationRounds(String tournamentId) async {
    final result = await _db.client.select(
      'qualification_rounds',
      filters: {'tournament_id': 'eq.$tournamentId'},
    );
    return result.map((row) => QualificationRound.fromJson(row)).toList();
  }

  Future<QualificationRound> createQualificationRound({
    required String tournamentId,
    required String name,
    int advanceCount = 8,
    String sortDirection = 'desc',
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('qualification_rounds', {
      'id': id,
      'tournament_id': tournamentId,
      'name': name,
      'advance_count': advanceCount,
      'sort_direction': sortDirection,
    });

    return QualificationRound(
      id: id,
      tournamentId: tournamentId,
      name: name,
      advanceCount: advanceCount,
      sortDirection: sortDirection,
      createdAt: DateTime.now(),
    );
  }

  Future<QualificationResult> recordQualificationResult({
    required String qualificationRoundId,
    required String userId,
    required double resultValue,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('qualification_results', {
      'id': id,
      'qualification_round_id': qualificationRoundId,
      'user_id': userId,
      'result_value': resultValue,
      'advanced': false,
    });

    return QualificationResult(
      id: id,
      qualificationRoundId: qualificationRoundId,
      userId: userId,
      resultValue: resultValue,
      createdAt: DateTime.now(),
    );
  }

  Future<List<QualificationResult>> getQualificationResults(String qualificationRoundId) async {
    final result = await _db.client.select(
      'qualification_results',
      filters: {'qualification_round_id': 'eq.$qualificationRoundId'},
      order: 'result_value.desc',
    );
    return result.map((row) => QualificationResult.fromJson(row)).toList();
  }

  Future<List<QualificationResult>> finalizeQualification(String qualificationRoundId) async {
    // Get round details
    final roundResult = await _db.client.select(
      'qualification_rounds',
      filters: {'id': 'eq.$qualificationRoundId'},
    );
    if (roundResult.isEmpty) return [];
    final round = roundResult.first;

    final advanceCount = safeInt(round, 'advance_count');
    final sortDirection = safeString(round, 'sort_direction');

    // Get results sorted
    final order = sortDirection == 'desc' ? 'result_value.desc' : 'result_value.asc';
    final results = await _db.client.select(
      'qualification_results',
      filters: {'qualification_round_id': 'eq.$qualificationRoundId'},
      order: order,
    );

    // Mark top N as advanced
    for (int i = 0; i < results.length; i++) {
      final advanced = i < advanceCount;
      await _db.client.update(
        'qualification_results',
        {
          'advanced': advanced,
          'rank': i + 1,
        },
        filters: {'id': 'eq.${results[i]['id']}'},
      );
    }

    // Return advanced results
    final advancedResults = await _db.client.select(
      'qualification_results',
      filters: {
        'qualification_round_id': 'eq.$qualificationRoundId',
        'advanced': 'eq.true',
      },
      order: 'rank.asc',
    );
    return advancedResults.map((row) => QualificationResult.fromJson(row)).toList();
  }
}
