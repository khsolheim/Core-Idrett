import 'package:test/test.dart';
import 'package:core_idrett_backend/models/tournament_round.dart';
import 'package:core_idrett_backend/models/tournament_match.dart';

void main() {
  group('RoundType', () {
    test('value returnerer korrekt string', () {
      expect(RoundType.winners.value, equals('winners'));
      expect(RoundType.losers.value, equals('losers'));
      expect(RoundType.bronze.value, equals('bronze'));
      expect(RoundType.final_.value, equals('final'));
    });

    test('fromString konverterer korrekt', () {
      expect(RoundType.fromString('winners'), equals(RoundType.winners));
      expect(RoundType.fromString('losers'), equals(RoundType.losers));
      expect(RoundType.fromString('bronze'), equals(RoundType.bronze));
      expect(RoundType.fromString('final'), equals(RoundType.final_));
    });

    test('fromString kaster exception for ukjent verdi', () {
      expect(() => RoundType.fromString('unknown'), throwsArgumentError);
    });
  });

  group('TournamentRound', () {
    test('roundtrip med alle felt populert', () {
      final original = TournamentRound(
        id: 'round-1',
        tournamentId: 'tournament-1',
        roundNumber: 1,
        roundName: 'Kvartfinale',
        roundType: RoundType.winners,
        status: MatchStatus.inProgress,
        scheduledTime: DateTime.parse('2024-03-15T14:00:00.000Z'),
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TournamentRound.fromJson expects DateTime objects
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      if (json['scheduled_time'] != null) {
        json['scheduled_time'] = DateTime.parse(json['scheduled_time'] as String);
      }
      final decoded = TournamentRound.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TournamentRound(
        id: 'round-2',
        tournamentId: 'tournament-2',
        roundNumber: 2,
        // roundName is null
        roundType: RoundType.final_,
        status: MatchStatus.pending,
        // scheduledTime is null
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TournamentRound.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = TournamentRound.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
