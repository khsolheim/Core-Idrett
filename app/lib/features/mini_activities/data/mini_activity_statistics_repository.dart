import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/mini_activity_statistics.dart';

final miniActivityStatisticsRepositoryProvider = Provider<MiniActivityStatisticsRepository>((ref) {
  return MiniActivityStatisticsRepository(ref.watch(apiClientProvider));
});

class MiniActivityStatisticsRepository {
  final ApiClient _apiClient;

  MiniActivityStatisticsRepository(this._apiClient);

  // ============ PLAYER STATS ============

  Future<MiniActivityPlayerStats> getPlayerStats({
    required String teamId,
    required String userId,
    String? seasonId,
  }) async {
    final queryParams = <String, String>{};
    if (seasonId != null) queryParams['season_id'] = seasonId;

    final response = await _apiClient.get(
      '/mini-activity-stats/team/$teamId/user/$userId',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return MiniActivityPlayerStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MiniActivityPlayerStats>> getTeamLeaderboard({
    required String teamId,
    String? seasonId,
    int? limit,
    String sortBy = 'total_points',
  }) async {
    final queryParams = <String, String>{
      'sort_by': sortBy,
    };
    if (seasonId != null) queryParams['season_id'] = seasonId;
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get(
      '/mini-activity-stats/team/$teamId/leaderboard',
      queryParameters: queryParams,
    );
    final data = response.data as List;
    return data.map((json) => MiniActivityPlayerStats.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<PlayerStatsAggregate> getPlayerStatsAggregate({
    required String teamId,
    required String userId,
    String? seasonId,
  }) async {
    final queryParams = <String, String>{};
    if (seasonId != null) queryParams['season_id'] = seasonId;

    final response = await _apiClient.get(
      '/mini-activity-stats/team/$teamId/user/$userId/aggregate',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return PlayerStatsAggregate.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ HEAD TO HEAD ============

  Future<HeadToHeadStats> getHeadToHead({
    required String teamId,
    required String user1Id,
    required String user2Id,
  }) async {
    final response = await _apiClient.get('/mini-activity-stats/team/$teamId/head-to-head', queryParameters: {
      'user1_id': user1Id,
      'user2_id': user2Id,
    });
    return HeadToHeadStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<HeadToHeadStats>> getHeadToHeadRecords({
    required String teamId,
    required String userId,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get(
      '/mini-activity-stats/team/$teamId/user/$userId/head-to-head',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data as List;
    return data.map((json) => HeadToHeadStats.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<HeadToHeadStats>> getTopRivalries({
    required String teamId,
    int limit = 10,
  }) async {
    final response = await _apiClient.get('/mini-activity-stats/team/$teamId/rivalries', queryParameters: {
      'limit': limit.toString(),
    });
    final data = response.data as List;
    return data.map((json) => HeadToHeadStats.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ============ TEAM HISTORY ============

  Future<List<MiniActivityTeamHistory>> getUserHistory({
    required String teamId,
    required String userId,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get(
      '/mini-activity-stats/team/$teamId/user/$userId/history',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data as List;
    return data.map((json) => MiniActivityTeamHistory.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<MiniActivityTeamHistory>> getMiniActivityHistory(String miniActivityId) async {
    final response = await _apiClient.get('/mini-activity-stats/mini-activity/$miniActivityId/history');
    final data = response.data as List;
    return data.map((json) => MiniActivityTeamHistory.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ============ POINT SOURCES ============

  Future<List<LeaderboardPointSource>> getPointSources({
    required String leaderboardEntryId,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get(
      '/mini-activity-stats/entry/$leaderboardEntryId/sources',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data as List;
    return data.map((json) => LeaderboardPointSource.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<LeaderboardPointSource>> getUserPointSources({
    required String teamId,
    required String userId,
    String? seasonId,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (seasonId != null) queryParams['season_id'] = seasonId;
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _apiClient.get(
      '/mini-activity-stats/team/$teamId/user/$userId/sources',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data as List;
    return data.map((json) => LeaderboardPointSource.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ============ TEAM STATS ============

  Future<TeamMiniActivityStats> getTeamStats({
    required String teamId,
    String? seasonId,
  }) async {
    final queryParams = <String, String>{};
    if (seasonId != null) queryParams['season_id'] = seasonId;

    final response = await _apiClient.get(
      '/mini-activity-stats/team/$teamId/summary',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    return TeamMiniActivityStats.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ REFRESH / RECALCULATE ============

  Future<void> recalculateStats({
    required String teamId,
    String? userId,
    String? miniActivityId,
  }) async {
    await _apiClient.post('/mini-activity-stats/team/$teamId/recalculate', data: {
      'user_id': ?userId,
      'mini_activity_id': ?miniActivityId,
    });
  }
}
