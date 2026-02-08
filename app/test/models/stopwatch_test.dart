import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/stopwatch.dart';

void main() {
  group('StopwatchSession', () {
    test('roundtrip med alle felt populert', () {
      final times = [
        StopwatchTime(
          id: 'time-1',
          sessionId: 'session-1',
          userId: 'user-1',
          timeMs: 65432,
          isSplit: false,
          splitNumber: null,
          recordedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          userName: 'Ola Nordmann',
          userProfileImageUrl: 'https://example.com/avatars/ola.jpg',
        ),
      ];

      final original = StopwatchSession(
        id: 'session-1',
        miniActivityId: 'mini-act-1',
        teamId: 'team-1',
        name: '60 meter sprint',
        sessionType: StopwatchSessionType.stopwatch,
        countdownDurationMs: 60000,
        status: StopwatchSessionStatus.completed,
        startedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        completedAt: DateTime.parse('2024-01-15T10:15:00.000Z'),
        createdAt: DateTime.parse('2024-01-15T09:55:00.000Z'),
        createdBy: 'user-coach',
        times: times,
        creatorName: 'Kari Hansen',
      );

      final json = original.toJson();
      final decoded = StopwatchSession.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = StopwatchSession(
        id: 'session-2',
        name: 'Stafett',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        createdBy: 'user-coach',
      );

      final json = original.toJson();
      final decoded = StopwatchSession.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('StopwatchTime', () {
    test('roundtrip med alle felt populert', () {
      final original = StopwatchTime(
        id: 'time-1',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 65432,
        isSplit: true,
        splitNumber: 2,
        recordedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        userName: 'Ola Nordmann',
        userProfileImageUrl: 'https://example.com/avatars/ola.jpg',
      );

      final json = original.toJson();
      final decoded = StopwatchTime.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = StopwatchTime(
        id: 'time-2',
        sessionId: 'session-1',
        userId: 'user-2',
        timeMs: 72150,
        recordedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      final json = original.toJson();
      final decoded = StopwatchTime.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('StopwatchSessionWithTimes', () {
    test('roundtrip med alle felt populert', () {
      final session = StopwatchSession(
        id: 'session-1',
        name: '60 meter sprint',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        createdBy: 'user-coach',
        status: StopwatchSessionStatus.completed,
      );

      final times = [
        StopwatchTime(
          id: 'time-1',
          sessionId: 'session-1',
          userId: 'user-1',
          timeMs: 65432,
          recordedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          userName: 'Ola Nordmann',
        ),
        StopwatchTime(
          id: 'time-2',
          sessionId: 'session-1',
          userId: 'user-2',
          timeMs: 72150,
          recordedAt: DateTime.parse('2024-01-15T10:31:00.000Z'),
          userName: 'Kari Hansen',
        ),
      ];

      final fastestTime = times[0];
      final slowestTime = times[1];
      final averageTimeMs = (65432 + 72150) / 2;

      final original = StopwatchSessionWithTimes(
        session: session,
        times: times,
        fastestTime: fastestTime,
        slowestTime: slowestTime,
        averageTimeMs: averageTimeMs,
      );

      final json = original.toJson();
      final decoded = StopwatchSessionWithTimes.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final session = StopwatchSession(
        id: 'session-2',
        name: 'Nedtelling',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        createdBy: 'user-coach',
      );

      final original = StopwatchSessionWithTimes(
        session: session,
        times: [],
      );

      final json = original.toJson();
      final decoded = StopwatchSessionWithTimes.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
