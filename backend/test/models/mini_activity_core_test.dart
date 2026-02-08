import 'package:test/test.dart';
import 'package:core_idrett_backend/models/mini_activity_core.dart';

void main() {
  group('ActivityTemplate', () {
    test('roundtrip med alle felt populert', () {
      final original = ActivityTemplate(
        id: 'template-1',
        teamId: 'team-1',
        name: 'Fotballgolf',
        type: 'individual',
        defaultPoints: 5,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        description: 'Lag fotballgolf-bane med kjegler',
        instructions: 'Spark ballen til hvert kjegle med færrest mulig spark',
        sportType: 'fotball',
        suggestedRules: {'max_kicks': 10, 'team_size': 2},
        isFavorite: true,
        winPoints: 3,
        drawPoints: 1,
        lossPoints: 0,
        leaderboardId: 'leaderboard-1',
      );

      final json = original.toJson();
      final decoded = ActivityTemplate.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ActivityTemplate(
        id: 'template-2',
        teamId: 'team-2',
        name: 'Sprint',
        type: 'individual',
        defaultPoints: 3,
        createdAt: DateTime.parse('2024-02-15T14:00:00.000Z'),
        // description is null
        // instructions is null
        // sportType is null
        // suggestedRules is null
        isFavorite: false,
        winPoints: 3,
        drawPoints: 1,
        lossPoints: 0,
        // leaderboardId is null
      );

      final json = original.toJson();
      final decoded = ActivityTemplate.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivity', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivity(
        id: 'mini-1',
        instanceId: 'instance-1',
        templateId: 'template-1',
        name: 'Fotballgolf - Mars 2024',
        type: 'team',
        divisionMethod: 'random',
        numTeams: 4,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        teamId: null,
        leaderboardId: 'leaderboard-1',
        enableLeaderboard: true,
        winPoints: 3,
        drawPoints: 1,
        lossPoints: 0,
        description: 'Månedlig konkurranse',
        maxParticipants: 20,
        handicapEnabled: true,
        archivedAt: null,
        winnerTeamId: 'mini-team-1',
      );

      final json = original.toJson();
      final decoded = MiniActivity.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med standalone mini-activity', () {
      final original = MiniActivity(
        id: 'mini-2',
        instanceId: null,
        templateId: 'template-2',
        name: 'Standalone Sprint',
        type: 'individual',
        divisionMethod: null,
        numTeams: 2,
        createdAt: DateTime.parse('2024-03-16T14:00:00.000Z'),
        teamId: 'team-1',
        leaderboardId: null,
        enableLeaderboard: false,
        winPoints: 3,
        drawPoints: 1,
        lossPoints: 0,
        description: null,
        maxParticipants: null,
        handicapEnabled: false,
        archivedAt: null,
        winnerTeamId: null,
      );

      final json = original.toJson();
      final decoded = MiniActivity.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.isStandalone, isTrue);
    });

    test('isArchived returnerer true når archivedAt er satt', () {
      final archived = MiniActivity(
        id: 'mini-3',
        name: 'Archived Activity',
        type: 'individual',
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        archivedAt: DateTime.parse('2024-03-20T10:00:00.000Z'),
      );

      expect(archived.isArchived, isTrue);
    });

    test('hasResult returnerer true når winnerTeamId er satt', () {
      final withResult = MiniActivity(
        id: 'mini-4',
        name: 'Activity With Result',
        type: 'team',
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        winnerTeamId: 'mini-team-1',
      );

      expect(withResult.hasResult, isTrue);
    });
  });
}
