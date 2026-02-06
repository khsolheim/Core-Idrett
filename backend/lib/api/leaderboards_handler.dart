import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../models/season.dart';
import '../services/leaderboard_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class LeaderboardsHandler {
  final LeaderboardService _leaderboardService;
  final TeamService _teamService;

  LeaderboardsHandler(this._leaderboardService, this._teamService);

  Router get router {
    final router = Router();

    // Leaderboard routes
    router.get('/teams/<teamId>', _getLeaderboards);
    router.get('/teams/<teamId>/main', _getMainLeaderboard);
    router.get('/teams/<teamId>/ranked', _getRankedLeaderboard);
    router.get('/teams/<teamId>/trends', _getLeaderboardWithTrends);
    router.get('/teams/<teamId>/users/<userId>/position', _getUserRankedPosition);
    router.get('/teams/<teamId>/users/<userId>/monthly', _getUserMonthlyStats);
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

  Future<Response> _getLeaderboards(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasonId = request.url.queryParameters['season_id'];
      final leaderboards = await _leaderboardService.getLeaderboardsForTeam(
        teamId,
        seasonId: seasonId,
      );

      return resp.ok({
        'leaderboards': leaderboards.map((l) => l.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente leaderboards: $e');
    }
  }

  Future<Response> _getMainLeaderboard(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final leaderboard = await _leaderboardService.getMainLeaderboard(teamId);

      if (leaderboard == null) {
        return resp.notFound('Ingen hovedranking funnet');
      }

      // Also get entries
      final entries = await _leaderboardService.getLeaderboardEntries(
        leaderboard.id,
        limit: 50,
      );

      return resp.ok({
        ...leaderboard.toJson(),
        'entries': entries.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente hovedranking: $e');
    }
  }

  Future<Response> _getLeaderboardById(Request request, String leaderboardId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final leaderboard = await _leaderboardService.getLeaderboardById(leaderboardId);
      if (leaderboard == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, leaderboard.teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette leaderboardet');
      }

      return resp.ok(leaderboard.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente leaderboard: $e');
    }
  }

  Future<Response> _createLeaderboard(Request request, String teamId) async {
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
        return resp.forbidden('Kun admin kan opprette leaderboards');
      }

      final body = jsonDecode(await request.readAsString());
      final name = body['name'] as String?;

      if (name == null || name.isEmpty) {
        return resp.badRequest('Navn er pakrevd');
      }

      final leaderboard = await _leaderboardService.createLeaderboard(
        teamId: teamId,
        seasonId: body['season_id'] as String?,
        name: name,
        description: body['description'] as String?,
        isMain: body['is_main'] as bool? ?? false,
        sortOrder: body['sort_order'] as int? ?? 0,
      );

      return resp.ok(leaderboard.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette leaderboard: $e');
    }
  }

  Future<Response> _updateLeaderboard(Request request, String leaderboardId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan oppdatere leaderboards');
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
        return resp.notFound('Leaderboard ikke funnet');
      }

      return resp.ok(leaderboard.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere leaderboard: $e');
    }
  }

  Future<Response> _deleteLeaderboard(Request request, String leaderboardId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan slette leaderboards');
      }

      await _leaderboardService.deleteLeaderboard(leaderboardId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette leaderboard: $e');
    }
  }

  Future<Response> _getEntries(Request request, String leaderboardId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette leaderboardet');
      }

      final limitParam = request.url.queryParameters['limit'];
      final offsetParam = request.url.queryParameters['offset'];

      final entries = await _leaderboardService.getLeaderboardEntries(
        leaderboardId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
        offset: offsetParam != null ? int.tryParse(offsetParam) ?? 0 : 0,
      );

      return resp.ok({
        'entries': entries.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente entries: $e');
    }
  }

  Future<Response> _getUserEntry(Request request, String leaderboardId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette leaderboardet');
      }

      final entry = await _leaderboardService.getUserEntry(leaderboardId, targetUserId);

      if (entry == null) {
        return resp.notFound('Bruker ikke funnet i leaderboard');
      }

      return resp.ok(entry.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente brukerentry: $e');
    }
  }

  Future<Response> _addPoints(Request request, String leaderboardId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan legge til poeng');
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

        return resp.ok(entry.toJson());
      } else if (body['user_points'] != null) {
        final userPoints = Map<String, int>.from(body['user_points'] as Map);

        await _leaderboardService.addPointsToUsers(
          leaderboardId: leaderboardId,
          userPoints: userPoints,
        );

        return resp.ok({'success': true});
      } else {
        return resp.badRequest('user_id eller user_points er pakrevd');
      }
    } catch (e) {
      return resp.serverError('Kunne ikke legge til poeng: $e');
    }
  }

  Future<Response> _resetLeaderboard(Request request, String leaderboardId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan nullstille leaderboard');
      }

      await _leaderboardService.resetLeaderboard(leaderboardId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke nullstille leaderboard: $e');
    }
  }

  Future<Response> _getPointConfigs(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final configs = await _leaderboardService.getPointConfigsForMiniActivity(miniActivityId);

      return resp.ok({
        'configs': configs.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente poengkonfigurasjon: $e');
    }
  }

  Future<Response> _upsertPointConfig(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = jsonDecode(await request.readAsString());
      final leaderboardId = body['leaderboard_id'] as String?;

      if (leaderboardId == null) {
        return resp.badRequest('leaderboard_id er pakrevd');
      }

      // Verify admin access to leaderboard's team
      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan konfigurere poeng');
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

      return resp.ok(config.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere poengkonfigurasjon: $e');
    }
  }

  Future<Response> _deletePointConfig(
    Request request,
    String miniActivityId,
    String leaderboardId,
  ) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _leaderboardService.getTeamIdForLeaderboard(leaderboardId);
      if (teamId == null) {
        return resp.notFound('Leaderboard ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan fjerne poengkonfigurasjon');
      }

      await _leaderboardService.deletePointConfig(miniActivityId, leaderboardId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette poengkonfigurasjon: $e');
    }
  }

  // ============ RANKED LEADERBOARD ENDPOINTS ============

  Future<Response> _getRankedLeaderboard(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasonId = request.url.queryParameters['season_id'];
      final categoryParam = request.url.queryParameters['category'];
      final limitParam = request.url.queryParameters['limit'];
      final offsetParam = request.url.queryParameters['offset'];
      final includeOptedOutParam = request.url.queryParameters['include_opted_out'];

      // Parse category if provided
      LeaderboardCategory? category;
      if (categoryParam != null) {
        category = LeaderboardCategory.values.where(
          (c) => c.name == categoryParam,
        ).firstOrNull;
      }

      final entries = await _leaderboardService.getRankedEntries(
        teamId,
        category: category,
        seasonId: seasonId,
        excludeOptedOut: includeOptedOutParam != 'true',
        limit: limitParam != null ? int.tryParse(limitParam) : null,
        offset: offsetParam != null ? int.tryParse(offsetParam) ?? 0 : 0,
      );

      return resp.ok({
        'entries': entries.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente rangert leaderboard: $e');
    }
  }

  Future<Response> _getLeaderboardWithTrends(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasonId = request.url.queryParameters['season_id'];
      final categoryParam = request.url.queryParameters['category'];
      final limitParam = request.url.queryParameters['limit'];

      // Parse category if provided
      LeaderboardCategory? category;
      if (categoryParam != null) {
        category = LeaderboardCategory.values.where(
          (c) => c.name == categoryParam,
        ).firstOrNull;
      }

      final entries = await _leaderboardService.getLeaderboardWithTrends(
        teamId,
        category: category,
        seasonId: seasonId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
      );

      return resp.ok({
        'entries': entries.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente leaderboard med trender: $e');
    }
  }

  Future<Response> _getUserRankedPosition(
    Request request,
    String teamId,
    String targetUserId,
  ) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasonId = request.url.queryParameters['season_id'];

      final entry = await _leaderboardService.getUserRankedPosition(
        teamId,
        targetUserId,
        seasonId: seasonId,
      );

      if (entry == null) {
        return resp.notFound('Bruker ikke funnet i leaderboard');
      }

      return resp.ok(entry.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente brukerposisjon: $e');
    }
  }

  Future<Response> _getUserMonthlyStats(
    Request request,
    String teamId,
    String targetUserId,
  ) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final yearParam = request.url.queryParameters['year'];
      final monthParam = request.url.queryParameters['month'];
      final limitParam = request.url.queryParameters['limit'];

      final stats = await _leaderboardService.getUserMonthlyStats(
        teamId,
        targetUserId,
        year: yearParam != null ? int.tryParse(yearParam) : null,
        month: monthParam != null ? int.tryParse(monthParam) : null,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
      );

      return resp.ok({
        'stats': stats,
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente månedlig statistikk: $e');
    }
  }
}
