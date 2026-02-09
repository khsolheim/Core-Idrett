import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/stopwatch.dart';
import 'user_service.dart';
import '../helpers/parsing_helpers.dart';

class StopwatchService {
  final Database _db;
  final UserService _userService;
  final _uuid = const Uuid();

  StopwatchService(this._db, this._userService);

  // ============ SESSION CRUD ============

  Future<StopwatchSession> createSession({
    String? miniActivityId,
    String? teamId,
    String? name,
    required StopwatchSessionType sessionType,
    int? countdownDurationMs,
    required String createdBy,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('stopwatch_sessions', {
      'id': id,
      'mini_activity_id': miniActivityId,
      'team_id': teamId,
      'name': name,
      'session_type': sessionType.value,
      'countdown_duration_ms': countdownDurationMs,
      'status': 'pending',
      'created_by': createdBy,
    });

    return StopwatchSession(
      id: id,
      miniActivityId: miniActivityId,
      teamId: teamId,
      name: name,
      sessionType: sessionType,
      countdownDurationMs: countdownDurationMs,
      status: StopwatchSessionStatus.pending,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  Future<StopwatchSession?> getSessionById(String sessionId) async {
    final result = await _db.client.select(
      'stopwatch_sessions',
      filters: {'id': 'eq.$sessionId'},
    );
    if (result.isEmpty) return null;
    return StopwatchSession.fromJson(result.first);
  }

  Future<List<StopwatchSession>> getSessionsForMiniActivity(String miniActivityId) async {
    final result = await _db.client.select(
      'stopwatch_sessions',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
      order: 'created_at.desc',
    );
    return result.map((row) => StopwatchSession.fromJson(row)).toList();
  }

  Future<List<StopwatchSession>> getSessionsForTeam(String teamId) async {
    final result = await _db.client.select(
      'stopwatch_sessions',
      filters: {'team_id': 'eq.$teamId'},
      order: 'created_at.desc',
    );
    return result.map((row) => StopwatchSession.fromJson(row)).toList();
  }

  Future<List<StopwatchSession>> getActiveSessions(String teamId) async {
    final result = await _db.client.select(
      'stopwatch_sessions',
      filters: {
        'team_id': 'eq.$teamId',
        'status': 'in.(pending,running,paused)',
      },
      order: 'created_at.desc',
    );
    return result.map((row) => StopwatchSession.fromJson(row)).toList();
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.client.delete(
      'stopwatch_sessions',
      filters: {'id': 'eq.$sessionId'},
    );
  }

  // ============ SESSION CONTROL ============

  Future<StopwatchSession?> startSession(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return null;
    if (!session.canStart && !session.canResume) return session;

    if (session.canStart) {
      // Fresh start
      await _db.client.update(
        'stopwatch_sessions',
        {
          'status': 'running',
          'started_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': 'eq.$sessionId'},
      );
    } else if (session.canResume) {
      // Resume from pause - update elapsed time and restart
      final now = DateTime.now();
      await _db.client.update(
        'stopwatch_sessions',
        {
          'status': 'running',
          'started_at': now.toIso8601String(),
          'paused_at': null,
        },
        filters: {'id': 'eq.$sessionId'},
      );
    }

    return getSessionById(sessionId);
  }

  Future<StopwatchSession?> pauseSession(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null || !session.isRunning) return session;

    final now = DateTime.now();
    final elapsedSinceStart = session.startedAt != null
        ? now.difference(session.startedAt!).inMilliseconds
        : 0;

    await _db.client.update(
      'stopwatch_sessions',
      {
        'status': 'paused',
        'paused_at': now.toIso8601String(),
        'elapsed_ms_at_pause': session.elapsedMsAtPause + elapsedSinceStart,
      },
      filters: {'id': 'eq.$sessionId'},
    );

    return getSessionById(sessionId);
  }

  Future<StopwatchSession?> stopSession(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return session;

    final now = DateTime.now();
    int finalElapsed = session.elapsedMsAtPause;

    if (session.isRunning && session.startedAt != null) {
      finalElapsed += now.difference(session.startedAt!).inMilliseconds;
    }

    await _db.client.update(
      'stopwatch_sessions',
      {
        'status': 'completed',
        'completed_at': now.toIso8601String(),
        'elapsed_ms_at_pause': finalElapsed,
      },
      filters: {'id': 'eq.$sessionId'},
    );

    return getSessionById(sessionId);
  }

  Future<StopwatchSession?> resetSession(String sessionId) async {
    await _db.client.update(
      'stopwatch_sessions',
      {
        'status': 'pending',
        'started_at': null,
        'paused_at': null,
        'completed_at': null,
        'elapsed_ms_at_pause': 0,
      },
      filters: {'id': 'eq.$sessionId'},
    );

    // Delete all times
    await _db.client.delete(
      'stopwatch_times',
      filters: {'session_id': 'eq.$sessionId'},
    );

    return getSessionById(sessionId);
  }

  Future<void> cancelSession(String sessionId) async {
    await _db.client.update(
      'stopwatch_sessions',
      {'status': 'cancelled'},
      filters: {'id': 'eq.$sessionId'},
    );
  }

  // ============ TIME RECORDING ============

  Future<StopwatchTime> recordTime({
    required String sessionId,
    required String userId,
    required int timeMs,
    bool isSplit = false,
    int? splitNumber,
    int? lapNumber,
    String? notes,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('stopwatch_times', {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'time_ms': timeMs,
      'is_split': isSplit,
      'split_number': splitNumber,
      'lap_number': lapNumber,
      'notes': notes,
    });

    return StopwatchTime(
      id: id,
      sessionId: sessionId,
      userId: userId,
      timeMs: timeMs,
      isSplit: isSplit,
      splitNumber: splitNumber,
      lapNumber: lapNumber,
      notes: notes,
      recordedAt: DateTime.now(),
    );
  }

  /// Record current elapsed time for a user
  Future<StopwatchTime?> recordCurrentTime({
    required String sessionId,
    required String userId,
    bool isSplit = false,
    int? splitNumber,
    String? notes,
  }) async {
    final session = await getSessionById(sessionId);
    if (session == null) return null;

    final timeMs = session.getCurrentElapsedMs();
    return recordTime(
      sessionId: sessionId,
      userId: userId,
      timeMs: timeMs,
      isSplit: isSplit,
      splitNumber: splitNumber,
      notes: notes,
    );
  }

  Future<List<StopwatchTime>> getTimesForSession(String sessionId) async {
    final result = await _db.client.select(
      'stopwatch_times',
      filters: {'session_id': 'eq.$sessionId'},
      order: 'time_ms.asc',
    );
    return result.map((row) => StopwatchTime.fromJson(row)).toList();
  }

  Future<List<StopwatchTime>> getTimesForUser({
    required String sessionId,
    required String userId,
  }) async {
    final result = await _db.client.select(
      'stopwatch_times',
      filters: {
        'session_id': 'eq.$sessionId',
        'user_id': 'eq.$userId',
      },
      order: 'recorded_at.asc',
    );
    return result.map((row) => StopwatchTime.fromJson(row)).toList();
  }

  Future<void> deleteTime(String timeId) async {
    await _db.client.delete(
      'stopwatch_times',
      filters: {'id': 'eq.$timeId'},
    );
  }

  Future<void> updateTime({
    required String timeId,
    int? timeMs,
    String? notes,
  }) async {
    final updates = <String, dynamic>{};
    if (timeMs != null) updates['time_ms'] = timeMs;
    if (notes != null) updates['notes'] = notes;

    if (updates.isNotEmpty) {
      await _db.client.update(
        'stopwatch_times',
        updates,
        filters: {'id': 'eq.$timeId'},
      );
    }
  }

  // ============ SESSION WITH TIMES ============

  Future<StopwatchSessionWithTimes?> getSessionWithTimes(String sessionId) async {
    final session = await getSessionById(sessionId);
    if (session == null) return null;

    final times = await getTimesForSession(sessionId);
    return StopwatchSessionWithTimes(session: session, times: times);
  }

  // ============ RANKINGS ============

  Future<List<Map<String, dynamic>>> getSessionRankings(String sessionId) async {
    // Get session details
    final session = await getSessionById(sessionId);
    if (session == null) return [];

    // Get all times (final times, not splits)
    final times = await _db.client.select(
      'stopwatch_times',
      filters: {
        'session_id': 'eq.$sessionId',
        'is_split': 'eq.false',
      },
      order: 'time_ms.asc',
    );

    // Get user info
    final userIds = times.map((t) => safeString(t, 'user_id')).toSet().toList();
    if (userIds.isEmpty) return [];

    final userMap = await _userService.getUserMap(userIds);

    // Build rankings
    final rankings = <Map<String, dynamic>>[];
    for (int i = 0; i < times.length; i++) {
      final time = times[i];
      final user = userMap[time['user_id']] ?? {};
      final stopwatchTime = StopwatchTime.fromJson(time);

      rankings.add({
        'rank': i + 1,
        'user_id': time['user_id'],
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
        'time_ms': time['time_ms'],
        'formatted_time': stopwatchTime.formattedTime,
        'notes': time['notes'],
        'recorded_at': time['recorded_at'],
      });
    }

    return rankings;
  }

  // ============ BULK OPERATIONS ============

  Future<void> recordMultipleTimes({
    required String sessionId,
    required List<Map<String, dynamic>> times,
  }) async {
    for (final t in times) {
      await recordTime(
        sessionId: sessionId,
        userId: safeString(t, 'user_id'),
        timeMs: safeInt(t, 'time_ms'),
        isSplit: safeBool(t, 'is_split', defaultValue: false),
        splitNumber: safeIntNullable(t, 'split_number'),
        notes: safeStringNullable(t, 'notes'),
      );
    }
  }
}
