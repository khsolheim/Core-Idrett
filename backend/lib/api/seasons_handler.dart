import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/season_service.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';

class SeasonsHandler {
  final SeasonService _seasonService;
  final AuthService _authService;
  final TeamService _teamService;

  SeasonsHandler(this._seasonService, this._authService, this._teamService);

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

  Future<String?> _getUserId(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    final token = authHeader.substring(7);
    final user = await _authService.getUserFromToken(token);
    return user?.id;
  }

  Future<bool> _isTeamAdmin(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    if (team == null) return false;
    return team['user_is_admin'] == true || team['user_role'] == 'admin';
  }

  Future<Response> _getSeasons(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify user is team member
      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final seasons = await _seasonService.getSeasonsForTeam(teamId);

      return Response.ok(
        jsonEncode({
          'seasons': seasons.map((s) => s.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente sesonger: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getActiveSeason(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify user is team member
      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final season = await _seasonService.getActiveSeason(teamId);

      if (season == null) {
        return Response.notFound(
          jsonEncode({'error': 'Ingen aktiv sesong funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(season.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente aktiv sesong: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getSeasonById(Request request, String seasonId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final season = await _seasonService.getSeasonById(seasonId);
      if (season == null) {
        return Response.notFound(
          jsonEncode({'error': 'Sesong ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify user is team member
      final team = await _teamService.getTeamById(season.teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til denne sesongen'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(season.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente sesong: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createSeason(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify user is admin
      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan opprette sesonger'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final name = body['name'] as String?;

      if (name == null || name.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Navn er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final startDateStr = body['start_date'] as String?;
      final endDateStr = body['end_date'] as String?;
      final setActive = body['set_active'] as bool? ?? false;

      final season = await _seasonService.createSeason(
        teamId: teamId,
        name: name,
        startDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
        setActive: setActive,
      );

      return Response.ok(
        jsonEncode(season.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette sesong: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _updateSeason(Request request, String seasonId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _seasonService.getTeamIdForSeason(seasonId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Sesong ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan oppdatere sesonger'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

      final startDateStr = body['start_date'] as String?;
      final endDateStr = body['end_date'] as String?;

      final season = await _seasonService.updateSeason(
        seasonId: seasonId,
        name: body['name'] as String?,
        startDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
        clearStartDate: body['clear_start_date'] == true,
        clearEndDate: body['clear_end_date'] == true,
      );

      if (season == null) {
        return Response.notFound(
          jsonEncode({'error': 'Sesong ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(season.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke oppdatere sesong: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _activateSeason(Request request, String seasonId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _seasonService.getTeamIdForSeason(seasonId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Sesong ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan aktivere sesonger'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _seasonService.setActiveSeason(teamId, seasonId);

      final season = await _seasonService.getSeasonById(seasonId);

      return Response.ok(
        jsonEncode(season?.toJson() ?? {}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke aktivere sesong: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteSeason(Request request, String seasonId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _seasonService.getTeamIdForSeason(seasonId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Sesong ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan slette sesonger'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final success = await _seasonService.deleteSeason(seasonId);

      if (!success) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Kan ikke slette aktiv sesong eller sesong med data'
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette sesong: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _startNewSeason(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan starte ny sesong'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final name = body['name'] as String?;

      if (name == null || name.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Navn er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final startDateStr = body['start_date'] as String?;
      final endDateStr = body['end_date'] as String?;

      final season = await _seasonService.startNewSeason(
        teamId: teamId,
        name: name,
        startDate: startDateStr != null ? DateTime.tryParse(startDateStr) : null,
        endDate: endDateStr != null ? DateTime.tryParse(endDateStr) : null,
      );

      return Response.ok(
        jsonEncode(season.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke starte ny sesong: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
