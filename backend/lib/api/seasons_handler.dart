import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/season_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class SeasonsHandler {
  final SeasonService _seasonService;
  final TeamService _teamService;

  SeasonsHandler(this._seasonService, this._teamService);

  Router get router {
    final router = Router();

    // Season routes
    router.get('/teams/<teamId>', _getSeasons);
    router.get('/teams/<teamId>/active', _getActiveSeason);
    router.post('/teams/<teamId>', _createSeason);
    router.get('/<seasonId>', _getSeasonById);
    router.patch('/<seasonId>', _updateSeason);
    router.post('/<seasonId>/activate', _activateSeason);
    router.delete('/<seasonId>', _deleteSeason);
    router.post('/teams/<teamId>/new', _startNewSeason);

    return router;
  }

  Future<Response> _getSeasons(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify user is team member
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasons = await _seasonService.getSeasonsForTeam(teamId);

      return resp.ok({
        'seasons': seasons.map((s) => s.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente sesonger');
    }
  }

  Future<Response> _getActiveSeason(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify user is team member
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final season = await _seasonService.getActiveSeason(teamId);

      if (season == null) {
        return resp.notFound('Ingen aktiv sesong funnet');
      }

      return resp.ok(season.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente aktiv sesong');
    }
  }

  Future<Response> _getSeasonById(Request request, String seasonId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final season = await _seasonService.getSeasonById(seasonId);
      if (season == null) {
        return resp.notFound('Sesong ikke funnet');
      }

      // Verify user is team member
      final team = await requireTeamMember(_teamService, season.teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til denne sesongen');
      }

      return resp.ok(season.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente sesong');
    }
  }

  Future<Response> _createSeason(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify user is admin
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan opprette sesonger');
      }

      final body = await parseBody(request);
      final name = safeStringNullable(body, 'name');

      if (name == null || name.isEmpty) {
        return resp.badRequest('Navn er pakrevd');
      }

      final startDateStr = safeStringNullable(body, 'start_date');
      final endDateStr = safeStringNullable(body, 'end_date');
      final setActive = safeBoolNullable(body, 'set_active') ?? false;

      final season = await _seasonService.createSeason(
        teamId: teamId,
        name: name,
        startDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
        setActive: setActive,
      );

      return resp.ok(season.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette sesong');
    }
  }

  Future<Response> _updateSeason(Request request, String seasonId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _seasonService.getTeamIdForSeason(seasonId);
      if (teamId == null) {
        return resp.notFound('Sesong ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan oppdatere sesonger');
      }

      final body = await parseBody(request);

      final startDateStr = safeStringNullable(body, 'start_date');
      final endDateStr = safeStringNullable(body, 'end_date');

      final season = await _seasonService.updateSeason(
        seasonId: seasonId,
        name: safeStringNullable(body, 'name'),
        startDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
        clearStartDate: body['clear_start_date'] == true,
        clearEndDate: body['clear_end_date'] == true,
      );

      if (season == null) {
        return resp.notFound('Sesong ikke funnet');
      }

      return resp.ok(season.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere sesong');
    }
  }

  Future<Response> _activateSeason(Request request, String seasonId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _seasonService.getTeamIdForSeason(seasonId);
      if (teamId == null) {
        return resp.notFound('Sesong ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan aktivere sesonger');
      }

      await _seasonService.setActiveSeason(teamId, seasonId);

      final season = await _seasonService.getSeasonById(seasonId);

      return resp.ok(season?.toJson() ?? {});
    } catch (e) {
      return resp.serverError('Kunne ikke aktivere sesong');
    }
  }

  Future<Response> _deleteSeason(Request request, String seasonId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _seasonService.getTeamIdForSeason(seasonId);
      if (teamId == null) {
        return resp.notFound('Sesong ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan slette sesonger');
      }

      final success = await _seasonService.deleteSeason(seasonId);

      if (!success) {
        return resp.badRequest(
          'Kan ikke slette aktiv sesong eller sesong med data',
        );
      }

      return resp.ok({'message': 'Sesong slettet'});
    } catch (e) {
      return resp.serverError('Kunne ikke slette sesong');
    }
  }

  Future<Response> _startNewSeason(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan starte ny sesong');
      }

      final body = await parseBody(request);
      final name = safeStringNullable(body, 'name');

      if (name == null || name.isEmpty) {
        return resp.badRequest('Navn er pakrevd');
      }

      final startDateStr = safeStringNullable(body, 'start_date');
      final endDateStr = safeStringNullable(body, 'end_date');

      final season = await _seasonService.startNewSeason(
        teamId: teamId,
        name: name,
        startDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
      );

      return resp.ok(season.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke starte ny sesong');
    }
  }
}
