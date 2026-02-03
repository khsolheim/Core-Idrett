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
        if (seasonId != null) 'season_id': seasonId,
        if (trainingPoints != null) 'training_points': trainingPoints,
        if (matchPoints != null) 'match_points': matchPoints,
        if (socialPoints != null) 'social_points': socialPoints,
        if (trainingWeight != null) 'training_weight': trainingWeight,
        if (matchWeight != null) 'match_weight': matchWeight,
        if (socialWeight != null) 'social_weight': socialWeight,
        if (competitionWeight != null) 'competition_weight': competitionWeight,
        if (miniActivityDistribution != null)
          'mini_activity_distribution': miniActivityDistribution,
        if (autoAwardAttendance != null)
          'auto_award_attendance': autoAwardAttendance,
        if (visibility != null) 'visibility': visibility,
        if (allowOptOut != null) 'allow_opt_out': allowOptOut,
        if (requireAbsenceReason != null)
          'require_absence_reason': requireAbsenceReason,
        if (requireAbsenceApproval != null)
          'require_absence_approval': requireAbsenceApproval,
        if (excludeValidAbsenceFromPercentage != null)
          'exclude_valid_absence_from_percentage':
              excludeValidAbsenceFromPercentage,
        if (newPlayerStartMode != null)
          'new_player_start_mode': newPlayerStartMode,
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
        if (trainingPoints != null) 'training_points': trainingPoints,
        if (matchPoints != null) 'match_points': matchPoints,
        if (socialPoints != null) 'social_points': socialPoints,
        if (trainingWeight != null) 'training_weight': trainingWeight,
        if (matchWeight != null) 'match_weight': matchWeight,
        if (socialWeight != null) 'social_weight': socialWeight,
        if (competitionWeight != null) 'competition_weight': competitionWeight,
        if (miniActivityDistribution != null)
          'mini_activity_distribution': miniActivityDistribution,
        if (autoAwardAttendance != null)
          'auto_award_attendance': autoAwardAttendance,
        if (visibility != null) 'visibility': visibility,
        if (allowOptOut != null) 'allow_opt_out': allowOptOut,
        if (requireAbsenceReason != null)
          'require_absence_reason': requireAbsenceReason,
        if (requireAbsenceApproval != null)
          'require_absence_approval': requireAbsenceApproval,
        if (excludeValidAbsenceFromPercentage != null)
          'exclude_valid_absence_from_percentage':
              excludeValidAbsenceFromPercentage,
        if (newPlayerStartMode != null)
          'new_player_start_mode': newPlayerStartMode,
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
    final data = response.data['points'] as List;
    return data
        .map((e) => AttendancePoints.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = response.data['entries'] as List;
    return data
        .map((e) => RankedLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = response.data['entries'] as List;
    return data
        .map((e) => RankedLeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = response.data['monthly_stats'] as List;
    return data
        .map((e) => MonthlyUserStats.fromJson(e as Map<String, dynamic>))
        .toList();
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
        if (seasonId != null) 'season_id': seasonId,
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
    final data = response.data['adjustments'] as List;
    return data
        .map((e) => ManualPointAdjustment.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = response.data['adjustments'] as List;
    return data
        .map((e) => ManualPointAdjustment.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
