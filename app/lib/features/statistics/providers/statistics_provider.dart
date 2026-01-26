import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/statistics.dart';
import '../data/statistics_repository.dart';

// Repository provider
final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return StatisticsRepository(client);
});

// Leaderboard provider
final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, String>((ref, teamId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getLeaderboard(teamId);
});

// Leaderboard with year
final leaderboardWithYearProvider =
    FutureProvider.family<List<LeaderboardEntry>, ({String teamId, int? year})>((ref, params) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getLeaderboard(params.teamId, year: params.year);
});

// Team attendance provider
final teamAttendanceProvider = FutureProvider.family<List<AttendanceRecord>, String>((ref, teamId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getTeamAttendance(teamId);
});

// Player statistics provider
final playerStatisticsProvider =
    FutureProvider.family<PlayerStatistics, ({String teamId, String userId})>((ref, params) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getPlayerStatistics(params.teamId, params.userId);
});

// Match stats provider
final matchStatsProvider = FutureProvider.family<List<MatchStats>, String>((ref, instanceId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getMatchStats(instanceId);
});

// Record match stats notifier
class RecordMatchStatsNotifier extends StateNotifier<AsyncValue<MatchStats?>> {
  final StatisticsRepository _repo;
  final Ref _ref;

  RecordMatchStatsNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<MatchStats?> recordStats({
    required String instanceId,
    required String userId,
    int goals = 0,
    int assists = 0,
    int minutesPlayed = 0,
    int yellowCards = 0,
    int redCards = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final stats = await _repo.recordMatchStats(
        instanceId: instanceId,
        userId: userId,
        goals: goals,
        assists: assists,
        minutesPlayed: minutesPlayed,
        yellowCards: yellowCards,
        redCards: redCards,
      );
      state = AsyncValue.data(stats);
      // Invalidate related providers
      _ref.invalidate(matchStatsProvider(instanceId));
      return stats;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final recordMatchStatsProvider = StateNotifierProvider<RecordMatchStatsNotifier, AsyncValue<MatchStats?>>((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);
  return RecordMatchStatsNotifier(repo, ref);
});
