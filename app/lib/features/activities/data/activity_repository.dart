import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/activity.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(apiClientProvider));
});

class ActivityRepository {
  final ApiClient _apiClient;

  ActivityRepository(this._apiClient);

  Future<List<Activity>> getActivitiesForTeam(String teamId) async {
    final response = await _apiClient.get('/activities/team/$teamId');
    final data = response.data as List;
    return data.map((json) => Activity.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<ActivityInstance>> getUpcomingInstances(String teamId, {int limit = 20}) async {
    final response = await _apiClient.get(
      '/activities/team/$teamId/upcoming',
      queryParameters: {'limit': limit.toString()},
    );
    final data = response.data as List;
    return data.map((json) => ActivityInstance.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<ActivityInstance> getInstance(String instanceId) async {
    final response = await _apiClient.get('/activities/instances/$instanceId');
    return ActivityInstance.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Activity> createActivity({
    required String teamId,
    required String title,
    required ActivityType type,
    String? location,
    String? description,
    required RecurrenceType recurrenceType,
    DateTime? recurrenceEndDate,
    required ResponseType responseType,
    int? responseDeadlineHours,
    required DateTime firstDate,
    String? startTime,
    String? endTime,
  }) async {
    final response = await _apiClient.post('/activities/team/$teamId', data: {
      'title': title,
      'type': type.toApiString(),
      'location': location,
      'description': description,
      'recurrence_type': recurrenceType.toApiString(),
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'response_type': responseType.toApiString(),
      'response_deadline_hours': responseDeadlineHours,
      'first_date': firstDate.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
    });
    return Activity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> respond({
    required String instanceId,
    UserResponse? response,
    String? comment,
  }) async {
    await _apiClient.post('/activities/instances/$instanceId/respond', data: {
      'response': response?.toApiString(),
      'comment': comment,
    });
  }

  Future<void> updateInstanceStatus({
    required String instanceId,
    required InstanceStatus status,
    String? reason,
  }) async {
    await _apiClient.patch('/activities/instances/$instanceId/status', data: {
      'status': status.name,
      'reason': reason,
    });
  }

  Future<void> deleteActivity(String activityId) async {
    await _apiClient.delete('/activities/$activityId');
  }
}
