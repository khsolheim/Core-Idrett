import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/points_config.dart';
import '../data/points_repository.dart';

// Repository provider
final pointsRepositoryProvider = Provider<PointsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PointsRepository(client);
});

// ============ POINTS CONFIG ============

final pointsConfigProvider =
    FutureProvider.family<TeamPointsConfig, ({String teamId, String? seasonId})>(
        (ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getConfig(params.teamId, seasonId: params.seasonId);
});

final teamPointsConfigProvider =
    FutureProvider.family<TeamPointsConfig, String>((ref, teamId) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getConfig(teamId);
});

class PointsConfigNotifier extends StateNotifier<AsyncValue<TeamPointsConfig?>> {
  final PointsRepository _repo;
  final Ref _ref;

  PointsConfigNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<TeamPointsConfig?> createOrUpdateConfig({
    required String teamId,
    String? seasonId,
    int? trainingPoints,
    int? matchPoints,
    int? socialPoints,
    double? trainingWeight,
    double? matchWeight,
    double? socialWeight,
    double? competitionWeight,
    MiniActivityDistribution? miniActivityDistribution,
    bool? autoAwardAttendance,
    LeaderboardVisibility? visibility,
    bool? allowOptOut,
    bool? requireAbsenceReason,
    bool? requireAbsenceApproval,
    bool? excludeValidAbsenceFromPercentage,
    NewPlayerStartMode? newPlayerStartMode,
  }) async {
    state = const AsyncValue.loading();
    try {
      final config = await _repo.createOrUpdateConfig(
        teamId: teamId,
        seasonId: seasonId,
        trainingPoints: trainingPoints,
        matchPoints: matchPoints,
        socialPoints: socialPoints,
        trainingWeight: trainingWeight,
        matchWeight: matchWeight,
        socialWeight: socialWeight,
        competitionWeight: competitionWeight,
        miniActivityDistribution: miniActivityDistribution?.toJsonString(),
        autoAwardAttendance: autoAwardAttendance,
        visibility: visibility?.toJsonString(),
        allowOptOut: allowOptOut,
        requireAbsenceReason: requireAbsenceReason,
        requireAbsenceApproval: requireAbsenceApproval,
        excludeValidAbsenceFromPercentage: excludeValidAbsenceFromPercentage,
        newPlayerStartMode: newPlayerStartMode?.toJsonString(),
      );
      state = AsyncValue.data(config);
      _ref.invalidate(teamPointsConfigProvider(teamId));
      _ref.invalidate(pointsConfigProvider((teamId: teamId, seasonId: seasonId)));
      return config;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteConfig(String teamId, String configId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteConfig(configId);
      state = const AsyncValue.data(null);
      _ref.invalidate(teamPointsConfigProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final pointsConfigNotifierProvider =
    StateNotifierProvider<PointsConfigNotifier, AsyncValue<TeamPointsConfig?>>(
        (ref) {
  final repo = ref.watch(pointsRepositoryProvider);
  return PointsConfigNotifier(repo, ref);
});

// ============ ATTENDANCE STATS ============

final userAttendanceStatsProvider = FutureProvider.family<UserAttendanceStats,
    ({String teamId, String? userId, String? seasonId})>((ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getTeamAttendanceStats(
    params.teamId,
    userId: params.userId,
    seasonId: params.seasonId,
  );
});

final userAttendancePointsProvider = FutureProvider.family<List<AttendancePoints>,
    ({String userId, String? teamId, String? seasonId})>((ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getUserAttendancePoints(
    params.userId,
    teamId: params.teamId,
    seasonId: params.seasonId,
  );
});

class AttendancePointsNotifier extends StateNotifier<AsyncValue<AttendancePoints?>> {
  final PointsRepository _repo;
  final Ref _ref;

  AttendancePointsNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<AttendancePoints?> awardPoints({
    required String teamId,
    required String instanceId,
    required String userId,
    required String activityType,
    String? seasonId,
    required int basePoints,
    required double weightedPoints,
  }) async {
    state = const AsyncValue.loading();
    try {
      final points = await _repo.awardAttendancePoints(
        teamId: teamId,
        instanceId: instanceId,
        userId: userId,
        activityType: activityType,
        seasonId: seasonId,
        basePoints: basePoints,
        weightedPoints: weightedPoints,
      );
      state = AsyncValue.data(points);
      // Invalidate related providers
      _ref.invalidate(userAttendanceStatsProvider(
          (teamId: teamId, userId: userId, seasonId: seasonId)));
      _ref.invalidate(userAttendancePointsProvider(
          (userId: userId, teamId: teamId, seasonId: seasonId)));
      return points;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final attendancePointsNotifierProvider =
    StateNotifierProvider<AttendancePointsNotifier, AsyncValue<AttendancePoints?>>(
        (ref) {
  final repo = ref.watch(pointsRepositoryProvider);
  return AttendancePointsNotifier(repo, ref);
});

// ============ OPT-OUT ============

final optOutStatusProvider =
    FutureProvider.family<bool, ({String teamId, String userId})>(
        (ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getOptOut(params.teamId, params.userId);
});

class OptOutNotifier extends StateNotifier<AsyncValue<void>> {
  final PointsRepository _repo;
  final Ref _ref;

  OptOutNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<bool> setOptOut(String teamId, String userId, bool optOut) async {
    state = const AsyncValue.loading();
    try {
      await _repo.setOptOut(teamId, userId, optOut);
      state = const AsyncValue.data(null);
      _ref.invalidate(optOutStatusProvider((teamId: teamId, userId: userId)));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final optOutNotifierProvider =
    StateNotifierProvider<OptOutNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(pointsRepositoryProvider);
  return OptOutNotifier(repo, ref);
});

// ============ RANKED LEADERBOARDS ============

final rankedLeaderboardProvider = FutureProvider.family<List<RankedLeaderboardEntry>,
    ({String teamId, LeaderboardCategory? category, String? seasonId})>(
    (ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getRankedLeaderboard(
    params.teamId,
    category: params.category,
    seasonId: params.seasonId,
  );
});

final userRankedPositionProvider = FutureProvider.family<RankedLeaderboardEntry?,
    ({String teamId, String userId, LeaderboardCategory? category, String? seasonId})>(
    (ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getUserRankedPosition(
    params.teamId,
    params.userId,
    category: params.category,
    seasonId: params.seasonId,
  );
});

final leaderboardWithTrendsProvider = FutureProvider.family<
    List<RankedLeaderboardEntry>,
    ({String teamId, LeaderboardCategory? category, String? seasonId})>(
    (ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getLeaderboardWithTrends(
    params.teamId,
    category: params.category,
    seasonId: params.seasonId,
  );
});

// ============ MONTHLY STATS ============

final monthlyStatsProvider = FutureProvider.family<List<MonthlyUserStats>,
    ({String teamId, String userId, int? year, String? seasonId})>(
    (ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getMonthlyStats(
    params.teamId,
    params.userId,
    year: params.year,
    seasonId: params.seasonId,
  );
});

// Simplified provider for user monthly stats with limited months
final userMonthlyStatsProvider = FutureProvider.family<List<MonthlyUserStats>,
    ({String teamId, String userId, int months})>((ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  // Get stats for current year
  final currentYear = DateTime.now().year;
  final allStats = await repo.getMonthlyStats(
    params.teamId,
    params.userId,
    year: currentYear,
  );
  // Return last N months
  final sorted = allStats..sort((a, b) {
    if (a.year != b.year) return a.year.compareTo(b.year);
    return a.month.compareTo(b.month);
  });
  if (sorted.length <= params.months) return sorted;
  return sorted.sublist(sorted.length - params.months);
});

// ============ SELECTED CATEGORY STATE ============

final selectedLeaderboardCategoryProvider =
    StateProvider<LeaderboardCategory>((ref) => LeaderboardCategory.total);

// ============ MANUAL ADJUSTMENTS ============

final teamAdjustmentsProvider = FutureProvider.family<List<ManualPointAdjustment>,
    ({String teamId, String? seasonId, int? limit})>((ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getTeamAdjustments(
    params.teamId,
    seasonId: params.seasonId,
    limit: params.limit,
  );
});

final userAdjustmentsProvider = FutureProvider.family<List<ManualPointAdjustment>,
    ({String userId, String? teamId, String? seasonId})>((ref, params) async {
  final repo = ref.watch(pointsRepositoryProvider);
  return repo.getUserAdjustments(
    params.userId,
    teamId: params.teamId,
    seasonId: params.seasonId,
  );
});

class ManualAdjustmentNotifier extends StateNotifier<AsyncValue<ManualPointAdjustment?>> {
  final PointsRepository _repo;
  final Ref _ref;

  ManualAdjustmentNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<ManualPointAdjustment?> createAdjustment({
    required String teamId,
    required String userId,
    required int points,
    required AdjustmentType adjustmentType,
    required String reason,
    String? seasonId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final adjustment = await _repo.createAdjustment(
        teamId: teamId,
        userId: userId,
        points: points,
        adjustmentType: adjustmentType,
        reason: reason,
        seasonId: seasonId,
      );
      state = AsyncValue.data(adjustment);
      // Invalidate related providers
      _ref.invalidate(teamAdjustmentsProvider(
          (teamId: teamId, seasonId: seasonId, limit: null)));
      _ref.invalidate(userAdjustmentsProvider(
          (userId: userId, teamId: teamId, seasonId: seasonId)));
      _ref.invalidate(userAttendanceStatsProvider(
          (teamId: teamId, userId: userId, seasonId: seasonId)));
      return adjustment;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final manualAdjustmentNotifierProvider =
    StateNotifierProvider<ManualAdjustmentNotifier, AsyncValue<ManualPointAdjustment?>>(
        (ref) {
  final repo = ref.watch(pointsRepositoryProvider);
  return ManualAdjustmentNotifier(repo, ref);
});
