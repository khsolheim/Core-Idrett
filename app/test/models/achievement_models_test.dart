import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/achievement_models.dart';
import 'package:core_idrett/data/models/achievement_enums.dart';

void main() {
  group('AchievementDefinition', () {
    test('roundtrip med alle felt populert', () {
      final criteria = AchievementCriteria(
        type: AchievementCriteriaType.attendanceStreak,
        threshold: 10,
        percentage: 90.0,
        activityType: 'training',
        timeframe: 'monthly',
        customData: {'bonus': true},
      );

      final original = AchievementDefinition(
        id: 'achievement-1',
        teamId: 'team-1',
        code: 'STREAK_10',
        name: 'Ti på rad',
        description: 'Deltatt på 10 treninger på rad',
        icon: '🔥',
        color: '#FF5722',
        tier: AchievementTier.gold,
        category: AchievementCategory.streak,
        criteria: criteria,
        bonusPoints: 50,
        isActive: true,
        isSecret: false,
        isRepeatable: true,
        repeatCooldownDays: 30,
        createdAt: DateTime.parse('2024-01-01T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AchievementDefinition.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final criteria = AchievementCriteria(
        type: AchievementCriteriaType.custom,
      );

      final original = AchievementDefinition(
        id: 'achievement-2',
        // teamId is null (global achievement)
        code: 'FIRST_WIN',
        name: 'Første seier',
        // description, icon, color, repeatCooldownDays are null
        tier: AchievementTier.bronze,
        category: AchievementCategory.milestone,
        criteria: criteria,
        bonusPoints: 10,
        isActive: true,
        isSecret: false,
        isRepeatable: false,
        createdAt: DateTime.parse('2024-01-01T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AchievementDefinition.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('UserAchievement', () {
    test('roundtrip med alle felt populert', () {
      final definition = AchievementDefinition(
        id: 'achievement-1',
        code: 'PERFECT_MONTH',
        name: 'Perfekt måned',
        tier: AchievementTier.silver,
        category: AchievementCategory.attendance,
        criteria: AchievementCriteria(type: AchievementCriteriaType.perfectAttendance),
        createdAt: DateTime.parse('2024-01-01T10:00:00.000Z'),
      );

      final original = UserAchievement(
        id: 'user-achievement-1',
        userId: 'user-1',
        achievementId: 'achievement-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        pointsAwarded: 25,
        repeatCount: 2,
        triggerReference: {'month': 'january', 'year': 2024},
        awardedAt: DateTime.parse('2024-01-31T20:00:00.000Z'),
        definition: definition,
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/ola.jpg',
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
        // seasonId, repeatCount, triggerReference, definition, userName, userAvatarUrl are null
        pointsAwarded: 10,
        awardedAt: DateTime.parse('2024-02-15T18:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = UserAchievement.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('AchievementProgress', () {
    test('roundtrip med alle felt populert', () {
      final definition = AchievementDefinition(
        id: 'achievement-1',
        code: '100_POINTS',
        name: '100 poeng',
        tier: AchievementTier.gold,
        category: AchievementCategory.milestone,
        criteria: AchievementCriteria(type: AchievementCriteriaType.pointsTotal, threshold: 100),
        createdAt: DateTime.parse('2024-01-01T10:00:00.000Z'),
      );

      final original = AchievementProgress(
        id: 'progress-1',
        userId: 'user-1',
        achievementId: 'achievement-1',
        teamId: 'team-1',
        seasonId: 'season-1',
        currentValue: 75,
        targetValue: 100,
        updatedAt: DateTime.parse('2024-01-20T16:00:00.000Z'),
        definition: definition,
        userName: 'Kari Hansen',
      );

      final json = original.toJson();
      final decoded = AchievementProgress.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AchievementProgress(
        id: 'progress-2',
        // userId is null (team-wide progress)
        achievementId: 'achievement-2',
        teamId: 'team-2',
        // seasonId, targetValue, definition, userName are null
        currentValue: 50,
        updatedAt: DateTime.parse('2024-02-01T12:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AchievementProgress.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('UserAchievementsSummary', () {
    test('roundtrip med alle felt populert', () {
      final recentAchievements = [
        UserAchievement(
          id: 'user-achievement-1',
          userId: 'user-1',
          achievementId: 'achievement-1',
          teamId: 'team-1',
          pointsAwarded: 25,
          awardedAt: DateTime.parse('2024-01-20T15:00:00.000Z'),
        ),
      ];

      final inProgress = [
        AchievementProgress(
          id: 'progress-1',
          achievementId: 'achievement-2',
          teamId: 'team-1',
          currentValue: 80,
          targetValue: 100,
          updatedAt: DateTime.parse('2024-01-25T10:00:00.000Z'),
        ),
      ];

      final original = UserAchievementsSummary(
        userId: 'user-1',
        totalAchievements: 15,
        bronzeCount: 5,
        silverCount: 6,
        goldCount: 3,
        platinumCount: 1,
        totalBonusPoints: 350,
        recentAchievements: recentAchievements,
        inProgress: inProgress,
      );

      final json = original.toJson();
      final decoded = UserAchievementsSummary.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = UserAchievementsSummary(
        userId: 'user-2',
        totalAchievements: 0,
        bronzeCount: 0,
        silverCount: 0,
        goldCount: 0,
        platinumCount: 0,
        totalBonusPoints: 0,
        // recentAchievements and inProgress default to empty lists
      );

      final json = original.toJson();
      final decoded = UserAchievementsSummary.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
