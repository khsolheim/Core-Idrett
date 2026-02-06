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
