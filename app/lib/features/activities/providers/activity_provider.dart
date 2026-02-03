import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
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

// Notifier for managing activity creation
class CreateActivityNotifier extends Notifier<AsyncValue<void>> {
  late final ActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(activityRepositoryProvider);
    return const AsyncValue.data(null);
  }

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
      ref.invalidate(teamActivitiesProvider(teamId));
      ref.invalidate(upcomingInstancesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final createActivityProvider = NotifierProvider<CreateActivityNotifier, AsyncValue<void>>(
    CreateActivityNotifier.new);

// Notifier for responding to activities
class ActivityResponseNotifier extends Notifier<AsyncValue<void>> {
  late final ActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(activityRepositoryProvider);
    return const AsyncValue.data(null);
  }

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
      ref.invalidate(instanceDetailProvider(instanceId));
      ref.invalidate(upcomingInstancesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final activityResponseProvider = NotifierProvider<ActivityResponseNotifier, AsyncValue<void>>(
    ActivityResponseNotifier.new);

// Notifier for updating instance status
class InstanceStatusNotifier extends Notifier<AsyncValue<void>> {
  late final ActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(activityRepositoryProvider);
    return const AsyncValue.data(null);
  }

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
      ref.invalidate(instanceDetailProvider(instanceId));
      ref.invalidate(upcomingInstancesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final instanceStatusProvider = NotifierProvider<InstanceStatusNotifier, AsyncValue<void>>(
    InstanceStatusNotifier.new);

// Provider for calendar instances by month
final calendarInstancesProvider = FutureProvider.family<
    List<ActivityInstance>,
    ({String teamId, DateTime from, DateTime to})>((ref, params) async {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getInstancesByDateRange(
    params.teamId,
    from: params.from,
    to: params.to,
  );
});

// Notifier for editing instances
class EditInstanceNotifier extends Notifier<AsyncValue<InstanceOperationResult?>> {
  late final ActivityRepository _repository;

  @override
  AsyncValue<InstanceOperationResult?> build() {
    _repository = ref.watch(activityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<InstanceOperationResult?> editInstance({
    required String instanceId,
    required String teamId,
    required EditScope scope,
    String? title,
    String? location,
    String? description,
    String? startTime,
    String? endTime,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.editInstance(
        instanceId: instanceId,
        scope: scope,
        title: title,
        location: location,
        description: description,
        startTime: startTime,
        endTime: endTime,
        date: date,
      );
      // Invalidate relevant providers to refresh data
      ref.invalidate(instanceDetailProvider(instanceId));
      ref.invalidate(upcomingInstancesProvider(teamId));
      ref.invalidate(teamActivitiesProvider(teamId));
      // Also invalidate any affected instances
      for (final affectedId in result.affectedInstanceIds) {
        ref.invalidate(instanceDetailProvider(affectedId));
      }
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final editInstanceProvider = NotifierProvider<EditInstanceNotifier, AsyncValue<InstanceOperationResult?>>(
    EditInstanceNotifier.new);

// Notifier for deleting instances
class DeleteInstanceNotifier extends Notifier<AsyncValue<InstanceOperationResult?>> {
  late final ActivityRepository _repository;

  @override
  AsyncValue<InstanceOperationResult?> build() {
    _repository = ref.watch(activityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<InstanceOperationResult?> deleteInstance({
    required String instanceId,
    required String teamId,
    required EditScope scope,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.deleteInstance(
        instanceId: instanceId,
        scope: scope,
      );
      // Invalidate relevant providers to refresh data
      ref.invalidate(upcomingInstancesProvider(teamId));
      ref.invalidate(teamActivitiesProvider(teamId));
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final deleteInstanceProvider = NotifierProvider<DeleteInstanceNotifier, AsyncValue<InstanceOperationResult?>>(
    DeleteInstanceNotifier.new);

/// Provider for realtime activity response updates
/// Watch this provider to enable realtime updates for a specific team
final activityResponsesRealtimeProvider = Provider.family<void, String>((ref, teamId) {
  final supabaseService = ref.watch(supabaseServiceProvider);

  if (!supabaseService.isInitialized) {
    // Supabase not initialized, realtime updates disabled
    return;
  }

  // Debounce timer to avoid too frequent invalidations
  Timer? debounceTimer;

  final channel = supabaseService.subscribeToActivityResponses(
    teamId: teamId,
    onUpdate: () {
      // Debounce to avoid rapid-fire updates
      debounceTimer?.cancel();
      debounceTimer = Timer(const Duration(milliseconds: 500), () {
        // Invalidate providers to trigger refresh
        ref.invalidate(upcomingInstancesProvider(teamId));
      });
    },
  );

  // Cleanup subscription when provider is disposed
  ref.onDispose(() {
    debounceTimer?.cancel();
    if (channel != null) {
      supabaseService.unsubscribe(channel);
    }
  });
});

// Notifier for awarding attendance points
class AttendancePointsNotifier extends Notifier<AsyncValue<AttendancePointsResult?>> {
  late final ActivityRepository _repository;

  @override
  AsyncValue<AttendancePointsResult?> build() {
    _repository = ref.watch(activityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<AttendancePointsResult?> awardPoints({
    required String instanceId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.awardAttendancePoints(instanceId);
      // Invalidate instance to refresh status
      ref.invalidate(instanceDetailProvider(instanceId));
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final attendancePointsProvider = NotifierProvider<AttendancePointsNotifier, AsyncValue<AttendancePointsResult?>>(
    AttendancePointsNotifier.new);
