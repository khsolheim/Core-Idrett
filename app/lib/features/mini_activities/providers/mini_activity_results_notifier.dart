import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mini_activity.dart';
import '../data/mini_activity_repository.dart';
import 'mini_activity_providers.dart';

// Notifier for team division
class TeamDivisionNotifier extends Notifier<AsyncValue<MiniActivity?>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<MiniActivity?> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<MiniActivity?> divideTeams({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    required DivisionMethod method,
    required int numberOfTeams,
    required List<String> participantUserIds,
    String? teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.divideTeams(
        miniActivityId: miniActivityId,
        method: method,
        numberOfTeams: numberOfTeams,
        participantUserIds: participantUserIds,
        teamId: teamId,
      );
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      // Invalidate the appropriate provider based on whether it's standalone or instance-based
      if (instanceId != null) {
        ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      } else if (teamId != null) {
        ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId));
      }
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final teamDivisionProvider = NotifierProvider<TeamDivisionNotifier, AsyncValue<MiniActivity?>>(TeamDivisionNotifier.new);

// Notifier for recording scores
class RecordScoresNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<bool> recordScores({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    Map<String, int>? teamScores,
    Map<String, int>? participantPoints,
    bool addToLeaderboard = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.recordScores(
        miniActivityId: miniActivityId,
        teamScores: teamScores,
        participantPoints: participantPoints,
        addToLeaderboard: addToLeaderboard,
      );
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      // Invalidate the appropriate provider based on whether it's standalone or instance-based
      if (instanceId != null) {
        ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      } else if (teamId != null) {
        ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId));
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordScoresProvider = NotifierProvider<RecordScoresNotifier, AsyncValue<void>>(RecordScoresNotifier.new);

// Notifier for adjustments (bonus/penalty)
class AdjustmentNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<MiniActivityAdjustment?> awardAdjustment({
    required String miniActivityId,
    String? miniTeamId,
    String? userId,
    required int points,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.awardAdjustment(
        miniActivityId: miniActivityId,
        miniTeamId: miniTeamId,
        userId: userId,
        points: points,
        reason: reason,
      );
      ref.invalidate(miniActivityAdjustmentsProvider(miniActivityId));
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteAdjustment({
    required String adjustmentId,
    required String miniActivityId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteAdjustment(adjustmentId);
      ref.invalidate(miniActivityAdjustmentsProvider(miniActivityId));
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final adjustmentProvider = NotifierProvider<AdjustmentNotifier, AsyncValue<void>>(AdjustmentNotifier.new);

// Notifier for handicaps
class HandicapNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<MiniActivityHandicap?> setHandicap({
    required String miniActivityId,
    required String userId,
    required double handicapValue,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.setHandicap(
        miniActivityId: miniActivityId,
        userId: userId,
        handicapValue: handicapValue,
      );
      ref.invalidate(miniActivityHandicapsProvider(miniActivityId));
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> removeHandicap({
    required String miniActivityId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeHandicap(
        miniActivityId: miniActivityId,
        userId: userId,
      );
      ref.invalidate(miniActivityHandicapsProvider(miniActivityId));
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final handicapProvider = NotifierProvider<HandicapNotifier, AsyncValue<void>>(HandicapNotifier.new);

// ============ RESULT MANAGEMENT NOTIFIER ============

class ResultManagementNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  /// Helper to invalidate the appropriate provider based on context
  void _invalidateAppropriateProvider(String? instanceId, String? teamId) {
    if (instanceId != null) {
      ref.invalidate(instanceMiniActivitiesProvider(instanceId));
    } else if (teamId != null) {
      ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId));
    }
  }

  Future<MiniActivity?> setWinner({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    String? winnerTeamId,
    bool addToLeaderboard = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.setWinner(
        miniActivityId: miniActivityId,
        winnerTeamId: winnerTeamId,
        addToLeaderboard: addToLeaderboard,
      );
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _invalidateAppropriateProvider(instanceId, teamId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> clearResult({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.clearResult(miniActivityId);
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _invalidateAppropriateProvider(instanceId, teamId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final resultManagementProvider = NotifierProvider<ResultManagementNotifier, AsyncValue<void>>(ResultManagementNotifier.new);
