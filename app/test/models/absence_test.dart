import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/absence.dart';

void main() {
  group('AbsenceCategory', () {
    test('roundtrip med alle felt populert', () {
      final original = AbsenceCategory(
        id: 'cat-1',
        teamId: 'team-1',
        name: 'Sykdom',
        requiresApproval: true,
        countsAsValid: true,
        sortOrder: 1,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AbsenceCategory.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // AbsenceCategory har default-verdier, ikke nullable felt
      final original = AbsenceCategory(
        id: 'cat-2',
        teamId: 'team-1',
        name: 'Jobb',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AbsenceCategory.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('AbsenceRecord', () {
    test('roundtrip med alle felt populert', () {
      final original = AbsenceRecord(
        id: 'record-1',
        userId: 'user-1',
        instanceId: 'instance-1',
        categoryId: 'cat-1',
        reason: 'Influensa',
        status: AbsenceStatus.approved,
        approvedBy: 'user-admin',
        approvedAt: DateTime.parse('2024-01-15T11:00:00.000Z'),
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        categoryName: 'Sykdom',
        categoryCountsAsValid: true,
        activityName: 'Onsdagstrening',
        activityDate: DateTime.parse('2024-01-17T18:00:00.000Z'),
        approvedByName: 'Kari Hansen',
      );

      final json = original.toJson();
      final decoded = AbsenceRecord.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AbsenceRecord(
        id: 'record-2',
        userId: 'user-2',
        instanceId: 'instance-2',
        status: AbsenceStatus.pending,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AbsenceRecord.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('AbsenceSummary', () {
    test('roundtrip med alle felt populert', () {
      final pendingAbsences = [
        AbsenceRecord(
          id: 'record-1',
          userId: 'user-1',
          instanceId: 'instance-1',
          status: AbsenceStatus.pending,
          createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
          userName: 'Ola Nordmann',
        ),
        AbsenceRecord(
          id: 'record-2',
          userId: 'user-2',
          instanceId: 'instance-2',
          status: AbsenceStatus.pending,
          createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          userName: 'Kari Hansen',
        ),
      ];

      final original = AbsenceSummary(
        teamId: 'team-1',
        pendingCount: 2,
        approvedCount: 5,
        rejectedCount: 1,
        pendingAbsences: pendingAbsences,
      );

      final json = original.toJson();
      final decoded = AbsenceSummary.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AbsenceSummary(
        teamId: 'team-2',
      );

      final json = original.toJson();
      final decoded = AbsenceSummary.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
