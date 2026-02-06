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
