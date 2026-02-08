import 'package:test/test.dart';
import 'package:core_idrett_backend/models/stopwatch.dart';

void main() {
  group('StopwatchSessionType', () {
    test('value returnerer korrekt string', () {
      expect(StopwatchSessionType.stopwatch.value, equals('stopwatch'));
      expect(StopwatchSessionType.countdown.value, equals('countdown'));
    });

    test('fromString konverterer korrekt', () {
      expect(StopwatchSessionType.fromString('stopwatch'), equals(StopwatchSessionType.stopwatch));
      expect(StopwatchSessionType.fromString('countdown'), equals(StopwatchSessionType.countdown));
    });

    test('fromString kaster exception for ukjent verdi', () {
      expect(() => StopwatchSessionType.fromString('unknown'), throwsArgumentError);
    });

    test('displayName returnerer norske navn', () {
      expect(StopwatchSessionType.stopwatch.displayName, equals('Stoppeklokke'));
      expect(StopwatchSessionType.countdown.displayName, equals('Nedtelling'));
    });
  });

  group('StopwatchSessionStatus', () {
    test('value returnerer korrekt string', () {
      expect(StopwatchSessionStatus.pending.value, equals('pending'));
      expect(StopwatchSessionStatus.running.value, equals('running'));
      expect(StopwatchSessionStatus.paused.value, equals('paused'));
      expect(StopwatchSessionStatus.completed.value, equals('completed'));
      expect(StopwatchSessionStatus.cancelled.value, equals('cancelled'));
    });

    test('fromString konverterer korrekt', () {
      expect(StopwatchSessionStatus.fromString('pending'), equals(StopwatchSessionStatus.pending));
      expect(StopwatchSessionStatus.fromString('running'), equals(StopwatchSessionStatus.running));
      expect(StopwatchSessionStatus.fromString('paused'), equals(StopwatchSessionStatus.paused));
      expect(StopwatchSessionStatus.fromString('completed'), equals(StopwatchSessionStatus.completed));
      expect(StopwatchSessionStatus.fromString('cancelled'), equals(StopwatchSessionStatus.cancelled));
    });

    test('fromString kaster exception for ukjent verdi', () {
      expect(() => StopwatchSessionStatus.fromString('unknown'), throwsArgumentError);
    });
  });

  group('StopwatchSession', () {
    test('roundtrip med alle felt populert', () {
      final original = StopwatchSession(
        id: 'session-1',
        miniActivityId: 'mini-activity-1',
        teamId: 'team-1',
        name: '60m sprint',
        sessionType: StopwatchSessionType.stopwatch,
        countdownDurationMs: null,
        status: StopwatchSessionStatus.running,
        startedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        pausedAt: null,
        completedAt: null,
        elapsedMsAtPause: 0,
        createdAt: DateTime.parse('2024-03-15T09:55:00.000Z'),
        createdBy: 'user-1',
      );

      final json = original.toJson();
      // Fix DateTime: StopwatchSession.fromJson expects DateTime objects
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      if (json['started_at'] != null) {
        json['started_at'] = DateTime.parse(json['started_at'] as String);
      }
      final decoded = StopwatchSession.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med countdown type', () {
      final original = StopwatchSession(
        id: 'session-2',
        miniActivityId: 'mini-activity-2',
        teamId: 'team-1',
        name: '5 minutters utfordring',
        sessionType: StopwatchSessionType.countdown,
        countdownDurationMs: 300000, // 5 minutes
        status: StopwatchSessionStatus.pending,
        startedAt: null,
        pausedAt: null,
        completedAt: null,
        elapsedMsAtPause: 0,
        createdAt: DateTime.parse('2024-03-16T14:00:00.000Z'),
        createdBy: 'user-2',
      );

      final json = original.toJson();
      // Fix DateTime: StopwatchSession.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = StopwatchSession.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = StopwatchSession(
        id: 'session-3',
        // miniActivityId is null
        // teamId is null
        // name is null
        sessionType: StopwatchSessionType.stopwatch,
        // countdownDurationMs is null
        status: StopwatchSessionStatus.completed,
        // startedAt is null
        // pausedAt is null
        completedAt: DateTime.parse('2024-03-17T15:30:00.000Z'),
        elapsedMsAtPause: 5000,
        createdAt: DateTime.parse('2024-03-17T15:00:00.000Z'),
        createdBy: 'user-3',
      );

      final json = original.toJson();
      // Fix DateTime fields
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      if (json['completed_at'] != null) {
        json['completed_at'] = DateTime.parse(json['completed_at'] as String);
      }
      final decoded = StopwatchSession.fromJson(json);

      expect(decoded, equals(original));
    });

    test('status helpers fungerer korrekt', () {
      final running = StopwatchSession(
        id: 'session-4',
        sessionType: StopwatchSessionType.stopwatch,
        status: StopwatchSessionStatus.running,
        createdAt: DateTime.parse('2024-03-18T10:00:00.000Z'),
        createdBy: 'user-1',
      );

      expect(running.isRunning, isTrue);
      expect(running.isPaused, isFalse);
      expect(running.isCompleted, isFalse);
      expect(running.canStart, isFalse);
      expect(running.canResume, isFalse);

      final paused = StopwatchSession(
        id: 'session-5',
        sessionType: StopwatchSessionType.stopwatch,
        status: StopwatchSessionStatus.paused,
        createdAt: DateTime.parse('2024-03-18T11:00:00.000Z'),
        createdBy: 'user-1',
      );

      expect(paused.isPaused, isTrue);
      expect(paused.canResume, isTrue);
    });
  });

  group('StopwatchTime', () {
    test('roundtrip med alle felt populert', () {
      final original = StopwatchTime(
        id: 'time-1',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 8456,
        isSplit: true,
        splitNumber: 1,
        lapNumber: 1,
        notes: 'God tid!',
        recordedAt: DateTime.parse('2024-03-15T10:05:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: StopwatchTime.fromJson expects DateTime object
      json['recorded_at'] = DateTime.parse(json['recorded_at'] as String);
      final decoded = StopwatchTime.fromJson(json);

      expect(decoded, equals(original));
      expect(json['formatted_time'], isNotNull);
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = StopwatchTime(
        id: 'time-2',
        sessionId: 'session-2',
        userId: 'user-2',
        timeMs: 125340,
        isSplit: false,
        // splitNumber is null
        // lapNumber is null
        // notes is null
        recordedAt: DateTime.parse('2024-03-16T14:30:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: StopwatchTime.fromJson expects DateTime object
      json['recorded_at'] = DateTime.parse(json['recorded_at'] as String);
      final decoded = StopwatchTime.fromJson(json);

      expect(decoded, equals(original));
    });

    test('formattedTime formaterer korrekt', () {
      final time1 = StopwatchTime(
        id: 'time-3',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 8456, // 8.456 sekunder
        recordedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(time1.formattedTime, equals('00:08.456'));

      final time2 = StopwatchTime(
        id: 'time-4',
        sessionId: 'session-1',
        userId: 'user-2',
        timeMs: 3665789, // 1 time, 1 minutt, 5.789 sekunder
        recordedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(time2.formattedTime, equals('01:01:05.789'));
    });

    test('formattedTimeShort formaterer uten millisekunder', () {
      final time = StopwatchTime(
        id: 'time-5',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 125456, // 2 minutt, 5.456 sekunder
        recordedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(time.formattedTimeShort, equals('02:05'));
    });

    test('timeInSeconds konverterer til sekunder med desimaler', () {
      final time = StopwatchTime(
        id: 'time-6',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 8456,
        recordedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(time.timeInSeconds, equals(8.456));
    });
  });

  group('StopwatchSessionWithTimes', () {
    test('toJson inkluderer session og times', () {
      final session = StopwatchSession(
        id: 'session-1',
        sessionType: StopwatchSessionType.stopwatch,
        status: StopwatchSessionStatus.completed,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        createdBy: 'user-1',
      );

      final time1 = StopwatchTime(
        id: 'time-1',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 8456,
        recordedAt: DateTime.parse('2024-03-15T10:05:00.000Z'),
      );

      final time2 = StopwatchTime(
        id: 'time-2',
        sessionId: 'session-1',
        userId: 'user-2',
        timeMs: 9123,
        recordedAt: DateTime.parse('2024-03-15T10:06:00.000Z'),
      );

      final sessionWithTimes = StopwatchSessionWithTimes(
        session: session,
        times: [time1, time2],
      );

      final json = sessionWithTimes.toJson();

      expect(json['session'], isNotNull);
      expect(json['times'], hasLength(2));
      expect(json['fastest_time'], isNotNull);
      expect(json['slowest_time'], isNotNull);
      expect(json['average_time_ms'], equals(8789));
    });

    test('sortedByTime sorterer etter tid', () {
      final session = StopwatchSession(
        id: 'session-1',
        sessionType: StopwatchSessionType.stopwatch,
        status: StopwatchSessionStatus.completed,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        createdBy: 'user-1',
      );

      final time1 = StopwatchTime(
        id: 'time-1',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 9000,
        recordedAt: DateTime.parse('2024-03-15T10:05:00.000Z'),
      );

      final time2 = StopwatchTime(
        id: 'time-2',
        sessionId: 'session-1',
        userId: 'user-2',
        timeMs: 8000,
        recordedAt: DateTime.parse('2024-03-15T10:06:00.000Z'),
      );

      final sessionWithTimes = StopwatchSessionWithTimes(
        session: session,
        times: [time1, time2],
      );

      final sorted = sessionWithTimes.sortedByTime;
      expect(sorted.first.timeMs, equals(8000));
      expect(sorted.last.timeMs, equals(9000));
    });

    test('fastestTime og slowestTime returnerer korrekte verdier', () {
      final session = StopwatchSession(
        id: 'session-1',
        sessionType: StopwatchSessionType.stopwatch,
        status: StopwatchSessionStatus.completed,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        createdBy: 'user-1',
      );

      final time1 = StopwatchTime(
        id: 'time-1',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 9000,
        recordedAt: DateTime.parse('2024-03-15T10:05:00.000Z'),
      );

      final time2 = StopwatchTime(
        id: 'time-2',
        sessionId: 'session-1',
        userId: 'user-2',
        timeMs: 8000,
        recordedAt: DateTime.parse('2024-03-15T10:06:00.000Z'),
      );

      final sessionWithTimes = StopwatchSessionWithTimes(
        session: session,
        times: [time1, time2],
      );

      expect(sessionWithTimes.fastestTime?.timeMs, equals(8000));
      expect(sessionWithTimes.slowestTime?.timeMs, equals(9000));
    });

    test('averageTimeMs beregner gjennomsnitt korrekt', () {
      final session = StopwatchSession(
        id: 'session-1',
        sessionType: StopwatchSessionType.stopwatch,
        status: StopwatchSessionStatus.completed,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        createdBy: 'user-1',
      );

      final time1 = StopwatchTime(
        id: 'time-1',
        sessionId: 'session-1',
        userId: 'user-1',
        timeMs: 8000,
        recordedAt: DateTime.parse('2024-03-15T10:05:00.000Z'),
      );

      final time2 = StopwatchTime(
        id: 'time-2',
        sessionId: 'session-1',
        userId: 'user-2',
        timeMs: 10000,
        recordedAt: DateTime.parse('2024-03-15T10:06:00.000Z'),
      );

      final sessionWithTimes = StopwatchSessionWithTimes(
        session: session,
        times: [time1, time2],
      );

      expect(sessionWithTimes.averageTimeMs, equals(9000));
    });
  });
}
