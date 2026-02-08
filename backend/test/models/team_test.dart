import 'package:test/test.dart';
import 'package:core_idrett_backend/models/team.dart';

void main() {
  group('Team', () {
    test('roundtrip med alle felt populert', () {
      final original = Team(
        id: 'team-1',
        name: 'Vålerenga Fotball',
        sport: 'Fotball',
        inviteCode: 'VIF2024',
        createdAt: DateTime.parse('2024-01-10T09:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: Team.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = Team.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Team(
        id: 'team-2',
        name: 'Rosenborg Ballklubb',
        // sport is null
        // inviteCode is null
        createdAt: DateTime.parse('2024-02-15T11:30:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: Team.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = Team.fromJson(json);

      expect(decoded, equals(original));
    });
  });

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
      // Fix DateTime: TrainerType.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = TrainerType.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // TrainerType has no optional fields except defaults
      final original = TrainerType(
        id: 'trainer-type-2',
        teamId: 'team-2',
        name: 'Assistenttrener',
        displayOrder: 2,
        createdAt: DateTime.parse('2024-02-20T14:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TrainerType.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = TrainerType.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TeamMember', () {
    test('roundtrip med alle felt populert', () {
      final original = TeamMember(
        id: 'member-1',
        userId: 'user-1',
        teamId: 'team-1',
        role: 'admin',
        isAdmin: true,
        isFineBoss: false,
        isCoach: true,
        trainerTypeId: 'trainer-type-1',
        trainerTypeName: 'Hovedtrener',
        isActive: true,
        isInjured: false,
        joinedAt: DateTime.parse('2024-01-12T08:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TeamMember.fromJson expects DateTime object
      json['joined_at'] = DateTime.parse(json['joined_at'] as String);
      final decoded = TeamMember.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TeamMember(
        id: 'member-2',
        userId: 'user-2',
        teamId: 'team-2',
        role: 'player',
        isAdmin: false,
        isFineBoss: false,
        isCoach: false,
        // trainerTypeId is null
        // trainerTypeName is null
        isActive: true,
        isInjured: false,
        joinedAt: DateTime.parse('2024-02-25T12:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TeamMember.fromJson expects DateTime object
      json['joined_at'] = DateTime.parse(json['joined_at'] as String);
      final decoded = TeamMember.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
