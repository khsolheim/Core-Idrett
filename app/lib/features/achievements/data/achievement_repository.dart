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
    final data = response.data['definitions'] as List;
    return data
        .map((e) => AchievementDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
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
        if (description != null) 'description': description,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        'tier': tier.name,
        'category': category.name,
        'criteria': criteria.toJson(),
        'bonus_points': bonusPoints,
        'is_active': isActive,
        'is_secret': isSecret,
        'is_repeatable': isRepeatable,
        if (repeatCooldownDays != null)
          'repeat_cooldown_days': repeatCooldownDays,
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
        if (name != null) 'name': name,
        if (description != null || clearDescription) 'description': description,
        if (clearDescription) 'clear_description': true,
        if (icon != null) 'icon': icon,
        if (color != null) 'color': color,
        if (tier != null) 'tier': tier.name,
        if (criteria != null) 'criteria': criteria.toJson(),
        if (bonusPoints != null) 'bonus_points': bonusPoints,
        if (isActive != null) 'is_active': isActive,
        if (isSecret != null) 'is_secret': isSecret,
        if (isRepeatable != null) 'is_repeatable': isRepeatable,
        if (repeatCooldownDays != null)
          'repeat_cooldown_days': repeatCooldownDays,
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
    final data = response.data['achievements'] as List;
    return data
        .map((e) => UserAchievement.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = response.data['progress'] as List;
    return data
        .map((e) => AchievementProgress.fromJson(e as Map<String, dynamic>))
        .toList();
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
        if (seasonId != null) 'season_id': seasonId,
        if (pointsAwarded != null) 'points_awarded': pointsAwarded,
        if (triggerReference != null) 'trigger_reference': triggerReference,
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
    final data = response.data['awarded'] as List;
    return data
        .map((e) => UserAchievement.fromJson(e as Map<String, dynamic>))
        .toList();
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
    final data = response.data['achievements'] as List;
    return data
        .map((e) => UserAchievement.fromJson(e as Map<String, dynamic>))
        .toList();
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
