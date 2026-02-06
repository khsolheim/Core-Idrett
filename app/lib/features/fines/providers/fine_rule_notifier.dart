import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/fine.dart';
import '../data/fines_repository.dart';
import 'fines_providers.dart';

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
