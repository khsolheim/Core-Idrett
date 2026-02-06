import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/tournament_service.dart';
import '../models/tournament.dart';
import 'helpers/response_helpers.dart' as resp;
import 'helpers/auth_helpers.dart';

class TournamentsHandler {
  final TournamentService _tournamentService;

  TournamentsHandler(this._tournamentService);

  Router get router {
    final router = Router();

    // Tournament CRUD
    router.post('/mini-activity/<miniActivityId>', _createTournament);
    router.get('/mini-activity/<miniActivityId>', _getTournamentForMiniActivity);
    router.get('/<tournamentId>', _getTournamentById);
    router.put('/<tournamentId>', _updateTournament);
    router.delete('/<tournamentId>', _deleteTournament);

    // Bracket generation
    router.post('/<tournamentId>/generate-bracket', _generateBracket);

    // Round management
    router.get('/<tournamentId>/rounds', _getRounds);
    router.post('/<tournamentId>/rounds', _createRound);
    router.put('/rounds/<roundId>', _updateRound);

    // Match management
    router.get('/<tournamentId>/matches', _getMatches);
    router.get('/matches/<matchId>', _getMatchById);
    router.put('/matches/<matchId>', _updateMatch);
    router.post('/matches/<matchId>/start', _startMatch);
    router.post('/matches/<matchId>/complete', _completeMatch);
    router.post('/matches/<matchId>/walkover', _declareWalkover);

    // Best-of games
    router.get('/matches/<matchId>/games', _getMatchGames);
    router.post('/matches/<matchId>/games', _recordGame);
    router.put('/games/<gameId>', _updateGame);

    // Group management
    router.get('/<tournamentId>/groups', _getGroups);
    router.post('/<tournamentId>/groups', _createGroup);
    router.put('/groups/<groupId>', _updateGroup);
    router.delete('/groups/<groupId>', _deleteGroup);

    // Group standings
    router.get('/groups/<groupId>/standings', _getGroupStandings);

    // Group matches
    router.get('/groups/<groupId>/matches', _getGroupMatches);
    router.post('/groups/<groupId>/matches', _createGroupMatch);
    router.put('/group-matches/<matchId>', _updateGroupMatch);
    router.post('/group-matches/<matchId>/complete', _completeGroupMatch);

    // Qualification rounds
    router.get('/<tournamentId>/qualifications', _getQualificationRounds);
    router.post('/<tournamentId>/qualifications', _createQualificationRound);
    router.get('/qualifications/<qualificationId>/results', _getQualificationResults);
    router.post('/qualifications/<qualificationId>/results', _recordQualificationResult);
    router.post('/qualifications/<qualificationId>/finalize', _finalizeQualification);

    return router;
  }

  // ============ TOURNAMENT CRUD ============

  Future<Response> _createTournament(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final typeStr = data['tournament_type'] as String?;
      if (typeStr == null) {
        return resp.badRequest('Mangler påkrevd felt (tournament_type)');
      }

      final tournament = await _tournamentService.createTournament(
        miniActivityId: miniActivityId,
        tournamentType: TournamentType.fromString(typeStr),
        bestOf: data['best_of'] as int? ?? 1,
        bronzeFinal: data['bronze_final'] as bool? ?? false,
        seedingMethod: data['seeding_method'] != null
            ? SeedingMethod.fromString(data['seeding_method'] as String)
            : SeedingMethod.random,
        maxParticipants: data['max_participants'] as int?,
      );

      return resp.ok(tournament.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getTournamentForMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final tournament = await _tournamentService.getTournamentForMiniActivity(miniActivityId);
      if (tournament == null) {
        return resp.notFound('Turnering ikke funnet');
      }

      return resp.ok(tournament.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getTournamentById(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final tournament = await _tournamentService.getTournamentById(tournamentId);
      if (tournament == null) {
        return resp.notFound('Turnering ikke funnet');
      }

      return resp.ok(tournament.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateTournament(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final tournament = await _tournamentService.updateTournament(
        tournamentId: tournamentId,
        bestOf: data['best_of'] as int?,
        bronzeFinal: data['bronze_final'] as bool?,
        status: data['status'] != null
            ? TournamentStatus.fromString(data['status'] as String)
            : null,
      );

      return resp.ok(tournament.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _deleteTournament(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _tournamentService.deleteTournament(tournamentId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ BRACKET GENERATION ============

  Future<Response> _generateBracket(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final teamIds = (data['team_ids'] as List?)?.cast<String>() ?? [];
      if (teamIds.isEmpty) {
        return resp.badRequest('Mangler påkrevd felt (team_ids)');
      }

      final matches = await _tournamentService.generateSingleEliminationBracket(
        tournamentId: tournamentId,
        teamIds: teamIds,
      );

      return resp.ok(matches.map((m) => m.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ ROUNDS ============

  Future<Response> _getRounds(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final rounds = await _tournamentService.getRoundsForTournament(tournamentId);
      return resp.ok(rounds.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _createRound(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final roundNumber = data['round_number'] as int?;
      final roundName = data['round_name'] as String?;

      if (roundNumber == null || roundName == null) {
        return resp.badRequest('Mangler påkrevde felt (round_number, round_name)');
      }

      final round = await _tournamentService.createRound(
        tournamentId: tournamentId,
        roundNumber: roundNumber,
        roundName: roundName,
        roundType: data['round_type'] != null
            ? RoundType.fromString(data['round_type'] as String)
            : RoundType.winners,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
      );

      return resp.ok(round.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateRound(Request request, String roundId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final round = await _tournamentService.updateRound(
        roundId: roundId,
        roundName: data['round_name'] as String?,
        status: data['status'] != null
            ? TournamentStatus.fromString(data['status'] as String)
            : null,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
      );

      return resp.ok(round.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ MATCHES ============

  Future<Response> _getMatches(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final roundId = request.url.queryParameters['round_id'];
      final matches = await _tournamentService.getMatchesForTournament(
        tournamentId,
        roundId: roundId,
      );
      return resp.ok(matches.map((m) => m.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getMatchById(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final match = await _tournamentService.getMatchById(matchId);
      if (match == null) {
        return resp.notFound('Kamp ikke funnet');
      }

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final match = await _tournamentService.updateMatch(
        matchId: matchId,
        teamAScore: data['team_a_score'] as int?,
        teamBScore: data['team_b_score'] as int?,
        status: data['status'] != null
            ? MatchStatus.fromString(data['status'] as String)
            : null,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _startMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final match = await _tournamentService.startMatch(matchId);
      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _completeMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final winnerId = data['winner_id'] as String?;
      if (winnerId == null) {
        return resp.badRequest('Mangler påkrevd felt (winner_id)');
      }

      final match = await _tournamentService.completeMatch(matchId, winnerId);
      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _declareWalkover(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final winnerId = data['winner_id'] as String?;
      final reason = data['reason'] as String?;

      if (winnerId == null) {
        return resp.badRequest('Mangler påkrevd felt (winner_id)');
      }

      final match = await _tournamentService.declareWalkover(
        matchId: matchId,
        winnerId: winnerId,
        reason: reason,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ GAMES (Best-of) ============

  Future<Response> _getMatchGames(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final games = await _tournamentService.getGamesForMatch(matchId);
      return resp.ok(games.map((g) => g.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _recordGame(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final gameNumber = data['game_number'] as int?;
      final winnerId = data['winner_id'] as String?;

      if (gameNumber == null || winnerId == null) {
        return resp.badRequest('Mangler påkrevde felt (game_number, winner_id)');
      }

      final game = await _tournamentService.recordGame(
        matchId: matchId,
        gameNumber: gameNumber,
        teamAScore: data['team_a_score'] as int? ?? 0,
        teamBScore: data['team_b_score'] as int? ?? 0,
        winnerId: winnerId,
      );

      return resp.ok(game.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateGame(Request request, String gameId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final game = await _tournamentService.updateGame(
        gameId: gameId,
        teamAScore: data['team_a_score'] as int?,
        teamBScore: data['team_b_score'] as int?,
        winnerId: data['winner_id'] as String?,
        status: data['status'] != null
            ? MatchStatus.fromString(data['status'] as String)
            : null,
      );

      return resp.ok(game.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ GROUPS ============

  Future<Response> _getGroups(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final groups = await _tournamentService.getGroupsForTournament(tournamentId);
      return resp.ok(groups.map((g) => g.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _createGroup(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      if (name == null) {
        return resp.badRequest('Mangler påkrevd felt (name)');
      }

      final group = await _tournamentService.createGroup(
        tournamentId: tournamentId,
        name: name,
        advanceCount: data['advance_count'] as int? ?? 2,
        sortOrder: data['sort_order'] as int? ?? 0,
      );

      return resp.ok(group.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateGroup(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final group = await _tournamentService.updateGroup(
        groupId: groupId,
        name: data['name'] as String?,
        advanceCount: data['advance_count'] as int?,
        sortOrder: data['sort_order'] as int?,
      );

      return resp.ok(group.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _deleteGroup(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _tournamentService.deleteGroup(groupId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ GROUP STANDINGS ============

  Future<Response> _getGroupStandings(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final standings = await _tournamentService.getGroupStandings(groupId);
      return resp.ok(standings.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ GROUP MATCHES ============

  Future<Response> _getGroupMatches(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final matches = await _tournamentService.getGroupMatches(groupId);
      return resp.ok(matches.map((m) => m.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _createGroupMatch(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final teamAId = data['team_a_id'] as String?;
      final teamBId = data['team_b_id'] as String?;

      if (teamAId == null || teamBId == null) {
        return resp.badRequest('Mangler påkrevde felt (team_a_id, team_b_id)');
      }

      final match = await _tournamentService.createGroupMatch(
        groupId: groupId,
        teamAId: teamAId,
        teamBId: teamBId,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
        matchOrder: data['match_order'] as int? ?? 0,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateGroupMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final match = await _tournamentService.updateGroupMatch(
        matchId: matchId,
        teamAScore: data['team_a_score'] as int?,
        teamBScore: data['team_b_score'] as int?,
        status: data['status'] != null
            ? MatchStatus.fromString(data['status'] as String)
            : null,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _completeGroupMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final teamAScore = data['team_a_score'] as int?;
      final teamBScore = data['team_b_score'] as int?;

      if (teamAScore == null || teamBScore == null) {
        return resp.badRequest('Mangler påkrevde felt (team_a_score, team_b_score)');
      }

      final match = await _tournamentService.completeGroupMatch(
        matchId: matchId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ QUALIFICATION ROUNDS ============

  Future<Response> _getQualificationRounds(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final rounds = await _tournamentService.getQualificationRounds(tournamentId);
      return resp.ok(rounds.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _createQualificationRound(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      if (name == null) {
        return resp.badRequest('Mangler påkrevd felt (name)');
      }

      final round = await _tournamentService.createQualificationRound(
        tournamentId: tournamentId,
        name: name,
        advanceCount: data['advance_count'] as int? ?? 8,
        sortDirection: data['sort_direction'] as String? ?? 'desc',
      );

      return resp.ok(round.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getQualificationResults(Request request, String qualificationId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final results = await _tournamentService.getQualificationResults(qualificationId);
      return resp.ok(results.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _recordQualificationResult(Request request, String qualificationId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final participantUserId = data['user_id'] as String?;
      final resultValue = (data['result_value'] as num?)?.toDouble();

      if (participantUserId == null || resultValue == null) {
        return resp.badRequest('Mangler påkrevde felt (user_id, result_value)');
      }

      final result = await _tournamentService.recordQualificationResult(
        qualificationRoundId: qualificationId,
        userId: participantUserId,
        resultValue: resultValue,
      );

      return resp.ok(result.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _finalizeQualification(Request request, String qualificationId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final advancedResults = await _tournamentService.finalizeQualification(qualificationId);
      return resp.ok(advancedResults.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }
}
