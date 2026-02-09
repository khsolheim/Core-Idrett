import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core_idrett_backend/db/database.dart';
import 'package:core_idrett_backend/db/supabase_client.dart';
import 'package:core_idrett_backend/models/fine.dart';
import 'package:core_idrett_backend/services/fine/fine_crud_service.dart';
import 'package:core_idrett_backend/services/fine/fine_summary_service.dart';
import 'package:core_idrett_backend/services/user_service.dart';
import 'package:core_idrett_backend/services/team_service.dart';

class MockDatabase extends Mock implements Database {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockUserService extends Mock implements UserService {}
class MockTeamService extends Mock implements TeamService {}

void main() {
  late MockDatabase db;
  late MockSupabaseClient client;
  late MockUserService userService;
  late MockTeamService teamService;

  setUp(() {
    db = MockDatabase();
    client = MockSupabaseClient();
    userService = MockUserService();
    teamService = MockTeamService();

    when(() => db.client).thenReturn(client);
  });

  group('FineCrudService', () {
    late FineCrudService service;

    setUp(() {
      service = FineCrudService(db, userService);
    });

    group('recordPayment', () {
      test('oppretter betaling og returnerer FinePayment', () async {
        when(() => client.insert('fine_payments', any()))
          .thenAnswer((_) async => [
            {
              'id': 'payment-1',
              'fine_id': 'fine-1',
              'amount': 50.0,
              'paid_at': '2026-02-09T10:00:00Z',
              'registered_by': 'user-1',
            }
          ]);

        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 100.0}
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 50.0}
        ]);

        final payment = await service.recordPayment(
          fineId: 'fine-1',
          amount: 50.0,
          registeredBy: 'user-1',
        );

        expect(payment.id, equals('payment-1'));
        expect(payment.amount, equals(50.0));
        verify(() => client.insert('fine_payments', any())).called(1);
      });

      test('oppdaterer fine status til paid når totalt betalt >= fine amount', () async {
        when(() => client.insert('fine_payments', any()))
          .thenAnswer((_) async => [
            {
              'id': 'payment-1',
              'fine_id': 'fine-1',
              'amount': 100.0,
              'paid_at': '2026-02-09T10:00:00Z',
              'registered_by': 'user-1',
            }
          ]);

        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 100.0}
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 100.0}
        ]);

        when(() => client.update(
          'fines',
          {'status': 'paid'},
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        await service.recordPayment(
          fineId: 'fine-1',
          amount: 100.0,
          registeredBy: 'user-1',
        );

        verify(() => client.update(
          'fines',
          {'status': 'paid'},
          filters: any(named: 'filters'),
        )).called(1);
      });

      test('oppdaterer IKKE status når delvis betaling (totalt < amount)', () async {
        when(() => client.insert('fine_payments', any()))
          .thenAnswer((_) async => [
            {
              'id': 'payment-1',
              'fine_id': 'fine-1',
              'amount': 30.0,
              'paid_at': '2026-02-09T10:00:00Z',
              'registered_by': 'user-1',
            }
          ]);

        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 100.0}
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 30.0}
        ]);

        await service.recordPayment(
          fineId: 'fine-1',
          amount: 30.0,
          registeredBy: 'user-1',
        );

        verifyNever(() => client.update(
          'fines',
          {'status': 'paid'},
          filters: any(named: 'filters'),
        ));
      });

      test('flere delvise betalinger → status oppdateres når totalt >= amount', () async {
        // First payment: 30kr
        when(() => client.insert('fine_payments', any()))
          .thenAnswer((_) async => [
            {
              'id': 'payment-1',
              'fine_id': 'fine-1',
              'amount': 30.0,
              'paid_at': '2026-02-09T10:00:00Z',
              'registered_by': 'user-1',
            }
          ]);

        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 100.0}
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 30.0}
        ]);

        await service.recordPayment(
          fineId: 'fine-1',
          amount: 30.0,
          registeredBy: 'user-1',
        );

        verifyNever(() => client.update(
          'fines',
          {'status': 'paid'},
          filters: any(named: 'filters'),
        ));

        // Second payment: 40kr (total: 70kr)
        when(() => client.insert('fine_payments', any()))
          .thenAnswer((_) async => [
            {
              'id': 'payment-2',
              'fine_id': 'fine-1',
              'amount': 40.0,
              'paid_at': '2026-02-09T10:00:00Z',
              'registered_by': 'user-1',
            }
          ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 30.0},
          {'amount': 40.0},
        ]);

        await service.recordPayment(
          fineId: 'fine-1',
          amount: 40.0,
          registeredBy: 'user-1',
        );

        verifyNever(() => client.update(
          'fines',
          {'status': 'paid'},
          filters: any(named: 'filters'),
        ));

        // Third payment: 30kr (total: 100kr, fully paid)
        when(() => client.insert('fine_payments', any()))
          .thenAnswer((_) async => [
            {
              'id': 'payment-3',
              'fine_id': 'fine-1',
              'amount': 30.0,
              'paid_at': '2026-02-09T10:00:00Z',
              'registered_by': 'user-1',
            }
          ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 30.0},
          {'amount': 40.0},
          {'amount': 30.0},
        ]);

        when(() => client.update(
          'fines',
          {'status': 'paid'},
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        await service.recordPayment(
          fineId: 'fine-1',
          amount: 30.0,
          registeredBy: 'user-1',
        );

        verify(() => client.update(
          'fines',
          {'status': 'paid'},
          filters: any(named: 'filters'),
        )).called(1);
      });
    });

    group('approveFine', () {
      test('godkjenner pending fine → status blir approved', () async {
        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'status': 'pending'}
        ]);

        when(() => client.update(
          'fines',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => userService.getUserMap(any()))
          .thenAnswer((_) async => {});

        when(() => client.select(
          'fines',
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'fine-1',
            'team_id': 'team-1',
            'offender_id': 'user-1',
            'reporter_id': 'user-2',
            'status': 'approved',
            'amount': 50.0,
            'is_game_day': false,
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => []);

        when(() => client.select(
          'fine_appeals',
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => []);

        final fine = await service.approveFine('fine-1', 'admin-1');

        expect(fine, isNotNull);
        final captured = verify(() => client.update(
          'fines',
          captureAny(),
          filters: any(named: 'filters'),
        )).captured;

        expect(captured.length, equals(1));
        final updateData = captured[0] as Map<String, dynamic>;
        expect(updateData['status'], equals('approved'));
        expect(updateData['approved_by'], equals('admin-1'));
        expect(updateData['resolved_at'], isNotNull);
      });

      test('returnerer null når fine ikke er pending', () async {
        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'status': 'approved'}
        ]);

        final fine = await service.approveFine('fine-1', 'admin-1');

        expect(fine, isNull);
      });
    });

    group('rejectFine', () {
      test('avviser pending fine → status blir rejected', () async {
        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'status': 'pending'}
        ]);

        when(() => client.update(
          'fines',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => userService.getUserMap(any()))
          .thenAnswer((_) async => {});

        when(() => client.select(
          'fines',
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'fine-1',
            'team_id': 'team-1',
            'offender_id': 'user-1',
            'reporter_id': 'user-2',
            'status': 'rejected',
            'amount': 50.0,
            'is_game_day': false,
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => []);

        when(() => client.select(
          'fine_appeals',
          filters: {'fine_id': 'eq.fine-1'},
        )).thenAnswer((_) async => []);

        final fine = await service.rejectFine('fine-1', 'admin-1');

        expect(fine, isNotNull);
        final captured = verify(() => client.update(
          'fines',
          captureAny(),
          filters: any(named: 'filters'),
        )).captured;

        expect(captured.length, equals(1));
        final updateData = captured[0] as Map<String, dynamic>;
        expect(updateData['status'], equals('rejected'));
        expect(updateData['approved_by'], equals('admin-1'));
        expect(updateData['resolved_at'], isNotNull);
      });

      test('returnerer null når fine ikke er pending', () async {
        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'status': 'approved'}
        ]);

        final fine = await service.rejectFine('fine-1', 'admin-1');

        expect(fine, isNull);
      });
    });

    group('createAppeal', () {
      test('oppretter klage for approved fine → fine status blir appealed', () async {
        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'status': 'approved'}
        ]);

        when(() => client.update(
          'fines',
          {'status': 'appealed'},
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        when(() => client.insert('fine_appeals', any()))
          .thenAnswer((_) async => [
            {
              'id': 'appeal-1',
              'fine_id': 'fine-1',
              'reason': 'Uenig i beløp',
              'status': 'pending',
              'created_at': '2026-02-09T10:00:00Z',
            }
          ]);

        final appeal = await service.createAppeal(
          fineId: 'fine-1',
          reason: 'Uenig i beløp',
        );

        expect(appeal, isNotNull);
        expect(appeal!.fineId, equals('fine-1'));
        verify(() => client.update(
          'fines',
          {'status': 'appealed'},
          filters: any(named: 'filters'),
        )).called(1);
      });

      test('returnerer null når fine ikke er approved', () async {
        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'status': 'pending'}
        ]);

        final appeal = await service.createAppeal(
          fineId: 'fine-1',
          reason: 'Uenig',
        );

        expect(appeal, isNull);
        verifyNever(() => client.insert('fine_appeals', any()));
      });
    });

    group('resolveAppeal', () {
      test('godkjent klage (accepted) → fine status blir rejected', () async {
        when(() => client.select(
          'fine_appeals',
          filters: {'id': 'eq.appeal-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'appeal-1',
            'fine_id': 'fine-1',
            'reason': 'Uenig',
            'status': 'pending',
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        when(() => client.update(
          'fine_appeals',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => [
          {
            'id': 'appeal-1',
            'fine_id': 'fine-1',
            'reason': 'Uenig',
            'status': 'accepted',
            'decided_by': 'admin-1',
            'decided_at': '2026-02-09T11:00:00Z',
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        when(() => client.update(
          'fines',
          {'status': 'rejected'},
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        final appeal = await service.resolveAppeal(
          appealId: 'appeal-1',
          decidedBy: 'admin-1',
          accepted: true,
        );

        expect(appeal, isNotNull);
        verify(() => client.update(
          'fines',
          {'status': 'rejected'},
          filters: any(named: 'filters'),
        )).called(1);
      });

      test('avvist klage (rejected) → fine status blir approved', () async {
        when(() => client.select(
          'fine_appeals',
          filters: {'id': 'eq.appeal-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'appeal-1',
            'fine_id': 'fine-1',
            'reason': 'Uenig',
            'status': 'pending',
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        when(() => client.update(
          'fine_appeals',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => [
          {
            'id': 'appeal-1',
            'fine_id': 'fine-1',
            'reason': 'Uenig',
            'status': 'rejected',
            'decided_by': 'admin-1',
            'decided_at': '2026-02-09T11:00:00Z',
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        when(() => client.update(
          'fines',
          {'status': 'approved'},
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        final appeal = await service.resolveAppeal(
          appealId: 'appeal-1',
          decidedBy: 'admin-1',
          accepted: false,
        );

        expect(appeal, isNotNull);
        verify(() => client.update(
          'fines',
          {'status': 'approved'},
          filters: any(named: 'filters'),
        )).called(1);
      });

      test('avvist klage med extraFee → fine amount øker med extraFee', () async {
        when(() => client.select(
          'fine_appeals',
          filters: {'id': 'eq.appeal-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'appeal-1',
            'fine_id': 'fine-1',
            'reason': 'Uenig',
            'status': 'pending',
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        when(() => client.update(
          'fine_appeals',
          any(),
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => [
          {
            'id': 'appeal-1',
            'fine_id': 'fine-1',
            'reason': 'Uenig',
            'status': 'rejected',
            'extra_fee': 25.0,
            'decided_by': 'admin-1',
            'decided_at': '2026-02-09T11:00:00Z',
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        when(() => client.select(
          'fines',
          select: any(named: 'select'),
          filters: {'id': 'eq.fine-1'},
        )).thenAnswer((_) async => [
          {'amount': 100.0}
        ]);

        when(() => client.update(
          'fines',
          {
            'status': 'approved',
            'amount': 125.0,
          },
          filters: any(named: 'filters'),
        )).thenAnswer((_) async => []);

        await service.resolveAppeal(
          appealId: 'appeal-1',
          decidedBy: 'admin-1',
          accepted: false,
          extraFee: 25.0,
        );

        verify(() => client.update(
          'fines',
          {
            'status': 'approved',
            'amount': 125.0,
          },
          filters: any(named: 'filters'),
        )).called(1);
      });

      test('returnerer null når appeal ikke er pending', () async {
        when(() => client.select(
          'fine_appeals',
          filters: {'id': 'eq.appeal-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'appeal-1',
            'fine_id': 'fine-1',
            'reason': 'Uenig',
            'status': 'accepted',
            'created_at': '2026-02-09T10:00:00Z',
          }
        ]);

        final appeal = await service.resolveAppeal(
          appealId: 'appeal-1',
          decidedBy: 'admin-1',
          accepted: true,
        );

        expect(appeal, isNull);
      });
    });
  });

  group('FineSummaryService', () {
    late FineSummaryService service;

    setUp(() {
      service = FineSummaryService(db, userService, teamService);
    });

    group('getTeamSummary', () {
      test('returnerer korrekt oppsummering for lag med bøter', () async {
        when(() => client.select(
          'fines',
          filters: {'team_id': 'eq.team-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'fine-1',
            'status': 'pending',
            'amount': 50.0,
          },
          {
            'id': 'fine-2',
            'status': 'approved',
            'amount': 100.0,
          },
          {
            'id': 'fine-3',
            'status': 'paid',
            'amount': 75.0,
          },
          {
            'id': 'fine-4',
            'status': 'appealed',
            'amount': 60.0,
          },
          {
            'id': 'fine-5',
            'status': 'rejected',
            'amount': 40.0,
          },
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'in.(fine-1,fine-2,fine-3,fine-4,fine-5)'},
        )).thenAnswer((_) async => [
          {'amount': 30.0},
          {'amount': 45.0},
        ]);

        final summary = await service.getTeamSummary('team-1');

        expect(summary.fineCount, equals(5));
        expect(summary.pendingCount, equals(2)); // pending + appealed
        expect(summary.paidCount, equals(1));
        expect(summary.totalFines, equals(160.0)); // approved + appealed = 100 + 60
        expect(summary.totalPending, equals(110.0)); // pending + appealed = 50 + 60
        expect(summary.totalPaid, equals(75.0)); // sum of payments
      });

      test('returnerer nuller når lag ikke har bøter', () async {
        when(() => client.select(
          'fines',
          filters: {'team_id': 'eq.team-1'},
        )).thenAnswer((_) async => []);

        final summary = await service.getTeamSummary('team-1');

        expect(summary.fineCount, equals(0));
        expect(summary.pendingCount, equals(0));
        expect(summary.paidCount, equals(0));
        expect(summary.totalFines, equals(0.0));
        expect(summary.totalPaid, equals(0.0));
      });

      test('ekskluderer rejected og pending fra totalFines', () async {
        when(() => client.select(
          'fines',
          filters: {'team_id': 'eq.team-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'fine-1',
            'status': 'pending',
            'amount': 50.0,
          },
          {
            'id': 'fine-2',
            'status': 'rejected',
            'amount': 100.0,
          },
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'in.(fine-1,fine-2)'},
        )).thenAnswer((_) async => []);

        final summary = await service.getTeamSummary('team-1');

        expect(summary.totalFines, equals(0.0)); // Only approved/appealed count
        expect(summary.totalPending, equals(50.0)); // pending counts as pending
      });
    });

    group('getUserSummaries', () {
      test('returnerer tom liste når lag ikke har medlemmer', () async {
        when(() => teamService.getTeamMemberUserIds('team-1'))
          .thenAnswer((_) async => []);

        final summaries = await service.getUserSummaries('team-1');

        expect(summaries, isEmpty);
      });

      test('returnerer per-bruker oppsummeringer med riktige totaler', () async {
        when(() => teamService.getTeamMemberUserIds('team-1'))
          .thenAnswer((_) async => ['user-1', 'user-2', 'user-3']);

        when(() => userService.getUserMap(['user-1', 'user-2', 'user-3']))
          .thenAnswer((_) async => {
            'user-1': {'name': 'Ola Nordmann', 'avatar_url': null},
            'user-2': {'name': 'Kari Hansen', 'avatar_url': 'http://avatar2.jpg'},
            'user-3': {'name': 'Per Jensen', 'avatar_url': null},
          });

        when(() => client.select(
          'fines',
          filters: {'team_id': 'eq.team-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'fine-1',
            'offender_id': 'user-1',
            'status': 'approved',
            'amount': 100.0,
          },
          {
            'id': 'fine-2',
            'offender_id': 'user-1',
            'status': 'paid',
            'amount': 50.0,
          },
          {
            'id': 'fine-3',
            'offender_id': 'user-2',
            'status': 'approved',
            'amount': 75.0,
          },
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'in.(fine-1,fine-2,fine-3)'},
        )).thenAnswer((_) async => [
          {'fine_id': 'fine-1', 'amount': 30.0},
          {'fine_id': 'fine-2', 'amount': 50.0},
          {'fine_id': 'fine-3', 'amount': 25.0},
        ]);

        final summaries = await service.getUserSummaries('team-1');

        expect(summaries.length, equals(3));

        final user1 = summaries.firstWhere((s) => s.userId == 'user-1');
        expect(user1.userName, equals('Ola Nordmann'));
        expect(user1.fineCount, equals(2));
        expect(user1.totalFines, equals(150.0));
        expect(user1.totalPaid, equals(80.0));

        final user2 = summaries.firstWhere((s) => s.userId == 'user-2');
        expect(user2.userName, equals('Kari Hansen'));
        expect(user2.fineCount, equals(1));
        expect(user2.totalFines, equals(75.0));
        expect(user2.totalPaid, equals(25.0));

        final user3 = summaries.firstWhere((s) => s.userId == 'user-3');
        expect(user3.userName, equals('Per Jensen'));
        expect(user3.fineCount, equals(0));
        expect(user3.totalFines, equals(0.0));
        expect(user3.totalPaid, equals(0.0));
      });

      test('sorterer etter ubetalt beløp (descending)', () async {
        when(() => teamService.getTeamMemberUserIds('team-1'))
          .thenAnswer((_) async => ['user-1', 'user-2', 'user-3']);

        when(() => userService.getUserMap(['user-1', 'user-2', 'user-3']))
          .thenAnswer((_) async => {
            'user-1': {'name': 'User 1'},
            'user-2': {'name': 'User 2'},
            'user-3': {'name': 'User 3'},
          });

        when(() => client.select(
          'fines',
          filters: {'team_id': 'eq.team-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'fine-1',
            'offender_id': 'user-1',
            'status': 'approved',
            'amount': 50.0, // 50 - 10 = 40 unpaid
          },
          {
            'id': 'fine-2',
            'offender_id': 'user-2',
            'status': 'approved',
            'amount': 100.0, // 100 - 20 = 80 unpaid
          },
          {
            'id': 'fine-3',
            'offender_id': 'user-3',
            'status': 'approved',
            'amount': 30.0, // 30 - 10 = 20 unpaid
          },
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'in.(fine-1,fine-2,fine-3)'},
        )).thenAnswer((_) async => [
          {'fine_id': 'fine-1', 'amount': 10.0},
          {'fine_id': 'fine-2', 'amount': 20.0},
          {'fine_id': 'fine-3', 'amount': 10.0},
        ]);

        final summaries = await service.getUserSummaries('team-1');

        // Should be sorted: user-2 (80), user-1 (40), user-3 (20)
        expect(summaries[0].userId, equals('user-2'));
        expect(summaries[1].userId, equals('user-1'));
        expect(summaries[2].userId, equals('user-3'));
      });

      test('inkluderer kun approved/appealed/paid fines i totaler', () async {
        when(() => teamService.getTeamMemberUserIds('team-1'))
          .thenAnswer((_) async => ['user-1']);

        when(() => userService.getUserMap(['user-1']))
          .thenAnswer((_) async => {
            'user-1': {'name': 'User 1'},
          });

        when(() => client.select(
          'fines',
          filters: {'team_id': 'eq.team-1'},
        )).thenAnswer((_) async => [
          {
            'id': 'fine-1',
            'offender_id': 'user-1',
            'status': 'approved',
            'amount': 100.0,
          },
          {
            'id': 'fine-2',
            'offender_id': 'user-1',
            'status': 'pending',
            'amount': 50.0,
          },
          {
            'id': 'fine-3',
            'offender_id': 'user-1',
            'status': 'rejected',
            'amount': 75.0,
          },
        ]);

        when(() => client.select(
          'fine_payments',
          select: any(named: 'select'),
          filters: {'fine_id': 'in.(fine-1,fine-2,fine-3)'},
        )).thenAnswer((_) async => []);

        final summaries = await service.getUserSummaries('team-1');

        expect(summaries[0].fineCount, equals(3)); // All fines counted
        expect(summaries[0].totalFines, equals(100.0)); // Only approved
      });
    });
  });
}
