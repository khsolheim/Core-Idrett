import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/team.dart';

void main() {
  group('TrainerType', () {
    test('roundtrip med alle felt populert', () {
      final original = TrainerType(
        id: 'trainer-type-1',
        teamId: 'team-1',
        name: 'Hovedtrener',
        displayOrder: 1,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TrainerType.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // TrainerType har ingen valgfrie felt, så begge tester er like
      final original = TrainerType(
        id: 'trainer-type-2',
        teamId: 'team-1',
        name: 'Assistenttrener',
        displayOrder: 2,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TrainerType.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('Team', () {
    test('roundtrip med alle felt populert', () {
      final trainerType = TrainerType(
        id: 'trainer-type-1',
        teamId: 'team-1',
        name: 'Hovedtrener',
        displayOrder: 1,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final original = Team(
        id: 'team-1',
        name: 'Rosenborg BK',
        sport: 'Fotball',
        inviteCode: 'RBK2024',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        userIsAdmin: true,
        userIsFineBoss: true,
        userIsCoach: true,
        userTrainerType: trainerType,
      );

      final json = original.toJson();
      // Note: toJson doesn't include user role fields, so we need to add them for the test
      json['user_is_admin'] = original.userIsAdmin;
      json['user_is_fine_boss'] = original.userIsFineBoss;
      json['user_is_coach'] = original.userIsCoach;
      if (original.userTrainerType != null) {
        json['user_trainer_type'] = original.userTrainerType!.toJson();
      }

      final decoded = Team.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Team(
        id: 'team-2',
        name: 'Brann FK',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        userIsAdmin: false,
        userIsFineBoss: false,
        userIsCoach: false,
      );

      final json = original.toJson();
      json['user_is_admin'] = original.userIsAdmin;
      json['user_is_fine_boss'] = original.userIsFineBoss;
      json['user_is_coach'] = original.userIsCoach;

      final decoded = Team.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TeamMember', () {
    test('roundtrip med alle felt populert', () {
      final trainerType = TrainerType(
        id: 'trainer-type-1',
        teamId: 'team-1',
        name: 'Hovedtrener',
        displayOrder: 1,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final original = TeamMember(
        id: 'member-1',
        userId: 'user-1',
        teamId: 'team-1',
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        userBirthDate: DateTime.parse('1995-03-15T00:00:00.000Z'),
        isAdmin: true,
        isFineBoss: true,
        isCoach: true,
        trainerType: trainerType,
        isActive: true,
        isInjured: false,
        joinedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TeamMember.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TeamMember(
        id: 'member-2',
        userId: 'user-2',
        teamId: 'team-1',
        userName: 'Kari Hansen',
        isAdmin: false,
        isFineBoss: false,
        isCoach: false,
        isActive: true,
        isInjured: false,
        joinedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TeamMember.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TeamSettings', () {
    test('roundtrip med alle felt populert', () {
      final original = TeamSettings(
        teamId: 'team-1',
        attendancePoints: 2,
        winPoints: 5,
        drawPoints: 2,
        lossPoints: 1,
        appealFee: 50.0,
        gameDayMultiplier: 2.0,
      );

      final json = original.toJson();
      final decoded = TeamSettings.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // TeamSettings har default-verdier, ikke nullable felt
      final original = TeamSettings(
        teamId: 'team-2',
        attendancePoints: 1,
        winPoints: 3,
        drawPoints: 1,
        lossPoints: 0,
      );

      final json = original.toJson();
      final decoded = TeamSettings.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
