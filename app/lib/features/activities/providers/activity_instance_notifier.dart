import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/models/activity.dart';
import '../data/activity_repository.dart';
import 'activity_providers.dart';

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
