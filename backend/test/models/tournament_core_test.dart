import 'package:test/test.dart';
import 'package:core_idrett_backend/models/tournament_core.dart';

void main() {
  group('TournamentType', () {
    test('value returnerer korrekt string', () {
      expect(TournamentType.singleElimination.value, equals('single_elimination'));
      expect(TournamentType.doubleElimination.value, equals('double_elimination'));
      expect(TournamentType.groupPlay.value, equals('group_play'));
      expect(TournamentType.groupKnockout.value, equals('group_knockout'));
    });

    test('fromString konverterer korrekt', () {
      expect(TournamentType.fromString('single_elimination'), equals(TournamentType.singleElimination));
      expect(TournamentType.fromString('double_elimination'), equals(TournamentType.doubleElimination));
      expect(TournamentType.fromString('group_play'), equals(TournamentType.groupPlay));
      expect(TournamentType.fromString('group_knockout'), equals(TournamentType.groupKnockout));
    });

    test('fromString kaster exception for ukjent verdi', () {
      expect(() => TournamentType.fromString('unknown'), throwsArgumentError);
    });

    test('displayName returnerer norske navn', () {
      expect(TournamentType.singleElimination.displayName, equals('Utslagsturnering'));
      expect(TournamentType.doubleElimination.displayName, equals('Dobbel utslagsturnering'));
      expect(TournamentType.groupPlay.displayName, equals('Gruppespill'));
      expect(TournamentType.groupKnockout.displayName, equals('Gruppespill + Sluttspill'));
    });
  });

  group('TournamentStatus', () {
    test('value returnerer korrekt string', () {
      expect(TournamentStatus.setup.value, equals('setup'));
      expect(TournamentStatus.inProgress.value, equals('in_progress'));
      expect(TournamentStatus.completed.value, equals('completed'));
      expect(TournamentStatus.cancelled.value, equals('cancelled'));
    });

    test('fromString konverterer korrekt', () {
      expect(TournamentStatus.fromString('setup'), equals(TournamentStatus.setup));
      expect(TournamentStatus.fromString('in_progress'), equals(TournamentStatus.inProgress));
      expect(TournamentStatus.fromString('completed'), equals(TournamentStatus.completed));
      expect(TournamentStatus.fromString('cancelled'), equals(TournamentStatus.cancelled));
    });

    test('fromString kaster exception for ukjent verdi', () {
      expect(() => TournamentStatus.fromString('unknown'), throwsArgumentError);
    });
  });

  group('SeedingMethod', () {
    test('value returnerer korrekt string', () {
      expect(SeedingMethod.random.value, equals('random'));
      expect(SeedingMethod.ranked.value, equals('ranked'));
      expect(SeedingMethod.manual.value, equals('manual'));
    });

    test('fromString konverterer korrekt', () {
      expect(SeedingMethod.fromString('random'), equals(SeedingMethod.random));
      expect(SeedingMethod.fromString('ranked'), equals(SeedingMethod.ranked));
      expect(SeedingMethod.fromString('manual'), equals(SeedingMethod.manual));
    });

    test('fromString kaster exception for ukjent verdi', () {
      expect(() => SeedingMethod.fromString('unknown'), throwsArgumentError);
    });
  });

  group('Tournament', () {
    test('roundtrip med alle felt populert', () {
      final original = Tournament(
        id: 'tournament-1',
        miniActivityId: 'mini-activity-1',
        tournamentType: TournamentType.singleElimination,
        bestOf: 3,
        bronzeFinal: true,
        seedingMethod: SeedingMethod.ranked,
        maxParticipants: 16,
        status: TournamentStatus.inProgress,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: Tournament.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = Tournament.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Tournament(
        id: 'tournament-2',
        miniActivityId: 'mini-activity-2',
        tournamentType: TournamentType.groupPlay,
        bestOf: 1,
        bronzeFinal: false,
        seedingMethod: SeedingMethod.random,
        // maxParticipants is null
        status: TournamentStatus.setup,
        createdAt: DateTime.parse('2024-03-16T14:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: Tournament.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = Tournament.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
