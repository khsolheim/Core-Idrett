import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/notification.dart';

class NotificationService {
  final Database _db;
  final _uuid = const Uuid();

  NotificationService(this._db);

  // ============ DEVICE TOKENS ============

  Future<DeviceToken> registerToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    // Check if token already exists
    final existing = await _db.client.select(
      'device_tokens',
      filters: {
        'user_id': 'eq.$userId',
        'token': 'eq.$token',
      },
    );

    if (existing.isNotEmpty) {
      // Update last_used_at
      final result = await _db.client.update(
        'device_tokens',
        {'last_used_at': DateTime.now().toIso8601String()},
        filters: {'id': 'eq.${existing.first['id']}'},
      );
      return DeviceToken.fromRow(result.first);
    }

    // Insert new token
    final id = _uuid.v4();
    final result = await _db.client.insert('device_tokens', {
      'id': id,
      'user_id': userId,
      'token': token,
      'platform': platform,
    });

    return DeviceToken.fromRow(result.first);
  }

  Future<void> removeToken(String userId, String token) async {
    await _db.client.delete(
      'device_tokens',
      filters: {
        'user_id': 'eq.$userId',
        'token': 'eq.$token',
      },
    );
  }

  Future<List<DeviceToken>> getTokensForUser(String userId) async {
    final result = await _db.client.select(
      'device_tokens',
      filters: {'user_id': 'eq.$userId'},
    );
    return result.map((r) => DeviceToken.fromRow(r)).toList();
  }

  Future<List<DeviceToken>> getTokensForUsers(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    final result = await _db.client.select(
      'device_tokens',
      filters: {'user_id': 'in.(${userIds.join(',')})'},
    );
    return result.map((r) => DeviceToken.fromRow(r)).toList();
  }

  // ============ NOTIFICATION PREFERENCES ============

  Future<NotificationPreferences> getPreferences(
    String userId, {
    String? teamId,
  }) async {
    final filters = <String, String>{'user_id': 'eq.$userId'};
    if (teamId != null) {
      filters['team_id'] = 'eq.$teamId';
    } else {
      filters['team_id'] = 'is.null';
    }

    final result = await _db.client.select(
      'notification_preferences',
      filters: filters,
    );

    if (result.isNotEmpty) {
      return NotificationPreferences.fromRow(result.first);
    }

    // Create default preferences
    return await _createDefaultPreferences(userId, teamId: teamId);
  }

  Future<NotificationPreferences> _createDefaultPreferences(
    String userId, {
    String? teamId,
  }) async {
    final id = _uuid.v4();
    final result = await _db.client.insert('notification_preferences', {
      'id': id,
      'user_id': userId,
      'team_id': teamId,
      'new_activity': true,
      'activity_reminder': true,
      'activity_cancelled': true,
      'activity_updated': true,
      'new_fine': true,
      'fine_decision': true,
      'team_message': true,
    });

    return NotificationPreferences.fromRow(result.first);
  }

  Future<NotificationPreferences> updatePreferences({
    required String userId,
    String? teamId,
    bool? newActivity,
    bool? activityReminder,
    bool? activityCancelled,
    bool? activityUpdated,
    bool? newFine,
    bool? fineDecision,
    bool? teamMessage,
  }) async {
    // Get or create preferences first
    final prefs = await getPreferences(userId, teamId: teamId);

    final updates = <String, dynamic>{};
    if (newActivity != null) updates['new_activity'] = newActivity;
    if (activityReminder != null) updates['activity_reminder'] = activityReminder;
    if (activityCancelled != null) updates['activity_cancelled'] = activityCancelled;
    if (activityUpdated != null) updates['activity_updated'] = activityUpdated;
    if (newFine != null) updates['new_fine'] = newFine;
    if (fineDecision != null) updates['fine_decision'] = fineDecision;
    if (teamMessage != null) updates['team_message'] = teamMessage;

    if (updates.isEmpty) return prefs;

    final result = await _db.client.update(
      'notification_preferences',
      updates,
      filters: {'id': 'eq.${prefs.id}'},
    );

    return NotificationPreferences.fromRow(result.first);
  }

  // ============ SEND NOTIFICATIONS ============

  Future<List<String>> getUsersToNotify({
    required List<String> userIds,
    required NotificationType type,
    String? teamId,
  }) async {
    if (userIds.isEmpty) return [];

    // Get preferences for these users
    final filters = <String, String>{
      'user_id': 'in.(${userIds.join(',')})',
      type.prefKey: 'eq.true',
    };

    if (teamId != null) {
      // Get both team-specific and global preferences
      final teamPrefs = await _db.client.select(
        'notification_preferences',
        select: 'user_id',
        filters: {...filters, 'team_id': 'eq.$teamId'},
      );

      final globalPrefs = await _db.client.select(
        'notification_preferences',
        select: 'user_id',
        filters: {...filters, 'team_id': 'is.null'},
      );

      // Users with team-specific opt-out override global settings
      final teamOptedOut = await _db.client.select(
        'notification_preferences',
        select: 'user_id',
        filters: {
          'user_id': 'in.(${userIds.join(',')})',
          'team_id': 'eq.$teamId',
          type.prefKey: 'eq.false',
        },
      );

      final teamOptedOutIds =
          teamOptedOut.map((r) => r['user_id'] as String).toSet();

      // Combine preferences: team settings override global
      final enabledUsers = <String>{};
      for (final r in teamPrefs) {
        enabledUsers.add(r['user_id'] as String);
      }
      for (final r in globalPrefs) {
        final userId = r['user_id'] as String;
        if (!teamOptedOutIds.contains(userId)) {
          enabledUsers.add(userId);
        }
      }

      return enabledUsers.toList();
    } else {
      // Just check global preferences
      final result = await _db.client.select(
        'notification_preferences',
        select: 'user_id',
        filters: {...filters, 'team_id': 'is.null'},
      );
      return result.map((r) => r['user_id'] as String).toList();
    }
  }

  // ============ FCM PUSH NOTIFICATIONS ============

  /// FCM server key from environment
  String? get _fcmServerKey => Platform.environment['FCM_SERVER_KEY'];

  /// Send push notification to specific device tokens
  Future<FcmSendResult> sendPushNotification({
    required List<String> tokens,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, String>? data,
  }) async {
    if (_fcmServerKey == null || _fcmServerKey!.isEmpty) {
      return FcmSendResult(
        success: false,
        successCount: 0,
        failureCount: tokens.length,
        error: 'FCM_SERVER_KEY not configured',
      );
    }

    if (tokens.isEmpty) {
      return FcmSendResult(success: true, successCount: 0, failureCount: 0);
    }

    final payload = {
      'registration_ids': tokens,
      'notification': {
        'title': title,
        'body': body,
        'sound': 'default',
      },
      'data': {
        'type': type.name,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        ...?data,
      },
      'priority': 'high',
    };

    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_fcmServerKey',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return FcmSendResult(
          success: true,
          successCount: result['success'] as int? ?? 0,
          failureCount: result['failure'] as int? ?? 0,
        );
      } else {
        return FcmSendResult(
          success: false,
          successCount: 0,
          failureCount: tokens.length,
          error: 'FCM returned status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return FcmSendResult(
        success: false,
        successCount: 0,
        failureCount: tokens.length,
        error: 'Failed to send FCM: $e',
      );
    }
  }

  /// Send notification to users (fetches tokens and sends)
  Future<FcmSendResult> notifyUsers({
    required List<String> userIds,
    required String title,
    required String body,
    required NotificationType type,
    String? teamId,
    Map<String, String>? data,
  }) async {
    // Filter users based on their notification preferences
    final eligibleUserIds = await getUsersToNotify(
      userIds: userIds,
      type: type,
      teamId: teamId,
    );

    if (eligibleUserIds.isEmpty) {
      return FcmSendResult(success: true, successCount: 0, failureCount: 0);
    }

    // Get device tokens for eligible users
    final deviceTokens = await getTokensForUsers(eligibleUserIds);
    final tokens = deviceTokens.map((t) => t.token).toList();

    if (tokens.isEmpty) {
      return FcmSendResult(success: true, successCount: 0, failureCount: 0);
    }

    return sendPushNotification(
      tokens: tokens,
      title: title,
      body: body,
      type: type,
      data: data,
    );
  }

  /// Build notification payload (for debugging/logging)
  Map<String, dynamic> buildNotificationPayload({
    required String title,
    required String body,
    required NotificationType type,
    Map<String, String>? data,
  }) {
    return {
      'notification': {
        'title': title,
        'body': body,
      },
      'data': {
        'type': type.name,
        ...?data,
      },
    };
  }

  // ============ ACTIVITY NOTIFICATION HELPERS ============

  /// Notify team members about activity update (single instance)
  Future<FcmSendResult> notifyActivityUpdated({
    required List<String> userIds,
    required String teamId,
    required String activityTitle,
    required String date,
    String? time,
  }) async {
    final timeStr = time != null ? ' kl $time' : '';
    return notifyUsers(
      userIds: userIds,
      title: 'Aktivitet endret',
      body: '$activityTitle $date$timeStr er endret',
      type: NotificationType.activityUpdated,
      teamId: teamId,
      data: {
        'team_id': teamId,
      },
    );
  }

  /// Notify team members about bulk activity update
  Future<FcmSendResult> notifyActivitiesUpdated({
    required List<String> userIds,
    required String teamId,
    required String activityTitle,
    required int count,
    required String fromDate,
  }) async {
    return notifyUsers(
      userIds: userIds,
      title: 'Aktiviteter endret',
      body: '$count $activityTitle fra $fromDate er endret',
      type: NotificationType.activityUpdated,
      teamId: teamId,
      data: {
        'team_id': teamId,
      },
    );
  }

  /// Notify team members about activity deletion (single instance)
  Future<FcmSendResult> notifyActivityDeleted({
    required List<String> userIds,
    required String teamId,
    required String activityTitle,
    required String date,
  }) async {
    return notifyUsers(
      userIds: userIds,
      title: 'Aktivitet avlyst',
      body: '$activityTitle $date er avlyst',
      type: NotificationType.activityCancelled,
      teamId: teamId,
      data: {
        'team_id': teamId,
      },
    );
  }

  /// Notify team members about bulk activity deletion
  Future<FcmSendResult> notifyActivitiesDeleted({
    required List<String> userIds,
    required String teamId,
    required String activityTitle,
    required int count,
    required String fromDate,
  }) async {
    return notifyUsers(
      userIds: userIds,
      title: 'Aktiviteter avlyst',
      body: '$count $activityTitle fra $fromDate er avlyst',
      type: NotificationType.activityCancelled,
      teamId: teamId,
      data: {
        'team_id': teamId,
      },
    );
  }
}

/// Result of FCM send operation
class FcmSendResult {
  final bool success;
  final int successCount;
  final int failureCount;
  final String? error;

  FcmSendResult({
    required this.success,
    required this.successCount,
    required this.failureCount,
    this.error,
  });

  Map<String, dynamic> toJson() => {
    'success': success,
    'success_count': successCount,
    'failure_count': failureCount,
    if (error != null) 'error': error,
  };
}
