import 'package:test/test.dart';
import 'package:core_idrett_backend/models/tournament_group.dart';
import 'package:core_idrett_backend/models/tournament_match.dart';

void main() {
  group('TournamentGroup', () {
    test('roundtrip med alle felt populert', () {
      final original = TournamentGroup(
        id: 'group-1',
        tournamentId: 'tournament-1',
        name: 'Gruppe A',
        advanceCount: 2,
        sortOrder: 1,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TournamentGroup.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = TournamentGroup.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med default verdier', () {
      final original = TournamentGroup(
        id: 'group-2',
        tournamentId: 'tournament-2',
        name: 'Gruppe B',
        advanceCount: 2,
        sortOrder: 0,
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: TournamentGroup.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
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
        played: 6,
        won: 4,
        drawn: 1,
        lost: 1,
        goalsFor: 12,
        goalsAgainst: 5,
        points: 13,
        position: 1,
        updatedAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: GroupStanding.fromJson expects DateTime object
      json['updated_at'] = DateTime.parse(json['updated_at'] as String);
      final decoded = GroupStanding.fromJson(json);

      expect(decoded, equals(original));
      expect(json['goal_difference'], equals(7));
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
        // position is null
        updatedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: GroupStanding.fromJson expects DateTime object
      json['updated_at'] = DateTime.parse(json['updated_at'] as String);
      final decoded = GroupStanding.fromJson(json);

      expect(decoded, equals(original));
    });

    test('goalDifference beregnes korrekt', () {
      final standing = GroupStanding(
        id: 'standing-3',
        groupId: 'group-1',
        teamId: 'team-1',
        goalsFor: 15,
        goalsAgainst: 8,
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(standing.goalDifference, equals(7));
    });
  });

  group('GroupMatch', () {
    test('roundtrip med alle felt populert', () {
      final original = GroupMatch(
        id: 'group-match-1',
        groupId: 'group-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        teamAScore: 3,
        teamBScore: 2,
        status: MatchStatus.completed,
        scheduledTime: DateTime.parse('2024-03-15T14:00:00.000Z'),
        matchOrder: 1,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: GroupMatch.fromJson expects DateTime objects
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      if (json['scheduled_time'] != null) {
        json['scheduled_time'] = DateTime.parse(json['scheduled_time'] as String);
      }
      final decoded = GroupMatch.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = GroupMatch(
        id: 'group-match-2',
        groupId: 'group-2',
        teamAId: 'team-c',
        teamBId: 'team-d',
        // teamAScore is null
        // teamBScore is null
        status: MatchStatus.pending,
        // scheduledTime is null
        matchOrder: 0,
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: GroupMatch.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = GroupMatch.fromJson(json);

      expect(decoded, equals(original));
    });

    test('isCompleted returnerer true for fullførte kamper', () {
      final match = GroupMatch(
        id: 'group-match-3',
        groupId: 'group-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        status: MatchStatus.completed,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(match.isCompleted, isTrue);
    });

    test('isDraw returnerer true når score er lik', () {
      final match = GroupMatch(
        id: 'group-match-4',
        groupId: 'group-1',
        teamAId: 'team-a',
        teamBId: 'team-b',
        teamAScore: 2,
        teamBScore: 2,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(match.isDraw, isTrue);
    });
  });

  group('QualificationRound', () {
    test('roundtrip med alle felt populert', () {
      final original = QualificationRound(
        id: 'qual-round-1',
        tournamentId: 'tournament-1',
        name: 'Kvalifiseringsrunde',
        advanceCount: 8,
        sortDirection: 'desc',
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: QualificationRound.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = QualificationRound.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med sortDirection asc', () {
      final original = QualificationRound(
        id: 'qual-round-2',
        tournamentId: 'tournament-2',
        name: 'Kvalifisering',
        advanceCount: 4,
        sortDirection: 'asc',
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: QualificationRound.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = QualificationRound.fromJson(json);

      expect(decoded, equals(original));
    });

    test('sortDescending returnerer true for desc', () {
      final round = QualificationRound(
        id: 'qual-round-3',
        tournamentId: 'tournament-1',
        name: 'Test',
        sortDirection: 'desc',
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(round.sortDescending, isTrue);
    });
  });

  group('QualificationResult', () {
    test('roundtrip med alle felt populert', () {
      final original = QualificationResult(
        id: 'qual-result-1',
        qualificationRoundId: 'qual-round-1',
        userId: 'user-1',
        resultValue: 85.5,
        advanced: true,
        rank: 3,
        createdAt: DateTime.parse('2024-03-15T16:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: QualificationResult.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = QualificationResult.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = QualificationResult(
        id: 'qual-result-2',
        qualificationRoundId: 'qual-round-2',
        userId: 'user-2',
        resultValue: 62.0,
        advanced: false,
        // rank is null
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: QualificationResult.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = QualificationResult.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
