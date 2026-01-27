import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';

class LeaderboardsHandler {
  final LeaderboardService _leaderboardService;
  final AuthService _authService;
  final TeamService _teamService;

  LeaderboardsHandler(this._leaderboardService, this._authService, this._teamService);

  Router get router {
    final router = Router();

    // Leaderboard routes
    router.get('/teams/<teamId>', _getLeaderboards);
    router.get('/teams/<teamId>/main', _getMainLeaderboard);
    router.post('/teams/<teamId>', _createLeaderboard);
    router.get('/<leaderboardId>', _getLeaderboardById);
    router.patch('/<leaderboardId>', _updateLeaderboard);
    router.delete('/<leaderboardId>', _deleteLeaderboard);

    // Entries routes
    router.get('/<leaderboardId>/entries', _getEntries);
    router.get('/<leaderboardId>/entries/<userId>', _getUserEntry);
    router.post('/<leaderboardId>/entries', _addPoints);
    router.post('/<leaderboardId>/reset', _resetLeaderboard);

    // Point config routes
    router.get('/mini/<miniActivityId>/config', _getPointConfigs);
    router.post('/mini/<miniActivityId>/config', _upsertPointConfig);
    router.delete('/mini/<miniActivityId>/config/<leaderboardId>', _deletePointConfig);

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

  Future<Response> _getLeaderboards(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final seasonId = request.url.queryParameters['season_id'];
      final leaderboards = await _leaderboardService.getLeaderboardsForTeam(
        teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode({
          'leaderboards': leaderboards.map((l) => l.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente leaderboards: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getMainLeaderboard(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final leaderboard = await _leaderboardService.getMainLeaderboard(teamId);

      if (leaderboard == null) {
        return Response.notFound(
          jsonEncode({'error': 'Ingen hovedranking funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Also get entries
      final entries = await _leaderboardService.getLeaderboardEntries(
        leaderboard.id,
        limit: 50,
      );

      return Response.ok(
        jsonEncode({
          ...leaderboard.toJson(),
          'entries': entries.map((e) => e.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente hovedranking: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getLeaderboardById(Request request, String leaderboardId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final leaderboard = await _leaderboardService.getLeaderboardById(leaderboardId);
      if (leaderboard == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(leaderboard.teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette leaderboardet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(leaderboard.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente leaderboard: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createLeaderboard(Request request, String teamId) async {
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
          jsonEncode({'error': 'Kun admin kan opprette leaderboards'}),
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

      final leaderboard = await _leaderboardService.createLeaderboard(
        teamId: teamId,
        seasonId: body['season_id'] as String?,
        name: name,
        description: body['description'] as String?,
        isMain: body['is_main'] as bool? ?? false,
        sortOrder: body['sort_order'] as int? ?? 0,
      );

      return Response.ok(
        jsonEncode(leaderboard.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette leaderboard: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _updateLeaderboard(Request request, String leaderboardId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan oppdatere leaderboards'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

      final leaderboard = await _leaderboardService.updateLeaderboard(
        leaderboardId: leaderboardId,
        name: body['name'] as String?,
        description: body['description'] as String?,
        isMain: body['is_main'] as bool?,
        sortOrder: body['sort_order'] as int?,
        clearDescription: body['clear_description'] == true,
      );

      if (leaderboard == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(leaderboard.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke oppdatere leaderboard: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteLeaderboard(Request request, String leaderboardId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan slette leaderboards'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _leaderboardService.deleteLeaderboard(leaderboardId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette leaderboard: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getEntries(Request request, String leaderboardId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette leaderboardet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final limitParam = request.url.queryParameters['limit'];
      final offsetParam = request.url.queryParameters['offset'];

      final entries = await _leaderboardService.getLeaderboardEntries(
        leaderboardId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
        offset: offsetParam != null ? int.tryParse(offsetParam) ?? 0 : 0,
      );

      return Response.ok(
        jsonEncode({
          'entries': entries.map((e) => e.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente entries: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserEntry(Request request, String leaderboardId, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette leaderboardet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final entry = await _leaderboardService.getUserEntry(leaderboardId, targetUserId);

      if (entry == null) {
        return Response.notFound(
          jsonEncode({'error': 'Bruker ikke funnet i leaderboard'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(entry.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente brukerentry: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _addPoints(Request request, String leaderboardId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan legge til poeng'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

      // Support single user or multiple users
      if (body['user_id'] != null) {
        final targetUserId = body['user_id'] as String;
        final points = body['points'] as int? ?? 0;
        final addToExisting = body['add_to_existing'] as bool? ?? true;

        final entry = await _leaderboardService.upsertEntry(
          leaderboardId: leaderboardId,
          userId: targetUserId,
          points: points,
          addToExisting: addToExisting,
        );

        return Response.ok(
          jsonEncode(entry.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
      } else if (body['user_points'] != null) {
        final userPoints = Map<String, int>.from(body['user_points'] as Map);

        await _leaderboardService.addPointsToUsers(
          leaderboardId: leaderboardId,
          userPoints: userPoints,
        );

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id eller user_points er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke legge til poeng: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _resetLeaderboard(Request request, String leaderboardId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan nullstille leaderboard'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _leaderboardService.resetLeaderboard(leaderboardId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke nullstille leaderboard: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getPointConfigs(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final configs = await _leaderboardService.getPointConfigsForMiniActivity(miniActivityId);

      return Response.ok(
        jsonEncode({
          'configs': configs.map((c) => c.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente poengkonfigurasjon: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _upsertPointConfig(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final leaderboardId = body['leaderboard_id'] as String?;

      if (leaderboardId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'leaderboard_id er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Verify admin access to leaderboard's team
      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan konfigurere poeng'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final config = await _leaderboardService.upsertPointConfig(
        miniActivityId: miniActivityId,
        leaderboardId: leaderboardId,
        distributionType: body['distribution_type'] as String? ?? 'winner_only',
        pointsFirst: body['points_first'] as int? ?? 5,
        pointsSecond: body['points_second'] as int? ?? 3,
        pointsThird: body['points_third'] as int? ?? 1,
        pointsParticipation: body['points_participation'] as int? ?? 0,
      );

      return Response.ok(
        jsonEncode(config.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke oppdatere poengkonfigurasjon: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deletePointConfig(
    Request request,
    String miniActivityId,
    String leaderboardId,
  ) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Leaderboard ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan fjerne poengkonfigurasjon'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _leaderboardService.deletePointConfig(miniActivityId, leaderboardId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette poengkonfigurasjon: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
