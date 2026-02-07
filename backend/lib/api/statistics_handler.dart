import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/statistics_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class StatisticsHandler {
  final StatisticsService _statisticsService;
  final TeamService _teamService;

  StatisticsHandler(this._statisticsService, this._teamService);

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
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final yearParam = request.url.queryParameters['year'];
      final year = yearParam != null ? int.tryParse(yearParam) : null;

      final leaderboard = await _statisticsService.getLeaderboard(teamId, seasonYear: year);

      return resp.ok({
        'leaderboard': leaderboard.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente leaderboard: $e');
    }
  }

  Future<Response> _getTeamAttendance(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final fromParam = request.url.queryParameters['from'];
      final toParam = request.url.queryParameters['to'];

      final from = fromParam != null ? DateTime.tryParse(fromParam) : null;
      final to = toParam != null ? DateTime.tryParse(toParam) : null;

      final attendance = await _statisticsService.getTeamAttendance(
        teamId,
        fromDate: from,
        toDate: to,
      );

      return resp.ok({
        'attendance': attendance.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente oppmote: $e');
    }
  }

  Future<Response> _getPlayerStatistics(Request request, String teamId, String userId) async {
    try {
      final requestUserId = getUserId(request);
      if (requestUserId == null) return resp.forbidden('Ikke autorisert');

      final team = await requireTeamMember(_teamService, teamId, requestUserId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final stats = await _statisticsService.getPlayerStatistics(userId, teamId);

      if (stats == null) {
        return resp.notFound('Spiller ikke funnet i laget');
      }

      return resp.ok(stats.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente spillerstatistikk: $e');
    }
  }

  Future<Response> _getMatchStats(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final stats = await _statisticsService.getMatchStats(instanceId);

      return resp.ok({
        'match_stats': stats.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente kampstatistikk: $e');
    }
  }

  Future<Response> _recordMatchStats(Request request, String instanceId) async {
    try {
      final requestUserId = getUserId(request);
      if (requestUserId == null) return resp.forbidden('Ikke autorisert');

      final body = await parseBody(request);
      final userId = body['user_id'] as String?;

      if (userId == null) {
        return resp.badRequest('user_id er pakrevd');
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
        return resp.serverError('Kunne ikke registrere statistikk');
      }

      return resp.ok(stats.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke registrere kampstatistikk: $e');
    }
  }
}
