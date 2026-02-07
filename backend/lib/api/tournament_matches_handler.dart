import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/tournament_service.dart';
import '../services/team_service.dart';
import '../models/tournament.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class TournamentMatchesHandler {
  final TournamentService _tournamentService;
  final TeamService _teamService;

  TournamentMatchesHandler(this._tournamentService, this._teamService);

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
        await _tournamentService.getTeamIdForTournament(tournamentId);
    if (teamId == null) return null;
    return requireTeamMember(_teamService, teamId, userId);
  }

  Future<Response> _getMatches(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final roundId = request.url.queryParameters['round_id'];
      final matches = await _tournamentService.getMatchesForTournament(
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
      if (userId == null) return resp.unauthorized();

      final match = await _tournamentService.getMatchById(matchId);
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
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

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
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _startMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final match = await _tournamentService.startMatch(matchId);
      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _completeMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

      final winnerId = data['winner_id'] as String?;
      if (winnerId == null) {
        return resp.badRequest('Mangler påkrevd felt (winner_id)');
      }

      final match = await _tournamentService.completeMatch(matchId, winnerId);
      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _declareWalkover(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

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
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getMatchGames(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final games = await _tournamentService.getGamesForMatch(matchId);
      return resp.ok(games.map((g) => g.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _recordGame(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

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
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateGame(Request request, String gameId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

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
      return resp.serverError('En feil oppstod');
    }
  }
}
