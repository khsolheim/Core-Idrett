import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/points_config_leaderboard.dart';
import 'package:core_idrett/data/models/points_config_enums.dart';

void main() {
  group('RankedLeaderboardEntry', () {
    test('roundtrip med alle felt populert', () {
      final original = RankedLeaderboardEntry(
        id: 'entry-1',
        leaderboardId: 'leaderboard-1',
        userId: 'user-1',
        points: 150,
        rank: 1,
        attendanceRate: 90.5,
        currentStreak: 5,
        optedOut: false,
        trend: 'up',
        rankChange: 2,
        updatedAt: DateTime.parse('2024-01-20T12:00:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/ola.jpg',
      );

      final json = original.toJson();
      final decoded = RankedLeaderboardEntry.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = RankedLeaderboardEntry(
        id: 'entry-2',
        leaderboardId: 'leaderboard-2',
        userId: 'user-2',
        points: 75,
        rank: 8,
        // attendanceRate, currentStreak, trend, rankChange, userName, userAvatarUrl are null
        optedOut: true,
        updatedAt: DateTime.parse('2024-01-20T12:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = RankedLeaderboardEntry.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MonthlyUserStats', () {
    test('roundtrip med alle felt populert', () {
      final original = MonthlyUserStats(
        id: 'stats-1',
        teamId: 'team-1',
        userId: 'user-1',
        year: 2024,
        month: 1,
        trainingAttended: 8,
        trainingPossible: 10,
        matchAttended: 4,
        matchPossible: 5,
        socialAttended: 2,
        socialPossible: 2,
        attendancePoints: 30,
        competitionPoints: 20,
        bonusPoints: 10,
        penaltyPoints: 5,
        attendanceRate: 85.0,
        updatedAt: DateTime.parse('2024-01-31T23:59:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MonthlyUserStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MonthlyUserStats(
        id: 'stats-2',
        teamId: 'team-2',
        userId: 'user-2',
        year: 2024,
        month: 2,
        trainingAttended: 5,
        trainingPossible: 8,
        matchAttended: 2,
        matchPossible: 4,
        socialAttended: 1,
        socialPossible: 2,
        attendancePoints: 15,
        competitionPoints: 8,
        bonusPoints: 0,
        penaltyPoints: 0,
        // attendanceRate is null
        updatedAt: DateTime.parse('2024-02-29T23:59:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MonthlyUserStats.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('ManualPointAdjustment', () {
    test('roundtrip med alle felt populert', () {
      final original = ManualPointAdjustment(
        id: 'adjustment-1',
        teamId: 'team-1',
        userId: 'user-1',
        seasonId: 'season-1',
        points: 10,
        adjustmentType: AdjustmentType.bonus,
        reason: 'Ekstra innsats under kamp',
        createdBy: 'admin-1',
        createdAt: DateTime.parse('2024-01-15T14:00:00.000Z'),
        userName: 'Kari Hansen',
        userAvatarUrl: 'https://example.com/kari.jpg',
        createdByName: 'Trener Olsen',
      );

      final json = original.toJson();
      final decoded = ManualPointAdjustment.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ManualPointAdjustment(
        id: 'adjustment-2',
        teamId: 'team-2',
        userId: 'user-2',
        // seasonId, userName, userAvatarUrl, createdByName are null
        points: -5,
        adjustmentType: AdjustmentType.penalty,
        reason: 'For sent til trening',
        createdBy: 'admin-2',
        createdAt: DateTime.parse('2024-01-20T09:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = ManualPointAdjustment.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
