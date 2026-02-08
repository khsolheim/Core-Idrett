import 'package:test/test.dart';
import 'package:core_idrett_backend/models/points_config.dart';

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
        trainingWeight: 1.0,
        matchWeight: 1.5,
        socialWeight: 0.5,
        competitionWeight: 1.2,
        miniActivityDistribution: 'top_three',
        autoAwardAttendance: true,
        visibility: 'all',
        allowOptOut: false,
        requireAbsenceReason: true,
        requireAbsenceApproval: false,
        excludeValidAbsenceFromPercentage: true,
        newPlayerStartMode: 'from_join',
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-15T14:00:00.000Z'),
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
        miniActivityDistribution: 'winner_only',
        autoAwardAttendance: false,
        visibility: 'admins_only',
        allowOptOut: true,
        requireAbsenceReason: false,
        requireAbsenceApproval: false,
        excludeValidAbsenceFromPercentage: false,
        newPlayerStartMode: 'from_season_start',
        createdAt: DateTime.parse('2024-02-15T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-16T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TeamPointsConfig.fromJson(json);

      expect(decoded, equals(original));
    });

    test('getWeightedPoints beregner vektede poeng korrekt', () {
      final config = TeamPointsConfig(
        id: 'config-1',
        teamId: 'team-1',
        trainingPoints: 2,
        matchPoints: 3,
        socialPoints: 1,
        trainingWeight: 1.0,
        matchWeight: 1.5,
        socialWeight: 0.5,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      expect(config.getWeightedPoints('training'), equals(2.0));
      expect(config.getWeightedPoints('match'), equals(4.5));
      expect(config.getWeightedPoints('social'), equals(0.5));
      expect(config.getWeightedPoints('unknown'), equals(1.0));
    });

    test('getBasePoints returnerer base poeng korrekt', () {
      final config = TeamPointsConfig(
        id: 'config-1',
        teamId: 'team-1',
        trainingPoints: 2,
        matchPoints: 3,
        socialPoints: 1,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      expect(config.getBasePoints('training'), equals(2));
      expect(config.getBasePoints('match'), equals(3));
      expect(config.getBasePoints('social'), equals(1));
      expect(config.getBasePoints('unknown'), equals(1));
    });

    test('copyWith oppdaterer kun spesifiserte felt', () {
      final original = TeamPointsConfig(
        id: 'config-1',
        teamId: 'team-1',
        trainingPoints: 1,
        matchPoints: 2,
        socialPoints: 1,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      final updated = original.copyWith(
        trainingPoints: 3,
        matchPoints: 5,
      );

      expect(updated.id, equals(original.id));
      expect(updated.teamId, equals(original.teamId));
      expect(updated.trainingPoints, equals(3));
      expect(updated.matchPoints, equals(5));
      expect(updated.socialPoints, equals(1));
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
        weightedPoints: 2.0,
        awardedAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
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
        // seasonId is null
        activityType: 'match',
        basePoints: 3,
        weightedPoints: 4.5,
        awardedAt: DateTime.parse('2024-03-16T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AttendancePoints.fromJson(json);

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
        adjustmentType: 'bonus',
        reason: 'Ekstra innsats under kamp',
        createdBy: 'user-admin',
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        createdByName: 'Kari Hansen',
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
        // seasonId is null
        points: -5,
        adjustmentType: 'penalty',
        reason: 'Upassende oppførsel',
        createdBy: 'user-admin',
        createdAt: DateTime.parse('2024-03-16T14:00:00.000Z'),
        // userName is null
        // userAvatarUrl is null
        // createdByName is null
      );

      final json = original.toJson();
      final decoded = ManualPointAdjustment.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
