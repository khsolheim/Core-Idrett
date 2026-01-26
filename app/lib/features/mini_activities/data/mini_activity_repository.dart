import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/mini_activity.dart';

final miniActivityRepositoryProvider = Provider<MiniActivityRepository>((ref) {
  return MiniActivityRepository(ref.watch(apiClientProvider));
});

class MiniActivityRepository {
  final ApiClient _apiClient;

  MiniActivityRepository(this._apiClient);

  // ============ TEMPLATES ============

  Future<List<ActivityTemplate>> getTemplatesForTeam(String teamId) async {
    final response = await _apiClient.get('/mini-activities/templates/team/$teamId');
    final data = response.data as List;
    return data.map((json) => ActivityTemplate.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ActivityTemplate> createTemplate({
    required String teamId,
    required String name,
    required MiniActivityType type,
    int defaultPoints = 1,
  }) async {
    final response = await _apiClient.post('/mini-activities/templates/team/$teamId', data: {
      'name': name,
      'type': type.toApiString(),
      'default_points': defaultPoints,
    });
    return ActivityTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTemplate(String templateId) async {
    await _apiClient.delete('/mini-activities/templates/$templateId');
  }

  // ============ MINI-ACTIVITIES ============

  Future<List<MiniActivity>> getMiniActivitiesForInstance(String instanceId) async {
    final response = await _apiClient.get('/mini-activities/instance/$instanceId');
    final data = response.data as List;
    return data.map((json) => MiniActivity.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<MiniActivity> createMiniActivity({
    required String instanceId,
    String? templateId,
    required String name,
    required MiniActivityType type,
  }) async {
    final response = await _apiClient.post('/mini-activities/instance/$instanceId', data: {
      'template_id': templateId,
      'name': name,
      'type': type.toApiString(),
    });
    return MiniActivity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MiniActivity> getMiniActivityDetail(String miniActivityId) async {
    final response = await _apiClient.get('/mini-activities/$miniActivityId');
    return MiniActivity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteMiniActivity(String miniActivityId) async {
    await _apiClient.delete('/mini-activities/$miniActivityId');
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
    return MiniActivity.fromJson(response.data as Map<String, dynamic>);
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
    return MiniActivity.fromJson(response.data as Map<String, dynamic>);
  }
}
