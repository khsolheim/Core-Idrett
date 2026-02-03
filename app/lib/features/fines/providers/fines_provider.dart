import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/fine.dart';
import '../data/fines_repository.dart';

// Repository provider
final finesRepositoryProvider = Provider<FinesRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return FinesRepository(client);
});

// Fine Rules
final fineRulesProvider = FutureProvider.family<List<FineRule>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFineRules(teamId, activeOnly: true);
});

final allFineRulesProvider = FutureProvider.family<List<FineRule>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFineRules(teamId);
});

// Fines
final teamFinesProvider = FutureProvider.family<List<Fine>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFines(teamId);
});

final pendingFinesProvider = FutureProvider.family<List<Fine>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFines(teamId, status: 'pending');
});

final userFinesProvider =
    FutureProvider.family<List<Fine>, ({String teamId, String userId})>((ref, params) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFines(params.teamId, offenderId: params.userId);
});

// Unpaid approved fines for a specific user (for payment registration)
final unpaidUserFinesProvider =
    FutureProvider.family<List<Fine>, ({String teamId, String userId})>((ref, params) async {
  final repo = ref.watch(finesRepositoryProvider);
  final fines = await repo.getFines(params.teamId, offenderId: params.userId, status: 'approved');
  // Filter to only include fines with remaining balance
  return fines.where((f) => f.remainingAmount > 0).toList();
});

final fineDetailProvider = FutureProvider.family<Fine, String>((ref, fineId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFine(fineId);
});

// Appeals
final pendingAppealsProvider = FutureProvider.family<List<FineAppeal>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getPendingAppeals(teamId);
});

// Summary
final teamFinesSummaryProvider = FutureProvider.family<TeamFinesSummary, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getTeamSummary(teamId);
});

final userFinesSummariesProvider = FutureProvider.family<List<UserFinesSummary>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getUserSummaries(teamId);
});

// Fine Rule Actions
class FineRuleNotifier extends Notifier<AsyncValue<FineRule?>> {
  late final FinesRepository _repo;

  @override
  AsyncValue<FineRule?> build() {
    _repo = ref.watch(finesRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<FineRule?> createRule({
    required String teamId,
    required String name,
    required double amount,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      final rule = await _repo.createFineRule(
        teamId: teamId,
        name: name,
        amount: amount,
        description: description,
      );
      state = AsyncValue.data(rule);
      ref.invalidate(fineRulesProvider(teamId));
      ref.invalidate(allFineRulesProvider(teamId));
      return rule;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<FineRule?> updateRule({
    required String ruleId,
    required String teamId,
    String? name,
    double? amount,
    String? description,
    bool? active,
  }) async {
    state = const AsyncValue.loading();
    try {
      final rule = await _repo.updateFineRule(
        ruleId: ruleId,
        name: name,
        amount: amount,
        description: description,
        active: active,
      );
      state = AsyncValue.data(rule);
      ref.invalidate(fineRulesProvider(teamId));
      ref.invalidate(allFineRulesProvider(teamId));
      return rule;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteRule(String ruleId, String teamId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteFineRule(ruleId);
      state = const AsyncValue.data(null);
      ref.invalidate(fineRulesProvider(teamId));
      ref.invalidate(allFineRulesProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final fineRuleNotifierProvider = NotifierProvider<FineRuleNotifier, AsyncValue<FineRule?>>(FineRuleNotifier.new);

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
