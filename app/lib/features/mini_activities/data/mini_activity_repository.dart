import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/mini_activity.dart';

final miniActivityRepositoryProvider = Provider<MiniActivityRepository>((ref) {
  return MiniActivityRepository(ref.watch(apiClientProvider));
});

class MiniActivityRepository {
  final ApiClient _apiClient;

  MiniActivityRepository(this._apiClient);

  /// Helper to parse response data that might be String or Map
  Map<String, dynamic> _parseJsonResponse(dynamic data) {
    if (data is String) {
      return Map<String, dynamic>.from(const JsonDecoder().convert(data) as Map);
    } else if (data is Map<String, dynamic>) {
      return data;
    } else if (data is Map) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }
  }

  /// Helper to parse list response that might be String or List
  List<dynamic> _parseListResponse(dynamic data) {
    if (data is String) {
      return const JsonDecoder().convert(data) as List;
    } else if (data is List) {
      return data;
    } else {
      throw Exception('Unexpected response type: ${data.runtimeType}');
    }
  }

  // ============ TEMPLATES ============

  Future<List<ActivityTemplate>> getTemplatesForTeam(String teamId) async {
    final response = await _apiClient.get('/mini-activities/templates/team/$teamId');
    final data = _parseListResponse(response.data);
    return data.map((json) => ActivityTemplate.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ActivityTemplate> createTemplate({
    required String teamId,
    required String name,
    required MiniActivityType type,
    int defaultPoints = 1,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    int winPoints = 3,
    int drawPoints = 1,
    int lossPoints = 0,
    String? leaderboardId,
  }) async {
    final response = await _apiClient.post('/mini-activities/templates/team/$teamId', data: {
      'name': name,
      'type': type.toApiString(),
      'default_points': defaultPoints,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (sportType != null) 'sport_type': sportType,
      if (suggestedRules != null) 'suggested_rules': suggestedRules,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      if (leaderboardId != null) 'leaderboard_id': leaderboardId,
    });
    return ActivityTemplate.fromJson(_parseJsonResponse(response.data));
  }

  Future<ActivityTemplate> updateTemplate({
    required String templateId,
    String? name,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    bool? isFavorite,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
  }) async {
    final response = await _apiClient.patch('/mini-activities/templates/$templateId', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (instructions != null) 'instructions': instructions,
      if (sportType != null) 'sport_type': sportType,
      if (suggestedRules != null) 'suggested_rules': suggestedRules,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (winPoints != null) 'win_points': winPoints,
      if (drawPoints != null) 'draw_points': drawPoints,
      if (lossPoints != null) 'loss_points': lossPoints,
      if (leaderboardId != null) 'leaderboard_id': leaderboardId,
    });
    return ActivityTemplate.fromJson(_parseJsonResponse(response.data));
  }

  Future<ActivityTemplate> getTemplate(String templateId) async {
    final response = await _apiClient.get('/mini-activities/templates/$templateId');
    return ActivityTemplate.fromJson(_parseJsonResponse(response.data));
  }

  Future<void> deleteTemplate(String templateId) async {
    await _apiClient.delete('/mini-activities/templates/$templateId');
  }

  Future<ActivityTemplate> toggleTemplateFavorite(String templateId) async {
    final response = await _apiClient.post('/mini-activities/templates/$templateId/favorite');
    return ActivityTemplate.fromJson(_parseJsonResponse(response.data));
  }

  // ============ MINI-ACTIVITIES ============

  Future<List<MiniActivity>> getMiniActivitiesForInstance(String instanceId) async {
    final response = await _apiClient.get('/mini-activities/instance/$instanceId');
    final data = _parseListResponse(response.data);
    return data.map((json) => MiniActivity.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<MiniActivity>> getStandaloneForTeam(String teamId, {bool includeArchived = false}) async {
    final response = await _apiClient.get('/mini-activities/standalone/team/$teamId', queryParameters: {
      'include_archived': includeArchived.toString(),
    });
    final data = _parseListResponse(response.data);
    return data.map((json) => MiniActivity.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<MiniActivity> createMiniActivity({
    required String instanceId,
    String? templateId,
    required String name,
    required MiniActivityType type,
    String? description,
    int? maxParticipants,
    bool enableLeaderboard = true,
    int winPoints = 3,
    int drawPoints = 1,
    int lossPoints = 0,
    String? leaderboardId,
    bool handicapEnabled = false,
  }) async {
    final response = await _apiClient.post('/mini-activities/instance/$instanceId', data: {
      'template_id': templateId,
      'name': name,
      'type': type.toApiString(),
      if (description != null) 'description': description,
      if (maxParticipants != null) 'max_participants': maxParticipants,
      'enable_leaderboard': enableLeaderboard,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      if (leaderboardId != null) 'leaderboard_id': leaderboardId,
      'handicap_enabled': handicapEnabled,
    });
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<MiniActivity> createStandaloneMiniActivity({
    required String teamId,
    String? templateId,
    required String name,
    required MiniActivityType type,
    String? description,
    int? maxParticipants,
    bool enableLeaderboard = true,
    int winPoints = 3,
    int drawPoints = 1,
    int lossPoints = 0,
    String? leaderboardId,
    bool handicapEnabled = false,
  }) async {
    final response = await _apiClient.post('/mini-activities/standalone/team/$teamId', data: {
      'template_id': templateId,
      'name': name,
      'type': type.toApiString(),
      if (description != null) 'description': description,
      if (maxParticipants != null) 'max_participants': maxParticipants,
      'enable_leaderboard': enableLeaderboard,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      if (leaderboardId != null) 'leaderboard_id': leaderboardId,
      'handicap_enabled': handicapEnabled,
    });
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<MiniActivity> getMiniActivityDetail(String miniActivityId) async {
    final response = await _apiClient.get('/mini-activities/$miniActivityId');
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<MiniActivity> updateMiniActivity({
    required String miniActivityId,
    String? name,
    String? description,
    int? maxParticipants,
    bool? enableLeaderboard,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
    bool? handicapEnabled,
  }) async {
    final response = await _apiClient.patch('/mini-activities/$miniActivityId', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (maxParticipants != null) 'max_participants': maxParticipants,
      if (enableLeaderboard != null) 'enable_leaderboard': enableLeaderboard,
      if (winPoints != null) 'win_points': winPoints,
      if (drawPoints != null) 'draw_points': drawPoints,
      if (lossPoints != null) 'loss_points': lossPoints,
      if (leaderboardId != null) 'leaderboard_id': leaderboardId,
      if (handicapEnabled != null) 'handicap_enabled': handicapEnabled,
    });
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<void> deleteMiniActivity(String miniActivityId) async {
    await _apiClient.delete('/mini-activities/$miniActivityId');
  }

  Future<MiniActivity> archiveMiniActivity(String miniActivityId) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/archive');
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<MiniActivity> unarchiveMiniActivity(String miniActivityId) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/unarchive');
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<MiniActivity> duplicateMiniActivity(String miniActivityId, {String? newName}) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/duplicate', data: {
      if (newName != null) 'name': newName,
    });
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  // ============ TEAM DIVISION ============

  Future<MiniActivity> divideTeams({
    required String miniActivityId,
    required DivisionMethod method,
    required int numberOfTeams,
    required List<String> participantUserIds,
    String? teamId,
  }) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/divide-teams', data: {
      'method': method.toApiString(),
      'number_of_teams': numberOfTeams,
      'participant_user_ids': participantUserIds,
      'team_id': teamId,
    });
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<MiniActivity> resetTeamDivision(String miniActivityId) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/reset-division');
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<MiniActivity> addLateParticipant({
    required String miniActivityId,
    required String userId,
    required String miniTeamId,
  }) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/add-participant', data: {
      'user_id': userId,
      'mini_team_id': miniTeamId,
    });
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  Future<MiniActivity> updateTeamName({
    required String miniActivityId,
    required String miniTeamId,
    required String name,
  }) async {
    final response = await _apiClient.patch('/mini-activities/$miniActivityId/teams/$miniTeamId', data: {
      'name': name,
    });
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  // ============ SCORES ============

  Future<MiniActivity> recordScores({
    required String miniActivityId,
    Map<String, int>? teamScores,
    Map<String, int>? participantPoints,
  }) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/scores', data: {
      'team_scores': teamScores ?? {},
      'participant_points': participantPoints ?? {},
    });
    return MiniActivity.fromJson(_parseJsonResponse(response.data));
  }

  // ============ ADJUSTMENTS (BONUS/PENALTY) ============

  Future<List<MiniActivityAdjustment>> getAdjustments(String miniActivityId) async {
    final response = await _apiClient.get('/mini-activities/$miniActivityId/adjustments');
    final data = _parseListResponse(response.data);
    return data.map((json) => MiniActivityAdjustment.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<MiniActivityAdjustment> awardAdjustment({
    required String miniActivityId,
    String? miniTeamId,
    String? userId,
    required int points,
    String? reason,
  }) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/adjustments', data: {
      if (miniTeamId != null) 'team_id': miniTeamId,
      if (userId != null) 'user_id': userId,
      'points': points,
      if (reason != null) 'reason': reason,
    });
    return MiniActivityAdjustment.fromJson(_parseJsonResponse(response.data));
  }

  Future<void> deleteAdjustment(String adjustmentId) async {
    await _apiClient.delete('/mini-activities/adjustments/$adjustmentId');
  }

  // ============ HANDICAPS ============

  Future<List<MiniActivityHandicap>> getHandicaps(String miniActivityId) async {
    final response = await _apiClient.get('/mini-activities/$miniActivityId/handicaps');
    final data = _parseListResponse(response.data);
    return data.map((json) => MiniActivityHandicap.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<MiniActivityHandicap> setHandicap({
    required String miniActivityId,
    required String userId,
    required double handicapValue,
  }) async {
    final response = await _apiClient.post('/mini-activities/$miniActivityId/handicaps', data: {
      'user_id': userId,
      'handicap_value': handicapValue,
    });
    return MiniActivityHandicap.fromJson(_parseJsonResponse(response.data));
  }

  Future<void> removeHandicap({
    required String miniActivityId,
    required String userId,
  }) async {
    await _apiClient.delete('/mini-activities/$miniActivityId/handicaps/$userId');
  }
}
