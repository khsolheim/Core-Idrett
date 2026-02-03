import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/absence.dart';
import '../data/absence_repository.dart';

// Repository provider
final absenceRepositoryProvider = Provider<AbsenceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AbsenceRepository(client);
});

// ============ ABSENCE CATEGORIES ============

final absenceCategoriesProvider =
    FutureProvider.family<List<AbsenceCategory>, String>((ref, teamId) async {
  final repo = ref.watch(absenceRepositoryProvider);
  return repo.getCategories(teamId);
});

class AbsenceCategoryNotifier extends Notifier<AsyncValue<AbsenceCategory?>> {
  late final AbsenceRepository _repo;

  @override
  AsyncValue<AbsenceCategory?> build() {
    _repo = ref.watch(absenceRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<AbsenceCategory?> createCategory({
    required String teamId,
    required String name,
    bool requiresApproval = false,
    bool countsAsValid = true,
    int? sortOrder,
  }) async {
    state = const AsyncValue.loading();
    try {
      final category = await _repo.createCategory(
        teamId: teamId,
        name: name,
        requiresApproval: requiresApproval,
        countsAsValid: countsAsValid,
        sortOrder: sortOrder,
      );
      state = AsyncValue.data(category);
      ref.invalidate(absenceCategoriesProvider(teamId));
      return category;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<AbsenceCategory?> updateCategory({
    required String teamId,
    required String categoryId,
    String? name,
    bool? requiresApproval,
    bool? countsAsValid,
    int? sortOrder,
  }) async {
    state = const AsyncValue.loading();
    try {
      final category = await _repo.updateCategory(
        categoryId: categoryId,
        name: name,
        requiresApproval: requiresApproval,
        countsAsValid: countsAsValid,
        sortOrder: sortOrder,
      );
      state = AsyncValue.data(category);
      ref.invalidate(absenceCategoriesProvider(teamId));
      return category;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteCategory(String teamId, String categoryId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteCategory(categoryId);
      state = const AsyncValue.data(null);
      ref.invalidate(absenceCategoriesProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final absenceCategoryNotifierProvider =
    NotifierProvider<AbsenceCategoryNotifier, AsyncValue<AbsenceCategory?>>(
        AbsenceCategoryNotifier.new);

// ============ ABSENCE RECORDS ============

final teamAbsencesProvider = FutureProvider.family<List<AbsenceRecord>,
    ({String teamId, String? userId, String? status, String? seasonId})>(
    (ref, params) async {
  final repo = ref.watch(absenceRepositoryProvider);
  return repo.getTeamAbsences(
    params.teamId,
    userId: params.userId,
    status: params.status,
    seasonId: params.seasonId,
  );
});

final pendingAbsencesProvider =
    FutureProvider.family<List<AbsenceRecord>, String>((ref, teamId) async {
  final repo = ref.watch(absenceRepositoryProvider);
  return repo.getPendingAbsences(teamId);
});

final absenceDetailsProvider =
    FutureProvider.family<AbsenceRecord?, String>((ref, absenceId) async {
  final repo = ref.watch(absenceRepositoryProvider);
  return repo.getAbsenceDetails(absenceId);
});

final instanceAbsenceProvider = FutureProvider.family<AbsenceRecord?,
    ({String userId, String instanceId})>((ref, params) async {
  final repo = ref.watch(absenceRepositoryProvider);
  return repo.getAbsenceForInstance(params.userId, params.instanceId);
});

class AbsenceRecordNotifier extends Notifier<AsyncValue<AbsenceRecord?>> {
  late final AbsenceRepository _repo;

  @override
  AsyncValue<AbsenceRecord?> build() {
    _repo = ref.watch(absenceRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<AbsenceRecord?> registerAbsence({
    required String teamId,
    required String userId,
    required String instanceId,
    String? categoryId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final record = await _repo.registerAbsence(
        teamId: teamId,
        userId: userId,
        instanceId: instanceId,
        categoryId: categoryId,
        reason: reason,
      );
      state = AsyncValue.data(record);
      // Invalidate related providers
      ref.invalidate(pendingAbsencesProvider(teamId));
      ref.invalidate(teamAbsencesProvider(
          (teamId: teamId, userId: userId, status: null, seasonId: null)));
      ref.invalidate(
          instanceAbsenceProvider((userId: userId, instanceId: instanceId)));
      return record;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<AbsenceRecord?> approveAbsence(String teamId, String absenceId) async {
    state = const AsyncValue.loading();
    try {
      final record = await _repo.approveAbsence(absenceId);
      state = AsyncValue.data(record);
      ref.invalidate(pendingAbsencesProvider(teamId));
      ref.invalidate(absenceDetailsProvider(absenceId));
      return record;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<AbsenceRecord?> rejectAbsence(
    String teamId,
    String absenceId, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final record = await _repo.rejectAbsence(absenceId, reason: reason);
      state = AsyncValue.data(record);
      ref.invalidate(pendingAbsencesProvider(teamId));
      ref.invalidate(absenceDetailsProvider(absenceId));
      return record;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteAbsence(
    String teamId,
    String absenceId,
    String userId,
    String instanceId,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAbsence(absenceId);
      state = const AsyncValue.data(null);
      ref.invalidate(pendingAbsencesProvider(teamId));
      ref.invalidate(absenceDetailsProvider(absenceId));
      ref.invalidate(
          instanceAbsenceProvider((userId: userId, instanceId: instanceId)));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final absenceRecordNotifierProvider =
    NotifierProvider<AbsenceRecordNotifier, AsyncValue<AbsenceRecord?>>(
        AbsenceRecordNotifier.new);

// ============ ABSENCE SUMMARY ============

final absenceSummaryProvider =
    FutureProvider.family<AbsenceSummary, ({String teamId, String? seasonId})>(
        (ref, params) async {
  final repo = ref.watch(absenceRepositoryProvider);
  return repo.getTeamAbsenceSummary(params.teamId, seasonId: params.seasonId);
});

final validAbsenceCountProvider = FutureProvider.family<int,
    ({String userId, String teamId, String? seasonId})>((ref, params) async {
  final repo = ref.watch(absenceRepositoryProvider);
  return repo.countValidAbsences(
    params.userId,
    params.teamId,
    seasonId: params.seasonId,
  );
});

final hasValidAbsenceProvider =
    FutureProvider.family<bool, ({String userId, String instanceId})>(
        (ref, params) async {
  final repo = ref.watch(absenceRepositoryProvider);
  return repo.hasValidAbsence(params.userId, params.instanceId);
});

// ============ PENDING COUNT (for badge display) ============

final pendingAbsenceCountProvider =
    FutureProvider.family<int, String>((ref, teamId) async {
  final repo = ref.watch(absenceRepositoryProvider);
  final pending = await repo.getPendingAbsences(teamId);
  return pending.length;
});
