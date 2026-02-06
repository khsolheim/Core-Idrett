import '../../../core/utils/api_response_parser.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/points_config.dart';

class PointsRepository {
  final ApiClient _client;

  PointsRepository(this._client);

  // ============ POINTS CONFIG ============

  Future<TeamPointsConfig> getConfig(String teamId, {String? seasonId}) async {
    final params = seasonId != null ? {'season_id': seasonId} : null;
    final response = await _client.get(
      '/points/teams/$teamId/config',
      queryParameters: params,
    );
    return TeamPointsConfig.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeamPointsConfig> createOrUpdateConfig({
    required String teamId,
    String? seasonId,
    int? trainingPoints,
    int? matchPoints,
    int? socialPoints,
    double? trainingWeight,
    double? matchWeight,
    double? socialWeight,
    double? competitionWeight,
    String? miniActivityDistribution,
    bool? autoAwardAttendance,
    String? visibility,
    bool? allowOptOut,
    bool? requireAbsenceReason,
    bool? requireAbsenceApproval,
    bool? excludeValidAbsenceFromPercentage,
    String? newPlayerStartMode,
  }) async {
    final response = await _client.post(
      '/points/teams/$teamId/config',
      data: {
        'season_id': ?seasonId,
        'training_points': ?trainingPoints,
        'match_points': ?matchPoints,
        'social_points': ?socialPoints,
        'training_weight': ?trainingWeight,
        'match_weight': ?matchWeight,
        'social_weight': ?socialWeight,
        'competition_weight': ?competitionWeight,
        'mini_activity_distribution': ?miniActivityDistribution,
        'auto_award_attendance': ?autoAwardAttendance,
        'visibility': ?visibility,
        'allow_opt_out': ?allowOptOut,
        'require_absence_reason': ?requireAbsenceReason,
        'require_absence_approval': ?requireAbsenceApproval,
        'exclude_valid_absence_from_percentage':
              ?excludeValidAbsenceFromPercentage,
        'new_player_start_mode': ?newPlayerStartMode,
      },
    );
    return TeamPointsConfig.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeamPointsConfig?> updateConfig({
    required String configId,
    int? trainingPoints,
    int? matchPoints,
    int? socialPoints,
    double? trainingWeight,
    double? matchWeight,
    double? socialWeight,
    double? competitionWeight,
    String? miniActivityDistribution,
    bool? autoAwardAttendance,
    String? visibility,
    bool? allowOptOut,
    bool? requireAbsenceReason,
    bool? requireAbsenceApproval,
    bool? excludeValidAbsenceFromPercentage,
    String? newPlayerStartMode,
  }) async {
    final response = await _client.patch(
      '/points/config/$configId',
      data: {
        'training_points': ?trainingPoints,
        'match_points': ?matchPoints,
        'social_points': ?socialPoints,
        'training_weight': ?trainingWeight,
        'match_weight': ?matchWeight,
        'social_weight': ?socialWeight,
        'competition_weight': ?competitionWeight,
        'mini_activity_distribution': ?miniActivityDistribution,
        'auto_award_attendance': ?autoAwardAttendance,
        'visibility': ?visibility,
        'allow_opt_out': ?allowOptOut,
        'require_absence_reason': ?requireAbsenceReason,
        'require_absence_approval': ?requireAbsenceApproval,
        'exclude_valid_absence_from_percentage':
              ?excludeValidAbsenceFromPercentage,
        'new_player_start_mode': ?newPlayerStartMode,
      },
    );
    return TeamPointsConfig.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteConfig(String configId) async {
    await _client.delete('/points/config/$configId');
  }

  // ============ ATTENDANCE POINTS ============

  Future<UserAttendanceStats> getTeamAttendanceStats(
    String teamId, {
    String? userId,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (userId != null) params['user_id'] = userId;
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/points/teams/$teamId/attendance',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return UserAttendanceStats.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AttendancePoints>> getUserAttendancePoints(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (teamId != null) params['team_id'] = teamId;
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/points/users/$userId/attendance',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'points', AttendancePoints.fromJson);
  }

  Future<AttendancePoints> awardAttendancePoints({
    required String teamId,
    required String instanceId,
    required String userId,
    required String activityType,
    String? seasonId,
    required int basePoints,
    required double weightedPoints,
  }) async {
    final response = await _client.post(
      '/points/teams/$teamId/award/$instanceId',
      data: {
        'user_id': userId,
        'activity_type': activityType,
        'season_id': seasonId,
        'base_points': basePoints,
        'weighted_points': weightedPoints,
      },
    );
    return AttendancePoints.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ OPT-OUT ============

  Future<void> setOptOut(
    String teamId,
    String userId,
    bool optOut,
  ) async {
    await _client.post(
      '/points/teams/$teamId/opt-out',
      data: {
        'user_id': userId,
        'opt_out': optOut,
      },
    );
  }

  Future<bool> getOptOut(String teamId, String userId) async {
    final response = await _client.get('/points/teams/$teamId/opt-out/$userId');
    return response.data['opt_out'] as bool;
  }

  // ============ CATEGORY LEADERBOARDS ============

  Future<List<RankedLeaderboardEntry>> getRankedLeaderboard(
    String teamId, {
    LeaderboardCategory? category,
    String? seasonId,
    int? limit,
    int offset = 0,
    bool includeOptedOut = false,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category.name;
    if (seasonId != null) params['season_id'] = seasonId;
    if (limit != null) params['limit'] = limit.toString();
    if (offset > 0) params['offset'] = offset.toString();
    params['include_opted_out'] = includeOptedOut.toString();

    final response = await _client.get(
      '/leaderboards/teams/$teamId/ranked',
      queryParameters: params,
    );
    return parseList(response.data, 'entries', RankedLeaderboardEntry.fromJson);
  }

  Future<RankedLeaderboardEntry?> getUserRankedPosition(
    String teamId,
    String userId, {
    LeaderboardCategory? category,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category.name;
    if (seasonId != null) params['season_id'] = seasonId;

    try {
      final response = await _client.get(
        '/leaderboards/teams/$teamId/users/$userId/position',
        queryParameters: params.isNotEmpty ? params : null,
      );
      return RankedLeaderboardEntry.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<List<RankedLeaderboardEntry>> getLeaderboardWithTrends(
    String teamId, {
    LeaderboardCategory? category,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category.name;
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/leaderboards/teams/$teamId/trends',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'entries', RankedLeaderboardEntry.fromJson);
  }

  // ============ MONTHLY STATS ============

  Future<List<MonthlyUserStats>> getMonthlyStats(
    String teamId,
    String userId, {
    int? year,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (year != null) params['year'] = year.toString();
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/leaderboards/teams/$teamId/users/$userId/monthly',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'monthly_stats', MonthlyUserStats.fromJson);
  }

  // ============ MANUAL ADJUSTMENTS ============

  Future<ManualPointAdjustment> createAdjustment({
    required String teamId,
    required String userId,
    required int points,
    required AdjustmentType adjustmentType,
    required String reason,
    String? seasonId,
  }) async {
    final response = await _client.post(
      '/points/teams/$teamId/adjust',
      data: {
        'user_id': userId,
        'points': points,
        'adjustment_type': adjustmentType.toJsonString(),
        'reason': reason,
        'season_id': ?seasonId,
      },
    );
    return ManualPointAdjustment.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ManualPointAdjustment>> getTeamAdjustments(
    String teamId, {
    String? seasonId,
    int? limit,
  }) async {
    final params = <String, String>{};
    if (seasonId != null) params['season_id'] = seasonId;
    if (limit != null) params['limit'] = limit.toString();

    final response = await _client.get(
      '/points/teams/$teamId/adjustments',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'adjustments', ManualPointAdjustment.fromJson);
  }

  Future<List<ManualPointAdjustment>> getUserAdjustments(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (teamId != null) params['team_id'] = teamId;
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/points/users/$userId/adjustments',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'adjustments', ManualPointAdjustment.fromJson);
  }
}
