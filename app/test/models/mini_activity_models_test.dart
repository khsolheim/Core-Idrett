import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/mini_activity_models.dart';
import 'package:core_idrett/data/models/mini_activity_enums.dart';

void main() {
  group('ActivityTemplate', () {
    test('roundtrip med alle felt populert', () {
      final original = ActivityTemplate(
        id: 'template-1',
        teamId: 'team-1',
        name: 'Fotballtennis',
        type: MiniActivityType.team,
        defaultPoints: 3,
        createdAt: DateTime.parse('2024-01-01T10:00:00.000Z'),
        description: 'Populær aktivitet etter trening',
        instructions: 'Deles i lag, best av 3',
        sportType: 'fotball',
        suggestedRules: {'maxTouch': 3, 'serveSide': 'alternate'},
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
        name: 'Løpekonkurranse',
        type: MiniActivityType.individual,
        defaultPoints: 1,
        createdAt: DateTime.parse('2024-01-05T08:00:00.000Z'),
        // description, instructions, sportType, suggestedRules, leaderboardId are null
        isFavorite: false,
        winPoints: 3,
        drawPoints: 1,
        lossPoints: 0,
      );

      final json = original.toJson();
      final decoded = ActivityTemplate.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivity', () {
    test('roundtrip med alle felt populert', () {
      // Note: teams, participants, teamCount, participantCount are not included in toJson()
      // They are populated from API joins, not serialized
      final original = MiniActivity(
        id: 'mini-1',
        instanceId: 'instance-1',
        templateId: 'template-1',
        name: 'Fotballtennis onsdagskveld',
        type: MiniActivityType.team,
        divisionMethod: DivisionMethod.ranked,
        numTeams: 2,
        createdAt: DateTime.parse('2024-01-15T18:00:00.000Z'),
        teamId: 'team-1',
        leaderboardId: 'leaderboard-1',
        enableLeaderboard: true,
        winPoints: 3,
        drawPoints: 1,
        lossPoints: 0,
        description: 'Beste av 3 sett',
        maxParticipants: 12,
        handicapEnabled: false,
        archivedAt: DateTime.parse('2024-01-15T20:00:00.000Z'),
        winnerTeamId: 'team-a',
      );

      final json = original.toJson();
      final decoded = MiniActivity.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivity(
        id: 'mini-2',
        // instanceId, templateId, divisionMethod, teamId, leaderboardId, description,
        // maxParticipants, archivedAt, winnerTeamId are null
        // teams, participants, teamCount, participantCount not serialized by toJson()
        name: 'Sprint-konkurranse',
        type: MiniActivityType.individual,
        numTeams: 1,
        createdAt: DateTime.parse('2024-01-20T17:00:00.000Z'),
        enableLeaderboard: false,
        winPoints: 2,
        drawPoints: 0,
        lossPoints: 0,
        handicapEnabled: false,
      );

      final json = original.toJson();
      final decoded = MiniActivity.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
