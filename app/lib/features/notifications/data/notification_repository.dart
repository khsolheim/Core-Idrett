import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

class NotificationRepository {
  final ApiClient _client;

  NotificationRepository(this._client);

  Future<DeviceToken> registerToken({
    required String token,
    required String platform,
  }) async {
    final response = await _client.post('/notifications/tokens', data: {
      'token': token,
      'platform': platform,
    });
    return DeviceToken.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeToken(String token) async {
    // Use POST to /tokens/remove since DELETE doesn't support body
    await _client.post('/notifications/tokens/remove', data: {
      'token': token,
    });
  }

  Future<NotificationPreferences> getPreferences({String? teamId}) async {
    final queryParams = teamId != null ? {'team_id': teamId} : null;
    final response = await _client.get(
      '/notifications/preferences',
      queryParameters: queryParams,
    );
    return NotificationPreferences.fromJson(response.data as Map<String, dynamic>);
  }

  Future<NotificationPreferences> updatePreferences({
    String? teamId,
    bool? newActivity,
    bool? activityReminder,
    bool? activityCancelled,
    bool? newFine,
    bool? fineDecision,
    bool? teamMessage,
  }) async {
    final response = await _client.put('/notifications/preferences', data: {
      'team_id': ?teamId,
      'new_activity': ?newActivity,
      'activity_reminder': ?activityReminder,
      'activity_cancelled': ?activityCancelled,
      'new_fine': ?newFine,
      'fine_decision': ?fineDecision,
      'team_message': ?teamMessage,
    });
    return NotificationPreferences.fromJson(response.data as Map<String, dynamic>);
  }
}
