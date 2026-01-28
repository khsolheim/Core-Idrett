import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/stopwatch_service.dart';
import '../services/team_service.dart';
import '../models/stopwatch.dart';

class StopwatchHandler {
  final StopwatchService _stopwatchService;
  final AuthService _authService;
  final TeamService _teamService;

  StopwatchHandler(this._stopwatchService, this._authService, this._teamService);

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

  // ============ SESSION CRUD ============

  Future<Response> _createSession(Request request) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final sessionTypeStr = data['session_type'] as String?;
      if (sessionTypeStr == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevd felt (session_type)'}));
      }

      final session = await _stopwatchService.createSession(
        miniActivityId: data['mini_activity_id'] as String?,
        teamId: data['team_id'] as String?,
        name: data['name'] as String?,
        sessionType: StopwatchSessionType.fromString(sessionTypeStr),
        countdownDurationMs: data['countdown_duration_ms'] as int?,
        createdBy: userId,
      );

      return Response.ok(jsonEncode(session.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getSession(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final session = await _stopwatchService.getSessionById(sessionId);
      if (session == null) {
        return Response(404, body: jsonEncode({'error': 'Økt ikke funnet'}));
      }

      return Response.ok(jsonEncode(session.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getSessionWithTimes(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final sessionWithTimes = await _stopwatchService.getSessionWithTimes(sessionId);
      if (sessionWithTimes == null) {
        return Response(404, body: jsonEncode({'error': 'Økt ikke funnet'}));
      }

      return Response.ok(jsonEncode(sessionWithTimes.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteSession(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _stopwatchService.deleteSession(sessionId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ LIST SESSIONS ============

  Future<Response> _getSessionsForMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final sessions = await _stopwatchService.getSessionsForMiniActivity(miniActivityId);
      return Response.ok(jsonEncode(sessions.map((s) => s.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getSessionsForTeam(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final sessions = await _stopwatchService.getSessionsForTeam(teamId);
      return Response.ok(jsonEncode(sessions.map((s) => s.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getActiveSessions(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final sessions = await _stopwatchService.getActiveSessions(teamId);
      return Response.ok(jsonEncode(sessions.map((s) => s.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ SESSION CONTROL ============

  Future<Response> _startSession(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final session = await _stopwatchService.startSession(sessionId);
      if (session == null) {
        return Response(404, body: jsonEncode({'error': 'Økt ikke funnet'}));
      }

      return Response.ok(jsonEncode(session.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _pauseSession(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final session = await _stopwatchService.pauseSession(sessionId);
      if (session == null) {
        return Response(404, body: jsonEncode({'error': 'Økt ikke funnet'}));
      }

      return Response.ok(jsonEncode(session.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _stopSession(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final session = await _stopwatchService.stopSession(sessionId);
      if (session == null) {
        return Response(404, body: jsonEncode({'error': 'Økt ikke funnet'}));
      }

      return Response.ok(jsonEncode(session.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _resetSession(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final session = await _stopwatchService.resetSession(sessionId);
      if (session == null) {
        return Response(404, body: jsonEncode({'error': 'Økt ikke funnet'}));
      }

      return Response.ok(jsonEncode(session.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _cancelSession(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _stopwatchService.cancelSession(sessionId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ TIME RECORDING ============

  Future<Response> _recordTime(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final participantUserId = data['user_id'] as String?;
      final timeMs = data['time_ms'] as int?;

      if (participantUserId == null || timeMs == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (user_id, time_ms)'}));
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

      return Response.ok(jsonEncode(time.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _recordCurrentTime(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final participantUserId = data['user_id'] as String?;
      if (participantUserId == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevd felt (user_id)'}));
      }

      final time = await _stopwatchService.recordCurrentTime(
        sessionId: sessionId,
        userId: participantUserId,
        isSplit: data['is_split'] as bool? ?? false,
        splitNumber: data['split_number'] as int?,
        notes: data['notes'] as String?,
      );

      if (time == null) {
        return Response(404, body: jsonEncode({'error': 'Økt ikke funnet'}));
      }

      return Response.ok(jsonEncode(time.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getTimesForSession(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final times = await _stopwatchService.getTimesForSession(sessionId);
      return Response.ok(jsonEncode(times.map((t) => t.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getTimesForUser(Request request, String sessionId, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final times = await _stopwatchService.getTimesForUser(
        sessionId: sessionId,
        userId: targetUserId,
      );
      return Response.ok(jsonEncode(times.map((t) => t.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _updateTime(Request request, String timeId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      await _stopwatchService.updateTime(
        timeId: timeId,
        timeMs: data['time_ms'] as int?,
        notes: data['notes'] as String?,
      );

      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteTime(Request request, String timeId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _stopwatchService.deleteTime(timeId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ BULK OPERATIONS ============

  Future<Response> _recordMultipleTimes(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final times = (data['times'] as List?)?.cast<Map<String, dynamic>>();
      if (times == null || times.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevd felt (times)'}));
      }

      await _stopwatchService.recordMultipleTimes(
        sessionId: sessionId,
        times: times,
      );

      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ RANKINGS ============

  Future<Response> _getSessionRankings(Request request, String sessionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final rankings = await _stopwatchService.getSessionRankings(sessionId);
      return Response.ok(jsonEncode(rankings));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }
}
