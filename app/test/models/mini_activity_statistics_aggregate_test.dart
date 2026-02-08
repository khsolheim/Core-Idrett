import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/mini_activity_statistics_aggregate.dart';
import 'package:core_idrett/data/models/mini_activity_statistics_enums.dart';
import 'package:core_idrett/data/models/mini_activity_statistics_core.dart';

void main() {
  group('LeaderboardPointSource', () {
    test('roundtrip med alle felt populert', () {
      final original = LeaderboardPointSource(
        id: 'source-1',
        leaderboardEntryId: 'entry-1',
        userId: 'user-1',
        sourceType: PointSourceType.miniActivityWin,
        sourceId: 'mini-1',
        points: 10,
        description: 'Vant fotballtennis',
        recordedAt: DateTime.parse('2024-01-15T19:30:00.000Z'),
        sourceName: 'Fotballtennis onsdag',
      );

      final json = original.toJson();
      final decoded = LeaderboardPointSource.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = LeaderboardPointSource(
        id: 'source-2',
        leaderboardEntryId: 'entry-2',
        userId: 'user-2',
        sourceType: PointSourceType.manual,
        // sourceId, description, sourceName are null
        points: 5,
        recordedAt: DateTime.parse('2024-01-20T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = LeaderboardPointSource.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('PlayerStatsAggregate', () {
    test('roundtrip med alle felt populert', () {
      final overallStats = MiniActivityPlayerStats(
        id: 'stats-1',
        userId: 'user-1',
        teamId: 'team-1',
        totalParticipations: 50,
        totalWins: 30,
        totalLosses: 15,
        totalDraws: 5,
        totalPoints: 250,
        firstPlaceCount: 20,
        secondPlaceCount: 10,
        thirdPlaceCount: 5,
        updatedAt: DateTime.parse('2024-01-25T18:00:00.000Z'),
      );

      final seasonStats = MiniActivityPlayerStats(
        id: 'stats-2',
        userId: 'user-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        totalParticipations: 25,
        totalWins: 15,
        totalLosses: 8,
        totalDraws: 2,
        totalPoints: 125,
        firstPlaceCount: 10,
        secondPlaceCount: 5,
        thirdPlaceCount: 3,
        updatedAt: DateTime.parse('2024-01-25T18:00:00.000Z'),
      );

      final headToHeadRecords = [
        HeadToHeadStats(
          id: 'h2h-1',
          teamId: 'team-1',
          user1Id: 'user-1',
          user2Id: 'user-2',
          user1Wins: 5,
          user2Wins: 3,
          draws: 1,
          totalMatchups: 9,
          updatedAt: DateTime.parse('2024-01-20T15:00:00.000Z'),
        ),
      ];

      final recentHistory = [
        MiniActivityTeamHistory(
          id: 'history-1',
          userId: 'user-1',
          miniActivityId: 'mini-1',
          miniTeamId: 'team-a',
          pointsEarned: 10,
          wasWinner: true,
          recordedAt: DateTime.parse('2024-01-24T20:00:00.000Z'),
        ),
      ];

      final recentPointSources = [
        LeaderboardPointSource(
          id: 'source-1',
          leaderboardEntryId: 'entry-1',
          userId: 'user-1',
          sourceType: PointSourceType.miniActivityWin,
          points: 10,
          recordedAt: DateTime.parse('2024-01-24T20:00:00.000Z'),
        ),
      ];

      final original = PlayerStatsAggregate(
        overallStats: overallStats,
        seasonStats: seasonStats,
        headToHeadRecords: headToHeadRecords,
        recentHistory: recentHistory,
        recentPointSources: recentPointSources,
      );

      final json = original.toJson();
      final decoded = PlayerStatsAggregate.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = PlayerStatsAggregate(
        // overallStats, seasonStats are null
        // headToHeadRecords, recentHistory, recentPointSources default to empty lists
      );

      final json = original.toJson();
      final decoded = PlayerStatsAggregate.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TeamMiniActivityStats', () {
    test('roundtrip med alle felt populert', () {
      final topPlayers = [
        MiniActivityPlayerStats(
          id: 'stats-1',
          userId: 'user-1',
          teamId: 'team-1',
          totalParticipations: 30,
          totalWins: 20,
          totalLosses: 8,
          totalDraws: 2,
          totalPoints: 150,
          firstPlaceCount: 15,
          secondPlaceCount: 8,
          thirdPlaceCount: 3,
          updatedAt: DateTime.parse('2024-01-25T17:00:00.000Z'),
        ),
      ];

      final original = TeamMiniActivityStats(
        teamId: 'team-1',
        totalMiniActivities: 50,
        totalParticipations: 250,
        completedMiniActivities: 45,
        activeMiniActivities: 5,
        lastActivityAt: DateTime.parse('2024-01-25T19:00:00.000Z'),
        topPlayers: topPlayers,
      );

      final json = original.toJson();
      final decoded = TeamMiniActivityStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TeamMiniActivityStats(
        teamId: 'team-2',
        totalMiniActivities: 10,
        totalParticipations: 50,
        completedMiniActivities: 8,
        activeMiniActivities: 2,
        // lastActivityAt is null
        // topPlayers defaults to empty list
      );

      final json = original.toJson();
      final decoded = TeamMiniActivityStats.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
