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
}
