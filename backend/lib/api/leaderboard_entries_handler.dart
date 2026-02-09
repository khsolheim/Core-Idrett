import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/leaderboard_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class LeaderboardEntriesHandler {
  final LeaderboardService _leaderboardService;
  final TeamService _teamService;

  LeaderboardEntriesHandler(this._leaderboardService, this._teamService);

  Router get router {
    final router = Router();

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
      return resp.serverError('Kunne ikke hente entries');
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
      return resp.serverError('Kunne ikke hente brukerentry');
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

      final body = await parseBody(request);

      // Support single user or multiple users
      if (body['user_id'] != null) {
        final targetUserId = body['user_id'] as String;
        final points = safeIntNullable(body, 'points') ?? 0;
        final addToExisting = safeBoolNullable(body, 'add_to_existing') ?? true;

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
      return resp.serverError('Kunne ikke legge til poeng');
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
      return resp.serverError('Kunne ikke nullstille leaderboard');
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
      return resp.serverError('Kunne ikke hente poengkonfigurasjon');
    }
  }

  Future<Response> _upsertPointConfig(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await parseBody(request);
      final leaderboardId = safeStringNullable(body, 'leaderboard_id');

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
        distributionType: safeStringNullable(body, 'distribution_type') ?? 'winner_only',
        pointsFirst: safeIntNullable(body, 'points_first') ?? 5,
        pointsSecond: safeIntNullable(body, 'points_second') ?? 3,
        pointsThird: safeIntNullable(body, 'points_third') ?? 1,
        pointsParticipation: safeIntNullable(body, 'points_participation') ?? 0,
      );

      return resp.ok(config.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere poengkonfigurasjon');
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
      return resp.serverError('Kunne ikke slette poengkonfigurasjon');
    }
  }
}
