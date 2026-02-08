import 'package:test/test.dart';
import 'package:core_idrett_backend/models/mini_activity_statistics.dart';

void main() {
  group('MiniActivityPlayerStats', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityPlayerStats(
        id: 'stats-1',
        userId: 'user-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        totalParticipations: 20,
        totalWins: 12,
        totalLosses: 6,
        totalDraws: 2,
        totalPoints: 150,
        firstPlaceCount: 8,
        secondPlaceCount: 4,
        thirdPlaceCount: 3,
        bestStreak: 5,
        currentStreak: 3,
        averagePlacement: 2.1,
        updatedAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: MiniActivityPlayerStats.fromJson expects DateTime object
      json['updated_at'] = DateTime.parse(json['updated_at'] as String);
      final decoded = MiniActivityPlayerStats.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.winRate, closeTo(60.0, 0.01));
      expect(decoded.podiumRate, closeTo(75.0, 0.01));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityPlayerStats(
        id: 'stats-2',
        userId: 'user-2',
        teamId: 'team-2',
        // seasonId is null
        totalParticipations: 0,
        totalWins: 0,
        totalLosses: 0,
        totalDraws: 0,
        totalPoints: 0,
        firstPlaceCount: 0,
        secondPlaceCount: 0,
        thirdPlaceCount: 0,
        bestStreak: 0,
        currentStreak: 0,
        // averagePlacement is null
        updatedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime
      json['updated_at'] = DateTime.parse(json['updated_at'] as String);
      final decoded = MiniActivityPlayerStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('isOnWinningStreak og isOnLosingStreak fungerer korrekt', () {
      final winning = MiniActivityPlayerStats(
        id: 'stats-3',
        userId: 'user-1',
        teamId: 'team-1',
        currentStreak: 3,
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final losing = MiniActivityPlayerStats(
        id: 'stats-4',
        userId: 'user-2',
        teamId: 'team-1',
        currentStreak: -2,
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(winning.isOnWinningStreak, isTrue);
      expect(winning.isOnLosingStreak, isFalse);
      expect(losing.isOnWinningStreak, isFalse);
      expect(losing.isOnLosingStreak, isTrue);
    });
  });

  group('HeadToHeadStats', () {
    test('roundtrip med alle felt populert', () {
      final original = HeadToHeadStats(
        id: 'h2h-1',
        teamId: 'team-1',
        user1Id: 'user-1',
        user2Id: 'user-2',
        user1Wins: 8,
        user2Wins: 5,
        draws: 2,
        totalMatchups: 15,
        lastMatchupAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime
      json['updated_at'] = DateTime.parse(json['updated_at'] as String);
      if (json['last_matchup_at'] != null) {
        json['last_matchup_at'] = DateTime.parse(json['last_matchup_at'] as String);
      }
      final decoded = HeadToHeadStats.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.leaderId, equals('user-1'));
      expect(decoded.isTied, isFalse);
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = HeadToHeadStats(
        id: 'h2h-2',
        teamId: 'team-2',
        user1Id: 'user-3',
        user2Id: 'user-4',
        user1Wins: 0,
        user2Wins: 0,
        draws: 0,
        totalMatchups: 0,
        // lastMatchupAt is null
        updatedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime
      json['updated_at'] = DateTime.parse(json['updated_at'] as String);
      final decoded = HeadToHeadStats.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.isTied, isTrue);
    });
  });

  group('MiniActivityTeamHistory', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityTeamHistory(
        id: 'history-1',
        userId: 'user-1',
        miniActivityId: 'mini-1',
        miniTeamId: 'mini-team-1',
        teamName: 'Team Alpha',
        teammates: [
          {'user_id': 'user-2', 'name': 'Ola'},
          {'user_id': 'user-3', 'name': 'Kari'}
        ],
        placement: 1,
        pointsEarned: 10,
        wasWinner: true,
        recordedAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime
      json['recorded_at'] = DateTime.parse(json['recorded_at'] as String);
      final decoded = MiniActivityTeamHistory.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.isPodium, isTrue);
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityTeamHistory(
        id: 'history-2',
        userId: 'user-2',
        miniActivityId: 'mini-2',
        // miniTeamId is null
        // teamName is null
        // teammates is null
        // placement is null
        pointsEarned: 0,
        wasWinner: false,
        recordedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime
      json['recorded_at'] = DateTime.parse(json['recorded_at'] as String);
      final decoded = MiniActivityTeamHistory.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('LeaderboardPointSource', () {
    test('roundtrip med alle felt populert', () {
      final original = LeaderboardPointSource(
        id: 'source-1',
        leaderboardEntryId: 'entry-1',
        userId: 'user-1',
        sourceType: PointSourceType.miniActivity,
        sourceId: 'mini-1',
        points: 10,
        description: 'Vant fotballgolf',
        recordedAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime
      json['recorded_at'] = DateTime.parse(json['recorded_at'] as String);
      final decoded = LeaderboardPointSource.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.isPositive, isTrue);
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = LeaderboardPointSource(
        id: 'source-2',
        leaderboardEntryId: 'entry-2',
        userId: 'user-2',
        sourceType: PointSourceType.penalty,
        sourceId: 'adjustment-1',
        points: -5,
        // description is null
        recordedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime
      json['recorded_at'] = DateTime.parse(json['recorded_at'] as String);
      final decoded = LeaderboardPointSource.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.isNegative, isTrue);
    });
  });

  group('PlayerStatsAggregate', () {
    test('toJson inkluderer alle felt', () {
      final stats = MiniActivityPlayerStats(
        id: 'stats-1',
        userId: 'user-1',
        teamId: 'team-1',
        totalWins: 10,
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      final aggregate = PlayerStatsAggregate(
        stats: stats,
        headToHead: [],
        recentHistory: [],
        pointSources: [
          LeaderboardPointSource(
            id: 'source-1',
            leaderboardEntryId: 'entry-1',
            userId: 'user-1',
            sourceType: PointSourceType.miniActivity,
            sourceId: 'mini-1',
            points: 10,
            recordedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
          ),
        ],
      );

      final json = aggregate.toJson();

      expect(json['stats'], isNotNull);
      expect(json['head_to_head'], isList);
      expect(json['recent_history'], isList);
      expect(json['point_sources'], isList);
      expect(aggregate.totalPointsFromSources, equals(10));
    });
  });
}
