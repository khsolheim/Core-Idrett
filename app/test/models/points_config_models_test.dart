import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/points_config_models.dart';
import 'package:core_idrett/data/models/points_config_enums.dart';

void main() {
  group('TeamPointsConfig', () {
    test('roundtrip med alle felt populert', () {
      final original = TeamPointsConfig(
        id: 'config-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        trainingPoints: 2,
        matchPoints: 3,
        socialPoints: 1,
        trainingWeight: 1.5,
        matchWeight: 2.0,
        socialWeight: 0.75,
        competitionWeight: 1.25,
        miniActivityDistribution: MiniActivityDistribution.topThree,
        autoAwardAttendance: true,
        visibility: LeaderboardVisibility.all,
        allowOptOut: false,
        requireAbsenceReason: true,
        requireAbsenceApproval: true,
        excludeValidAbsenceFromPercentage: true,
        newPlayerStartMode: NewPlayerStartMode.fromJoin,
        createdAt: DateTime.parse('2024-01-01T08:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TeamPointsConfig.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TeamPointsConfig(
        id: 'config-2',
        teamId: 'team-2',
        // seasonId is null
        trainingPoints: 1,
        matchPoints: 2,
        socialPoints: 1,
        trainingWeight: 1.0,
        matchWeight: 1.5,
        socialWeight: 0.5,
        competitionWeight: 1.0,
        miniActivityDistribution: MiniActivityDistribution.winnerOnly,
        autoAwardAttendance: false,
        visibility: LeaderboardVisibility.rankingOnly,
        allowOptOut: true,
        requireAbsenceReason: false,
        requireAbsenceApproval: false,
        excludeValidAbsenceFromPercentage: false,
        newPlayerStartMode: NewPlayerStartMode.wholeSeason,
        createdAt: DateTime.parse('2024-01-01T08:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TeamPointsConfig.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('AttendancePoints', () {
    test('roundtrip med alle felt populert', () {
      final original = AttendancePoints(
        id: 'points-1',
        teamId: 'team-1',
        userId: 'user-1',
        instanceId: 'instance-1',
        seasonId: 'season-1',
        activityType: 'training',
        basePoints: 2,
        weightedPoints: 3.0,
        createdAt: DateTime.parse('2024-01-15T18:00:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/ola.jpg',
        activityName: 'Onsdagstrening',
        activityDate: DateTime.parse('2024-01-15T17:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AttendancePoints.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AttendancePoints(
        id: 'points-2',
        teamId: 'team-2',
        userId: 'user-2',
        instanceId: 'instance-2',
        // seasonId, userName, userAvatarUrl, activityName, activityDate are null
        activityType: 'match',
        basePoints: 3,
        weightedPoints: 4.5,
        createdAt: DateTime.parse('2024-01-20T19:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AttendancePoints.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('UserAttendanceStats', () {
    test('roundtrip med alle felt populert', () {
      final original = UserAttendanceStats(
        userId: 'user-1',
        teamId: 'team-1',
        totalPoints: 150,
        totalWeightedPoints: 225.5,
        trainingAttended: 20,
        trainingPossible: 24,
        matchAttended: 10,
        matchPossible: 12,
        socialAttended: 5,
        socialPossible: 6,
        attendanceRate: 85.0,
        currentStreak: 5,
        trainingPoints: 40,
        matchPoints: 30,
        socialPoints: 5,
        competitionPoints: 50,
        bonusPoints: 25,
      );

      final json = original.toJson();
      final decoded = UserAttendanceStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = UserAttendanceStats(
        userId: 'user-2',
        teamId: 'team-2',
        totalPoints: 50,
        totalWeightedPoints: 75.0,
        trainingAttended: 10,
        trainingPossible: 15,
        matchAttended: 5,
        matchPossible: 8,
        socialAttended: 2,
        socialPossible: 4,
        attendanceRate: 65.0,
        // currentStreak is null
        trainingPoints: 20,
        matchPoints: 15,
        socialPoints: 2,
        competitionPoints: 10,
        bonusPoints: 3,
      );

      final json = original.toJson();
      final decoded = UserAttendanceStats.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
