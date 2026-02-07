import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/stopwatch_service.dart';
import '../services/team_service.dart';
import '../models/stopwatch.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

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

    // Time recording
    router.post('/sessions/<sessionId>/times', _recordTime);
    router.post('/sessions/<sessionId>/record-current', _recordCurrentTime);
    router.get('/sessions/<sessionId>/times', _getTimesForSession);
    router.get('/sessions/<sessionId>/times/user/<userId>', _getTimesForUser);
    router.put('/times/<timeId>', _updateTime);
    router.delete('/times/<timeId>', _deleteTime);

    // Bulk operations
    router.post('/sessions/<sessionId>/times/bulk', _recordMultipleTimes);

    // Rankings
    router.get('/sessions/<sessionId>/rankings', _getSessionRankings);

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

      final sessionTypeStr = data['session_type'] as String?;
      if (sessionTypeStr == null) {
        return resp.badRequest('Mangler påkrevd felt (session_type)');
      }

      final session = await _stopwatchService.createSession(
        miniActivityId: data['mini_activity_id'] as String?,
        teamId: data['team_id'] as String?,
        name: data['name'] as String?,
        sessionType: StopwatchSessionType.fromString(sessionTypeStr),
        countdownDurationMs: data['countdown_duration_ms'] as int?,
        createdBy: userId,
      );

      return resp.ok(session.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _deleteSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _stopwatchService.deleteSession(sessionId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
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
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _cancelSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _stopwatchService.cancelSession(sessionId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ TIME RECORDING ============

  Future<Response> _recordTime(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final participantUserId = data['user_id'] as String?;
      final timeMs = data['time_ms'] as int?;

      if (participantUserId == null || timeMs == null) {
        return resp.badRequest('Mangler påkrevde felt (user_id, time_ms)');
      }

      final time = await _stopwatchService.recordTime(
        sessionId: sessionId,
        userId: participantUserId,
        timeMs: timeMs,
        isSplit: data['is_split'] as bool? ?? false,
        splitNumber: data['split_number'] as int?,
        lapNumber: data['lap_number'] as int?,
        notes: data['notes'] as String?,
      );

      return resp.ok(time.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _recordCurrentTime(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final participantUserId = data['user_id'] as String?;
      if (participantUserId == null) {
        return resp.badRequest('Mangler påkrevd felt (user_id)');
      }

      final time = await _stopwatchService.recordCurrentTime(
        sessionId: sessionId,
        userId: participantUserId,
        isSplit: data['is_split'] as bool? ?? false,
        splitNumber: data['split_number'] as int?,
        notes: data['notes'] as String?,
      );

      if (time == null) {
        return resp.notFound('Økt ikke funnet');
      }

      return resp.ok(time.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getTimesForSession(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final times = await _stopwatchService.getTimesForSession(sessionId);
      return resp.ok(times.map((t) => t.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getTimesForUser(Request request, String sessionId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final times = await _stopwatchService.getTimesForUser(
        sessionId: sessionId,
        userId: targetUserId,
      );
      return resp.ok(times.map((t) => t.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateTime(Request request, String timeId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      await _stopwatchService.updateTime(
        timeId: timeId,
        timeMs: data['time_ms'] as int?,
        notes: data['notes'] as String?,
      );

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _deleteTime(Request request, String timeId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _stopwatchService.deleteTime(timeId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ BULK OPERATIONS ============

  Future<Response> _recordMultipleTimes(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final times = (data['times'] as List?)?.cast<Map<String, dynamic>>();
      if (times == null || times.isEmpty) {
        return resp.badRequest('Mangler påkrevd felt (times)');
      }

      await _stopwatchService.recordMultipleTimes(
        sessionId: sessionId,
        times: times,
      );

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ RANKINGS ============

  Future<Response> _getSessionRankings(Request request, String sessionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final rankings = await _stopwatchService.getSessionRankings(sessionId);
      return resp.ok(rankings);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }
}
