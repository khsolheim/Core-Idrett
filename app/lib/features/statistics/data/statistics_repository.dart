import '../../../core/utils/api_response_parser.dart';
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
    return parseList(response.data, 'leaderboard', LeaderboardEntry.fromJson);
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
    return parseList(response.data, 'attendance', AttendanceRecord.fromJson);
  }

  Future<PlayerStatistics> getPlayerStatistics(String teamId, String userId) async {
    final response = await _client.get('/statistics/teams/$teamId/users/$userId/statistics');
    return PlayerStatistics.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MatchStats>> getMatchStats(String instanceId) async {
    final response = await _client.get('/statistics/instances/$instanceId/match-stats');
    return parseList(response.data, 'match_stats', MatchStats.fromJson);
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
    return parseList(response.data, 'seasons', Season.fromJson);
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
    return parseList(response.data, 'leaderboards', Leaderboard.fromJson);
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
    return parseList(response.data, 'entries', NewLeaderboardEntry.fromJson);
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
}
