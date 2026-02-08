import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/notification.dart';

void main() {
  group('NotificationPreferences', () {
    test('roundtrip med alle felt populert', () {
      final original = NotificationPreferences(
        id: 'pref-1',
        userId: 'user-1',
        teamId: 'team-1',
        newActivity: true,
        activityReminder: true,
        activityCancelled: true,
        newFine: true,
        fineDecision: true,
        teamMessage: true,
      );

      final json = original.toJson();
      final decoded = NotificationPreferences.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = NotificationPreferences(
        id: 'pref-2',
        userId: 'user-2',
        newActivity: false,
        activityReminder: false,
        activityCancelled: false,
        newFine: false,
        fineDecision: false,
        teamMessage: false,
      );

      final json = original.toJson();
      final decoded = NotificationPreferences.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('DeviceToken', () {
    test('roundtrip med alle felt populert', () {
      final original = DeviceToken(
        id: 'token-1',
        userId: 'user-1',
        token: 'fcm-token-abc123',
        platform: 'ios',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        lastUsedAt: DateTime.parse('2024-01-15T15:00:00.000Z'),
      );

      final jsonMap = {
        'id': original.id,
        'user_id': original.userId,
        'token': original.token,
        'platform': original.platform,
        'created_at': original.createdAt.toIso8601String(),
        'last_used_at': original.lastUsedAt.toIso8601String(),
      };
      final decoded = DeviceToken.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // DeviceToken har ingen valgfrie felt
      final original = DeviceToken(
        id: 'token-2',
        userId: 'user-2',
        token: 'fcm-token-xyz789',
        platform: 'android',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        lastUsedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final jsonMap = {
        'id': original.id,
        'user_id': original.userId,
        'token': original.token,
        'platform': original.platform,
        'created_at': original.createdAt.toIso8601String(),
        'last_used_at': original.lastUsedAt.toIso8601String(),
      };
      final decoded = DeviceToken.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });
}
