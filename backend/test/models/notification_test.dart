import 'package:test/test.dart';
import 'package:core_idrett_backend/models/notification.dart';

void main() {
  group('DeviceToken', () {
    test('roundtrip med alle felt populert', () {
      final original = DeviceToken(
        id: 'token-1',
        userId: 'user-1',
        token: 'ExponentPushToken[xxxxxxxxxxxxxxxxxxxxxx]',
        platform: 'ios',
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        lastUsedAt: DateTime.parse('2024-03-15T14:30:00.000Z'),
      );

      final json = original.toJson();
      final decoded = DeviceToken.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med android platform', () {
      final original = DeviceToken(
        id: 'token-2',
        userId: 'user-2',
        token: 'ExponentPushToken[yyyyyyyyyyyyyyyyyyyyyy]',
        platform: 'android',
        createdAt: DateTime.parse('2024-02-15T12:00:00.000Z'),
        lastUsedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = DeviceToken.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('NotificationPreferences', () {
    test('roundtrip med alle felt populert', () {
      final original = NotificationPreferences(
        id: 'pref-1',
        userId: 'user-1',
        teamId: 'team-1',
        newActivity: true,
        activityReminder: true,
        activityCancelled: true,
        activityUpdated: false,
        newFine: true,
        fineDecision: true,
        teamMessage: false,
      );

      final json = original.toJson();
      final decoded = NotificationPreferences.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = NotificationPreferences(
        id: 'pref-2',
        userId: 'user-2',
        // teamId is null (global preferences)
        newActivity: false,
        activityReminder: false,
        activityCancelled: false,
        activityUpdated: false,
        newFine: false,
        fineDecision: false,
        teamMessage: false,
      );

      final json = original.toJson();
      final decoded = NotificationPreferences.fromJson(json);

      expect(decoded, equals(original));
    });

    test('copyWith oppdaterer kun spesifiserte felt', () {
      final original = NotificationPreferences(
        id: 'pref-3',
        userId: 'user-3',
        teamId: 'team-1',
        newActivity: true,
        activityReminder: true,
        activityCancelled: true,
        activityUpdated: true,
        newFine: true,
        fineDecision: true,
        teamMessage: true,
      );

      final updated = original.copyWith(
        newActivity: false,
        teamMessage: false,
      );

      expect(updated.id, equals(original.id));
      expect(updated.userId, equals(original.userId));
      expect(updated.teamId, equals(original.teamId));
      expect(updated.newActivity, isFalse);
      expect(updated.activityReminder, isTrue);
      expect(updated.activityCancelled, isTrue);
      expect(updated.activityUpdated, isTrue);
      expect(updated.newFine, isTrue);
      expect(updated.fineDecision, isTrue);
      expect(updated.teamMessage, isFalse);
    });
  });

  group('NotificationType', () {
    test('prefKey returnerer korrekt string', () {
      expect(NotificationType.newActivity.prefKey, equals('new_activity'));
      expect(NotificationType.activityReminder.prefKey, equals('activity_reminder'));
      expect(NotificationType.activityCancelled.prefKey, equals('activity_cancelled'));
      expect(NotificationType.activityUpdated.prefKey, equals('activity_updated'));
      expect(NotificationType.newFine.prefKey, equals('new_fine'));
      expect(NotificationType.fineDecision.prefKey, equals('fine_decision'));
      expect(NotificationType.teamMessage.prefKey, equals('team_message'));
    });
  });
}
