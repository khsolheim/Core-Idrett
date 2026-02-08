import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/fine.dart';

void main() {
  group('FineRule', () {
    test('roundtrip med alle felt populert', () {
      final original = FineRule(
        id: 'rule-1',
        teamId: 'team-1',
        name: 'For sent til trening',
        amount: 50.0,
        description: 'Gjelder ved ankomst mer enn 5 minutter for sent',
        active: true,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = FineRule.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = FineRule(
        id: 'rule-2',
        teamId: 'team-1',
        name: 'Glemt utstyr',
        amount: 30.0,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = FineRule.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('FineAppeal', () {
    test('roundtrip med alle felt populert', () {
      final fine = Fine(
        id: 'fine-1',
        teamId: 'team-1',
        offenderId: 'user-1',
        reporterId: 'user-2',
        approvedBy: 'user-admin',
        status: 'approved',
        amount: 50.0,
        description: 'For sent til kamp',
        evidenceUrl: 'https://example.com/evidence/photo1.jpg',
        isGameDay: true,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        resolvedAt: DateTime.parse('2024-01-15T11:00:00.000Z'),
        offenderName: 'Ola Nordmann',
        reporterName: 'Kari Hansen',
      );

      final original = FineAppeal(
        id: 'appeal-1',
        fineId: 'fine-1',
        reason: 'Bussen var forsinket',
        status: 'accepted',
        extraFee: 25.0,
        decidedBy: 'user-admin',
        createdAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
        decidedAt: DateTime.parse('2024-01-15T13:00:00.000Z'),
        fine: fine,
      );

      final json = original.toJson();
      final decoded = FineAppeal.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = FineAppeal(
        id: 'appeal-2',
        fineId: 'fine-2',
        reason: 'Syk',
        status: 'pending',
        createdAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = FineAppeal.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('Fine', () {
    test('roundtrip med alle felt populert', () {
      final appeal = FineAppeal(
        id: 'appeal-1',
        fineId: 'fine-1',
        reason: 'Hadde gyldig grunn',
        status: 'pending',
        createdAt: DateTime.parse('2024-01-15T12:00:00.000Z'),
      );

      final original = Fine(
        id: 'fine-1',
        ruleId: 'rule-1',
        teamId: 'team-1',
        offenderId: 'user-1',
        reporterId: 'user-2',
        approvedBy: 'user-admin',
        status: 'appealed',
        amount: 50.0,
        description: 'Kom 10 minutter for sent',
        evidenceUrl: 'https://example.com/evidence/photo1.jpg',
        isGameDay: true,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        resolvedAt: DateTime.parse('2024-01-15T11:00:00.000Z'),
        offenderName: 'Ola Nordmann',
        offenderAvatarUrl: 'https://example.com/avatars/ola.jpg',
        reporterName: 'Kari Hansen',
        ruleName: 'For sent til trening',
        appeal: appeal,
        paidAmount: 25.0,
      );

      final json = original.toJson();
      final decoded = Fine.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Fine(
        id: 'fine-2',
        teamId: 'team-1',
        offenderId: 'user-1',
        reporterId: 'user-2',
        status: 'pending',
        amount: 30.0,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Fine.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('FinePayment', () {
    test('roundtrip med alle felt populert', () {
      final original = FinePayment(
        id: 'payment-1',
        fineId: 'fine-1',
        amount: 50.0,
        paidAt: DateTime.parse('2024-01-15T14:00:00.000Z'),
        registeredBy: 'user-admin',
      );

      final json = original.toJson();
      final decoded = FinePayment.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // FinePayment har ingen valgfrie felt
      final original = FinePayment(
        id: 'payment-2',
        fineId: 'fine-2',
        amount: 25.0,
        paidAt: DateTime.parse('2024-01-15T14:00:00.000Z'),
        registeredBy: 'user-admin',
      );

      final json = original.toJson();
      final decoded = FinePayment.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TeamFinesSummary', () {
    test('roundtrip med alle felt populert', () {
      final original = TeamFinesSummary(
        teamId: 'team-1',
        totalFines: 500.0,
        totalPaid: 300.0,
        totalPending: 200.0,
        fineCount: 10,
        pendingCount: 4,
        paidCount: 6,
      );

      final json = original.toJson();
      final decoded = TeamFinesSummary.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // TeamFinesSummary har default-verdier, ikke nullable felt
      final original = TeamFinesSummary(
        teamId: 'team-2',
      );

      final json = original.toJson();
      final decoded = TeamFinesSummary.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('UserFinesSummary', () {
    test('roundtrip med alle felt populert', () {
      final original = UserFinesSummary(
        userId: 'user-1',
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        totalFines: 150.0,
        totalPaid: 100.0,
        fineCount: 3,
      );

      final json = original.toJson();
      final decoded = UserFinesSummary.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = UserFinesSummary(
        userId: 'user-2',
        userName: 'Kari Hansen',
      );

      final json = original.toJson();
      final decoded = UserFinesSummary.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
