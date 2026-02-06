import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mini_activity.dart';
import '../data/mini_activity_repository.dart';
import 'mini_activity_providers.dart';

// Notifier for creating mini-activities
class CreateMiniActivityNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<bool> createMiniActivity({
    required String instanceId,
    String? templateId,
    required String name,
    required MiniActivityType type,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createMiniActivity(
        instanceId: instanceId,
        templateId: templateId,
        name: name,
        type: type,
      );
      ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteMiniActivity(String miniActivityId, String instanceId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteMiniActivity(miniActivityId);
      ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final createMiniActivityProvider = NotifierProvider<CreateMiniActivityNotifier, AsyncValue<void>>(CreateMiniActivityNotifier.new);

// Notifier for standalone mini-activities
class StandaloneMiniActivityNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<MiniActivity?> createStandaloneMiniActivity({
    required String teamId,
    String? templateId,
    required String name,
    required MiniActivityType type,
    String? description,
    int? maxParticipants,
    bool enableLeaderboard = true,
    int winPoints = 3,
    int drawPoints = 1,
    int lossPoints = 0,
    String? leaderboardId,
    bool handicapEnabled = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createStandaloneMiniActivity(
        teamId: teamId,
        templateId: templateId,
        name: name,
        type: type,
        description: description,
        maxParticipants: maxParticipants,
        enableLeaderboard: enableLeaderboard,
        winPoints: winPoints,
        drawPoints: drawPoints,
        lossPoints: lossPoints,
        leaderboardId: leaderboardId,
        handicapEnabled: handicapEnabled,
      );
      ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final standaloneMiniActivityProvider = NotifierProvider<StandaloneMiniActivityNotifier, AsyncValue<void>>(StandaloneMiniActivityNotifier.new);

// Notifier for managing mini-activity operations
class MiniActivityOperationsNotifier extends Notifier<AsyncValue<void>> {
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

  Future<MiniActivity?> updateMiniActivity({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    String? name,
    String? description,
    int? maxParticipants,
    bool? enableLeaderboard,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
    bool? handicapEnabled,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateMiniActivity(
        miniActivityId: miniActivityId,
        name: name,
        description: description,
        maxParticipants: maxParticipants,
        enableLeaderboard: enableLeaderboard,
        winPoints: winPoints,
        drawPoints: drawPoints,
        lossPoints: lossPoints,
        leaderboardId: leaderboardId,
        handicapEnabled: handicapEnabled,
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

  Future<MiniActivity?> archiveMiniActivity({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.archiveMiniActivity(miniActivityId);
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _invalidateAppropriateProvider(instanceId, teamId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> unarchiveMiniActivity({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.unarchiveMiniActivity(miniActivityId);
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _invalidateAppropriateProvider(instanceId, teamId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> duplicateMiniActivity({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    String? newName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.duplicateMiniActivity(miniActivityId, newName: newName);
      _invalidateAppropriateProvider(instanceId, teamId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> resetTeamDivision({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.resetTeamDivision(miniActivityId);
      ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _invalidateAppropriateProvider(instanceId, teamId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> addLateParticipant({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    required String userId,
    required String miniTeamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.addLateParticipant(
        miniActivityId: miniActivityId,
        userId: userId,
        miniTeamId: miniTeamId,
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

  Future<MiniActivity?> updateTeamName({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    required String miniTeamId,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateTeamName(
        miniActivityId: miniActivityId,
        miniTeamId: miniTeamId,
        name: name,
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
}

final miniActivityOperationsProvider = NotifierProvider<MiniActivityOperationsNotifier, AsyncValue<void>>(MiniActivityOperationsNotifier.new);

// ============ TEAM MANAGEMENT NOTIFIER ============

class TeamManagementNotifier extends Notifier<AsyncValue<void>> {
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

  Future<MiniActivity?> createTeam({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    required String name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createTeam(
        miniActivityId: miniActivityId,
        name: name,
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

  Future<MiniActivity?> deleteTeam({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    required String miniTeamId,
    String? moveParticipantsToTeamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.deleteTeam(
        miniActivityId: miniActivityId,
        miniTeamId: miniTeamId,
        moveParticipantsToTeamId: moveParticipantsToTeamId,
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

  Future<MiniActivity?> moveParticipant({
    required String miniActivityId,
    String? instanceId, // Nullable for standalone mini-activities
    String? teamId, // For invalidating standalone provider
    required String participantId,
    required String targetTeamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.moveParticipant(
        miniActivityId: miniActivityId,
        participantId: participantId,
        targetTeamId: targetTeamId,
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
}

final teamManagementProvider = NotifierProvider<TeamManagementNotifier, AsyncValue<void>>(TeamManagementNotifier.new);
