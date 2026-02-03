import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mini_activity_statistics.dart';
import '../data/mini_activity_statistics_repository.dart';

// ============ PARAMETER CLASSES ============

class PlayerStatsParams {
  final String teamId;
  final String userId;
  final String? seasonId;

  const PlayerStatsParams({
    required this.teamId,
    required this.userId,
    this.seasonId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStatsParams &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          userId == other.userId &&
          seasonId == other.seasonId;

  @override
  int get hashCode => teamId.hashCode ^ userId.hashCode ^ seasonId.hashCode;
}

class HeadToHeadParams {
  final String teamId;
  final String user1Id;
  final String user2Id;

  const HeadToHeadParams({
    required this.teamId,
    required this.user1Id,
    required this.user2Id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeadToHeadParams &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          user1Id == other.user1Id &&
          user2Id == other.user2Id;

  @override
  int get hashCode => teamId.hashCode ^ user1Id.hashCode ^ user2Id.hashCode;
}

class TeamLeaderboardParams {
  final String teamId;
  final String? seasonId;
  final int? limit;
  final String sortBy;

  const TeamLeaderboardParams({
    required this.teamId,
    this.seasonId,
    this.limit,
    this.sortBy = 'total_points',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamLeaderboardParams &&
          runtimeType == other.runtimeType &&
          teamId == other.teamId &&
          seasonId == other.seasonId &&
          limit == other.limit &&
          sortBy == other.sortBy;

  @override
  int get hashCode => teamId.hashCode ^ seasonId.hashCode ^ limit.hashCode ^ sortBy.hashCode;
}

// ============ READ PROVIDERS ============

// Provider for player stats
final playerStatsProvider = FutureProvider.family<MiniActivityPlayerStats, PlayerStatsParams>((ref, params) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getPlayerStats(
    teamId: params.teamId,
    userId: params.userId,
    seasonId: params.seasonId,
  );
});

// Provider for team leaderboard
final teamLeaderboardProvider = FutureProvider.family<List<MiniActivityPlayerStats>, TeamLeaderboardParams>((ref, params) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getTeamLeaderboard(
    teamId: params.teamId,
    seasonId: params.seasonId,
    limit: params.limit,
    sortBy: params.sortBy,
  );
});

// Provider for player stats aggregate (full profile)
final playerStatsAggregateProvider = FutureProvider.family<PlayerStatsAggregate, PlayerStatsParams>((ref, params) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getPlayerStatsAggregate(
    teamId: params.teamId,
    userId: params.userId,
    seasonId: params.seasonId,
  );
});

// Provider for head-to-head stats between two players
final headToHeadProvider = FutureProvider.family<HeadToHeadStats, HeadToHeadParams>((ref, params) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getHeadToHead(
    teamId: params.teamId,
    user1Id: params.user1Id,
    user2Id: params.user2Id,
  );
});

// Provider for all head-to-head records for a user
final userHeadToHeadRecordsProvider = FutureProvider.family<List<HeadToHeadStats>, PlayerStatsParams>((ref, params) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getHeadToHeadRecords(
    teamId: params.teamId,
    userId: params.userId,
  );
});

// Provider for top rivalries in a team
final topRivalriesProvider = FutureProvider.family<List<HeadToHeadStats>, String>((ref, teamId) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getTopRivalries(teamId: teamId);
});

// Provider for user history
final userHistoryProvider = FutureProvider.family<List<MiniActivityTeamHistory>, PlayerStatsParams>((ref, params) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getUserHistory(
    teamId: params.teamId,
    userId: params.userId,
  );
});

// Provider for mini-activity history
final miniActivityHistoryProvider = FutureProvider.family<List<MiniActivityTeamHistory>, String>((ref, miniActivityId) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getMiniActivityHistory(miniActivityId);
});

// Provider for point sources of a leaderboard entry
final pointSourcesProvider = FutureProvider.family<List<LeaderboardPointSource>, String>((ref, leaderboardEntryId) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getPointSources(leaderboardEntryId: leaderboardEntryId);
});

// Provider for user's point sources
final userPointSourcesProvider = FutureProvider.family<List<LeaderboardPointSource>, PlayerStatsParams>((ref, params) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getUserPointSources(
    teamId: params.teamId,
    userId: params.userId,
    seasonId: params.seasonId,
  );
});

// Provider for team stats summary
final teamMiniActivityStatsProvider = FutureProvider.family<TeamMiniActivityStats, String>((ref, teamId) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getTeamStats(teamId: teamId);
});

// ============ STATE NOTIFIERS ============

// StateNotifier for recalculating stats
class StatisticsRecalculateNotifier extends StateNotifier<AsyncValue<void>> {
  final MiniActivityStatisticsRepository _repository;
  final Ref _ref;

  StatisticsRecalculateNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> recalculateStats({
    required String teamId,
    String? userId,
    String? miniActivityId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.recalculateStats(
        teamId: teamId,
        userId: userId,
        miniActivityId: miniActivityId,
      );

      // Invalidate relevant providers
      _ref.invalidate(teamMiniActivityStatsProvider(teamId));
      _ref.invalidate(topRivalriesProvider(teamId));

      if (userId != null) {
        _ref.invalidate(playerStatsProvider(PlayerStatsParams(teamId: teamId, userId: userId)));
        _ref.invalidate(playerStatsAggregateProvider(PlayerStatsParams(teamId: teamId, userId: userId)));
        _ref.invalidate(userHeadToHeadRecordsProvider(PlayerStatsParams(teamId: teamId, userId: userId)));
        _ref.invalidate(userHistoryProvider(PlayerStatsParams(teamId: teamId, userId: userId)));
      }

      if (miniActivityId != null) {
        _ref.invalidate(miniActivityHistoryProvider(miniActivityId));
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final statisticsRecalculateProvider = StateNotifierProvider<StatisticsRecalculateNotifier, AsyncValue<void>>((ref) {
  return StatisticsRecalculateNotifier(ref.watch(miniActivityStatisticsRepositoryProvider), ref);
});

// ============ COMPUTED PROVIDERS ============

// Provider for current user's mini-activity stats (requires auth)
final currentUserMiniActivityStatsProvider = FutureProvider.family<MiniActivityPlayerStats?, String>((ref, teamId) async {
  // This would typically get the current user ID from an auth provider
  // For now, return null - will be connected when integrating with auth
  return null;
});

// Provider for mini-activity leaderboard sorted by wins
final teamWinsLeaderboardProvider = FutureProvider.family<List<MiniActivityPlayerStats>, String>((ref, teamId) async {
  final repository = ref.watch(miniActivityStatisticsRepositoryProvider);
  return repository.getTeamLeaderboard(
    teamId: teamId,
    sortBy: 'total_wins',
    limit: 10,
  );
});

// Provider for mini-activity leaderboard sorted by win rate
final teamWinRateLeaderboardProvider = FutureProvider.family<List<MiniActivityPlayerStats>, String>((ref, teamId) async {
  final stats = await ref.watch(teamLeaderboardProvider(TeamLeaderboardParams(
    teamId: teamId,
    limit: 50,
  )).future);

  // Sort by win rate (only include players with at least 3 participations)
  final qualified = stats.where((s) => s.totalParticipations >= 3).toList();
  qualified.sort((a, b) => b.winRate.compareTo(a.winRate));

  return qualified.take(10).toList();
});

// Provider for top performers (combined score)
final topPerformersProvider = FutureProvider.family<List<MiniActivityPlayerStats>, String>((ref, teamId) async {
  final stats = await ref.watch(teamLeaderboardProvider(TeamLeaderboardParams(
    teamId: teamId,
    limit: 50,
  )).future);

  // Calculate combined score: points + (podium finishes * 5)
  final withScores = stats.map((s) {
    final score = s.totalPoints + (s.podiumCount * 5);
    return MapEntry(score, s);
  }).toList();

  withScores.sort((a, b) => b.key.compareTo(a.key));

  return withScores.take(10).map((e) => e.value).toList();
});
