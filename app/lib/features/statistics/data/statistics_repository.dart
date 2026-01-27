import '../../../data/api/api_client.dart';
import '../../../data/models/statistics.dart';

class StatisticsRepository {
  final ApiClient _client;

  StatisticsRepository(this._client);

  Future<List<LeaderboardEntry>> getLeaderboard(String teamId, {int? year}) async {
    final queryParams = year != null ? {'year': year.toString()} : null;
    final response = await _client.get(
      '/statistics/teams/$teamId/leaderboard',
      queryParameters: queryParams,
    );
    final data = response.data['leaderboard'] as List;
    return data.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<AttendanceRecord>> getTeamAttendance(
    String teamId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, String>{};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();

    final response = await _client.get(
      '/statistics/teams/$teamId/attendance',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final data = response.data['attendance'] as List;
    return data.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PlayerStatistics> getPlayerStatistics(String teamId, String userId) async {
    final response = await _client.get('/statistics/teams/$teamId/users/$userId/statistics');
    return PlayerStatistics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MatchStats>> getMatchStats(String instanceId) async {
    final response = await _client.get('/statistics/instances/$instanceId/match-stats');
    final data = response.data['match_stats'] as List;
    return data.map((e) => MatchStats.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MatchStats> recordMatchStats({
    required String instanceId,
    required String userId,
    int goals = 0,
    int assists = 0,
    int minutesPlayed = 0,
    int yellowCards = 0,
    int redCards = 0,
  }) async {
    final response = await _client.post(
      '/statistics/instances/$instanceId/match-stats',
      data: {
        'user_id': userId,
        'goals': goals,
        'assists': assists,
        'minutes_played': minutesPlayed,
        'yellow_cards': yellowCards,
        'red_cards': redCards,
      },
    );
    return MatchStats.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ SEASONS ============

  Future<List<Season>> getSeasons(String teamId) async {
    final response = await _client.get('/seasons/teams/$teamId');
    final data = response.data['seasons'] as List;
    return data.map((e) => Season.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Season?> getActiveSeason(String teamId) async {
    try {
      final response = await _client.get('/seasons/teams/$teamId/active');
      return Season.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<Season> createSeason({
    required String teamId,
    required String name,
    DateTime? startDate,
    DateTime? endDate,
    bool setActive = false,
  }) async {
    final response = await _client.post(
      '/seasons/teams/$teamId',
      data: {
        'name': name,
        'start_date': startDate?.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'set_active': setActive,
      },
    );
    return Season.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Season> startNewSeason({
    required String teamId,
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _client.post(
      '/seasons/teams/$teamId/new',
      data: {
        'name': name,
        'start_date': startDate?.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
      },
    );
    return Season.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> activateSeason(String seasonId) async {
    await _client.post('/seasons/$seasonId/activate', data: {});
  }

  // ============ MULTIPLE LEADERBOARDS ============

  Future<List<Leaderboard>> getLeaderboards(String teamId, {String? seasonId}) async {
    final params = seasonId != null ? {'season_id': seasonId} : null;
    final response = await _client.get(
      '/leaderboards/teams/$teamId',
      queryParameters: params,
    );
    final data = response.data['leaderboards'] as List;
    return data.map((e) => Leaderboard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Leaderboard?> getMainLeaderboard(String teamId) async {
    try {
      final response = await _client.get('/leaderboards/teams/$teamId/main');
      return Leaderboard.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<NewLeaderboardEntry>> getLeaderboardEntries(
    String leaderboardId, {
    int? limit,
    int offset = 0,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (offset > 0) params['offset'] = offset.toString();

    final response = await _client.get(
      '/leaderboards/$leaderboardId/entries',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final data = response.data['entries'] as List;
    return data.map((e) => NewLeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Leaderboard> createLeaderboard({
    required String teamId,
    String? seasonId,
    required String name,
    String? description,
    bool isMain = false,
  }) async {
    final response = await _client.post(
      '/leaderboards/teams/$teamId',
      data: {
        'name': name,
        'description': description,
        'season_id': seasonId,
        'is_main': isMain,
      },
    );
    return Leaderboard.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteLeaderboard(String leaderboardId) async {
    await _client.delete('/leaderboards/$leaderboardId');
  }

  // ============ TEST TEMPLATES ============

  Future<List<TestTemplate>> getTestTemplates(String teamId) async {
    final response = await _client.get('/tests/templates/teams/$teamId');
    final data = response.data['templates'] as List;
    return data.map((e) => TestTemplate.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TestTemplate> createTestTemplate({
    required String teamId,
    required String name,
    String? description,
    required String unit,
    bool higherIsBetter = false,
  }) async {
    final response = await _client.post(
      '/tests/templates/teams/$teamId',
      data: {
        'name': name,
        'description': description,
        'unit': unit,
        'higher_is_better': higherIsBetter,
      },
    );
    return TestTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTestTemplate(String templateId) async {
    await _client.delete('/tests/templates/$templateId');
  }

  Future<List<TestResult>> getTestResults(
    String templateId, {
    String? userId,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (userId != null) params['user_id'] = userId;
    if (limit != null) params['limit'] = limit.toString();

    final response = await _client.get(
      '/tests/templates/$templateId/results',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final data = response.data['results'] as List;
    return data.map((e) => TestResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getTestRanking(
    String templateId, {
    int? limit,
  }) async {
    final params = limit != null ? {'limit': limit.toString()} : null;
    final response = await _client.get(
      '/tests/templates/$templateId/ranking',
      queryParameters: params,
    );
    return (response.data['ranking'] as List).cast<Map<String, dynamic>>();
  }

  Future<TestResult> recordTestResult({
    required String templateId,
    required String userId,
    String? instanceId,
    required double value,
    String? notes,
  }) async {
    final response = await _client.post(
      '/tests/templates/$templateId/results',
      data: {
        'user_id': userId,
        'instance_id': instanceId,
        'value': value,
        'notes': notes,
      },
    );
    return TestResult.fromJson(response.data as Map<String, dynamic>);
  }
}
