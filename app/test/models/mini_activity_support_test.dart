import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/mini_activity_support.dart';

void main() {
  group('MiniActivityTeam', () {
    test('roundtrip med alle felt populert', () {
      final participants = [
        MiniActivityParticipant(
          id: 'participant-1',
          userId: 'user-1',
          points: 15,
          userName: 'Ola Nordmann',
          userAvatarUrl: 'https://example.com/ola.jpg',
        ),
      ];

      final original = MiniActivityTeam(
        id: 'team-1',
        name: 'Lag Rød',
        finalScore: 11,
        participants: participants,
      );

      final json = original.toJson();
      final decoded = MiniActivityTeam.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityTeam(
        id: 'team-2',
        // name, finalScore, participants are null
      );

      final json = original.toJson();
      final decoded = MiniActivityTeam.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivityParticipant', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityParticipant(
        id: 'participant-1',
        userId: 'user-1',
        points: 20,
        userName: 'Kari Hansen',
        userAvatarUrl: 'https://example.com/kari.jpg',
      );

      final json = original.toJson();
      final decoded = MiniActivityParticipant.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityParticipant(
        id: 'participant-2',
        userId: 'user-2',
        points: 5,
        // userName and userAvatarUrl are null
      );

      final json = original.toJson();
      final decoded = MiniActivityParticipant.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivityAdjustment', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityAdjustment(
        id: 'adjustment-1',
        miniActivityId: 'mini-1',
        teamId: 'team-1',
        userId: 'user-1',
        points: 5,
        reason: 'Ekstra innsats',
        createdBy: 'admin-1',
        createdAt: DateTime.parse('2024-01-15T19:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MiniActivityAdjustment.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityAdjustment(
        id: 'adjustment-2',
        miniActivityId: 'mini-2',
        // teamId, userId, reason are null
        points: -3,
        createdBy: 'admin-2',
        createdAt: DateTime.parse('2024-01-20T18:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MiniActivityAdjustment.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivityHandicap', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityHandicap(
        id: 'handicap-1',
        miniActivityId: 'mini-1',
        userId: 'user-1',
        handicapValue: 2.5,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
        userName: 'Per Olsen',
      );

      final json = original.toJson();
      final decoded = MiniActivityHandicap.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityHandicap(
        id: 'handicap-2',
        miniActivityId: 'mini-2',
        userId: 'user-2',
        handicapValue: -1.5,
        createdAt: DateTime.parse('2024-01-20T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-20T10:00:00.000Z'),
        // userName is null
      );

      final json = original.toJson();
      final decoded = MiniActivityHandicap.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivityHistoryEntry', () {
    test('roundtrip med alle felt populert', () {
      final teams = [
        MiniActivityHistoryTeam(
          id: 'team-a',
          name: 'Lag Rød',
          finalScore: 15,
        ),
        MiniActivityHistoryTeam(
          id: 'team-b',
          name: 'Lag Blå',
          finalScore: 12,
        ),
      ];

      final original = MiniActivityHistoryEntry(
        id: 'history-1',
        name: 'Fotballtennis 15. januar',
        createdAt: DateTime.parse('2024-01-15T18:30:00.000Z'),
        winnerTeamId: 'team-a',
        teams: teams,
      );

      final jsonMap = {
        'id': original.id,
        'name': original.name,
        'created_at': original.createdAt.toIso8601String(),
        'winner_team_id': original.winnerTeamId,
        'teams': teams.map((t) => {
          'id': t.id,
          'name': t.name,
          'final_score': t.finalScore,
        }).toList(),
      };

      final decoded = MiniActivityHistoryEntry.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final teams = [
        MiniActivityHistoryTeam(
          id: 'team-c',
          name: 'Lag Grønn',
        ),
      ];

      final original = MiniActivityHistoryEntry(
        id: 'history-2',
        name: 'Sprint 20. januar',
        createdAt: DateTime.parse('2024-01-20T17:00:00.000Z'),
        // winnerTeamId is null
        teams: teams,
      );

      final jsonMap = {
        'id': original.id,
        'name': original.name,
        'created_at': original.createdAt.toIso8601String(),
        'winner_team_id': original.winnerTeamId,
        'teams': teams.map((t) => {
          'id': t.id,
          'name': t.name,
          'final_score': t.finalScore,
        }).toList(),
      };

      final decoded = MiniActivityHistoryEntry.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivityHistoryTeam', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityHistoryTeam(
        id: 'team-a',
        name: 'Lag Rød',
        finalScore: 21,
      );

      final jsonMap = {
        'id': original.id,
        'name': original.name,
        'final_score': original.finalScore,
      };

      final decoded = MiniActivityHistoryTeam.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityHistoryTeam(
        id: 'team-b',
        // name and finalScore are null
      );

      final jsonMap = {
        'id': original.id,
        'name': original.name,
        'final_score': original.finalScore,
      };

      final decoded = MiniActivityHistoryTeam.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });
}
