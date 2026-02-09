import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/mini_activity_statistics_service.dart';
import '../services/team_service.dart';
import '../models/mini_activity_statistics.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class MiniActivityStatisticsHandler {
  final MiniActivityPlayerStatsService _playerStatsService;
  final MiniActivityHeadToHeadService _headToHeadService;
  final MiniActivityStatsAggregationService _aggregationService;
  final TeamService _teamService;

  MiniActivityStatisticsHandler(
    this._playerStatsService,
    this._headToHeadService,
    this._aggregationService,
    this._teamService,
  );

  Router get router {
    final router = Router();

    // Player stats
    router.get('/team/<teamId>/players', _getTeamPlayerStats);
    router.get('/team/<teamId>/player/<userId>', _getPlayerStats);
    router.get('/team/<teamId>/player/<userId>/aggregate', _getPlayerStatsAggregate);

    // Head-to-head
    router.get('/team/<teamId>/head-to-head/<user1Id>/<user2Id>', _getHeadToHead);
    router.get('/team/<teamId>/user/<userId>/head-to-head', _getHeadToHeadForUser);

    // Team history
    router.get('/user/<userId>/history', _getTeamHistoryForUser);

    // Leaderboard
    router.get('/team/<teamId>/leaderboard', _getMiniActivityLeaderboard);

    // Point sources
    router.get('/user/<userId>/point-sources', _getPointSourcesForUser);
    router.get('/entry/<entryId>/point-sources', _getPointSourcesForEntry);

    // Process results (admin)
    router.post('/mini-activity/<miniActivityId>/process-results', _processMiniActivityResults);

    return router;
  }

  // ============ PLAYER STATS ============

  Future<Response> _getTeamPlayerStats(Request request, String teamId) async {
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
      final sortBy = request.url.queryParameters['sort_by'];
      final descending = request.url.queryParameters['descending'] != 'false';

      final stats = await _playerStatsService.getTeamPlayerStats(
        teamId: teamId,
        seasonId: seasonId,
        sortBy: sortBy,
        descending: descending,
      );

      return resp.ok(stats.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getPlayerStats(Request request, String teamId, String targetUserId) async {
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

      final stats = await _playerStatsService.getPlayerStats(
        userId: targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      if (stats == null) {
        return resp.notFound('Statistikk ikke funnet');
      }

      return resp.ok(stats.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getPlayerStatsAggregate(Request request, String teamId, String targetUserId) async {
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

      final aggregate = await _aggregationService.getPlayerStatsAggregate(
        userId: targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      if (aggregate == null) {
        return resp.notFound('Statistikk ikke funnet');
      }

      return resp.ok(aggregate.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ HEAD-TO-HEAD ============

  Future<Response> _getHeadToHead(Request request, String teamId, String user1Id, String user2Id) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final stats = await _headToHeadService.getHeadToHead(
        teamId: teamId,
        user1Id: user1Id,
        user2Id: user2Id,
      );

      if (stats == null) {
        return resp.notFound('Head-to-head statistikk ikke funnet');
      }

      return resp.ok(stats.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getHeadToHeadForUser(Request request, String teamId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final stats = await _headToHeadService.getHeadToHeadForUser(
        teamId: teamId,
        userId: targetUserId,
      );

      return resp.ok(stats.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ TEAM HISTORY ============

  Future<Response> _getTeamHistoryForUser(Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 50 : 50;

      final history = await _headToHeadService.getTeamHistoryForUser(
        userId: targetUserId,
        limit: limit,
      );

      return resp.ok(history.map((h) => h.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ LEADERBOARD ============

  Future<Response> _getMiniActivityLeaderboard(Request request, String teamId) async {
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
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 50 : 50;

      final leaderboard = await _aggregationService.getMiniActivityLeaderboard(
        teamId: teamId,
        seasonId: seasonId,
        limit: limit,
      );

      return resp.ok(leaderboard);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ POINT SOURCES ============

  Future<Response> _getPointSourcesForUser(Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final leaderboardEntryId = request.url.queryParameters['leaderboard_entry_id'];
      final sourceTypeStr = request.url.queryParameters['source_type'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 100 : 100;

      PointSourceType? sourceType;
      if (sourceTypeStr != null) {
        sourceType = PointSourceType.fromString(sourceTypeStr);
      }

      final sources = await _headToHeadService.getPointSourcesForUser(
        userId: targetUserId,
        leaderboardEntryId: leaderboardEntryId,
        sourceType: sourceType,
        limit: limit,
      );

      return resp.ok(sources.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getPointSourcesForEntry(Request request, String entryId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final sources = await _headToHeadService.getPointSourcesForEntry(entryId);
      return resp.ok(sources.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ PROCESS RESULTS ============

  Future<Response> _processMiniActivityResults(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final teamId = safeStringNullable(data, 'team_id');
      final results = (safeListNullable(data, 'results'))?.cast<Map<String, dynamic>>();

      if (teamId == null || results == null) {
        return resp.badRequest('Mangler pakrevde felt (team_id, results)');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan behandle resultater');
      }

      await _aggregationService.processMiniActivityResults(
        miniActivityId: miniActivityId,
        teamId: teamId,
        seasonId: safeStringNullable(data, 'season_id'),
        results: results,
      );

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
