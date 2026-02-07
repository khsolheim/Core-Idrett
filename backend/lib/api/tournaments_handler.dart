import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/tournament_service.dart';
import '../services/tournament_group_service.dart';
import '../services/team_service.dart';
import '../models/tournament.dart';
import 'tournament_groups_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class TournamentsHandler {
  final TournamentService _tournamentService;
  final TournamentGroupService _groupService;
  final TeamService _teamService;

  TournamentsHandler(this._tournamentService, this._groupService, this._teamService);

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

    // Mount groups & qualification routes
    final groupsHandler = TournamentGroupsHandler(_groupService, _tournamentService, _teamService);
    router.mount('/', groupsHandler.router.call);

    return router;
  }

  /// Verify team membership via mini_activity for routes with miniActivityId.
  Future<Map<String, dynamic>?> _requireTeamForMiniActivity(
      String miniActivityId, String userId) async {
    final teamId =
        await _tournamentService.getTeamIdForMiniActivity(miniActivityId);
    if (teamId == null) return null;
    return requireTeamMember(_teamService, teamId, userId);
  }

  /// Verify team membership via tournament for routes with tournamentId.
  Future<Map<String, dynamic>?> _requireTeamForTournament(
      String tournamentId, String userId) async {
    final teamId =
        await _tournamentService.getTeamIdForTournament(tournamentId);
    if (teamId == null) return null;
    return requireTeamMember(_teamService, teamId, userId);
  }

  // ============ TOURNAMENT CRUD ============

  Future<Response> _createTournament(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForMiniActivity(miniActivityId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final data = await parseBody(request);

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForMiniActivity(miniActivityId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final data = await parseBody(request);

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final data = await parseBody(request);

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final rounds = await _tournamentService.getRoundsForTournament(tournamentId);
      return resp.ok(rounds.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _createRound(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final data = await parseBody(request);

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final data = await parseBody(request);

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

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
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _startMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final match = await _tournamentService.startMatch(matchId);
      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _completeMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final data = await parseBody(request);

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
      if (userId == null) return resp.forbidden('Ikke autorisert');

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
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ GAMES (Best-of) ============

  Future<Response> _getMatchGames(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final games = await _tournamentService.getGamesForMatch(matchId);
      return resp.ok(games.map((g) => g.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _recordGame(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

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
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateGame(Request request, String gameId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

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
      return resp.serverError('En feil oppstod: $e');
    }
  }

}
