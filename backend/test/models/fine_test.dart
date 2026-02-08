import 'package:test/test.dart';
import 'package:core_idrett_backend/models/fine.dart';

void main() {
  group('FineRule', () {
    test('roundtrip med alle felt populert', () {
      final original = FineRule(
        id: 'rule-1',
        teamId: 'team-1',
        name: 'For sent til trening',
        amount: 50.0,
        description: 'Mer enn 5 minutter for sent',
        active: true,
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = FineRule.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = FineRule(
        id: 'rule-2',
        teamId: 'team-2',
        name: 'Glemt drakt',
        amount: 100.0,
        // description is null
        active: true,
        createdAt: DateTime.parse('2024-02-15T14:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = FineRule.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('Fine', () {
    test('roundtrip med alle felt populert', () {
      final appeal = FineAppeal(
        id: 'appeal-1',
        fineId: 'fine-1',
        reason: 'Jeg var ikke for sent, klokka var feil',
        status: 'pending',
        extraFee: null,
        decidedBy: null,
        createdAt: DateTime.parse('2024-03-12T15:00:00.000Z'),
        decidedAt: null,
        fine: null,
      );

      final original = Fine(
        id: 'fine-1',
        ruleId: 'rule-1',
        teamId: 'team-1',
        offenderId: 'user-1',
        reporterId: 'user-2',
        approvedBy: 'user-3',
        status: 'appealed',
        amount: 50.0,
        description: 'Kom 10 minutter for sent',
        evidenceUrl: 'https://example.com/evidence/1.jpg',
        isGameDay: false,
        createdAt: DateTime.parse('2024-03-10T18:30:00.000Z'),
        resolvedAt: DateTime.parse('2024-03-12T10:00:00.000Z'),
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
        // ruleId is null (manual fine)
        teamId: 'team-2',
        offenderId: 'user-4',
        reporterId: 'user-5',
        // approvedBy is null
        status: 'pending',
        amount: 75.0,
        // description is null
        // evidenceUrl is null
        isGameDay: true,
        createdAt: DateTime.parse('2024-03-15T12:00:00.000Z'),
        // resolvedAt is null
        // offenderName is null
        // offenderAvatarUrl is null
        // reporterName is null
        // ruleName is null
        // appeal is null
        // paidAmount is null
      );

      final json = original.toJson();
      final decoded = Fine.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('FineAppeal', () {
    test('roundtrip med alle felt populert', () {
      final original = FineAppeal(
        id: 'appeal-2',
        fineId: 'fine-3',
        reason: 'Jeg hadde gyldig grunn til å være forsinket',
        status: 'rejected',
        extraFee: 25.0,
        decidedBy: 'user-admin',
        createdAt: DateTime.parse('2024-03-16T10:00:00.000Z'),
        decidedAt: DateTime.parse('2024-03-17T14:30:00.000Z'),
        fine: null,
      );

      final json = original.toJson();
      final decoded = FineAppeal.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = FineAppeal(
        id: 'appeal-3',
        fineId: 'fine-4',
        reason: 'Dette var en feil',
        status: 'pending',
        // extraFee is null
        // decidedBy is null
        createdAt: DateTime.parse('2024-03-18T11:00:00.000Z'),
        // decidedAt is null
        // fine is null
      );

      final json = original.toJson();
      final decoded = FineAppeal.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('FinePayment', () {
    test('roundtrip med alle felt populert', () {
      final original = FinePayment(
        id: 'payment-1',
        fineId: 'fine-1',
        amount: 50.0,
        paidAt: DateTime.parse('2024-03-20T15:00:00.000Z'),
        registeredBy: 'user-admin',
      );

      final json = original.toJson();
      final decoded = FinePayment.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med delvis betaling', () {
      final original = FinePayment(
        id: 'payment-2',
        fineId: 'fine-2',
        amount: 25.0,
        paidAt: DateTime.parse('2024-03-21T10:30:00.000Z'),
        registeredBy: 'user-admin',
      );

      final json = original.toJson();
      final decoded = FinePayment.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('TeamFinesSummary', () {
    test('toJson inkluderer alle felt', () {
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

      expect(json['team_id'], equals('team-1'));
      expect(json['total_fines'], equals(500.0));
      expect(json['total_paid'], equals(300.0));
      expect(json['total_pending'], equals(200.0));
      expect(json['outstanding_balance'], equals(200.0));
      expect(json['fine_count'], equals(10));
      expect(json['pending_count'], equals(4));
      expect(json['paid_count'], equals(6));
    });

    test('outstandingBalance beregnes korrekt', () {
      final summary = TeamFinesSummary(
        teamId: 'team-1',
        totalFines: 1000.0,
        totalPaid: 750.0,
        totalPending: 250.0,
        fineCount: 5,
        pendingCount: 1,
        paidCount: 4,
      );

      expect(summary.outstandingBalance, equals(250.0));
    });
  });

  group('UserFinesSummary', () {
    test('toJson inkluderer alle felt', () {
      final original = UserFinesSummary(
        userId: 'user-1',
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        totalFines: 200.0,
        totalPaid: 150.0,
        fineCount: 4,
      );

      final json = original.toJson();

      expect(json['user_id'], equals('user-1'));
      expect(json['user_name'], equals('Ola Nordmann'));
      expect(json['user_avatar_url'], equals('https://example.com/avatars/ola.jpg'));
      expect(json['total_fines'], equals(200.0));
      expect(json['total_paid'], equals(150.0));
      expect(json['outstanding_balance'], equals(50.0));
      expect(json['fine_count'], equals(4));
    });

    test('toJson med valgfrie felt null', () {
      final original = UserFinesSummary(
        userId: 'user-2',
        userName: 'Kari Hansen',
        // userAvatarUrl is null
        totalFines: 100.0,
        totalPaid: 50.0,
        fineCount: 2,
      );

      final json = original.toJson();

      expect(json['user_id'], equals('user-2'));
      expect(json['user_name'], equals('Kari Hansen'));
      expect(json['user_avatar_url'], isNull);
      expect(json['outstanding_balance'], equals(50.0));
    });

    test('outstandingBalance beregnes korrekt', () {
      final summary = UserFinesSummary(
        userId: 'user-1',
        userName: 'Test User',
        userAvatarUrl: null,
        totalFines: 300.0,
        totalPaid: 200.0,
        fineCount: 3,
      );

      expect(summary.outstandingBalance, equals(100.0));
    });
  });
}
