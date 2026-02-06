import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/fine.dart';
import '../data/fines_repository.dart';
import 'fines_providers.dart';

// Fine Actions
class FineNotifier extends Notifier<AsyncValue<Fine?>> {
  late final FinesRepository _repo;

  @override
  AsyncValue<Fine?> build() {
    _repo = ref.watch(finesRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<Fine?> createFine({
    required String teamId,
    required String offenderId,
    String? ruleId,
    required double amount,
    String? description,
    String? evidenceUrl,
    bool isGameDay = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final fine = await _repo.createFine(
        teamId: teamId,
        offenderId: offenderId,
        ruleId: ruleId,
        amount: amount,
        description: description,
        evidenceUrl: evidenceUrl,
        isGameDay: isGameDay,
      );
      state = AsyncValue.data(fine);
      _invalidateFineProviders(teamId);
      return fine;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Fine?> approveFine(String fineId, String teamId) async {
    state = const AsyncValue.loading();
    try {
      final fine = await _repo.approveFine(fineId);
      state = AsyncValue.data(fine);
      _invalidateFineProviders(teamId);
      return fine;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Fine?> rejectFine(String fineId, String teamId) async {
    state = const AsyncValue.loading();
    try {
      final fine = await _repo.rejectFine(fineId);
      state = AsyncValue.data(fine);
      _invalidateFineProviders(teamId);
      return fine;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void _invalidateFineProviders(String teamId) {
    ref.invalidate(teamFinesProvider(teamId));
    ref.invalidate(pendingFinesProvider(teamId));
    ref.invalidate(teamFinesSummaryProvider(teamId));
    ref.invalidate(userFinesSummariesProvider(teamId));
  }
}

final fineNotifierProvider = NotifierProvider<FineNotifier, AsyncValue<Fine?>>(FineNotifier.new);

// Appeal Actions
class AppealNotifier extends Notifier<AsyncValue<FineAppeal?>> {
  late final FinesRepository _repo;

  @override
  AsyncValue<FineAppeal?> build() {
    _repo = ref.watch(finesRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<FineAppeal?> createAppeal({
    required String fineId,
    required String reason,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final appeal = await _repo.createAppeal(fineId: fineId, reason: reason);
      state = AsyncValue.data(appeal);
      ref.invalidate(teamFinesProvider(teamId));
      ref.invalidate(fineDetailProvider(fineId));
      ref.invalidate(pendingAppealsProvider(teamId));
      return appeal;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<FineAppeal?> resolveAppeal({
    required String appealId,
    required bool accepted,
    required String teamId,
    double? extraFee,
  }) async {
    state = const AsyncValue.loading();
    try {
      final appeal = await _repo.resolveAppeal(
        appealId: appealId,
        accepted: accepted,
        extraFee: extraFee,
      );
      state = AsyncValue.data(appeal);
      ref.invalidate(pendingAppealsProvider(teamId));
      ref.invalidate(teamFinesProvider(teamId));
      ref.invalidate(teamFinesSummaryProvider(teamId));
      ref.invalidate(userFinesSummariesProvider(teamId));
      return appeal;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final appealNotifierProvider = NotifierProvider<AppealNotifier, AsyncValue<FineAppeal?>>(AppealNotifier.new);

// Payment Actions
class PaymentNotifier extends Notifier<AsyncValue<FinePayment?>> {
  late final FinesRepository _repo;

  @override
  AsyncValue<FinePayment?> build() {
    _repo = ref.watch(finesRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<FinePayment?> recordPayment({
    required String fineId,
    required double amount,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final payment = await _repo.recordPayment(fineId: fineId, amount: amount);
      state = AsyncValue.data(payment);
      ref.invalidate(teamFinesProvider(teamId));
      ref.invalidate(fineDetailProvider(fineId));
      ref.invalidate(teamFinesSummaryProvider(teamId));
      ref.invalidate(userFinesSummariesProvider(teamId));
      return payment;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final paymentNotifierProvider = NotifierProvider<PaymentNotifier, AsyncValue<FinePayment?>>(PaymentNotifier.new);
