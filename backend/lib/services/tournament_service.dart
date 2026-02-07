import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/tournament.dart';
import 'tournament_group_service.dart';

class TournamentService {
  final Database _db;
  final TournamentGroupService groupService;
  final _uuid = const Uuid();

  TournamentService(this._db, this.groupService);

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
    return result.first['team_id'] as String?;
  }

  /// Get the team_id for a mini_activity.
  Future<String?> getTeamIdForMiniActivity(String miniActivityId) async {
    final result = await _db.client.select(
      'mini_activities',
      select: 'team_id',
      filters: {'id': 'eq.$miniActivityId'},
    );
    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
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

  // ============ MATCHES ============

  Future<TournamentMatch> updateMatch({
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
        'tournament_matches',
        updates,
        filters: {'id': 'eq.$matchId'},
      );
    }

    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return TournamentMatch.fromJson(result.first);
  }

  Future<TournamentMatch> startMatch(String matchId) async {
    await _db.client.update(
      'tournament_matches',
      {'status': 'in_progress'},
      filters: {'id': 'eq.$matchId'},
    );
    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return TournamentMatch.fromJson(result.first);
  }

  Future<TournamentMatch> completeMatch(String matchId, String winnerId) async {
    // Get current match to get scores
    final matchResult = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    if (matchResult.isEmpty) {
      throw Exception('Match not found');
    }
    final match = matchResult.first;

    await recordMatchResult(
      matchId: matchId,
      teamAScore: match['team_a_score'] as int? ?? 0,
      teamBScore: match['team_b_score'] as int? ?? 0,
      winnerId: winnerId,
    );

    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return TournamentMatch.fromJson(result.first);
  }

  Future<TournamentMatch> declareWalkover({
    required String matchId,
    required String winnerId,
    String? reason,
  }) async {
    await setWalkover(
      matchId: matchId,
      winnerId: winnerId,
      reason: reason,
    );

    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return TournamentMatch.fromJson(result.first);
  }

  Future<TournamentMatch> createMatch({
    required String tournamentId,
    required String roundId,
    required int bracketPosition,
    String? teamAId,
    String? teamBId,
    DateTime? scheduledTime,
    int matchOrder = 0,
    String? winnerGoesToMatchId,
    String? loserGoesToMatchId,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('tournament_matches', {
      'id': id,
      'tournament_id': tournamentId,
      'round_id': roundId,
      'bracket_position': bracketPosition,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'status': 'pending',
      'scheduled_time': scheduledTime?.toIso8601String(),
      'match_order': matchOrder,
      'winner_goes_to_match_id': winnerGoesToMatchId,
      'loser_goes_to_match_id': loserGoesToMatchId,
    });

    return TournamentMatch(
      id: id,
      tournamentId: tournamentId,
      roundId: roundId,
      bracketPosition: bracketPosition,
      teamAId: teamAId,
      teamBId: teamBId,
      status: MatchStatus.pending,
      scheduledTime: scheduledTime,
      matchOrder: matchOrder,
      winnerGoesToMatchId: winnerGoesToMatchId,
      loserGoesToMatchId: loserGoesToMatchId,
      createdAt: DateTime.now(),
    );
  }

  Future<List<TournamentMatch>> getMatchesForRound(String roundId) async {
    final result = await _db.client.select(
      'tournament_matches',
      filters: {'round_id': 'eq.$roundId'},
      order: 'match_order.asc',
    );
    return result.map((row) => TournamentMatch.fromJson(row)).toList();
  }

  Future<List<TournamentMatch>> getMatchesForTournament(String tournamentId, {String? roundId}) async {
    final filters = <String, String>{'tournament_id': 'eq.$tournamentId'};
    if (roundId != null) {
      filters['round_id'] = 'eq.$roundId';
    }
    final result = await _db.client.select(
      'tournament_matches',
      filters: filters,
      order: 'match_order.asc',
    );
    return result.map((row) => TournamentMatch.fromJson(row)).toList();
  }

  Future<TournamentMatch?> getMatchById(String matchId) async {
    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    if (result.isEmpty) return null;
    return TournamentMatch.fromJson(result.first);
  }

  Future<void> recordMatchResult({
    required String matchId,
    required int teamAScore,
    required int teamBScore,
    required String winnerId,
  }) async {
    await _db.client.update(
      'tournament_matches',
      {
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        'winner_id': winnerId,
        'status': 'completed',
      },
      filters: {'id': 'eq.$matchId'},
    );

    // Advance winner to next match
    final match = await getMatchById(matchId);
    if (match != null && match.winnerGoesToMatchId != null) {
      await _advanceTeamToMatch(winnerId, match.winnerGoesToMatchId!);
    }

    // Handle loser bracket
    final loserId = winnerId == match?.teamAId ? match?.teamBId : match?.teamAId;
    if (match != null && match.loserGoesToMatchId != null && loserId != null) {
      await _advanceTeamToMatch(loserId, match.loserGoesToMatchId!);
    }
  }

  Future<void> _advanceTeamToMatch(String teamId, String matchId) async {
    final nextMatch = await getMatchById(matchId);
    if (nextMatch == null) return;

    // Place in first available slot
    if (nextMatch.teamAId == null) {
      await _db.client.update(
        'tournament_matches',
        {'team_a_id': teamId},
        filters: {'id': 'eq.$matchId'},
      );
    } else if (nextMatch.teamBId == null) {
      await _db.client.update(
        'tournament_matches',
        {'team_b_id': teamId},
        filters: {'id': 'eq.$matchId'},
      );
    }
  }

  Future<void> setWalkover({
    required String matchId,
    required String winnerId,
    String? reason,
  }) async {
    await _db.client.update(
      'tournament_matches',
      {
        'winner_id': winnerId,
        'status': 'walkover',
        'is_walkover': true,
        'walkover_reason': reason,
      },
      filters: {'id': 'eq.$matchId'},
    );

    // Advance winner
    final match = await getMatchById(matchId);
    if (match != null && match.winnerGoesToMatchId != null) {
      await _advanceTeamToMatch(winnerId, match.winnerGoesToMatchId!);
    }
  }

  // ============ MATCH GAMES (Best-of series) ============

  Future<MatchGame> createGame({
    required String matchId,
    required int gameNumber,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('match_games', {
      'id': id,
      'match_id': matchId,
      'game_number': gameNumber,
      'team_a_score': 0,
      'team_b_score': 0,
      'status': 'pending',
    });

    return MatchGame(
      id: id,
      matchId: matchId,
      gameNumber: gameNumber,
      createdAt: DateTime.now(),
    );
  }

  Future<List<MatchGame>> getGamesForMatch(String matchId) async {
    final result = await _db.client.select(
      'match_games',
      filters: {'match_id': 'eq.$matchId'},
      order: 'game_number.asc',
    );
    return result.map((row) => MatchGame.fromJson(row)).toList();
  }

  Future<void> recordGameResult({
    required String gameId,
    required int teamAScore,
    required int teamBScore,
    String? winnerId,
  }) async {
    await _db.client.update(
      'match_games',
      {
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        'winner_id': winnerId,
        'status': 'completed',
      },
      filters: {'id': 'eq.$gameId'},
    );
  }

  Future<MatchGame> recordGame({
    required String matchId,
    required int gameNumber,
    required int teamAScore,
    required int teamBScore,
    required String winnerId,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('match_games', {
      'id': id,
      'match_id': matchId,
      'game_number': gameNumber,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'winner_id': winnerId,
      'status': 'completed',
    });

    return MatchGame(
      id: id,
      matchId: matchId,
      gameNumber: gameNumber,
      teamAScore: teamAScore,
      teamBScore: teamBScore,
      winnerId: winnerId,
      status: MatchStatus.completed,
      createdAt: DateTime.now(),
    );
  }

  Future<MatchGame> updateGame({
    required String gameId,
    int? teamAScore,
    int? teamBScore,
    String? winnerId,
    MatchStatus? status,
  }) async {
    final updates = <String, dynamic>{};
    if (teamAScore != null) updates['team_a_score'] = teamAScore;
    if (teamBScore != null) updates['team_b_score'] = teamBScore;
    if (winnerId != null) updates['winner_id'] = winnerId;
    if (status != null) updates['status'] = status.value;

    if (updates.isNotEmpty) {
      await _db.client.update(
        'match_games',
        updates,
        filters: {'id': 'eq.$gameId'},
      );
    }

    final result = await _db.client.select(
      'match_games',
      filters: {'id': 'eq.$gameId'},
    );
    return MatchGame.fromJson(result.first);
  }

  // ============ BRACKET GENERATION ============

  /// Generate a single elimination bracket
  Future<List<TournamentMatch>> generateSingleEliminationBracket({
    required String tournamentId,
    required List<String> teamIds,
    bool bronzeFinal = false,
  }) async {
    final allMatches = <TournamentMatch>[];
    final numTeams = teamIds.length;

    // Calculate number of rounds needed
    int numRounds = 0;
    int teamsInRound = numTeams;
    while (teamsInRound > 1) {
      numRounds++;
      teamsInRound = (teamsInRound / 2).ceil();
    }

    // Generate round names
    final roundNames = _generateRoundNames(numRounds, bronzeFinal);

    // Create rounds
    final rounds = <TournamentRound>[];
    for (int i = 0; i < numRounds; i++) {
      final round = await createRound(
        tournamentId: tournamentId,
        roundNumber: i + 1,
        roundName: roundNames[i],
        roundType: RoundType.winners,
      );
      rounds.add(round);
    }

    // Create bronze round if needed
    TournamentRound? bronzeRound;
    if (bronzeFinal && numRounds >= 2) {
      bronzeRound = await createRound(
        tournamentId: tournamentId,
        roundNumber: numRounds,
        roundName: 'Bronsefinale',
        roundType: RoundType.bronze,
      );
    }

    // Create matches for first round
    final firstRound = rounds.first;
    final matchesInFirstRound = (numTeams / 2).ceil();
    final firstRoundMatches = <TournamentMatch>[];

    for (int i = 0; i < matchesInFirstRound; i++) {
      final teamAIndex = i * 2;
      final teamBIndex = i * 2 + 1;

      final match = await createMatch(
        tournamentId: tournamentId,
        roundId: firstRound.id,
        bracketPosition: i,
        teamAId: teamAIndex < teamIds.length ? teamIds[teamAIndex] : null,
        teamBId: teamBIndex < teamIds.length ? teamIds[teamBIndex] : null,
        matchOrder: i,
      );
      firstRoundMatches.add(match);
      allMatches.add(match);

      // If only one team, auto-advance
      if (match.teamAId != null && match.teamBId == null) {
        await setWalkover(
          matchId: match.id,
          winnerId: match.teamAId!,
          reason: 'Frirunde',
        );
      }
    }

    // Create matches for subsequent rounds and link them
    var previousRoundMatches = firstRoundMatches;
    for (int r = 1; r < rounds.length; r++) {
      final round = rounds[r];
      final matchesInRound = (previousRoundMatches.length / 2).ceil();
      final currentRoundMatches = <TournamentMatch>[];

      for (int i = 0; i < matchesInRound; i++) {
        final match = await createMatch(
          tournamentId: tournamentId,
          roundId: round.id,
          bracketPosition: i,
          matchOrder: i,
        );
        currentRoundMatches.add(match);
        allMatches.add(match);
      }

      // Link previous round matches to this round
      for (int i = 0; i < previousRoundMatches.length; i += 2) {
        final targetMatchIndex = i ~/ 2;
        if (targetMatchIndex < currentRoundMatches.length) {
          // Update winner_goes_to_match_id
          await _db.client.update(
            'tournament_matches',
            {'winner_goes_to_match_id': currentRoundMatches[targetMatchIndex].id},
            filters: {'id': 'eq.${previousRoundMatches[i].id}'},
          );
          if (i + 1 < previousRoundMatches.length) {
            await _db.client.update(
              'tournament_matches',
              {'winner_goes_to_match_id': currentRoundMatches[targetMatchIndex].id},
              filters: {'id': 'eq.${previousRoundMatches[i + 1].id}'},
            );
          }
        }
      }

      previousRoundMatches = currentRoundMatches;
    }

    // Link semi-finals to bronze final if needed
    if (bronzeRound != null && rounds.length >= 2) {
      final semiFinalRound = rounds[rounds.length - 2];
      final semiFinalMatches = await getMatchesForRound(semiFinalRound.id);

      // Create bronze match
      final bronzeMatch = await createMatch(
        tournamentId: tournamentId,
        roundId: bronzeRound.id,
        bracketPosition: 0,
        matchOrder: 0,
      );
      allMatches.add(bronzeMatch);

      // Link losers to bronze
      for (final match in semiFinalMatches) {
        await _db.client.update(
          'tournament_matches',
          {'loser_goes_to_match_id': bronzeMatch.id},
          filters: {'id': 'eq.${match.id}'},
        );
      }
    }

    // Update tournament status
    await updateTournamentStatus(tournamentId, TournamentStatus.inProgress);

    return allMatches;
  }

  List<String> _generateRoundNames(int numRounds, bool hasBronze) {
    final names = <String>[];

    for (int i = numRounds; i > 0; i--) {
      if (i == 1) {
        names.insert(0, 'Finale');
      } else if (i == 2) {
        names.insert(0, 'Semifinale');
      } else if (i == 3) {
        names.insert(0, 'Kvartfinale');
      } else if (i == 4) {
        names.insert(0, '8-delsfinale');
      } else if (i == 5) {
        names.insert(0, '16-delsfinale');
      } else {
        names.insert(0, 'Runde ${numRounds - i + 1}');
      }
    }

    return names;
  }

  // ============ TOURNAMENT DETAIL ============

  Future<Map<String, dynamic>?> getTournamentDetail(String tournamentId) async {
    final tournament = await getTournamentById(tournamentId);
    if (tournament == null) return null;

    final rounds = await getRoundsForTournament(tournamentId);
    final matches = await getMatchesForTournament(tournamentId);
    final groups = await groupService.getGroupsForTournament(tournamentId);

    // Get standings for each group
    final groupsWithStandings = <Map<String, dynamic>>[];
    for (final group in groups) {
      final standings = await groupService.getGroupStandings(group.id);
      final groupMatches = await groupService.getGroupMatches(group.id);
      groupsWithStandings.add({
        ...group.toJson(),
        'standings': standings.map((s) => s.toJson()).toList(),
        'matches': groupMatches.map((m) => m.toJson()).toList(),
      });
    }

    // Organize matches by round
    final roundsWithMatches = rounds.map((r) {
      final roundMatches = matches.where((m) => m.roundId == r.id).toList();
      return {
        ...r.toJson(),
        'matches': roundMatches.map((m) => m.toJson()).toList(),
      };
    }).toList();

    return {
      ...tournament.toJson(),
      'rounds': roundsWithMatches,
      'groups': groupsWithStandings,
    };
  }
}
