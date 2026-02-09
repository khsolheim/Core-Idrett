import '../../db/database.dart';
import '../../models/mini_activity_statistics.dart';
import '../../helpers/parsing_helpers.dart';
import '../user_service.dart';
import 'player_stats_service.dart';
import 'head_to_head_service.dart';

class MiniActivityStatsAggregationService {
  final Database _db;
  final MiniActivityPlayerStatsService _playerStatsService;
  final MiniActivityHeadToHeadService _headToHeadService;
  final UserService _userService;

  MiniActivityStatsAggregationService(
    this._db,
    this._playerStatsService,
    this._headToHeadService,
    this._userService,
  );

  // ============ AGGREGATED STATS ============

  Future<PlayerStatsAggregate?> getPlayerStatsAggregate({
    required String userId,
    required String teamId,
    String? seasonId,
  }) async {
    final stats = await _playerStatsService.getPlayerStats(
      userId: userId,
      teamId: teamId,
      seasonId: seasonId,
    );

    if (stats == null) return null;

    final headToHead = await _headToHeadService.getHeadToHeadForUser(
      teamId: teamId,
      userId: userId,
    );

    final recentHistory = await _headToHeadService.getTeamHistoryForUser(
      userId: userId,
      limit: 10,
    );

    // Get leaderboard entry for point sources
    final leaderboardResult = await _db.client.select(
      'leaderboard_entries',
      select: 'id',
      filters: {'user_id': 'eq.$userId'},
    );

    List<LeaderboardPointSource> pointSources = [];
    if (leaderboardResult.isNotEmpty) {
      pointSources = await _headToHeadService.getPointSourcesForEntry(
        safeString(leaderboardResult.first, 'id'),
      );
    }

    return PlayerStatsAggregate(
      stats: stats,
      headToHead: headToHead,
      recentHistory: recentHistory,
      pointSources: pointSources,
    );
  }

  // ============ LEADERBOARD INTEGRATION ============

  Future<List<Map<String, dynamic>>> getMiniActivityLeaderboard({
    required String teamId,
    String? seasonId,
    int limit = 50,
  }) async {
    final stats = await _playerStatsService.getTeamPlayerStats(
      teamId: teamId,
      seasonId: seasonId,
      sortBy: 'points',
    );

    if (stats.isEmpty) return [];

    // Get user info
    final userIds = stats.map((s) => s.userId).toList();
    final userMap = await _userService.getUserMap(userIds);

    return stats.take(limit).map((s) {
      final user = userMap[s.userId] ?? {};
      return {
        'rank': stats.indexOf(s) + 1,
        'user_id': s.userId,
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
        'total_points': s.totalPoints,
        'total_wins': s.totalWins,
        'total_participations': s.totalParticipations,
        'win_rate': s.winRate,
        'first_place_count': s.firstPlaceCount,
        'second_place_count': s.secondPlaceCount,
        'third_place_count': s.thirdPlaceCount,
        'current_streak': s.currentStreak,
        'best_streak': s.bestStreak,
      };
    }).toList();
  }

  // ============ BATCH PROCESSING ============

  /// Process results from a completed mini-activity
  Future<void> processMiniActivityResults({
    required String miniActivityId,
    required String teamId,
    String? seasonId,
    required List<Map<String, dynamic>> results, // [{userId, placement, points, teamName, teammates, wasWinner}]
  }) async {
    for (final result in results) {
      final userId = safeString(result, 'user_id');
      final placement = safeIntNullable(result, 'placement');
      final points = safeInt(result, 'points', defaultValue: 0);
      final wasWinner = safeBool(result, 'was_winner', defaultValue: false);
      final teamName = safeStringNullable(result, 'team_name');
      final teammates = result['teammates'] as List<Map<String, dynamic>>?;

      // Update player stats
      await _playerStatsService.updatePlayerStats(
        userId: userId,
        teamId: teamId,
        seasonId: seasonId,
        addParticipations: 1,
        addWins: wasWinner ? 1 : 0,
        addLosses: (!wasWinner && placement != null && placement > 1) ? 1 : 0,
        addPoints: points,
        placement: placement,
      );

      // Record team history
      await _headToHeadService.recordTeamHistory(
        userId: userId,
        miniActivityId: miniActivityId,
        teamName: teamName,
        teammates: teammates,
        placement: placement,
        pointsEarned: points,
        wasWinner: wasWinner,
      );
    }

    // Process head-to-head for 1v1 or team matchups
    if (results.length >= 2) {
      final result1 = results[0];
      final result2 = results[1];

      final winner1 = safeBool(result1, 'was_winner', defaultValue: false);
      final winner2 = safeBool(result2, 'was_winner', defaultValue: false);

      await _headToHeadService.recordHeadToHeadResult(
        teamId: teamId,
        winnerId: winner1 ? safeString(result1, 'user_id') : safeString(result2, 'user_id'),
        loserId: winner1 ? safeString(result2, 'user_id') : safeString(result1, 'user_id'),
        isDraw: !winner1 && !winner2,
      );
    }
  }
}
