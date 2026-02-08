import 'package:test/test.dart';
import 'package:core_idrett_backend/models/absence.dart';

void main() {
  group('AbsenceCategory', () {
    test('roundtrip med alle felt populert', () {
      final original = AbsenceCategory(
        id: 'cat-1',
        teamId: 'team-1',
        name: 'Syk',
        description: 'Sykmelding eller forkjølelse',
        requiresApproval: false,
        countsAsValid: true,
        isActive: true,
        sortOrder: 1,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AbsenceCategory.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AbsenceCategory(
        id: 'cat-2',
        teamId: 'team-2',
        name: 'Ferie',
        // description is null
        requiresApproval: true,
        countsAsValid: true,
        isActive: true,
        sortOrder: 2,
        createdAt: DateTime.parse('2024-02-15T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = AbsenceCategory.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('AbsenceStatus', () {
    test('value returnerer korrekt string', () {
      expect(AbsenceStatus.pending.value, equals('pending'));
      expect(AbsenceStatus.approved.value, equals('approved'));
      expect(AbsenceStatus.rejected.value, equals('rejected'));
      expect(AbsenceStatus.autoApproved.value, equals('auto_approved'));
    });

    test('fromString konverterer korrekt', () {
      expect(AbsenceStatus.fromString('pending'), equals(AbsenceStatus.pending));
      expect(AbsenceStatus.fromString('approved'), equals(AbsenceStatus.approved));
      expect(AbsenceStatus.fromString('rejected'), equals(AbsenceStatus.rejected));
      expect(AbsenceStatus.fromString('auto_approved'), equals(AbsenceStatus.autoApproved));
      expect(AbsenceStatus.fromString('unknown'), equals(AbsenceStatus.pending));
    });

    test('displayName returnerer norske navn', () {
      expect(AbsenceStatus.pending.displayName, equals('Venter'));
      expect(AbsenceStatus.approved.displayName, equals('Godkjent'));
      expect(AbsenceStatus.rejected.displayName, equals('Avvist'));
      expect(AbsenceStatus.autoApproved.displayName, equals('Automatisk godkjent'));
    });

    test('isApproved sjekker godkjent status', () {
      expect(AbsenceStatus.approved.isApproved, isTrue);
      expect(AbsenceStatus.autoApproved.isApproved, isTrue);
      expect(AbsenceStatus.pending.isApproved, isFalse);
      expect(AbsenceStatus.rejected.isApproved, isFalse);
    });
  });

  group('AbsenceRecord', () {
    test('roundtrip med alle felt populert', () {
      final original = AbsenceRecord(
        id: 'absence-1',
        userId: 'user-1',
        instanceId: 'instance-1',
        categoryId: 'cat-1',
        reason: 'Har influensa, legeerklæring vedlagt',
        status: AbsenceStatus.approved,
        approvedBy: 'user-admin',
        approvedAt: DateTime.parse('2024-03-11T10:00:00.000Z'),
        rejectionReason: null,
        createdAt: DateTime.parse('2024-03-10T18:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-11T10:00:00.000Z'),
        userName: 'Ola Nordmann',
        categoryName: 'Syk',
        countsAsValid: true,
        approverName: 'Kari Hansen',
        activityTitle: 'Tirsdagstrening',
        activityDate: DateTime(2024, 3, 12),
        activityType: 'training',
        teamId: 'team-1',
      );

      final json = original.toJson();
      final decoded = AbsenceRecord.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = AbsenceRecord(
        id: 'absence-2',
        userId: 'user-2',
        instanceId: 'instance-2',
        // categoryId is null
        // reason is null
        status: AbsenceStatus.pending,
        // approvedBy is null
        // approvedAt is null
        // rejectionReason is null
        createdAt: DateTime.parse('2024-03-15T12:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-15T12:00:00.000Z'),
        // userName is null
        // categoryName is null
        // countsAsValid is null
        // approverName is null
        // activityTitle is null
        // activityDate is null
        // activityType is null
        // teamId is null
      );

      final json = original.toJson();
      final decoded = AbsenceRecord.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med avvist fravær', () {
      final original = AbsenceRecord(
        id: 'absence-3',
        userId: 'user-3',
        instanceId: 'instance-3',
        categoryId: 'cat-2',
        reason: 'Må jobbe',
        status: AbsenceStatus.rejected,
        approvedBy: 'user-admin',
        approvedAt: null,
        rejectionReason: 'Ikke godkjent grunn for fravær',
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-17T14:00:00.000Z'),
        userName: 'Ole Olsen',
        categoryName: 'Arbeid',
        countsAsValid: false,
        approverName: 'Kari Hansen',
        activityTitle: 'Søndagskamp',
        activityDate: DateTime(2024, 3, 20),
        activityType: 'match',
        teamId: 'team-1',
      );

      final json = original.toJson();
      final decoded = AbsenceRecord.fromJson(json);

      expect(decoded, equals(original));
    });

    test('isPending, isApproved, isRejected fungerer korrekt', () {
      final pending = AbsenceRecord(
        id: 'absence-4',
        userId: 'user-1',
        instanceId: 'instance-1',
        status: AbsenceStatus.pending,
        createdAt: DateTime.parse('2024-03-18T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-18T10:00:00.000Z'),
      );

      final approved = AbsenceRecord(
        id: 'absence-5',
        userId: 'user-2',
        instanceId: 'instance-2',
        status: AbsenceStatus.approved,
        createdAt: DateTime.parse('2024-03-18T11:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-18T11:00:00.000Z'),
      );

      final rejected = AbsenceRecord(
        id: 'absence-6',
        userId: 'user-3',
        instanceId: 'instance-3',
        status: AbsenceStatus.rejected,
        createdAt: DateTime.parse('2024-03-18T12:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-18T12:00:00.000Z'),
      );

      expect(pending.isPending, isTrue);
      expect(pending.isApproved, isFalse);
      expect(pending.isRejected, isFalse);

      expect(approved.isPending, isFalse);
      expect(approved.isApproved, isTrue);
      expect(approved.isRejected, isFalse);

      expect(rejected.isPending, isFalse);
      expect(rejected.isApproved, isFalse);
      expect(rejected.isRejected, isTrue);
    });
  });
}
