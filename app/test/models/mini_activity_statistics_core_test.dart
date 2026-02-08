import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/mini_activity_statistics_core.dart';

void main() {
  group('MiniActivityPlayerStats', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityPlayerStats(
        id: 'stats-1',
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
        updatedAt: DateTime.parse('2024-01-20T18:00:00.000Z'),
        userName: 'Ola Nordmann',
        userProfileImageUrl: 'https://example.com/ola.jpg',
        seasonName: 'Sesong 2024',
      );

      final json = original.toJson();
      final decoded = MiniActivityPlayerStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityPlayerStats(
        id: 'stats-2',
        userId: 'user-2',
        teamId: 'team-2',
        // seasonId, userName, userProfileImageUrl, seasonName are null
        totalParticipations: 10,
        totalWins: 5,
        totalLosses: 4,
        totalDraws: 1,
        totalPoints: 50,
        firstPlaceCount: 3,
        secondPlaceCount: 2,
        thirdPlaceCount: 1,
        updatedAt: DateTime.parse('2024-01-25T12:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MiniActivityPlayerStats.fromJson(json);

      expect(decoded, equals(original));
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
        lastMatchupAt: DateTime.parse('2024-01-18T19:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-18T19:30:00.000Z'),
        user1Name: 'Ola Nordmann',
        user2Name: 'Kari Hansen',
        user1ProfileImageUrl: 'https://example.com/ola.jpg',
        user2ProfileImageUrl: 'https://example.com/kari.jpg',
      );

      final json = original.toJson();
      final decoded = HeadToHeadStats.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = HeadToHeadStats(
        id: 'h2h-2',
        teamId: 'team-2',
        user1Id: 'user-3',
        user2Id: 'user-4',
        user1Wins: 2,
        user2Wins: 3,
        draws: 0,
        totalMatchups: 5,
        // lastMatchupAt, user1Name, user2Name, user1ProfileImageUrl, user2ProfileImageUrl are null
        updatedAt: DateTime.parse('2024-01-25T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = HeadToHeadStats.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('MiniActivityTeamHistory', () {
    test('roundtrip med alle felt populert', () {
      final original = MiniActivityTeamHistory(
        id: 'history-1',
        userId: 'user-1',
        miniActivityId: 'mini-1',
        miniTeamId: 'team-a',
        teamName: 'Lag Rød',
        placement: 1,
        pointsEarned: 10,
        wasWinner: true,
        recordedAt: DateTime.parse('2024-01-15T20:00:00.000Z'),
        userName: 'Per Olsen',
        miniActivityName: 'Fotballtennis onsdag',
      );

      final json = original.toJson();
      final decoded = MiniActivityTeamHistory.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityTeamHistory(
        id: 'history-2',
        userId: 'user-2',
        miniActivityId: 'mini-2',
        miniTeamId: 'team-b',
        // teamName, placement, userName, miniActivityName are null
        pointsEarned: 5,
        wasWinner: false,
        recordedAt: DateTime.parse('2024-01-20T19:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MiniActivityTeamHistory.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
