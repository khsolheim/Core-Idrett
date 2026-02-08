import 'package:test/test.dart';
import 'package:core_idrett_backend/models/achievement_user.dart';
import 'package:core_idrett_backend/models/achievement_definition.dart';

void main() {
  group('UserAchievement', () {
    test('roundtrip med alle felt populert', () {
      final original = UserAchievement(
        id: 'user-achievement-1',
        userId: 'user-1',
        achievementId: 'achievement-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        pointsAwarded: 50,
        awardedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        timesEarned: 2,
        lastEarnedAt: DateTime.parse('2024-03-20T14:00:00.000Z'),
        triggerReference: {'type': 'points', 'value': 100},
        achievementCode: 'POINTS_100',
        achievementName: '100 Poeng',
        achievementDescription: 'Oppnå 100 poeng',
        achievementIcon: 'trophy',
        achievementTier: AchievementTier.gold,
        achievementCategory: AchievementCategory.milestone,
        userName: 'Ola Nordmann',
        teamName: 'Vålerenga',
      );

      final json = original.toJson();
      final decoded = UserAchievement.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = UserAchievement(
        id: 'user-achievement-2',
        userId: 'user-2',
        achievementId: 'achievement-2',
        teamId: 'team-2',
        // seasonId is null
        pointsAwarded: 0,
        awardedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
        timesEarned: 1,
        lastEarnedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
        // triggerReference is null
        // achievementCode is null
        // achievementName is null
        // achievementDescription is null
        // achievementIcon is null
        // achievementTier is null
        // achievementCategory is null
        // userName is null
        // teamName is null
      );

      final json = original.toJson();
      final decoded = UserAchievement.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('AchievementProgress', () {
    test('roundtrip med alle felt populert', () {
      final original = AchievementProgress(
        id: 'progress-1',
        userId: 'user-1',
        achievementId: 'achievement-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        currentValue: 75,
        targetValue: 100,
        progressPercent: 75.0,
        lastContributionAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-15T18:00:00.000Z'),
        achievementCode: 'POINTS_100',
        achievementName: '100 Poeng',
        achievementIcon: 'trophy',
        achievementTier: AchievementTier.gold,
      );

      final json = original.toJson();
      final decoded = AchievementProgress.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AchievementProgress(
        id: 'progress-2',
        userId: 'user-2',
        achievementId: 'achievement-2',
        teamId: 'team-2',
        // seasonId is null
        currentValue: 0,
        targetValue: 50,
        progressPercent: 0.0,
        // lastContributionAt is null
        updatedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
        // achievementCode is null
        // achievementName is null
        // achievementIcon is null
        // achievementTier is null
      );

      final json = original.toJson();
      final decoded = AchievementProgress.fromJson(json);

      expect(decoded, equals(original));
    });

    test('isComplete returnerer true når currentValue >= targetValue', () {
      final complete = AchievementProgress(
        id: 'progress-3',
        userId: 'user-1',
        achievementId: 'achievement-1',
        teamId: 'team-1',
        currentValue: 100,
        targetValue: 100,
        progressPercent: 100.0,
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(complete.isComplete, isTrue);
    });

    test('isNearComplete returnerer true når progressPercent >= 75', () {
      final nearComplete = AchievementProgress(
        id: 'progress-4',
        userId: 'user-1',
        achievementId: 'achievement-1',
        teamId: 'team-1',
        currentValue: 80,
        targetValue: 100,
        progressPercent: 80.0,
        updatedAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
      );

      expect(nearComplete.isNearComplete, isTrue);
    });
  });
}
