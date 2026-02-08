import 'package:test/test.dart';
import 'package:core_idrett_backend/models/tournament_match.dart';

void main() {
  group('MatchStatus', () {
    test('value returnerer korrekt string', () {
      expect(MatchStatus.pending.value, equals('pending'));
      expect(MatchStatus.inProgress.value, equals('in_progress'));
      expect(MatchStatus.completed.value, equals('completed'));
      expect(MatchStatus.walkover.value, equals('walkover'));
      expect(MatchStatus.cancelled.value, equals('cancelled'));
    });

    test('fromString konverterer korrekt', () {
      expect(MatchStatus.fromString('pending'), equals(MatchStatus.pending));
      expect(MatchStatus.fromString('in_progress'), equals(MatchStatus.inProgress));
      expect(MatchStatus.fromString('completed'), equals(MatchStatus.completed));
      expect(MatchStatus.fromString('walkover'), equals(MatchStatus.walkover));
      expect(MatchStatus.fromString('cancelled'), equals(MatchStatus.cancelled));
    });

    test('fromString kaster exception for ukjent verdi', () {
      expect(() => MatchStatus.fromString('unknown'), throwsArgumentError);
    });
  });

  group('TournamentMatch', () {
    test('roundtrip med alle felt populert', () {
      final original = TournamentMatch(
        id: 'match-1',
        tournamentId: 'tournament-1',
        roundId: 'round-1',
        bracketPosition: 1,
        teamAId: 'team-a',
        teamBId: 'team-b',
        winnerId: 'team-a',
        teamAScore: 2,
        teamBScore: 1,
        status: MatchStatus.completed,
        scheduledTime: DateTime.parse('2024-03-15T14:00:00.000Z'),
        matchOrder: 1,
        winnerGoesToMatchId: 'match-2',
        loserGoesToMatchId: 'match-3',
        isWalkover: false,
        walkoverReason: null,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TournamentMatch.fromJson expects DateTime objects
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      if (json['scheduled_time'] != null) {
        json['scheduled_time'] = DateTime.parse(json['scheduled_time'] as String);
      }
      final decoded = TournamentMatch.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TournamentMatch(
        id: 'match-2',
        tournamentId: 'tournament-2',
        roundId: 'round-2',
        bracketPosition: 2,
        // teamAId is null
        // teamBId is null
        // winnerId is null
        // teamAScore is null
        // teamBScore is null
        status: MatchStatus.pending,
        // scheduledTime is null
        matchOrder: 0,
        // winnerGoesToMatchId is null
        // loserGoesToMatchId is null
        isWalkover: false,
        // walkoverReason is null
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TournamentMatch.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = TournamentMatch.fromJson(json);

      expect(decoded, equals(original));
    });

    test('hasTeams returnerer true når begge lag er satt', () {
      final match = TournamentMatch(
        id: 'match-3',
        tournamentId: 'tournament-1',
        roundId: 'round-1',
        bracketPosition: 1,
        teamAId: 'team-a',
        teamBId: 'team-b',
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(match.hasTeams, isTrue);
    });

    test('isCompleted returnerer true for completed og walkover', () {
      final completed = TournamentMatch(
        id: 'match-4',
        tournamentId: 'tournament-1',
        roundId: 'round-1',
        bracketPosition: 1,
        status: MatchStatus.completed,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final walkover = TournamentMatch(
        id: 'match-5',
        tournamentId: 'tournament-1',
        roundId: 'round-1',
        bracketPosition: 2,
        status: MatchStatus.walkover,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(completed.isCompleted, isTrue);
      expect(walkover.isCompleted, isTrue);
    });

    test('isDraw returnerer true når score er lik', () {
      final match = TournamentMatch(
        id: 'match-6',
        tournamentId: 'tournament-1',
        roundId: 'round-1',
        bracketPosition: 1,
        teamAScore: 2,
        teamBScore: 2,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(match.isDraw, isTrue);
    });
  });

  group('MatchGame', () {
    test('roundtrip med alle felt populert', () {
      final original = MatchGame(
        id: 'game-1',
        matchId: 'match-1',
        gameNumber: 1,
        teamAScore: 11,
        teamBScore: 9,
        winnerId: 'team-a',
        status: MatchStatus.completed,
        createdAt: DateTime.parse('2024-03-15T14:30:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: MatchGame.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = MatchGame.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MatchGame(
        id: 'game-2',
        matchId: 'match-2',
        gameNumber: 2,
        teamAScore: 0,
        teamBScore: 0,
        // winnerId is null
        status: MatchStatus.pending,
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: MatchGame.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = MatchGame.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
