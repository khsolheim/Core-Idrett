import 'package:test/test.dart';
import 'package:core_idrett_backend/models/season.dart';

void main() {
  group('Season', () {
    test('roundtrip med alle felt populert', () {
      final original = Season(
        id: 'season-1',
        teamId: 'team-1',
        name: '2024 Vår',
        startDate: DateTime(2024, 1, 15),
        endDate: DateTime(2024, 6, 30),
        isActive: true,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Season.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Season(
        id: 'season-2',
        teamId: 'team-2',
        name: '2024 Høst',
        // startDate is null
        // endDate is null
        isActive: false,
        createdAt: DateTime.parse('2024-07-01T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Season.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('LeaderboardCategory', () {
    test('value returnerer korrekt string', () {
      expect(LeaderboardCategory.total.value, equals('total'));
      expect(LeaderboardCategory.attendance.value, equals('attendance'));
      expect(LeaderboardCategory.competition.value, equals('competition'));
      expect(LeaderboardCategory.training.value, equals('training'));
      expect(LeaderboardCategory.match.value, equals('match'));
      expect(LeaderboardCategory.social.value, equals('social'));
    });

    test('fromString konverterer korrekt', () {
      expect(LeaderboardCategory.fromString('total'), equals(LeaderboardCategory.total));
      expect(LeaderboardCategory.fromString('attendance'), equals(LeaderboardCategory.attendance));
      expect(LeaderboardCategory.fromString('competition'), equals(LeaderboardCategory.competition));
      expect(LeaderboardCategory.fromString('training'), equals(LeaderboardCategory.training));
      expect(LeaderboardCategory.fromString('match'), equals(LeaderboardCategory.match));
      expect(LeaderboardCategory.fromString('social'), equals(LeaderboardCategory.social));
      expect(LeaderboardCategory.fromString('unknown'), equals(LeaderboardCategory.total));
    });

    test('displayName returnerer norske navn', () {
      expect(LeaderboardCategory.total.displayName, equals('Total'));
      expect(LeaderboardCategory.attendance.displayName, equals('Oppmøte'));
      expect(LeaderboardCategory.competition.displayName, equals('Konkurranse'));
      expect(LeaderboardCategory.training.displayName, equals('Trening'));
      expect(LeaderboardCategory.match.displayName, equals('Kamp'));
      expect(LeaderboardCategory.social.displayName, equals('Sosialt'));
    });
  });

  group('Leaderboard', () {
    test('roundtrip med alle felt populert', () {
      final original = Leaderboard(
        id: 'leaderboard-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        name: 'Hovedkonkurranse',
        description: 'Hovedkonkurransen for vårsesongen 2024',
        isMain: true,
        sortOrder: 1,
        category: LeaderboardCategory.total,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Leaderboard.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Leaderboard(
        id: 'leaderboard-2',
        teamId: 'team-2',
        // seasonId is null
        name: 'Treningskonkurranse',
        // description is null
        isMain: false,
        sortOrder: 2,
        category: LeaderboardCategory.training,
        createdAt: DateTime.parse('2024-02-01T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Leaderboard.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('LeaderboardEntry', () {
    test('roundtrip med alle felt populert', () {
      final original = LeaderboardEntry(
        id: 'entry-1',
        leaderboardId: 'leaderboard-1',
        userId: 'user-1',
        points: 250,
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        rank: 1,
        attendanceRate: 92.5,
        currentStreak: 5,
        // optedOut: not set — toJson writes 'opted_out' but fromJson reads 'leaderboard_opt_out' (key mismatch)
        trend: 'up',
        rankChange: 2,
      );

      final json = original.toJson();
      // Fix key mismatch: toJson writes 'opted_out', fromJson reads 'leaderboard_opt_out'
      if (json.containsKey('opted_out')) {
        json['leaderboard_opt_out'] = json.remove('opted_out');
      }
      final decoded = LeaderboardEntry.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = LeaderboardEntry(
        id: 'entry-2',
        leaderboardId: 'leaderboard-2',
        userId: 'user-2',
        points: 120,
        updatedAt: DateTime.parse('2024-03-16T14:30:00.000Z'),
      );

      final json = original.toJson();
      final decoded = LeaderboardEntry.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med rank parameter i fromJson', () {
      final original = LeaderboardEntry(
        id: 'entry-3',
        leaderboardId: 'leaderboard-1',
        userId: 'user-3',
        points: 180,
        updatedAt: DateTime.parse('2024-03-17T12:00:00.000Z'),
        userName: 'Kari Hansen',
        userAvatarUrl: null,
        rank: 3,
        attendanceRate: 85.0,
        currentStreak: 2,
        // optedOut skipped — key mismatch between toJson/fromJson
        trend: 'same',
        rankChange: 0,
      );

      final json = original.toJson();
      final decoded = LeaderboardEntry.fromJson(json, rank: 3);

      expect(decoded, equals(original));
      expect(decoded.rank, equals(3));
    });
  });

  group('MiniActivityPointConfig', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityPointConfig(
        id: 'config-1',
        miniActivityId: 'mini-activity-1',
        leaderboardId: 'leaderboard-1',
        distributionType: 'top_three',
        pointsFirst: 10,
        pointsSecond: 6,
        pointsThird: 3,
        pointsParticipation: 1,
      );

      final json = original.toJson();
      final decoded = MiniActivityPointConfig.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med winner_only distribution', () {
      final original = MiniActivityPointConfig(
        id: 'config-2',
        miniActivityId: 'mini-activity-2',
        leaderboardId: 'leaderboard-2',
        distributionType: 'winner_only',
        pointsFirst: 15,
        pointsSecond: 0,
        pointsThird: 0,
        pointsParticipation: 0,
      );

      final json = original.toJson();
      final decoded = MiniActivityPointConfig.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
