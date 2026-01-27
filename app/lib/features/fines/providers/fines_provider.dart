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
class FineRuleNotifier extends StateNotifier<AsyncValue<FineRule?>> {
  final FinesRepository _repo;
  final Ref _ref;

  FineRuleNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

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
      _ref.invalidate(fineRulesProvider(teamId));
      _ref.invalidate(allFineRulesProvider(teamId));
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
      _ref.invalidate(fineRulesProvider(teamId));
      _ref.invalidate(allFineRulesProvider(teamId));
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
      _ref.invalidate(fineRulesProvider(teamId));
      _ref.invalidate(allFineRulesProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final fineRuleNotifierProvider = StateNotifierProvider<FineRuleNotifier, AsyncValue<FineRule?>>((ref) {
  final repo = ref.watch(finesRepositoryProvider);
  return FineRuleNotifier(repo, ref);
});

// Fine Actions
class FineNotifier extends StateNotifier<AsyncValue<Fine?>> {
  final FinesRepository _repo;
  final Ref _ref;

  FineNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<Fine?> createFine({
    required String teamId,
    required String offenderId,
    String? ruleId,
    required double amount,
    String? description,
    String? evidenceUrl,
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
    _ref.invalidate(teamFinesProvider(teamId));
    _ref.invalidate(pendingFinesProvider(teamId));
    _ref.invalidate(teamFinesSummaryProvider(teamId));
    _ref.invalidate(userFinesSummariesProvider(teamId));
  }
}

final fineNotifierProvider = StateNotifierProvider<FineNotifier, AsyncValue<Fine?>>((ref) {
  final repo = ref.watch(finesRepositoryProvider);
  return FineNotifier(repo, ref);
});

// Appeal Actions
class AppealNotifier extends StateNotifier<AsyncValue<FineAppeal?>> {
  final FinesRepository _repo;
  final Ref _ref;

  AppealNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<FineAppeal?> createAppeal({
    required String fineId,
    required String reason,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final appeal = await _repo.createAppeal(fineId: fineId, reason: reason);
      state = AsyncValue.data(appeal);
      _ref.invalidate(teamFinesProvider(teamId));
      _ref.invalidate(fineDetailProvider(fineId));
      _ref.invalidate(pendingAppealsProvider(teamId));
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
      _ref.invalidate(pendingAppealsProvider(teamId));
      _ref.invalidate(teamFinesProvider(teamId));
      _ref.invalidate(teamFinesSummaryProvider(teamId));
      _ref.invalidate(userFinesSummariesProvider(teamId));
      return appeal;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final appealNotifierProvider = StateNotifierProvider<AppealNotifier, AsyncValue<FineAppeal?>>((ref) {
  final repo = ref.watch(finesRepositoryProvider);
  return AppealNotifier(repo, ref);
});

// Payment Actions
class PaymentNotifier extends StateNotifier<AsyncValue<FinePayment?>> {
  final FinesRepository _repo;
  final Ref _ref;

  PaymentNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<FinePayment?> recordPayment({
    required String fineId,
    required double amount,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final payment = await _repo.recordPayment(fineId: fineId, amount: amount);
      state = AsyncValue.data(payment);
      _ref.invalidate(teamFinesProvider(teamId));
      _ref.invalidate(fineDetailProvider(fineId));
      _ref.invalidate(teamFinesSummaryProvider(teamId));
      _ref.invalidate(userFinesSummariesProvider(teamId));
      return payment;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final paymentNotifierProvider = StateNotifierProvider<PaymentNotifier, AsyncValue<FinePayment?>>((ref) {
  final repo = ref.watch(finesRepositoryProvider);
  return PaymentNotifier(repo, ref);
});
