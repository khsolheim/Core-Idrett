import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/stopwatch.dart';

final stopwatchRepositoryProvider = Provider<StopwatchRepository>((ref) {
  return StopwatchRepository(ref.watch(apiClientProvider));
});

class StopwatchRepository {
  final ApiClient _apiClient;

  StopwatchRepository(this._apiClient);

  // ============ SESSIONS ============

  Future<StopwatchSession> createSession({
    String? miniActivityId,
    String? teamId,
    required String name,
    StopwatchSessionType sessionType = StopwatchSessionType.stopwatch,
    int? countdownDurationMs,
  }) async {
    final response = await _apiClient.post('/stopwatch/sessions', data: {
      'mini_activity_id': ?miniActivityId,
      'team_id': ?teamId,
      'name': name,
      'session_type': sessionType.toJson(),
      'countdown_duration_ms': ?countdownDurationMs,
    });
    return StopwatchSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StopwatchSession> getSession(String sessionId) async {
    final response = await _apiClient.get('/stopwatch/sessions/$sessionId');
    return StopwatchSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StopwatchSessionWithTimes> getSessionWithTimes(String sessionId) async {
    final response = await _apiClient.get('/stopwatch/sessions/$sessionId', queryParameters: {
      'include_times': 'true',
    });
    return StopwatchSessionWithTimes.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<StopwatchSession>> getSessionsForMiniActivity(String miniActivityId) async {
    final response = await _apiClient.get('/stopwatch/mini-activity/$miniActivityId/sessions');
    final data = response.data as List;
    return data.map((json) => StopwatchSession.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<StopwatchSession>> getSessionsForTeam(String teamId, {int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get(
      '/stopwatch/team/$teamId/sessions',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data as List;
    return data.map((json) => StopwatchSession.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<StopwatchSession> updateSession({
    required String sessionId,
    String? name,
    StopwatchSessionType? sessionType,
    int? countdownDurationMs,
  }) async {
    final response = await _apiClient.patch('/stopwatch/sessions/$sessionId', data: {
      'name': ?name,
      if (sessionType != null) 'session_type': sessionType.toJson(),
      'countdown_duration_ms': ?countdownDurationMs,
    });
    return StopwatchSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSession(String sessionId) async {
    await _apiClient.delete('/stopwatch/sessions/$sessionId');
  }

  // ============ SESSION CONTROL ============

  Future<StopwatchSession> startSession(String sessionId) async {
    final response = await _apiClient.post('/stopwatch/sessions/$sessionId/start');
    return StopwatchSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StopwatchSession> pauseSession(String sessionId) async {
    final response = await _apiClient.post('/stopwatch/sessions/$sessionId/pause');
    return StopwatchSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StopwatchSession> resumeSession(String sessionId) async {
    final response = await _apiClient.post('/stopwatch/sessions/$sessionId/resume');
    return StopwatchSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StopwatchSession> completeSession(String sessionId) async {
    final response = await _apiClient.post('/stopwatch/sessions/$sessionId/complete');
    return StopwatchSession.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StopwatchSession> resetSession(String sessionId) async {
    final response = await _apiClient.post('/stopwatch/sessions/$sessionId/reset');
    return StopwatchSession.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ TIME RECORDING ============

  Future<StopwatchTime> recordTime({
    required String sessionId,
    required String userId,
    required int timeMs,
    bool isSplit = false,
    int? splitNumber,
  }) async {
    final response = await _apiClient.post('/stopwatch/sessions/$sessionId/times', data: {
      'user_id': userId,
      'time_ms': timeMs,
      'is_split': isSplit,
      'split_number': ?splitNumber,
    });
    return StopwatchTime.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<StopwatchTime>> getTimesForSession(String sessionId) async {
    final response = await _apiClient.get('/stopwatch/sessions/$sessionId/times');
    final data = response.data as List;
    return data.map((json) => StopwatchTime.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<StopwatchTime>> getTimesForUser({
    required String sessionId,
    required String userId,
  }) async {
    final response = await _apiClient.get('/stopwatch/sessions/$sessionId/times', queryParameters: {
      'user_id': userId,
    });
    final data = response.data as List;
    return data.map((json) => StopwatchTime.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<StopwatchTime> updateTime({
    required String timeId,
    int? timeMs,
  }) async {
    final response = await _apiClient.patch('/stopwatch/times/$timeId', data: {
      'time_ms': ?timeMs,
    });
    return StopwatchTime.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTime(String timeId) async {
    await _apiClient.delete('/stopwatch/times/$timeId');
  }

  Future<void> clearTimesForSession(String sessionId) async {
    await _apiClient.delete('/stopwatch/sessions/$sessionId/times');
  }

  // ============ LEADERBOARD ============

  Future<List<StopwatchTime>> getLeaderboard(String sessionId, {int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get(
      '/stopwatch/sessions/$sessionId/leaderboard',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data as List;
    return data.map((json) => StopwatchTime.fromJson(json as Map<String, dynamic>)).toList();
  }
}
