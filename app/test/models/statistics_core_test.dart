import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/statistics_core.dart';

void main() {
  group('Season', () {
    test('roundtrip med alle felt populert', () {
      final original = Season(
        id: 'season-1',
        teamId: 'team-1',
        name: 'Sesong 2024',
        startDate: DateTime.parse('2024-01-01'),  // Date-only fields parse as local time
        endDate: DateTime.parse('2024-12-31'),
        isActive: true,
        createdAt: DateTime.parse('2024-01-01T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Season.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Season(
        id: 'season-2',
        teamId: 'team-2',
        name: 'Sesong 2023',
        // startDate and endDate are null
        isActive: false,
        createdAt: DateTime.parse('2023-01-01T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Season.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('Leaderboard', () {
    test('roundtrip med alle felt populert', () {
      final entries = [
        NewLeaderboardEntry(
          id: 'entry-1',
          leaderboardId: 'leaderboard-1',
          userId: 'user-1',
          points: 100,
          updatedAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
          userName: 'Ola Nordmann',
          userAvatarUrl: 'https://example.com/avatar1.jpg',
          rank: 1,
        ),
        NewLeaderboardEntry(
          id: 'entry-2',
          leaderboardId: 'leaderboard-1',
          userId: 'user-2',
          points: 90,
          updatedAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
          userName: 'Kari Hansen',
          userAvatarUrl: 'https://example.com/avatar2.jpg',
          rank: 2,
        ),
      ];

      final original = Leaderboard(
        id: 'leaderboard-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        name: 'Poengtavle 2024',
        description: 'Hovedtavle for sesongen',
        isMain: true,
        sortOrder: 1,
        createdAt: DateTime.parse('2024-01-01T10:00:00.000Z'),
        entries: entries,
      );

      final json = original.toJson();
      final decoded = Leaderboard.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Leaderboard(
        id: 'leaderboard-2',
        teamId: 'team-2',
        // seasonId, description, and entries are null
        name: 'Generell tavle',
        isMain: false,
        sortOrder: 2,
        createdAt: DateTime.parse('2024-01-01T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Leaderboard.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('NewLeaderboardEntry', () {
    test('roundtrip med alle felt populert', () {
      final original = NewLeaderboardEntry(
        id: 'entry-1',
        leaderboardId: 'leaderboard-1',
        userId: 'user-1',
        points: 150,
        updatedAt: DateTime.parse('2024-01-20T14:30:00.000Z'),
        userName: 'Per Olsen',
        userAvatarUrl: 'https://example.com/per.jpg',
        rank: 3,
      );

      final json = original.toJson();
      final decoded = NewLeaderboardEntry.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = NewLeaderboardEntry(
        id: 'entry-2',
        leaderboardId: 'leaderboard-2',
        userId: 'user-2',
        points: 75,
        updatedAt: DateTime.parse('2024-01-20T14:30:00.000Z'),
        // userName, userAvatarUrl, and rank are null
      );

      final json = original.toJson();
      final decoded = NewLeaderboardEntry.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TestTemplate', () {
    test('roundtrip med alle felt populert', () {
      final original = TestTemplate(
        id: 'template-1',
        teamId: 'team-1',
        name: 'Løpetest',
        description: '3000 meter løp',
        unit: 'sekunder',
        higherIsBetter: false,
        createdAt: DateTime.parse('2024-01-10T09:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TestTemplate.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TestTemplate(
        id: 'template-2',
        teamId: 'team-2',
        name: 'Spenst',
        // description is null
        unit: 'cm',
        higherIsBetter: true,
        createdAt: DateTime.parse('2024-01-10T09:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TestTemplate.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TestResult', () {
    test('roundtrip med alle felt populert', () {
      final original = TestResult(
        id: 'result-1',
        testTemplateId: 'template-1',
        userId: 'user-1',
        instanceId: 'instance-1',
        value: 720.5,
        recordedAt: DateTime.parse('2024-01-15T11:30:00.000Z'),
        notes: 'Gode forhold',
        userName: 'Lars Pettersen',
        userAvatarUrl: 'https://example.com/lars.jpg',
        testName: 'Løpetest',
        testUnit: 'sekunder',
      );

      final json = original.toJson();
      final decoded = TestResult.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TestResult(
        id: 'result-2',
        testTemplateId: 'template-2',
        userId: 'user-2',
        // instanceId, notes, userName, userAvatarUrl, testName, testUnit are null
        value: 245.0,
        recordedAt: DateTime.parse('2024-01-15T11:30:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TestResult.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
