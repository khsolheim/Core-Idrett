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

// ============ SEASONS ============

final seasonsProvider = FutureProvider.family<List<Season>, String>((ref, teamId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getSeasons(teamId);
});

final activeSeasonProvider = FutureProvider.family<Season?, String>((ref, teamId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getActiveSeason(teamId);
});

class SeasonNotifier extends StateNotifier<AsyncValue<void>> {
  final StatisticsRepository _repo;
  final Ref _ref;

  SeasonNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<Season?> createSeason({
    required String teamId,
    required String name,
    DateTime? startDate,
    DateTime? endDate,
    bool setActive = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final season = await _repo.createSeason(
        teamId: teamId,
        name: name,
        startDate: startDate,
        endDate: endDate,
        setActive: setActive,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(seasonsProvider(teamId));
      if (setActive) {
        _ref.invalidate(activeSeasonProvider(teamId));
      }
      return season;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Season?> startNewSeason({
    required String teamId,
    required String name,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = const AsyncValue.loading();
    try {
      final season = await _repo.startNewSeason(
        teamId: teamId,
        name: name,
        startDate: startDate,
        endDate: endDate,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(seasonsProvider(teamId));
      _ref.invalidate(activeSeasonProvider(teamId));
      return season;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> activateSeason(String teamId, String seasonId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.activateSeason(seasonId);
      state = const AsyncValue.data(null);
      _ref.invalidate(seasonsProvider(teamId));
      _ref.invalidate(activeSeasonProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final seasonNotifierProvider = StateNotifierProvider<SeasonNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);
  return SeasonNotifier(repo, ref);
});

// ============ MULTIPLE LEADERBOARDS ============

final leaderboardsProvider = FutureProvider.family<List<Leaderboard>, String>((ref, teamId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getLeaderboards(teamId);
});

final leaderboardsWithSeasonProvider =
    FutureProvider.family<List<Leaderboard>, ({String teamId, String? seasonId})>((ref, params) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getLeaderboards(params.teamId, seasonId: params.seasonId);
});

final mainLeaderboardProvider = FutureProvider.family<Leaderboard?, String>((ref, teamId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getMainLeaderboard(teamId);
});

final leaderboardEntriesProvider =
    FutureProvider.family<List<NewLeaderboardEntry>, String>((ref, leaderboardId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getLeaderboardEntries(leaderboardId);
});

class LeaderboardNotifier extends StateNotifier<AsyncValue<void>> {
  final StatisticsRepository _repo;
  final Ref _ref;

  LeaderboardNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<Leaderboard?> createLeaderboard({
    required String teamId,
    String? seasonId,
    required String name,
    String? description,
    bool isMain = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final leaderboard = await _repo.createLeaderboard(
        teamId: teamId,
        seasonId: seasonId,
        name: name,
        description: description,
        isMain: isMain,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(leaderboardsProvider(teamId));
      if (isMain) {
        _ref.invalidate(mainLeaderboardProvider(teamId));
      }
      return leaderboard;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteLeaderboard(String teamId, String leaderboardId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteLeaderboard(leaderboardId);
      state = const AsyncValue.data(null);
      _ref.invalidate(leaderboardsProvider(teamId));
      _ref.invalidate(mainLeaderboardProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final leaderboardNotifierProvider = StateNotifierProvider<LeaderboardNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);
  return LeaderboardNotifier(repo, ref);
});

// ============ TEST TEMPLATES ============

final testTemplatesProvider = FutureProvider.family<List<TestTemplate>, String>((ref, teamId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getTestTemplates(teamId);
});

final testResultsProvider =
    FutureProvider.family<List<TestResult>, String>((ref, templateId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getTestResults(templateId);
});

final testRankingProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, templateId) async {
  final repo = ref.watch(statisticsRepositoryProvider);
  return repo.getTestRanking(templateId);
});

class TestNotifier extends StateNotifier<AsyncValue<void>> {
  final StatisticsRepository _repo;
  final Ref _ref;

  TestNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<TestTemplate?> createTemplate({
    required String teamId,
    required String name,
    String? description,
    required String unit,
    bool higherIsBetter = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final template = await _repo.createTestTemplate(
        teamId: teamId,
        name: name,
        description: description,
        unit: unit,
        higherIsBetter: higherIsBetter,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(testTemplatesProvider(teamId));
      return template;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteTemplate(String teamId, String templateId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteTestTemplate(templateId);
      state = const AsyncValue.data(null);
      _ref.invalidate(testTemplatesProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<TestResult?> recordResult({
    required String templateId,
    required String userId,
    String? instanceId,
    required double value,
    String? notes,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repo.recordTestResult(
        templateId: templateId,
        userId: userId,
        instanceId: instanceId,
        value: value,
        notes: notes,
      );
      state = const AsyncValue.data(null);
      _ref.invalidate(testResultsProvider(templateId));
      _ref.invalidate(testRankingProvider(templateId));
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final testNotifierProvider = StateNotifierProvider<TestNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(statisticsRepositoryProvider);
  return TestNotifier(repo, ref);
});
