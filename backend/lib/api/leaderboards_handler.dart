import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../models/season.dart';
import '../services/leaderboard_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;
import 'leaderboard_entries_handler.dart';

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

    // Mount entries and point config handler
    final entriesHandler = LeaderboardEntriesHandler(_leaderboardService, _teamService);
    router.mount('/', entriesHandler.router.call);

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

      final body = await parseBody(request);
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

      final body = await parseBody(request);

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
