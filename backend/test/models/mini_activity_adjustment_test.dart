import 'package:test/test.dart';
import 'package:core_idrett_backend/models/mini_activity_adjustment.dart';

void main() {
  group('MiniActivityAdjustment', () {
    test('roundtrip med team adjustment', () {
      final original = MiniActivityAdjustment(
        id: 'adjustment-1',
        miniActivityId: 'mini-1',
        teamId: 'mini-team-1',
        userId: null,
        points: 5,
        reason: 'Bonus for kreativitet',
        createdBy: 'user-admin',
        createdAt: DateTime.parse('2024-03-15T16:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MiniActivityAdjustment.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.isTeamAdjustment, isTrue);
      expect(decoded.isBonus, isTrue);
    });

    test('roundtrip med user adjustment', () {
      final original = MiniActivityAdjustment(
        id: 'adjustment-2',
        miniActivityId: 'mini-2',
        teamId: null,
        userId: 'user-1',
        points: -3,
        reason: 'Straff for juks',
        createdBy: 'user-admin',
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MiniActivityAdjustment.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.isUserAdjustment, isTrue);
      expect(decoded.isPenalty, isTrue);
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = MiniActivityAdjustment(
        id: 'adjustment-3',
        miniActivityId: 'mini-3',
        // teamId is null
        // userId is null
        points: 0,
        // reason is null
        createdBy: 'user-admin',
        createdAt: DateTime.parse('2024-03-17T10:00:00.000Z'),
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
        handicapValue: 0.85,
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-20T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MiniActivityHandicap.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med lavt handicap', () {
      final original = MiniActivityHandicap(
        id: 'handicap-2',
        miniActivityId: 'mini-2',
        userId: 'user-2',
        handicapValue: 1.2,
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = MiniActivityHandicap.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
