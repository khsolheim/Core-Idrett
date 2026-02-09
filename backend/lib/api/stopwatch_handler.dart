import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/stopwatch_service.dart';
import '../services/team_service.dart';
import '../models/stopwatch.dart';
import 'stopwatch_times_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class StopwatchHandler {
  final StopwatchService _stopwatchService;
  final TeamService _teamService;

  StopwatchHandler(this._stopwatchService, this._teamService);

  Router get router {
    final router = Router();

    // Session CRUD
    router.post('/sessions', _createSession);
    router.get('/sessions/<sessionId>', _getSession);
    router.get('/sessions/<sessionId>/with-times', _getSessionWithTimes);
    router.delete('/sessions/<sessionId>', _deleteSession);

    // List sessions
    router.get('/mini-activity/<miniActivityId>/sessions', _getSessionsForMiniActivity);
    router.get('/team/<teamId>/sessions', _getSessionsForTeam);
    router.get('/team/<teamId>/active', _getActiveSessions);

    // Session control
    router.post('/sessions/<sessionId>/start', _startSession);
    router.post('/sessions/<sessionId>/pause', _pauseSession);
    router.post('/sessions/<sessionId>/stop', _stopSession);
    router.post('/sessions/<sessionId>/reset', _resetSession);
    router.post('/sessions/<sessionId>/cancel', _cancelSession);

    // Mount time recording, bulk, and ranking routes
    final timesHandler = StopwatchTimesHandler(_stopwatchService);
    router.mount('/', timesHandler.router.call);

    return router;
  }

  // ============ SESSION CRUD ============

  Future<Response> _createSession(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final sessionTypeStr = safeStringNullable(data, 'session_type');
      if (sessionTypeStr == null) {
        return resp.badRequest('Mangler påkrevd felt (session_type)');
      }

      final session = await _stopwatchService.createSession(
        miniActivityId: safeStringNullable(data, 'mini_activity_id'),
        teamId: safeStringNullable(data, 'team_id'),
        name: safeStringNullable(data, 'name'),
        sessionType: StopwatchSessionType.fromString(sessionTypeStr),
        countdownDurationMs: safeIntNullable(data, 'countdown_duration_ms'),
        createdBy: userId,
      );

      return resp.ok(session.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final session = await _stopwatchService.getSessionById(sessionId);
      if (session == null) {
        return resp.notFound('Økt ikke funnet');
      }

      return resp.ok(session.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getSessionWithTimes(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final sessionWithTimes = await _stopwatchService.getSessionWithTimes(sessionId);
      if (sessionWithTimes == null) {
        return resp.notFound('Økt ikke funnet');
      }

      return resp.ok(sessionWithTimes.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _deleteSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _stopwatchService.deleteSession(sessionId);
      return resp.ok({'message': 'Stoppeklokke slettet'});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ LIST SESSIONS ============

  Future<Response> _getSessionsForMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final sessions = await _stopwatchService.getSessionsForMiniActivity(miniActivityId);
      return resp.ok(sessions.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getSessionsForTeam(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final sessions = await _stopwatchService.getSessionsForTeam(teamId);
      return resp.ok(sessions.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getActiveSessions(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final sessions = await _stopwatchService.getActiveSessions(teamId);
      return resp.ok(sessions.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ SESSION CONTROL ============

  Future<Response> _startSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final session = await _stopwatchService.startSession(sessionId);
      if (session == null) {
        return resp.notFound('Økt ikke funnet');
      }

      return resp.ok(session.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _pauseSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final session = await _stopwatchService.pauseSession(sessionId);
      if (session == null) {
        return resp.notFound('Økt ikke funnet');
      }

      return resp.ok(session.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _stopSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final session = await _stopwatchService.stopSession(sessionId);
      if (session == null) {
        return resp.notFound('Økt ikke funnet');
      }

      return resp.ok(session.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _resetSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final session = await _stopwatchService.resetSession(sessionId);
      if (session == null) {
        return resp.notFound('Økt ikke funnet');
      }

      return resp.ok(session.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _cancelSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _stopwatchService.cancelSession(sessionId);
      return resp.ok({'message': 'Avbrutt'});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
