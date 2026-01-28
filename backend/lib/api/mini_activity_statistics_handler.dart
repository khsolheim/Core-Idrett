import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/mini_activity_statistics_service.dart';
import '../services/team_service.dart';
import '../models/mini_activity_statistics.dart';

class MiniActivityStatisticsHandler {
  final MiniActivityStatisticsService _statsService;
  final AuthService _authService;
  final TeamService _teamService;

  MiniActivityStatisticsHandler(this._statsService, this._authService, this._teamService);

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

  Future<String?> _getUserId(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    final token = authHeader.substring(7);
    final user = await _authService.getUserFromToken(token);
    return user?.id;
  }

  Future<bool> _isTeamMember(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    return team != null;
  }

  Future<bool> _isTeamAdmin(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    return team != null && team['user_role'] == 'admin';
  }

  // ============ PLAYER STATS ============

  Future<Response> _getTeamPlayerStats(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final seasonId = request.url.queryParameters['season_id'];
      final sortBy = request.url.queryParameters['sort_by'];
      final descending = request.url.queryParameters['descending'] != 'false';

      final stats = await _statsService.getTeamPlayerStats(
        teamId: teamId,
        seasonId: seasonId,
        sortBy: sortBy,
        descending: descending,
      );

      return Response.ok(jsonEncode(stats.map((s) => s.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getPlayerStats(Request request, String teamId, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final seasonId = request.url.queryParameters['season_id'];

      final stats = await _statsService.getPlayerStats(
        userId: targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      if (stats == null) {
        return Response(404, body: jsonEncode({'error': 'Statistikk ikke funnet'}));
      }

      return Response.ok(jsonEncode(stats.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getPlayerStatsAggregate(Request request, String teamId, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final seasonId = request.url.queryParameters['season_id'];

      final aggregate = await _statsService.getPlayerStatsAggregate(
        userId: targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      if (aggregate == null) {
        return Response(404, body: jsonEncode({'error': 'Statistikk ikke funnet'}));
      }

      return Response.ok(jsonEncode(aggregate.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ HEAD-TO-HEAD ============

  Future<Response> _getHeadToHead(Request request, String teamId, String user1Id, String user2Id) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final stats = await _statsService.getHeadToHead(
        teamId: teamId,
        user1Id: user1Id,
        user2Id: user2Id,
      );

      if (stats == null) {
        return Response(404, body: jsonEncode({'error': 'Head-to-head statistikk ikke funnet'}));
      }

      return Response.ok(jsonEncode(stats.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getHeadToHeadForUser(Request request, String teamId, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final stats = await _statsService.getHeadToHeadForUser(
        teamId: teamId,
        userId: targetUserId,
      );

      return Response.ok(jsonEncode(stats.map((s) => s.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ TEAM HISTORY ============

  Future<Response> _getTeamHistoryForUser(Request request, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 50 : 50;

      final history = await _statsService.getTeamHistoryForUser(
        userId: targetUserId,
        limit: limit,
      );

      return Response.ok(jsonEncode(history.map((h) => h.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ LEADERBOARD ============

  Future<Response> _getMiniActivityLeaderboard(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final seasonId = request.url.queryParameters['season_id'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 50 : 50;

      final leaderboard = await _statsService.getMiniActivityLeaderboard(
        teamId: teamId,
        seasonId: seasonId,
        limit: limit,
      );

      return Response.ok(jsonEncode(leaderboard));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ POINT SOURCES ============

  Future<Response> _getPointSourcesForUser(Request request, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final leaderboardEntryId = request.url.queryParameters['leaderboard_entry_id'];
      final sourceTypeStr = request.url.queryParameters['source_type'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 100 : 100;

      PointSourceType? sourceType;
      if (sourceTypeStr != null) {
        sourceType = PointSourceType.fromString(sourceTypeStr);
      }

      final sources = await _statsService.getPointSourcesForUser(
        userId: targetUserId,
        leaderboardEntryId: leaderboardEntryId,
        sourceType: sourceType,
        limit: limit,
      );

      return Response.ok(jsonEncode(sources.map((s) => s.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getPointSourcesForEntry(Request request, String entryId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final sources = await _statsService.getPointSourcesForEntry(entryId);
      return Response.ok(jsonEncode(sources.map((s) => s.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ PROCESS RESULTS ============

  Future<Response> _processMiniActivityResults(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final teamId = data['team_id'] as String?;
      final results = (data['results'] as List?)?.cast<Map<String, dynamic>>();

      if (teamId == null || results == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (team_id, results)'}));
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan behandle resultater'}));
      }

      await _statsService.processMiniActivityResults(
        miniActivityId: miniActivityId,
        teamId: teamId,
        seasonId: data['season_id'] as String?,
        results: results,
      );

      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }
}
