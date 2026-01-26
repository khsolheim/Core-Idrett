import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/statistics_service.dart';

class StatisticsHandler {
  final StatisticsService _statisticsService;

  StatisticsHandler(this._statisticsService);

  Router get router {
    final router = Router();

    // Team statistics
    router.get('/teams/<teamId>/leaderboard', _getLeaderboard);
    router.get('/teams/<teamId>/attendance', _getTeamAttendance);

    // Player statistics
    router.get('/teams/<teamId>/users/<userId>/statistics', _getPlayerStatistics);

    // Match stats
    router.get('/instances/<instanceId>/match-stats', _getMatchStats);
    router.post('/instances/<instanceId>/match-stats', _recordMatchStats);

    return router;
  }

  Future<Response> _getLeaderboard(Request request, String teamId) async {
    try {
      final yearParam = request.url.queryParameters['year'];
      final year = yearParam != null ? int.tryParse(yearParam) : null;

      final leaderboard = await _statisticsService.getLeaderboard(teamId, seasonYear: year);

      return Response.ok(
        jsonEncode({
          'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente leaderboard: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getTeamAttendance(Request request, String teamId) async {
    try {
      final fromParam = request.url.queryParameters['from'];
      final toParam = request.url.queryParameters['to'];

      final from = fromParam != null ? DateTime.tryParse(fromParam) : null;
      final to = toParam != null ? DateTime.tryParse(toParam) : null;

      final attendance = await _statisticsService.getTeamAttendance(
        teamId,
        fromDate: from,
        toDate: to,
      );

      return Response.ok(
        jsonEncode({
          'attendance': attendance.map((e) => e.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente oppmøte: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getPlayerStatistics(Request request, String teamId, String userId) async {
    try {
      final stats = await _statisticsService.getPlayerStatistics(userId, teamId);

      if (stats == null) {
        return Response.notFound(
          jsonEncode({'error': 'Spiller ikke funnet i laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(stats.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente spillerstatistikk: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getMatchStats(Request request, String instanceId) async {
    try {
      final stats = await _statisticsService.getMatchStats(instanceId);

      return Response.ok(
        jsonEncode({
          'match_stats': stats.map((e) => e.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente kampstatistikk: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _recordMatchStats(Request request, String instanceId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final userId = body['user_id'] as String?;

      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id er påkrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final stats = await _statisticsService.recordMatchStats(
        instanceId: instanceId,
        userId: userId,
        goals: body['goals'] ?? 0,
        assists: body['assists'] ?? 0,
        minutesPlayed: body['minutes_played'] ?? 0,
        yellowCards: body['yellow_cards'] ?? 0,
        redCards: body['red_cards'] ?? 0,
      );

      if (stats == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Kunne ikke registrere statistikk'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(stats.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke registrere kampstatistikk: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
