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
