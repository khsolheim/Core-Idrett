import 'package:test/test.dart';
import 'package:core_idrett_backend/models/achievement_definition.dart';

void main() {
  group('AchievementCriteria', () {
    test('roundtrip med alle felt populert', () {
      final original = AchievementCriteria(
        type: AchievementCriteriaType.attendanceStreak,
        threshold: 10,
        period: 'season',
      );

      final json = original.toJson();
      final decoded = AchievementCriteria.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AchievementCriteria(
        type: AchievementCriteriaType.firstAttendance,
        // threshold is null
        // period is null
      );

      final json = original.toJson();
      final decoded = AchievementCriteria.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('AchievementDefinition', () {
    test('roundtrip med alle felt populert', () {
      final criteria = AchievementCriteria(
        type: AchievementCriteriaType.totalPoints,
        threshold: 100,
        period: 'season',
      );

      final original = AchievementDefinition(
        id: 'achievement-1',
        teamId: 'team-1',
        code: 'POINTS_100',
        name: '100 Poeng',
        description: 'Oppnå 100 poeng i en sesong',
        icon: 'trophy',
        color: '#FFD700',
        tier: AchievementTier.gold,
        category: AchievementCategory.milestone,
        criteria: criteria,
        bonusPoints: 50,
        isActive: true,
        isSecret: false,
        isRepeatable: true,
        repeatCooldownDays: 30,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-15T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AchievementDefinition.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final criteria = AchievementCriteria(
        type: AchievementCriteriaType.firstAttendance,
      );

      final original = AchievementDefinition(
        id: 'achievement-2',
        // teamId is null (global)
        code: 'FIRST_ATTEND',
        name: 'Første Trening',
        // description is null
        // icon is null
        // color is null
        tier: AchievementTier.bronze,
        category: AchievementCategory.attendance,
        criteria: criteria,
        bonusPoints: 0,
        isActive: true,
        isSecret: false,
        isRepeatable: false,
        // repeatCooldownDays is null
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AchievementDefinition.fromJson(json);

      expect(decoded, equals(original));
    });

    test('isGlobal returnerer true når teamId er null', () {
      final criteria = AchievementCriteria(
        type: AchievementCriteriaType.firstAttendance,
      );

      final global = AchievementDefinition(
        id: 'achievement-3',
        teamId: null,
        code: 'GLOBAL',
        name: 'Global Achievement',
        category: AchievementCategory.special,
        criteria: criteria,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      expect(global.isGlobal, isTrue);
    });
  });
}
