import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/tournament_service.dart';
import '../services/tournament_group_service.dart';
import '../services/team_service.dart';
import '../models/tournament.dart';
import 'tournament_groups_handler.dart';
import 'tournament_matches_handler.dart';
import 'tournament_rounds_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
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

    // Mount groups & qualification routes
    final groupsHandler = TournamentGroupsHandler(_groupService, _tournamentService, _teamService);
    router.mount('/', groupsHandler.router.call);

    // Mount round routes
    final roundsHandler = TournamentRoundsHandler(_tournamentService, _teamService);
    router.mount('/', roundsHandler.router.call);

    // Mount match & game routes
    final matchesHandler = TournamentMatchesHandler(_tournamentService, _teamService);
    router.mount('/', matchesHandler.router.call);

    return router;
  }

  Future<Map<String, dynamic>?> _requireTeamForMiniActivity(
      String miniActivityId, String userId) async {
    final teamId =
        await _tournamentService.getTeamIdForMiniActivity(miniActivityId);
    if (teamId == null) return null;
    return requireTeamMember(_teamService, teamId, userId);
  }

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
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForMiniActivity(miniActivityId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final data = await parseBody(request);

      final typeStr = safeStringNullable(data, 'tournament_type');
      if (typeStr == null) {
        return resp.badRequest('Mangler påkrevd felt (tournament_type)');
      }

      final tournament = await _tournamentService.createTournament(
        miniActivityId: miniActivityId,
        tournamentType: TournamentType.fromString(typeStr),
        bestOf: safeIntNullable(data, 'best_of') ?? 1,
        bronzeFinal: safeBool(data, 'bronze_final', defaultValue: false),
        seedingMethod: data['seeding_method'] != null
            ? SeedingMethod.fromString(data['seeding_method'] as String)
            : SeedingMethod.random,
        maxParticipants: safeIntNullable(data, 'max_participants'),
      );

      return resp.ok(tournament.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getTournamentForMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForMiniActivity(miniActivityId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final tournament = await _tournamentService.getTournamentForMiniActivity(miniActivityId);
      if (tournament == null) {
        return resp.notFound('Turnering ikke funnet');
      }

      return resp.ok(tournament.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getTournamentById(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final tournament = await _tournamentService.getTournamentById(tournamentId);
      if (tournament == null) {
        return resp.notFound('Turnering ikke funnet');
      }

      return resp.ok(tournament.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateTournament(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final data = await parseBody(request);

      final tournament = await _tournamentService.updateTournament(
        tournamentId: tournamentId,
        bestOf: safeIntNullable(data, 'best_of'),
        bronzeFinal: safeBoolNullable(data, 'bronze_final'),
        status: data['status'] != null
            ? TournamentStatus.fromString(data['status'] as String)
            : null,
      );

      return resp.ok(tournament.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _deleteTournament(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      await _tournamentService.deleteTournament(tournamentId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ BRACKET GENERATION ============

  Future<Response> _generateBracket(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final data = await parseBody(request);

      final teamIds = (safeListNullable(data, 'team_ids'))?.cast<String>() ?? [];
      if (teamIds.isEmpty) {
        return resp.badRequest('Mangler påkrevd felt (team_ids)');
      }

      final matches = await _tournamentService.generateSingleEliminationBracket(
        tournamentId: tournamentId,
        teamIds: teamIds,
      );

      return resp.ok(matches.map((m) => m.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
