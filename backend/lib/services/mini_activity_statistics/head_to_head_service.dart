import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/mini_activity_statistics.dart';

class MiniActivityHeadToHeadService {
  final Database _db;
  final _uuid = const Uuid();

  MiniActivityHeadToHeadService(this._db);

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
}
