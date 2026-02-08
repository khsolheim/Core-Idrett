import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/tournament_group_models.dart';
import 'package:core_idrett/data/models/tournament_enums.dart';

void main() {
  group('TournamentGroup', () {
    test('roundtrip med alle felt populert', () {
      final standings = [
        GroupStanding(
          id: 'standing-1',
          groupId: 'group-1',
          teamId: 'team-1',
          played: 3,
          won: 2,
          drawn: 1,
          lost: 0,
          goalsFor: 8,
          goalsAgainst: 3,
          points: 7,
          position: 1,
          updatedAt: DateTime.parse('2024-01-18T20:00:00.000Z'),
          teamName: 'Lag Rød',
        ),
      ];

      final matches = [
        GroupMatch(
          id: 'match-1',
          groupId: 'group-1',
          teamAId: 'team-1',
          teamBId: 'team-2',
          teamAScore: 3,
          teamBScore: 1,
          status: MatchStatus.completed,
          scheduledTime: DateTime.parse('2024-01-15T14:00:00.000Z'),
          matchOrder: 1,
          createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
          teamAName: 'Lag Rød',
          teamBName: 'Lag Blå',
        ),
      ];

      final original = TournamentGroup(
        id: 'group-1',
        tournamentId: 'tournament-1',
        name: 'Gruppe A',
        advanceCount: 2,
        sortOrder: 1,
        createdAt: DateTime.parse('2024-01-10T09:00:00.000Z'),
        standings: standings,
        matches: matches,
      );

      final json = original.toJson();
      final decoded = TournamentGroup.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TournamentGroup(
        id: 'group-2',
        tournamentId: 'tournament-2',
        name: 'Gruppe B',
        advanceCount: 1,
        sortOrder: 2,
        createdAt: DateTime.parse('2024-01-10T09:00:00.000Z'),
        // standings and matches are null
      );

      final json = original.toJson();
      final decoded = TournamentGroup.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('GroupStanding', () {
    test('roundtrip med alle felt populert', () {
      final original = GroupStanding(
        id: 'standing-1',
        groupId: 'group-1',
        teamId: 'team-1',
        played: 5,
        won: 3,
        drawn: 1,
        lost: 1,
        goalsFor: 12,
        goalsAgainst: 6,
        points: 10,
        position: 1,
        updatedAt: DateTime.parse('2024-01-20T18:00:00.000Z'),
        teamName: 'Viking FK',
      );

      final json = original.toJson();
      final decoded = GroupStanding.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = GroupStanding(
        id: 'standing-2',
        groupId: 'group-2',
        teamId: 'team-2',
        played: 0,
        won: 0,
        drawn: 0,
        lost: 0,
        goalsFor: 0,
        goalsAgainst: 0,
        points: 0,
        position: 4,
        updatedAt: DateTime.parse('2024-01-20T18:00:00.000Z'),
        // teamName is null
      );

      final json = original.toJson();
      final decoded = GroupStanding.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('GroupMatch', () {
    test('roundtrip med alle felt populert', () {
      final original = GroupMatch(
        id: 'match-1',
        groupId: 'group-1',
        teamAId: 'team-1',
        teamBId: 'team-2',
        teamAScore: 2,
        teamBScore: 2,
        status: MatchStatus.completed,
        scheduledTime: DateTime.parse('2024-01-15T15:00:00.000Z'),
        matchOrder: 1,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        teamAName: 'Brann FK',
        teamBName: 'Rosenborg BK',
      );

      final json = original.toJson();
      final decoded = GroupMatch.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = GroupMatch(
        id: 'match-2',
        groupId: 'group-2',
        // teamAId, teamBId, scheduledTime, teamAName, teamBName are null
        teamAScore: 0,
        teamBScore: 0,
        status: MatchStatus.pending,
        matchOrder: 2,
        createdAt: DateTime.parse('2024-01-20T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = GroupMatch.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('QualificationRound', () {
    test('roundtrip med alle felt populert', () {
      final results = [
        QualificationResult(
          id: 'result-1',
          qualificationRoundId: 'qual-1',
          userId: 'user-1',
          resultValue: 42.5,
          advanced: true,
          rank: 1,
          createdAt: DateTime.parse('2024-01-15T16:00:00.000Z'),
          userName: 'Ola Nordmann',
        ),
      ];

      final original = QualificationRound(
        id: 'qual-1',
        tournamentId: 'tournament-1',
        name: 'Kvalifiseringsrunde',
        advanceCount: 8,
        sortDirection: 'asc',
        status: MatchStatus.completed,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        results: results,
      );

      final json = original.toJson();
      final decoded = QualificationRound.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = QualificationRound(
        id: 'qual-2',
        tournamentId: 'tournament-2',
        name: 'Tidskvalifisering',
        advanceCount: 4,
        sortDirection: 'desc',
        status: MatchStatus.pending,
        createdAt: DateTime.parse('2024-01-20T10:00:00.000Z'),
        // results is null
      );

      final json = original.toJson();
      final decoded = QualificationRound.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('QualificationResult', () {
    test('roundtrip med alle felt populert', () {
      final original = QualificationResult(
        id: 'result-1',
        qualificationRoundId: 'qual-1',
        userId: 'user-1',
        resultValue: 58.3,
        advanced: true,
        rank: 2,
        createdAt: DateTime.parse('2024-01-15T16:30:00.000Z'),
        userName: 'Kari Hansen',
      );

      final json = original.toJson();
      final decoded = QualificationResult.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = QualificationResult(
        id: 'result-2',
        qualificationRoundId: 'qual-2',
        userId: 'user-2',
        resultValue: 72.1,
        advanced: false,
        rank: 12,
        createdAt: DateTime.parse('2024-01-20T17:00:00.000Z'),
        // userName is null
      );

      final json = original.toJson();
      final decoded = QualificationResult.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
