import '../../../core/utils/api_response_parser.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/achievement.dart';

class AchievementRepository {
  final ApiClient _client;

  AchievementRepository(this._client);

  // ============ ACHIEVEMENT DEFINITIONS ============

  Future<List<AchievementDefinition>> getDefinitions(
    String teamId, {
    bool includeGlobal = true,
    bool activeOnly = true,
    AchievementCategory? category,
  }) async {
    final params = <String, String>{
      'include_global': includeGlobal.toString(),
      'active_only': activeOnly.toString(),
    };
    if (category != null) params['category'] = category.name;

    final response = await _client.get(
      '/achievements/teams/$teamId/definitions',
      queryParameters: params,
    );
    return parseList(response.data, 'definitions', AchievementDefinition.fromJson);
  }

  Future<AchievementDefinition?> getDefinitionById(String definitionId) async {
    try {
      final response =
          await _client.get('/achievements/definitions/$definitionId');
      return AchievementDefinition.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<AchievementDefinition> createDefinition({
    required String teamId,
    required String code,
    required String name,
    String? description,
    String? icon,
    String? color,
    AchievementTier tier = AchievementTier.bronze,
    required AchievementCategory category,
    required AchievementCriteria criteria,
    int bonusPoints = 0,
    bool isActive = true,
    bool isSecret = false,
    bool isRepeatable = false,
    int? repeatCooldownDays,
  }) async {
    final response = await _client.post(
      '/achievements/teams/$teamId/definitions',
      data: {
        'code': code,
        'name': name,
        'description': ?description,
        'icon': ?icon,
        'color': ?color,
        'tier': tier.name,
        'category': category.name,
        'criteria': criteria.toJson(),
        'bonus_points': bonusPoints,
        'is_active': isActive,
        'is_secret': isSecret,
        'is_repeatable': isRepeatable,
        'repeat_cooldown_days': ?repeatCooldownDays,
      },
    );
    return AchievementDefinition.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<AchievementDefinition?> updateDefinition({
    required String definitionId,
    String? name,
    String? description,
    String? icon,
    String? color,
    AchievementTier? tier,
    AchievementCriteria? criteria,
    int? bonusPoints,
    bool? isActive,
    bool? isSecret,
    bool? isRepeatable,
    int? repeatCooldownDays,
    bool clearDescription = false,
  }) async {
    final response = await _client.patch(
      '/achievements/definitions/$definitionId',
      data: {
        'name': ?name,
        if (description != null || clearDescription) 'description': description,
        if (clearDescription) 'clear_description': true,
        'icon': ?icon,
        'color': ?color,
        if (tier != null) 'tier': tier.name,
        if (criteria != null) 'criteria': criteria.toJson(),
        'bonus_points': ?bonusPoints,
        'is_active': ?isActive,
        'is_secret': ?isSecret,
        'is_repeatable': ?isRepeatable,
        'repeat_cooldown_days': ?repeatCooldownDays,
      },
    );
    return AchievementDefinition.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<void> deleteDefinition(String definitionId) async {
    await _client.delete('/achievements/definitions/$definitionId');
  }

  // ============ USER ACHIEVEMENTS ============

  Future<List<UserAchievement>> getUserAchievements(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (teamId != null) params['team_id'] = teamId;
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/achievements/users/$userId',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'achievements', UserAchievement.fromJson);
  }

  Future<List<AchievementProgress>> getUserProgress(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (teamId != null) params['team_id'] = teamId;
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/achievements/users/$userId/progress',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'progress', AchievementProgress.fromJson);
  }

  Future<UserAchievement> awardAchievement({
    required String teamId,
    required String userId,
    required String achievementId,
    String? seasonId,
    int? pointsAwarded,
    Map<String, dynamic>? triggerReference,
  }) async {
    final response = await _client.post(
      '/achievements/teams/$teamId/award',
      data: {
        'user_id': userId,
        'achievement_id': achievementId,
        'season_id': ?seasonId,
        'points_awarded': ?pointsAwarded,
        'trigger_reference': ?triggerReference,
      },
    );
    return UserAchievement.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<UserAchievement>> checkAndAwardAchievements(
    String teamId,
    String userId, {
    String? seasonId,
    Map<String, dynamic>? context,
  }) async {
    final requestData = <String, dynamic>{};
    if (context != null) requestData['context'] = context;
    if (seasonId != null) requestData['season_id'] = seasonId;

    final response = await _client.post(
      '/achievements/teams/$teamId/check/$userId',
      data: requestData,
    );
    return parseList(response.data, 'awarded', UserAchievement.fromJson);
  }

  // ============ ACHIEVEMENT SUMMARY ============

  Future<UserAchievementsSummary> getUserAchievementsSummary(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (teamId != null) params['team_id'] = teamId;
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/achievements/users/$userId/summary',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return UserAchievementsSummary.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ============ TEAM ACHIEVEMENTS OVERVIEW ============

  Future<List<UserAchievement>> getTeamRecentAchievements(
    String teamId, {
    int? limit,
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/achievements/teams/$teamId/recent',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'achievements', UserAchievement.fromJson);
  }

  Future<Map<String, int>> getTeamAchievementCounts(
    String teamId, {
    String? seasonId,
  }) async {
    final params = seasonId != null ? {'season_id': seasonId} : null;

    final response = await _client.get(
      '/achievements/teams/$teamId/counts',
      queryParameters: params,
    );
    final data = response.data['counts'] as Map<String, dynamic>;
    return data.map((key, value) => MapEntry(key, value as int));
  }
}
