import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mini_activity.dart';
import '../data/mini_activity_repository.dart';

// Provider for templates of a specific team
final teamTemplatesProvider = FutureProvider.family<List<ActivityTemplate>, String>((ref, teamId) async {
  final repository = ref.watch(miniActivityRepositoryProvider);
  return repository.getTemplatesForTeam(teamId);
});

// Provider for mini-activities of a specific activity instance
final instanceMiniActivitiesProvider = FutureProvider.family<List<MiniActivity>, String>((ref, instanceId) async {
  final repository = ref.watch(miniActivityRepositoryProvider);
  return repository.getMiniActivitiesForInstance(instanceId);
});

// Provider for mini-activity detail
final miniActivityDetailProvider = FutureProvider.family<MiniActivity, String>((ref, miniActivityId) async {
  final repository = ref.watch(miniActivityRepositoryProvider);
  return repository.getMiniActivityDetail(miniActivityId);
});

// Notifier for creating templates
class CreateTemplateNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<bool> createTemplate({
    required String teamId,
    required String name,
    required MiniActivityType type,
    int defaultPoints = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createTemplate(
        teamId: teamId,
        name: name,
        type: type,
        defaultPoints: defaultPoints,
      );
      ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteTemplate(String templateId, String teamId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTemplate(templateId);
      ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final createTemplateProvider = NotifierProvider<CreateTemplateNotifier, AsyncValue<void>>(CreateTemplateNotifier.new);

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

// Provider for standalone mini-activities of a team
final teamStandaloneMiniActivitiesProvider = FutureProvider.family<List<MiniActivity>, String>((ref, teamId) async {
  final repository = ref.watch(miniActivityRepositoryProvider);
  return repository.getStandaloneForTeam(teamId);
});

// Provider for adjustments of a mini-activity
final miniActivityAdjustmentsProvider = FutureProvider.family<List<MiniActivityAdjustment>, String>((ref, miniActivityId) async {
  final repository = ref.watch(miniActivityRepositoryProvider);
  return repository.getAdjustments(miniActivityId);
});

// Provider for handicaps of a mini-activity
final miniActivityHandicapsProvider = FutureProvider.family<List<MiniActivityHandicap>, String>((ref, miniActivityId) async {
  final repository = ref.watch(miniActivityRepositoryProvider);
  return repository.getHandicaps(miniActivityId);
});

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

// Notifier for template operations
class TemplateOperationsNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<ActivityTemplate?> updateTemplate({
    required String templateId,
    required String teamId,
    String? name,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    bool? isFavorite,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateTemplate(
        templateId: templateId,
        name: name,
        description: description,
        instructions: instructions,
        sportType: sportType,
        suggestedRules: suggestedRules,
        isFavorite: isFavorite,
        winPoints: winPoints,
        drawPoints: drawPoints,
        lossPoints: lossPoints,
        leaderboardId: leaderboardId,
      );
      ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<ActivityTemplate?> toggleFavorite({
    required String templateId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.toggleTemplateFavorite(templateId);
      ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final templateOperationsProvider = NotifierProvider<TemplateOperationsNotifier, AsyncValue<void>>(TemplateOperationsNotifier.new);

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

// ============ HISTORY PROVIDER ============

final miniActivityHistoryProvider = FutureProvider.family<List<MiniActivityHistoryEntry>, MiniActivityHistoryParams>((ref, params) async {
  final repository = ref.watch(miniActivityRepositoryProvider);
  return repository.getHistory(
    teamId: params.teamId,
    templateId: params.templateId,
    limit: params.limit,
  );
});

class MiniActivityHistoryParams {
  final String teamId;
  final String? templateId;
  final int limit;

  MiniActivityHistoryParams({
    required this.teamId,
    this.templateId,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MiniActivityHistoryParams &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          templateId == other.templateId &&
          limit == other.limit;

  @override
  int get hashCode => teamId.hashCode ^ templateId.hashCode ^ limit.hashCode;
}
