import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/stopwatch_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class StopwatchTimesHandler {
  final StopwatchService _stopwatchService;

  StopwatchTimesHandler(this._stopwatchService);

  Router get router {
    final router = Router();

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
