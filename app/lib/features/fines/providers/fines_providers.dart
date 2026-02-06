import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/fine.dart';
import '../data/fines_repository.dart';

// Repository provider
final finesRepositoryProvider = Provider<FinesRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return FinesRepository(client);
});

// Fine Rules
final fineRulesProvider = FutureProvider.family<List<FineRule>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFineRules(teamId, activeOnly: true);
});

final allFineRulesProvider = FutureProvider.family<List<FineRule>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFineRules(teamId);
});

// Fines
final teamFinesProvider = FutureProvider.family<List<Fine>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFines(teamId);
});

final pendingFinesProvider = FutureProvider.family<List<Fine>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFines(teamId, status: 'pending');
});

final userFinesProvider =
    FutureProvider.family<List<Fine>, ({String teamId, String userId})>((ref, params) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFines(params.teamId, offenderId: params.userId);
});

// Unpaid approved fines for a specific user (for payment registration)
final unpaidUserFinesProvider =
    FutureProvider.family<List<Fine>, ({String teamId, String userId})>((ref, params) async {
  final repo = ref.watch(finesRepositoryProvider);
  final fines = await repo.getFines(params.teamId, offenderId: params.userId, status: 'approved');
  // Filter to only include fines with remaining balance
  return fines.where((f) => f.remainingAmount > 0).toList();
});

final fineDetailProvider = FutureProvider.family<Fine, String>((ref, fineId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getFine(fineId);
});

// Appeals
final pendingAppealsProvider = FutureProvider.family<List<FineAppeal>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getPendingAppeals(teamId);
});

// Summary
final teamFinesSummaryProvider = FutureProvider.family<TeamFinesSummary, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getTeamSummary(teamId);
});

final userFinesSummariesProvider = FutureProvider.family<List<UserFinesSummary>, String>((ref, teamId) async {
  final repo = ref.watch(finesRepositoryProvider);
  return repo.getUserSummaries(teamId);
});
