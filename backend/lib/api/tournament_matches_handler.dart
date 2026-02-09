import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/tournament_service.dart';
import '../services/team_service.dart';
import '../models/tournament.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class TournamentMatchesHandler {
  final TournamentCrudService _crudService;
  final TournamentMatchesService _matchesService;
  final TeamService _teamService;

  TournamentMatchesHandler(this._crudService, this._matchesService, this._teamService);

  Router get router {
    final router = Router();

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

    return router;
  }

  Future<Map<String, dynamic>?> _requireTeamForTournament(
      String tournamentId, String userId) async {
    final teamId =
        await _crudService.getTeamIdForTournament(tournamentId);
    if (teamId == null) return null;
    return requireTeamMember(_teamService, teamId, userId);
  }

  Future<Response> _getMatches(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til denne turneringen');
      }

      final roundId = request.url.queryParameters['round_id'];
      final matches = await _matchesService.getMatchesForTournament(
        tournamentId,
        roundId: roundId,
      );
      return resp.ok(matches.map((m) => m.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getMatchById(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final match = await _matchesService.getMatchById(matchId);
      if (match == null) {
        return resp.notFound('Kamp ikke funnet');
      }

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final match = await _matchesService.updateMatch(
        matchId: matchId,
        teamAScore: safeIntNullable(data, 'team_a_score'),
        teamBScore: safeIntNullable(data, 'team_b_score'),
        status: data['status'] != null
            ? MatchStatus.fromString(data['status'] as String)
            : null,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.tryParse(safeString(data, 'scheduled_time'))
            : null,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _startMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final match = await _matchesService.startMatch(matchId);
      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _completeMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final winnerId = safeStringNullable(data, 'winner_id');
      if (winnerId == null) {
        return resp.badRequest('Mangler påkrevd felt (winner_id)');
      }

      final match = await _matchesService.completeMatch(matchId, winnerId);
      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _declareWalkover(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final winnerId = safeStringNullable(data, 'winner_id');
      final reason = safeStringNullable(data, 'reason');

      if (winnerId == null) {
        return resp.badRequest('Mangler påkrevd felt (winner_id)');
      }

      final match = await _matchesService.declareWalkover(
        matchId: matchId,
        winnerId: winnerId,
        reason: reason,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getMatchGames(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final games = await _matchesService.getGamesForMatch(matchId);
      return resp.ok(games.map((g) => g.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _recordGame(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final gameNumber = safeIntNullable(data, 'game_number');
      final winnerId = safeStringNullable(data, 'winner_id');

      if (gameNumber == null || winnerId == null) {
        return resp.badRequest('Mangler påkrevde felt (game_number, winner_id)');
      }

      final game = await _matchesService.recordGame(
        matchId: matchId,
        gameNumber: gameNumber,
        teamAScore: safeIntNullable(data, 'team_a_score') ?? 0,
        teamBScore: safeIntNullable(data, 'team_b_score') ?? 0,
        winnerId: winnerId,
      );

      return resp.ok(game.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateGame(Request request, String gameId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final game = await _matchesService.updateGame(
        gameId: gameId,
        teamAScore: safeIntNullable(data, 'team_a_score'),
        teamBScore: safeIntNullable(data, 'team_b_score'),
        winnerId: safeStringNullable(data, 'winner_id'),
        status: data['status'] != null
            ? MatchStatus.fromString(data['status'] as String)
            : null,
      );

      return resp.ok(game.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
