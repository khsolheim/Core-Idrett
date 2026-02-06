import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/activity.dart';
import '../data/activity_repository.dart';
import 'activity_providers.dart';

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
