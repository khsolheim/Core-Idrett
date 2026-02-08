import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/tournament_models.dart';
import 'package:core_idrett/data/models/tournament_enums.dart';
import 'package:core_idrett/data/models/tournament_group_models.dart';

void main() {
  group('Tournament', () {
    test('roundtrip med alle felt populert', () {
      final rounds = [
        TournamentRound(
          id: 'round-1',
          tournamentId: 'tournament-1',
          roundNumber: 1,
          roundName: 'Semifinale',
          roundType: RoundType.winners,
          status: MatchStatus.completed,
          scheduledTime: DateTime.parse('2024-01-15T14:00:00.000Z'),
          createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        ),
      ];

      final groups = [
        TournamentGroup(
          id: 'group-1',
          tournamentId: 'tournament-1',
          name: 'Gruppe A',
          advanceCount: 2,
          sortOrder: 1,
          createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        ),
      ];

      final original = Tournament(
        id: 'tournament-1',
        miniActivityId: 'mini-1',
        tournamentType: TournamentType.singleElimination,
        status: TournamentStatus.inProgress,
        bestOf: 3,
        bronzeFinal: true,
        seedingMethod: SeedingMethod.ranked,
        maxParticipants: 16,
        createdAt: DateTime.parse('2024-01-10T09:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T16:00:00.000Z'),
        rounds: rounds,
        groups: groups,
      );

      final json = original.toJson();
      final decoded = Tournament.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Tournament(
        id: 'tournament-2',
        miniActivityId: 'mini-2',
        tournamentType: TournamentType.groupPlay,
        status: TournamentStatus.draft,
        bestOf: 1,
        bronzeFinal: false,
        seedingMethod: SeedingMethod.random,
        // maxParticipants, updatedAt, rounds, groups are null
        createdAt: DateTime.parse('2024-01-20T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Tournament.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TournamentRound', () {
    test('roundtrip med alle felt populert', () {
      final matches = [
        TournamentMatch(
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
          scheduledTime: DateTime.parse('2024-01-15T14:00:00.000Z'),
          matchOrder: 1,
          createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        ),
      ];

      final original = TournamentRound(
        id: 'round-1',
        tournamentId: 'tournament-1',
        roundNumber: 1,
        roundName: 'Kvartfinale',
        roundType: RoundType.winners,
        status: MatchStatus.completed,
        scheduledTime: DateTime.parse('2024-01-15T14:00:00.000Z'),
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        matches: matches,
      );

      final json = original.toJson();
      final decoded = TournamentRound.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TournamentRound(
        id: 'round-2',
        tournamentId: 'tournament-2',
        roundNumber: 2,
        roundName: 'Finale',
        roundType: RoundType.final_,
        status: MatchStatus.pending,
        // scheduledTime and matches are null
        createdAt: DateTime.parse('2024-01-20T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TournamentRound.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TournamentMatch', () {
    test('roundtrip med alle felt populert', () {
      final games = [
        MatchGame(
          id: 'game-1',
          matchId: 'match-1',
          gameNumber: 1,
          teamAScore: 11,
          teamBScore: 9,
          winnerId: 'team-a',
          status: MatchStatus.completed,
          createdAt: DateTime.parse('2024-01-15T14:10:00.000Z'),
        ),
      ];

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
        scheduledTime: DateTime.parse('2024-01-15T14:00:00.000Z'),
        matchOrder: 1,
        winnerGoesToMatchId: 'match-final',
        loserGoesToMatchId: 'match-bronze',
        isWalkover: false,
        walkoverReason: null,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        games: games,
        teamAName: 'Lag Rød',
        teamBName: 'Lag Blå',
      );

      final json = original.toJson();
      final decoded = TournamentMatch.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TournamentMatch(
        id: 'match-2',
        tournamentId: 'tournament-2',
        // roundId, teamAId, teamBId, winnerId, scheduledTime, winnerGoesToMatchId,
        // loserGoesToMatchId, walkoverReason, games, teamAName, teamBName are null
        bracketPosition: 2,
        teamAScore: 0,
        teamBScore: 0,
        status: MatchStatus.pending,
        matchOrder: 2,
        isWalkover: false,
        createdAt: DateTime.parse('2024-01-20T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TournamentMatch.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MatchGame', () {
    test('roundtrip med alle felt populert', () {
      final original = MatchGame(
        id: 'game-1',
        matchId: 'match-1',
        gameNumber: 1,
        teamAScore: 11,
        teamBScore: 8,
        winnerId: 'team-a',
        status: MatchStatus.completed,
        createdAt: DateTime.parse('2024-01-15T14:10:00.000Z'),
      );

      final json = original.toJson();
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
        createdAt: DateTime.parse('2024-01-20T15:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MatchGame.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
