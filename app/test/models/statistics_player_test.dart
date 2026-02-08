import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/statistics_player.dart';

void main() {
  group('MatchStats', () {
    test('roundtrip med alle felt populert', () {
      final original = MatchStats(
        id: 'stats-1',
        instanceId: 'instance-1',
        userId: 'user-1',
        goals: 2,
        assists: 1,
        minutesPlayed: 90,
        yellowCards: 1,
        redCards: 0,
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/ola.jpg',
      );

      final json = original.toJson();
      final decoded = MatchStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MatchStats(
        id: 'stats-2',
        instanceId: 'instance-2',
        userId: 'user-2',
        goals: 0,
        assists: 0,
        minutesPlayed: 45,
        yellowCards: 0,
        redCards: 0,
        // userName and userAvatarUrl are null
      );

      final json = original.toJson();
      final decoded = MatchStats.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('PlayerRating', () {
    test('roundtrip med alle felt populert', () {
      final original = PlayerRating(
        id: 'rating-1',
        userId: 'user-1',
        teamId: 'team-1',
        rating: 1250.5,
        wins: 15,
        losses: 8,
        draws: 3,
        updatedAt: DateTime.parse('2024-01-20T16:00:00.000Z'),
        userName: 'Kari Hansen',
        userAvatarUrl: 'https://example.com/kari.jpg',
      );

      final json = original.toJson();
      final decoded = PlayerRating.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = PlayerRating(
        id: 'rating-2',
        userId: 'user-2',
        teamId: 'team-2',
        rating: 1000.0,
        wins: 0,
        losses: 0,
        draws: 0,
        updatedAt: DateTime.parse('2024-01-20T16:00:00.000Z'),
        // userName and userAvatarUrl are null
      );

      final json = original.toJson();
      final decoded = PlayerRating.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('SeasonStats', () {
    test('roundtrip med alle felt populert', () {
      final original = SeasonStats(
        id: 'stats-1',
        userId: 'user-1',
        teamId: 'team-1',
        seasonYear: 2024,
        attendanceCount: 18,
        totalPoints: 95,
        totalGoals: 12,
        totalAssists: 8,
        totalWins: 10,
        totalLosses: 4,
        totalDraws: 2,
        userName: 'Per Olsen',
        userAvatarUrl: 'https://example.com/per.jpg',
      );

      final json = original.toJson();
      final decoded = SeasonStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = SeasonStats(
        id: 'stats-2',
        userId: 'user-2',
        teamId: 'team-2',
        seasonYear: 2023,
        attendanceCount: 0,
        totalPoints: 0,
        totalGoals: 0,
        totalAssists: 0,
        totalWins: 0,
        totalLosses: 0,
        totalDraws: 0,
        // userName and userAvatarUrl are null
      );

      final json = original.toJson();
      final decoded = SeasonStats.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('PlayerStatistics', () {
    test('roundtrip med alle felt populert', () {
      final rating = PlayerRating(
        id: 'rating-1',
        userId: 'user-1',
        teamId: 'team-1',
        rating: 1150.0,
        wins: 12,
        losses: 6,
        draws: 2,
        updatedAt: DateTime.parse('2024-01-20T10:00:00.000Z'),
      );

      final seasonStats = SeasonStats(
        id: 'stats-1',
        userId: 'user-1',
        teamId: 'team-1',
        seasonYear: 2024,
        attendanceCount: 20,
        totalPoints: 110,
        totalGoals: 8,
        totalAssists: 5,
        totalWins: 12,
        totalLosses: 4,
        totalDraws: 1,
      );

      final original = PlayerStatistics(
        userId: 'user-1',
        teamId: 'team-1',
        userName: 'Lars Pettersen',
        userAvatarUrl: 'https://example.com/lars.jpg',
        rating: rating,
        currentSeason: seasonStats,
        totalActivities: 25,
        attendedActivities: 20,
        attendancePercentage: 80.0,
      );

      final json = original.toJson();
      final decoded = PlayerStatistics.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = PlayerStatistics(
        userId: 'user-2',
        teamId: 'team-2',
        userName: 'Nina Berg',
        // userAvatarUrl, rating, currentSeason are null
        totalActivities: 10,
        attendedActivities: 7,
        attendancePercentage: 70.0,
      );

      final json = original.toJson();
      final decoded = PlayerStatistics.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('LeaderboardEntry', () {
    test('roundtrip med alle felt populert', () {
      final original = LeaderboardEntry(
        rank: 1,
        userId: 'user-1',
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/ola.jpg',
        totalPoints: 150,
        rating: 1300.0,
        wins: 18,
        losses: 5,
        draws: 3,
      );

      final json = original.toJson();
      final decoded = LeaderboardEntry.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = LeaderboardEntry(
        rank: 10,
        userId: 'user-2',
        userName: 'Kari Hansen',
        // userAvatarUrl is null
        totalPoints: 45,
        rating: 950.0,
        wins: 3,
        losses: 8,
        draws: 1,
      );

      final json = original.toJson();
      final decoded = LeaderboardEntry.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('AttendanceRecord', () {
    test('roundtrip med alle felt populert', () {
      final original = AttendanceRecord(
        userId: 'user-1',
        userName: 'Per Olsen',
        userAvatarUrl: 'https://example.com/per.jpg',
        totalActivities: 30,
        attended: 25,
        missed: 5,
        percentage: 83.3,
      );

      final json = original.toJson();
      final decoded = AttendanceRecord.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AttendanceRecord(
        userId: 'user-2',
        userName: 'Nina Berg',
        // userAvatarUrl is null
        totalActivities: 15,
        attended: 10,
        missed: 5,
        percentage: 66.7,
      );

      final json = original.toJson();
      final decoded = AttendanceRecord.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
