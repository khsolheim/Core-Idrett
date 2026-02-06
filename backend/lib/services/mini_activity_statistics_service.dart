import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/mini_activity_statistics.dart';

class MiniActivityStatisticsService {
  final Database _db;
  final _uuid = const Uuid();

  MiniActivityStatisticsService(this._db);

  // ============ PLAYER STATS ============

  Future<MiniActivityPlayerStats?> getPlayerStats({
    required String userId,
    required String teamId,
    String? seasonId,
  }) async {
    final filters = <String, String>{
      'user_id': 'eq.$userId',
      'team_id': 'eq.$teamId',
    };
    if (seasonId != null) {
      filters['season_id'] = 'eq.$seasonId';
    } else {
      filters['season_id'] = 'is.null';
    }

    final result = await _db.client.select(
      'mini_activity_player_stats',
      filters: filters,
    );

    if (result.isEmpty) return null;
    return MiniActivityPlayerStats.fromJson(result.first);
  }

  Future<MiniActivityPlayerStats> getOrCreatePlayerStats({
    required String userId,
    required String teamId,
    String? seasonId,
  }) async {
    var stats = await getPlayerStats(
      userId: userId,
      teamId: teamId,
      seasonId: seasonId,
    );

    if (stats != null) return stats;

    final id = _uuid.v4();
    await _db.client.insert('mini_activity_player_stats', {
      'id': id,
      'user_id': userId,
      'team_id': teamId,
      'season_id': seasonId,
    });

    return MiniActivityPlayerStats(
      id: id,
      userId: userId,
      teamId: teamId,
      seasonId: seasonId,
      updatedAt: DateTime.now(),
    );
  }

  Future<List<MiniActivityPlayerStats>> getTeamPlayerStats({
    required String teamId,
    String? seasonId,
    String? sortBy,
    bool descending = true,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (seasonId != null) {
      filters['season_id'] = 'eq.$seasonId';
    }

    String order;
    switch (sortBy) {
      case 'wins':
        order = descending ? 'total_wins.desc' : 'total_wins.asc';
        break;
      case 'points':
        order = descending ? 'total_points.desc' : 'total_points.asc';
        break;
      case 'participations':
        order = descending ? 'total_participations.desc' : 'total_participations.asc';
        break;
      default:
        order = 'total_points.desc';
    }

    final result = await _db.client.select(
      'mini_activity_player_stats',
      filters: filters,
      order: order,
    );

    return result.map((row) => MiniActivityPlayerStats.fromJson(row)).toList();
  }

  Future<void> updatePlayerStats({
    required String userId,
    required String teamId,
    String? seasonId,
    int? addParticipations,
    int? addWins,
    int? addLosses,
    int? addDraws,
    int? addPoints,
    int? placement,
  }) async {
    final stats = await getOrCreatePlayerStats(
      userId: userId,
      teamId: teamId,
      seasonId: seasonId,
    );

    final updates = <String, dynamic>{'updated_at': DateTime.now().toIso8601String()};

    if (addParticipations != null) {
      updates['total_participations'] = stats.totalParticipations + addParticipations;
    }
    if (addWins != null) {
      updates['total_wins'] = stats.totalWins + addWins;

      // Update streak
      if (addWins > 0) {
        final newStreak = stats.currentStreak >= 0
            ? stats.currentStreak + addWins
            : addWins;
        updates['current_streak'] = newStreak;
        if (newStreak > stats.bestStreak) {
          updates['best_streak'] = newStreak;
        }
      }
    }
    if (addLosses != null) {
      updates['total_losses'] = stats.totalLosses + addLosses;

      // Reset winning streak
      if (addLosses > 0) {
        updates['current_streak'] = stats.currentStreak > 0
            ? -addLosses
            : stats.currentStreak - addLosses;
      }
    }
    if (addDraws != null) {
      updates['total_draws'] = stats.totalDraws + addDraws;
    }
    if (addPoints != null) {
      updates['total_points'] = stats.totalPoints + addPoints;
    }
    if (placement != null) {
      if (placement == 1) {
        updates['first_place_count'] = stats.firstPlaceCount + 1;
      } else if (placement == 2) {
        updates['second_place_count'] = stats.secondPlaceCount + 1;
      } else if (placement == 3) {
        updates['third_place_count'] = stats.thirdPlaceCount + 1;
      }

      // Update average placement
      final totalPlacements = stats.totalParticipations + (addParticipations ?? 0);
      if (totalPlacements > 0) {
        final currentTotal = (stats.averagePlacement ?? 0) * stats.totalParticipations;
        updates['average_placement'] = (currentTotal + placement) / totalPlacements;
      }
    }

    await _db.client.update(
      'mini_activity_player_stats',
      updates,
      filters: {'id': 'eq.${stats.id}'},
    );
  }

  // ============ HEAD-TO-HEAD ============

  Future<HeadToHeadStats?> getHeadToHead({
    required String teamId,
    required String user1Id,
    required String user2Id,
  }) async {
    // Ensure consistent ordering
    final orderedUser1 = user1Id.compareTo(user2Id) < 0 ? user1Id : user2Id;
    final orderedUser2 = user1Id.compareTo(user2Id) < 0 ? user2Id : user1Id;

    final result = await _db.client.select(
      'mini_activity_head_to_head',
      filters: {
        'team_id': 'eq.$teamId',
        'user1_id': 'eq.$orderedUser1',
        'user2_id': 'eq.$orderedUser2',
      },
    );

    if (result.isEmpty) return null;
    return HeadToHeadStats.fromJson(result.first);
  }

  Future<HeadToHeadStats> getOrCreateHeadToHead({
    required String teamId,
    required String user1Id,
    required String user2Id,
  }) async {
    var stats = await getHeadToHead(
      teamId: teamId,
      user1Id: user1Id,
      user2Id: user2Id,
    );

    if (stats != null) return stats;

    // Ensure consistent ordering
    final orderedUser1 = user1Id.compareTo(user2Id) < 0 ? user1Id : user2Id;
    final orderedUser2 = user1Id.compareTo(user2Id) < 0 ? user2Id : user1Id;

    final id = _uuid.v4();
    await _db.client.insert('mini_activity_head_to_head', {
      'id': id,
      'team_id': teamId,
      'user1_id': orderedUser1,
      'user2_id': orderedUser2,
    });

    return HeadToHeadStats(
      id: id,
      teamId: teamId,
      user1Id: orderedUser1,
      user2Id: orderedUser2,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> recordHeadToHeadResult({
    required String teamId,
    required String winnerId,
    required String loserId,
    bool isDraw = false,
  }) async {
    final stats = await getOrCreateHeadToHead(
      teamId: teamId,
      user1Id: winnerId,
      user2Id: loserId,
    );

    final updates = <String, dynamic>{
      'total_matchups': stats.totalMatchups + 1,
      'last_matchup_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (isDraw) {
      updates['draws'] = stats.draws + 1;
    } else {
      // Determine which user won based on ordering
      if (winnerId == stats.user1Id) {
        updates['user1_wins'] = stats.user1Wins + 1;
      } else {
        updates['user2_wins'] = stats.user2Wins + 1;
      }
    }

    await _db.client.update(
      'mini_activity_head_to_head',
      updates,
      filters: {'id': 'eq.${stats.id}'},
    );
  }

  Future<List<HeadToHeadStats>> getHeadToHeadForUser({
    required String teamId,
    required String userId,
  }) async {
    final result = await _db.client.select(
      'mini_activity_head_to_head',
      filters: {
        'team_id': 'eq.$teamId',
        'or': '(user1_id.eq.$userId,user2_id.eq.$userId)',
      },
      order: 'total_matchups.desc',
    );

    return result.map((row) => HeadToHeadStats.fromJson(row)).toList();
  }

  // ============ TEAM HISTORY ============

  Future<void> recordTeamHistory({
    required String userId,
    required String miniActivityId,
    String? miniTeamId,
    String? teamName,
    List<Map<String, dynamic>>? teammates,
    int? placement,
    int pointsEarned = 0,
    bool wasWinner = false,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('mini_activity_team_history', {
      'id': id,
      'user_id': userId,
      'mini_activity_id': miniActivityId,
      'mini_team_id': miniTeamId,
      'team_name': teamName,
      'teammates': teammates,
      'placement': placement,
      'points_earned': pointsEarned,
      'was_winner': wasWinner,
    });
  }

  Future<List<MiniActivityTeamHistory>> getTeamHistoryForUser({
    required String userId,
    int limit = 50,
  }) async {
    final result = await _db.client.select(
      'mini_activity_team_history',
      filters: {'user_id': 'eq.$userId'},
      order: 'recorded_at.desc',
    );

    return result
        .take(limit)
        .map((row) => MiniActivityTeamHistory.fromJson(row))
        .toList();
  }

  // ============ LEADERBOARD POINT SOURCES ============

  Future<void> recordPointSource({
    required String leaderboardEntryId,
    required String userId,
    required PointSourceType sourceType,
    required String sourceId,
    required int points,
    String? description,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('leaderboard_point_sources', {
      'id': id,
      'leaderboard_entry_id': leaderboardEntryId,
      'user_id': userId,
      'source_type': sourceType.value,
      'source_id': sourceId,
      'points': points,
      'description': description,
    });
  }

  Future<List<LeaderboardPointSource>> getPointSourcesForUser({
    required String userId,
    String? leaderboardEntryId,
    PointSourceType? sourceType,
    int limit = 100,
  }) async {
    final filters = <String, String>{'user_id': 'eq.$userId'};
    if (leaderboardEntryId != null) {
      filters['leaderboard_entry_id'] = 'eq.$leaderboardEntryId';
    }
    if (sourceType != null) {
      filters['source_type'] = 'eq.${sourceType.value}';
    }

    final result = await _db.client.select(
      'leaderboard_point_sources',
      filters: filters,
      order: 'recorded_at.desc',
    );

    return result
        .take(limit)
        .map((row) => LeaderboardPointSource.fromJson(row))
        .toList();
  }

  Future<List<LeaderboardPointSource>> getPointSourcesForEntry(String leaderboardEntryId) async {
    final result = await _db.client.select(
      'leaderboard_point_sources',
      filters: {'leaderboard_entry_id': 'eq.$leaderboardEntryId'},
      order: 'recorded_at.desc',
    );

    return result.map((row) => LeaderboardPointSource.fromJson(row)).toList();
  }

  // ============ AGGREGATED STATS ============

  Future<PlayerStatsAggregate?> getPlayerStatsAggregate({
    required String userId,
    required String teamId,
    String? seasonId,
  }) async {
    final stats = await getPlayerStats(
      userId: userId,
      teamId: teamId,
      seasonId: seasonId,
    );

    if (stats == null) return null;

    final headToHead = await getHeadToHeadForUser(
      teamId: teamId,
      userId: userId,
    );

    final recentHistory = await getTeamHistoryForUser(
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
      pointSources = await getPointSourcesForEntry(
        leaderboardResult.first['id'] as String,
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
    final stats = await getTeamPlayerStats(
      teamId: teamId,
      seasonId: seasonId,
      sortBy: 'points',
    );

    if (stats.isEmpty) return [];

    // Get user info
    final userIds = stats.map((s) => s.userId).toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

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
      final userId = result['user_id'] as String;
      final placement = result['placement'] as int?;
      final points = result['points'] as int? ?? 0;
      final wasWinner = result['was_winner'] as bool? ?? false;
      final teamName = result['team_name'] as String?;
      final teammates = result['teammates'] as List<Map<String, dynamic>>?;

      // Update player stats
      await updatePlayerStats(
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
      await recordTeamHistory(
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
    if (results.length == 2) {
      final result1 = results[0];
      final result2 = results[1];

      final winner1 = result1['was_winner'] as bool? ?? false;
      final winner2 = result2['was_winner'] as bool? ?? false;

      await recordHeadToHeadResult(
        teamId: teamId,
        winnerId: winner1 ? result1['user_id'] as String : result2['user_id'] as String,
        loserId: winner1 ? result2['user_id'] as String : result1['user_id'] as String,
        isDraw: !winner1 && !winner2,
      );
    }
  }
}
