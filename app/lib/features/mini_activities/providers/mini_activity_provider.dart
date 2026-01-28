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

// StateNotifier for creating templates
class CreateTemplateNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  CreateTemplateNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

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
      _ref.invalidate(teamTemplatesProvider(teamId));
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
      _ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final createTemplateProvider = StateNotifierProvider<CreateTemplateNotifier, AsyncValue<void>>((ref) {
  return CreateTemplateNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});

// StateNotifier for creating mini-activities
class CreateMiniActivityNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  CreateMiniActivityNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

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
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
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
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final createMiniActivityProvider = StateNotifierProvider<CreateMiniActivityNotifier, AsyncValue<void>>((ref) {
  return CreateMiniActivityNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});

// StateNotifier for team division
class TeamDivisionNotifier extends StateNotifier<AsyncValue<MiniActivity?>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  TeamDivisionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<MiniActivity?> divideTeams({
    required String miniActivityId,
    required String instanceId,
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
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final teamDivisionProvider = StateNotifierProvider<TeamDivisionNotifier, AsyncValue<MiniActivity?>>((ref) {
  return TeamDivisionNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});

// StateNotifier for recording scores
class RecordScoresNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  RecordScoresNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> recordScores({
    required String miniActivityId,
    required String instanceId,
    Map<String, int>? teamScores,
    Map<String, int>? participantPoints,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.recordScores(
        miniActivityId: miniActivityId,
        teamScores: teamScores,
        participantPoints: participantPoints,
      );
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final recordScoresProvider = StateNotifierProvider<RecordScoresNotifier, AsyncValue<void>>((ref) {
  return RecordScoresNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});

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

// StateNotifier for managing mini-activity operations
class MiniActivityOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  MiniActivityOperationsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<MiniActivity?> updateMiniActivity({
    required String miniActivityId,
    required String instanceId,
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
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> archiveMiniActivity({
    required String miniActivityId,
    required String instanceId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.archiveMiniActivity(miniActivityId);
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> unarchiveMiniActivity({
    required String miniActivityId,
    required String instanceId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.unarchiveMiniActivity(miniActivityId);
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> duplicateMiniActivity({
    required String miniActivityId,
    required String instanceId,
    String? newName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.duplicateMiniActivity(miniActivityId, newName: newName);
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> resetTeamDivision({
    required String miniActivityId,
    required String instanceId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.resetTeamDivision(miniActivityId);
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> addLateParticipant({
    required String miniActivityId,
    required String instanceId,
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
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MiniActivity?> updateTeamName({
    required String miniActivityId,
    required String instanceId,
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
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      _ref.invalidate(instanceMiniActivitiesProvider(instanceId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final miniActivityOperationsProvider = StateNotifierProvider<MiniActivityOperationsNotifier, AsyncValue<void>>((ref) {
  return MiniActivityOperationsNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});

// StateNotifier for adjustments (bonus/penalty)
class AdjustmentNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  AdjustmentNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

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
      _ref.invalidate(miniActivityAdjustmentsProvider(miniActivityId));
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
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
      _ref.invalidate(miniActivityAdjustmentsProvider(miniActivityId));
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final adjustmentProvider = StateNotifierProvider<AdjustmentNotifier, AsyncValue<void>>((ref) {
  return AdjustmentNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});

// StateNotifier for handicaps
class HandicapNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  HandicapNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

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
      _ref.invalidate(miniActivityHandicapsProvider(miniActivityId));
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
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
      _ref.invalidate(miniActivityHandicapsProvider(miniActivityId));
      _ref.invalidate(miniActivityDetailProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final handicapProvider = StateNotifierProvider<HandicapNotifier, AsyncValue<void>>((ref) {
  return HandicapNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});

// StateNotifier for standalone mini-activities
class StandaloneMiniActivityNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  StandaloneMiniActivityNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

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
      _ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final standaloneMiniActivityProvider = StateNotifierProvider<StandaloneMiniActivityNotifier, AsyncValue<void>>((ref) {
  return StandaloneMiniActivityNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});

// StateNotifier for template operations
class TemplateOperationsNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityRepository _repository;
  final Ref _ref;

  TemplateOperationsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

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
      _ref.invalidate(teamTemplatesProvider(teamId));
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
      _ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final templateOperationsProvider = StateNotifierProvider<TemplateOperationsNotifier, AsyncValue<void>>((ref) {
  return TemplateOperationsNotifier(ref.watch(miniActivityRepositoryProvider), ref);
});
