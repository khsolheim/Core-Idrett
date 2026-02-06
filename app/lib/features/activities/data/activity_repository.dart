import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/activity.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(apiClientProvider));
});

class ActivityRepository {
  final ApiClient _apiClient;

  ActivityRepository(this._apiClient);

  /// Helper to safely parse list responses from API
  List<dynamic> _parseListResponse(dynamic responseData) {
    if (responseData == null) {
      return [];
    }
    if (responseData is List) {
      return responseData;
    }
    if (responseData is String) {
      final decoded = jsonDecode(responseData);
      if (decoded is List) {
        return decoded;
      }
      if (decoded == null) {
        return [];
      }
      throw Exception('Unexpected response format: expected List, got ${decoded.runtimeType}');
    }
    throw Exception('Unexpected response format: expected List, got ${responseData.runtimeType}');
  }

  Future<List<Activity>> getActivitiesForTeam(String teamId) async {
    final response = await _apiClient.get('/activities/team/$teamId');
    final data = _parseListResponse(response.data);
    return data.map((json) => Activity.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<ActivityInstance>> getUpcomingInstances(String teamId, {int limit = 20}) async {
    final response = await _apiClient.get(
      '/activities/team/$teamId/upcoming',
      queryParameters: {'limit': limit.toString()},
    );
    final data = _parseListResponse(response.data);
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

  Future<List<ActivityInstance>> getInstancesByDateRange(
    String teamId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _apiClient.get(
      '/activities/team/$teamId/instances',
      queryParameters: {
        'from': from.toIso8601String().split('T').first,
        'to': to.toIso8601String().split('T').first,
      },
    );
    final data = _parseListResponse(response.data);
    return data.map((json) => ActivityInstance.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Edit an activity instance with the specified scope
  Future<InstanceOperationResult> editInstance({
    required String instanceId,
    required EditScope scope,
    String? title,
    String? location,
    String? description,
    String? startTime,
    String? endTime,
    DateTime? date,
  }) async {
    final data = <String, dynamic>{
      'edit_scope': scope.toApiString(),
    };

    if (title != null) data['title'] = title;
    if (location != null) data['location'] = location;
    if (description != null) data['description'] = description;
    if (startTime != null) data['start_time'] = startTime;
    if (endTime != null) data['end_time'] = endTime;
    if (date != null && scope == EditScope.single) {
      data['date'] = date.toIso8601String().split('T').first;
    }

    final response = await _apiClient.patch(
      '/activities/instances/$instanceId',
      data: data,
    );
    return InstanceOperationResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete an activity instance with the specified scope
  Future<InstanceOperationResult> deleteInstance({
    required String instanceId,
    required EditScope scope,
  }) async {
    final response = await _apiClient.delete(
      '/activities/instances/$instanceId',
      data: {
        'delete_scope': scope.toApiString(),
      },
    );
    return InstanceOperationResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Award attendance points to all users who responded 'yes' to a completed activity
  Future<AttendancePointsResult> awardAttendancePoints(String instanceId) async {
    final response = await _apiClient.post('/activities/instances/$instanceId/award-attendance');
    return AttendancePointsResult.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Result of awarding attendance points
class AttendancePointsResult {
  final bool success;
  final int pointsAwardedTo;
  final String message;

  AttendancePointsResult({
    required this.success,
    required this.pointsAwardedTo,
    required this.message,
  });

  factory AttendancePointsResult.fromJson(Map<String, dynamic> json) {
    return AttendancePointsResult(
      success: json['success'] as bool? ?? false,
      pointsAwardedTo: json['points_awarded_to'] as int? ?? 0,
      message: json['message'] as String? ?? '',
    );
  }
}
