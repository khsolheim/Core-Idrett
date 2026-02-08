import 'package:test/test.dart';
import 'package:core_idrett_backend/models/statistics.dart';

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
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
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
        // userName is null
        // userAvatarUrl is null
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
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
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
        updatedAt: DateTime.parse('2024-03-16T14:00:00.000Z'),
        // userName is null
        // userAvatarUrl is null
      );

      final json = original.toJson();
      final decoded = PlayerRating.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('SeasonStats', () {
    test('roundtrip med alle felt populert', () {
      final original = SeasonStats(
        id: 'season-stats-1',
        userId: 'user-1',
        teamId: 'team-1',
        seasonYear: 2024,
        attendanceCount: 25,
        totalPoints: 150,
        totalGoals: 8,
        totalAssists: 5,
        totalWins: 12,
        totalLosses: 6,
        totalDraws: 2,
        userName: 'Kari Hansen',
        userAvatarUrl: 'https://example.com/avatars/kari.jpg',
      );

      final json = original.toJson();
      final decoded = SeasonStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = SeasonStats(
        id: 'season-stats-2',
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
        // userName is null
        // userAvatarUrl is null
      );

      final json = original.toJson();
      final decoded = SeasonStats.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('PlayerStatistics', () {
    test('toJson inkluderer alle felt med nested objects', () {
      final rating = PlayerRating(
        id: 'rating-1',
        userId: 'user-1',
        teamId: 'team-1',
        rating: 1150.0,
        wins: 10,
        losses: 5,
        draws: 1,
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final seasonStats = SeasonStats(
        id: 'season-stats-1',
        userId: 'user-1',
        teamId: 'team-1',
        seasonYear: 2024,
        attendanceCount: 20,
        totalPoints: 120,
        totalGoals: 5,
        totalAssists: 3,
        totalWins: 8,
        totalLosses: 4,
        totalDraws: 1,
      );

      final original = PlayerStatistics(
        userId: 'user-1',
        teamId: 'team-1',
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        rating: rating,
        currentSeason: seasonStats,
        totalActivities: 25,
        attendedActivities: 22,
        attendancePercentage: 88.0,
      );

      final json = original.toJson();

      expect(json['user_id'], equals('user-1'));
      expect(json['team_id'], equals('team-1'));
      expect(json['user_name'], equals('Ola Nordmann'));
      expect(json['user_avatar_url'], equals('https://example.com/avatars/ola.jpg'));
      expect(json['rating'], isNotNull);
      expect(json['current_season'], isNotNull);
      expect(json['total_activities'], equals(25));
      expect(json['attended_activities'], equals(22));
      expect(json['attendance_percentage'], equals(88.0));
    });

    test('toJson med valgfrie felt null', () {
      final original = PlayerStatistics(
        userId: 'user-2',
        teamId: 'team-2',
        userName: 'Kari Hansen',
        // userAvatarUrl is null
        // rating is null
        // currentSeason is null
        totalActivities: 10,
        attendedActivities: 8,
        attendancePercentage: 80.0,
      );

      final json = original.toJson();

      expect(json['user_id'], equals('user-2'));
      expect(json['user_name'], equals('Kari Hansen'));
      expect(json['user_avatar_url'], isNull);
      expect(json['rating'], isNull);
      expect(json['current_season'], isNull);
    });
  });

  group('LeaderboardEntry (statistics)', () {
    test('toJson inkluderer alle felt', () {
      final original = LeaderboardEntry(
        rank: 1,
        userId: 'user-1',
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        totalPoints: 250,
        rating: 1300.5,
        wins: 20,
        losses: 5,
        draws: 2,
      );

      final json = original.toJson();

      expect(json['rank'], equals(1));
      expect(json['user_id'], equals('user-1'));
      expect(json['user_name'], equals('Ola Nordmann'));
      expect(json['user_avatar_url'], equals('https://example.com/avatars/ola.jpg'));
      expect(json['total_points'], equals(250));
      expect(json['rating'], equals(1300.5));
      expect(json['wins'], equals(20));
      expect(json['losses'], equals(5));
      expect(json['draws'], equals(2));
    });

    test('toJson med valgfrie felt null', () {
      final original = LeaderboardEntry(
        rank: 5,
        userId: 'user-2',
        userName: 'Kari Hansen',
        // userAvatarUrl is null
        totalPoints: 100,
        rating: 1000.0,
        wins: 5,
        losses: 3,
        draws: 0,
      );

      final json = original.toJson();

      expect(json['rank'], equals(5));
      expect(json['user_avatar_url'], isNull);
    });
  });

  group('AttendanceRecord', () {
    test('toJson inkluderer alle felt', () {
      final original = AttendanceRecord(
        userId: 'user-1',
        userName: 'Ole Olsen',
        userAvatarUrl: 'https://example.com/avatars/ole.jpg',
        totalActivities: 30,
        attended: 27,
        missed: 3,
        percentage: 90.0,
      );

      final json = original.toJson();

      expect(json['user_id'], equals('user-1'));
      expect(json['user_name'], equals('Ole Olsen'));
      expect(json['user_avatar_url'], equals('https://example.com/avatars/ole.jpg'));
      expect(json['total_activities'], equals(30));
      expect(json['attended'], equals(27));
      expect(json['missed'], equals(3));
      expect(json['percentage'], equals(90.0));
    });

    test('toJson med valgfrie felt null', () {
      final original = AttendanceRecord(
        userId: 'user-2',
        userName: 'Emma Larsen',
        // userAvatarUrl is null
        totalActivities: 15,
        attended: 12,
        missed: 3,
        percentage: 80.0,
      );

      final json = original.toJson();

      expect(json['user_name'], equals('Emma Larsen'));
      expect(json['user_avatar_url'], isNull);
    });
  });
}
