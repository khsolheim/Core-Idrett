import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/activity.dart';
import '../data/activity_repository.dart';

// Provider for activities of a specific team
final teamActivitiesProvider = FutureProvider.family<List<Activity>, String>((ref, teamId) async {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getActivitiesForTeam(teamId);
});

// Provider for upcoming instances of a specific team
final upcomingInstancesProvider = FutureProvider.family<List<ActivityInstance>, String>((ref, teamId) async {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getUpcomingInstances(teamId);
});

// Provider for a specific instance with responses
final instanceDetailProvider = FutureProvider.family<ActivityInstance, String>((ref, instanceId) async {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getInstance(instanceId);
});

// StateNotifier for managing activity creation
class CreateActivityNotifier extends StateNotifier<AsyncValue<void>> {
  final ActivityRepository _repository;
  final Ref _ref;

  CreateActivityNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> createActivity({
    required String teamId,
    required String title,
    required ActivityType type,
    String? location,
    String? description,
    required RecurrenceType recurrenceType,
    DateTime? recurrenceEndDate,
    required ResponseType responseType,
    int? responseDeadlineHours,
    required DateTime firstDate,
    String? startTime,
    String? endTime,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createActivity(
        teamId: teamId,
        title: title,
        type: type,
        location: location,
        description: description,
        recurrenceType: recurrenceType,
        recurrenceEndDate: recurrenceEndDate,
        responseType: responseType,
        responseDeadlineHours: responseDeadlineHours,
        firstDate: firstDate,
        startTime: startTime,
        endTime: endTime,
      );
      // Invalidate the team activities to refresh the list
      _ref.invalidate(teamActivitiesProvider(teamId));
      _ref.invalidate(upcomingInstancesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final createActivityProvider = StateNotifierProvider<CreateActivityNotifier, AsyncValue<void>>((ref) {
  return CreateActivityNotifier(ref.watch(activityRepositoryProvider), ref);
});

// StateNotifier for responding to activities
class ActivityResponseNotifier extends StateNotifier<AsyncValue<void>> {
  final ActivityRepository _repository;
  final Ref _ref;

  ActivityResponseNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> respond({
    required String instanceId,
    required String teamId,
    UserResponse? response,
    String? comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.respond(
        instanceId: instanceId,
        response: response,
        comment: comment,
      );
      // Invalidate to refresh data
      _ref.invalidate(instanceDetailProvider(instanceId));
      _ref.invalidate(upcomingInstancesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final activityResponseProvider = StateNotifierProvider<ActivityResponseNotifier, AsyncValue<void>>((ref) {
  return ActivityResponseNotifier(ref.watch(activityRepositoryProvider), ref);
});

// StateNotifier for updating instance status
class InstanceStatusNotifier extends StateNotifier<AsyncValue<void>> {
  final ActivityRepository _repository;
  final Ref _ref;

  InstanceStatusNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> updateStatus({
    required String instanceId,
    required String teamId,
    required InstanceStatus status,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateInstanceStatus(
        instanceId: instanceId,
        status: status,
        reason: reason,
      );
      // Invalidate to refresh data
      _ref.invalidate(instanceDetailProvider(instanceId));
      _ref.invalidate(upcomingInstancesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final instanceStatusProvider = StateNotifierProvider<InstanceStatusNotifier, AsyncValue<void>>((ref) {
  return InstanceStatusNotifier(ref.watch(activityRepositoryProvider), ref);
});
