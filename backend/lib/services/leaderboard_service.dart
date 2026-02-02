import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/season.dart';
import '../models/mini_activity_statistics.dart';

class LeaderboardService {
  final Database _db;
  final _uuid = const Uuid();

  LeaderboardService(this._db);

  // ============ LEADERBOARDS ============

  /// Get all leaderboards for a team (optionally filtered by season)
  Future<List<Leaderboard>> getLeaderboardsForTeam(
    String teamId, {
    String? seasonId,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (seasonId != null) {
      filters['season_id'] = 'eq.$seasonId';
    }

    final result = await _db.client.select(
      'leaderboards',
      filters: filters,
      order: 'is_main.desc,sort_order.asc,name.asc',
    );

    return result.map((row) => Leaderboard.fromRow(row)).toList();
  }

  /// Get a leaderboard by ID
  Future<Leaderboard?> getLeaderboardById(String leaderboardId) async {
    final result = await _db.client.select(
      'leaderboards',
      filters: {'id': 'eq.$leaderboardId'},
    );

    if (result.isEmpty) return null;
    return Leaderboard.fromRow(result.first);
  }

  /// Get the main leaderboard for a team's active season
  Future<Leaderboard?> getMainLeaderboard(String teamId) async {
    final result = await _db.client.select(
      'leaderboards',
      filters: {
        'team_id': 'eq.$teamId',
        'is_main': 'eq.true',
      },
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Leaderboard.fromRow(result.first);
  }

  /// Create a new leaderboard
  Future<Leaderboard> createLeaderboard({
    required String teamId,
    String? seasonId,
    required String name,
    String? description,
    bool isMain = false,
    int sortOrder = 0,
  }) async {
    final id = _uuid.v4();

    // If setting as main, unset other main leaderboards
    if (isMain) {
      final filters = <String, String>{'team_id': 'eq.$teamId'};
      if (seasonId != null) {
        filters['season_id'] = 'eq.$seasonId';
      }
      await _db.client.update(
        'leaderboards',
        {'is_main': false},
        filters: filters,
      );
    }

    await _db.client.insert('leaderboards', {
      'id': id,
      'team_id': teamId,
      'season_id': seasonId,
      'name': name,
      'description': description,
      'is_main': isMain,
      'sort_order': sortOrder,
    });

    return Leaderboard(
      id: id,
      teamId: teamId,
      seasonId: seasonId,
      name: name,
      description: description,
      isMain: isMain,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
  }

  /// Update a leaderboard
  Future<Leaderboard?> updateLeaderboard({
    required String leaderboardId,
    String? name,
    String? description,
    bool? isMain,
    int? sortOrder,
    bool clearDescription = false,
  }) async {
    final current = await getLeaderboardById(leaderboardId);
    if (current == null) return null;

    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (clearDescription) {
      updates['description'] = null;
    } else if (description != null) {
      updates['description'] = description;
    }
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    // Handle is_main separately to unset others
    if (isMain == true) {
      final filters = <String, String>{'team_id': 'eq.${current.teamId}'};
      if (current.seasonId != null) {
        filters['season_id'] = 'eq.${current.seasonId}';
      }
      await _db.client.update(
        'leaderboards',
        {'is_main': false},
        filters: filters,
      );
      updates['is_main'] = true;
    } else if (isMain == false) {
      updates['is_main'] = false;
    }

    if (updates.isEmpty) {
      return current;
    }

    await _db.client.update(
      'leaderboards',
      updates,
      filters: {'id': 'eq.$leaderboardId'},
    );

    return getLeaderboardById(leaderboardId);
  }

  /// Delete a leaderboard
  Future<void> deleteLeaderboard(String leaderboardId) async {
    await _db.client.delete(
      'leaderboards',
      filters: {'id': 'eq.$leaderboardId'},
    );
  }

  // ============ LEADERBOARD ENTRIES ============

  /// Get entries for a leaderboard with user info and ranking
  Future<List<LeaderboardEntry>> getLeaderboardEntries(
    String leaderboardId, {
    int? limit,
    int offset = 0,
  }) async {
    final entries = await _db.client.select(
      'leaderboard_entries',
      filters: {'leaderboard_id': 'eq.$leaderboardId'},
      order: 'points.desc,updated_at.asc',
      limit: limit,
      offset: offset,
    );

    if (entries.isEmpty) return [];

    // Get user info
    final userIds = entries.map((e) => e['user_id'] as String).toSet().toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    // Build entries with rank
    final result = <LeaderboardEntry>[];
    int currentRank = offset + 1;
    int? lastPoints;
    int sameRankCount = 0;

    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      final points = e['points'] as int? ?? 0;
      final user = userMap[e['user_id']] ?? {};

      // Handle ties (same points = same rank)
      if (lastPoints != null && points == lastPoints) {
        sameRankCount++;
      } else {
        currentRank += sameRankCount;
        sameRankCount = 0;
      }
      lastPoints = points;

      final entry = LeaderboardEntry(
        id: e['id'] as String,
        leaderboardId: e['leaderboard_id'] as String,
        userId: e['user_id'] as String,
        points: points,
        updatedAt: DateTime.parse(e['updated_at'] as String),
        userName: user['name'] as String?,
        userAvatarUrl: user['avatar_url'] as String?,
        rank: currentRank,
      );

      result.add(entry);
      if (i == 0 || points != lastPoints) {
        currentRank++;
      }
    }

    return result;
  }

  /// Get a user's entry in a leaderboard
  Future<LeaderboardEntry?> getUserEntry(
    String leaderboardId,
    String userId,
  ) async {
    final result = await _db.client.select(
      'leaderboard_entries',
      filters: {
        'leaderboard_id': 'eq.$leaderboardId',
        'user_id': 'eq.$userId',
      },
    );

    if (result.isEmpty) return null;

    // Get rank by counting entries with more points
    final pointsResult = await _db.client.select(
      'leaderboard_entries',
      select: 'id',
      filters: {
        'leaderboard_id': 'eq.$leaderboardId',
        'points': 'gt.${result.first['points']}',
      },
    );

    final rank = pointsResult.length + 1;

    return LeaderboardEntry.fromRow(result.first, rank: rank);
  }

  /// Add or update points for a user in a leaderboard
  Future<LeaderboardEntry> upsertEntry({
    required String leaderboardId,
    required String userId,
    required int points,
    bool addToExisting = true,
  }) async {
    // Check for existing entry
    final existing = await _db.client.select(
      'leaderboard_entries',
      filters: {
        'leaderboard_id': 'eq.$leaderboardId',
        'user_id': 'eq.$userId',
      },
    );

    if (existing.isEmpty) {
      // Insert new entry
      final id = _uuid.v4();
      await _db.client.insert('leaderboard_entries', {
        'id': id,
        'leaderboard_id': leaderboardId,
        'user_id': userId,
        'points': points,
      });

      return LeaderboardEntry(
        id: id,
        leaderboardId: leaderboardId,
        userId: userId,
        points: points,
        updatedAt: DateTime.now(),
      );
    } else {
      // Update existing entry
      final currentPoints = existing.first['points'] as int? ?? 0;
      final newPoints = addToExisting ? currentPoints + points : points;

      await _db.client.update(
        'leaderboard_entries',
        {
          'points': newPoints,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {
          'leaderboard_id': 'eq.$leaderboardId',
          'user_id': 'eq.$userId',
        },
      );

      return LeaderboardEntry(
        id: existing.first['id'] as String,
        leaderboardId: leaderboardId,
        userId: userId,
        points: newPoints,
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Add points to multiple users at once
  Future<void> addPointsToUsers({
    required String leaderboardId,
    required Map<String, int> userPoints, // userId -> points to add
  }) async {
    for (final entry in userPoints.entries) {
      await upsertEntry(
        leaderboardId: leaderboardId,
        userId: entry.key,
        points: entry.value,
        addToExisting: true,
      );
    }
  }

  /// Reset all entries in a leaderboard
  Future<void> resetLeaderboard(String leaderboardId) async {
    await _db.client.update(
      'leaderboard_entries',
      {'points': 0, 'updated_at': DateTime.now().toIso8601String()},
      filters: {'leaderboard_id': 'eq.$leaderboardId'},
    );
  }

  /// Add points to a user's leaderboard entry with a traceable source
  /// This creates both the leaderboard entry (if needed) and a point source record
  Future<LeaderboardEntry> addPointsWithSource({
    required String leaderboardId,
    required String userId,
    required int points,
    required PointSourceType sourceType,
    required String sourceId,
    String? description,
  }) async {
    // Find or create the leaderboard entry
    final existing = await _db.client.select(
      'leaderboard_entries',
      filters: {
        'leaderboard_id': 'eq.$leaderboardId',
        'user_id': 'eq.$userId',
      },
    );

    String entryId;
    int newPoints;

    if (existing.isEmpty) {
      // Create new entry
      entryId = _uuid.v4();
      newPoints = points;
      await _db.client.insert('leaderboard_entries', {
        'id': entryId,
        'leaderboard_id': leaderboardId,
        'user_id': userId,
        'points': newPoints,
      });
    } else {
      // Update existing entry
      entryId = existing.first['id'] as String;
      final currentPoints = existing.first['points'] as int? ?? 0;
      newPoints = currentPoints + points;

      await _db.client.update(
        'leaderboard_entries',
        {
          'points': newPoints,
          'updated_at': DateTime.now().toIso8601String(),
        },
        filters: {'id': 'eq.$entryId'},
      );
    }

    // Record the point source for traceability
    await _db.client.insert('leaderboard_point_sources', {
      'id': _uuid.v4(),
      'leaderboard_entry_id': entryId,
      'user_id': userId,
      'source_type': sourceType.value,
      'source_id': sourceId,
      'points': points,
      'description': description,
    });

    return LeaderboardEntry(
      id: entryId,
      leaderboardId: leaderboardId,
      userId: userId,
      points: newPoints,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if points have already been awarded for a specific source
  Future<bool> hasPointsForSource({
    required String userId,
    required PointSourceType sourceType,
    required String sourceId,
  }) async {
    final result = await _db.client.select(
      'leaderboard_point_sources',
      select: 'id',
      filters: {
        'user_id': 'eq.$userId',
        'source_type': 'eq.${sourceType.value}',
        'source_id': 'eq.$sourceId',
      },
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Get team ID for a leaderboard (for authorization checks)
  Future<String?> getTeamIdForLeaderboard(String leaderboardId) async {
    final result = await _db.client.select(
      'leaderboards',
      select: 'team_id',
      filters: {'id': 'eq.$leaderboardId'},
    );

    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
  }

  // ============ POINT CONFIGURATION ============

  /// Get point configurations for a mini-activity
  Future<List<MiniActivityPointConfig>> getPointConfigsForMiniActivity(
    String miniActivityId,
  ) async {
    final result = await _db.client.select(
      'mini_activity_point_config',
      filters: {'mini_activity_id': 'eq.$miniActivityId'},
    );

    return result.map((row) => MiniActivityPointConfig.fromRow(row)).toList();
  }

  /// Create or update point configuration
  Future<MiniActivityPointConfig> upsertPointConfig({
    required String miniActivityId,
    required String leaderboardId,
    String distributionType = 'winner_only',
    int pointsFirst = 5,
    int pointsSecond = 3,
    int pointsThird = 1,
    int pointsParticipation = 0,
  }) async {
    // Check for existing
    final existing = await _db.client.select(
      'mini_activity_point_config',
      filters: {
        'mini_activity_id': 'eq.$miniActivityId',
        'leaderboard_id': 'eq.$leaderboardId',
      },
    );

    if (existing.isEmpty) {
      final id = _uuid.v4();
      await _db.client.insert('mini_activity_point_config', {
        'id': id,
        'mini_activity_id': miniActivityId,
        'leaderboard_id': leaderboardId,
        'distribution_type': distributionType,
        'points_first': pointsFirst,
        'points_second': pointsSecond,
        'points_third': pointsThird,
        'points_participation': pointsParticipation,
      });

      return MiniActivityPointConfig(
        id: id,
        miniActivityId: miniActivityId,
        leaderboardId: leaderboardId,
        distributionType: distributionType,
        pointsFirst: pointsFirst,
        pointsSecond: pointsSecond,
        pointsThird: pointsThird,
        pointsParticipation: pointsParticipation,
      );
    } else {
      await _db.client.update(
        'mini_activity_point_config',
        {
          'distribution_type': distributionType,
          'points_first': pointsFirst,
          'points_second': pointsSecond,
          'points_third': pointsThird,
          'points_participation': pointsParticipation,
        },
        filters: {
          'mini_activity_id': 'eq.$miniActivityId',
          'leaderboard_id': 'eq.$leaderboardId',
        },
      );

      return MiniActivityPointConfig(
        id: existing.first['id'] as String,
        miniActivityId: miniActivityId,
        leaderboardId: leaderboardId,
        distributionType: distributionType,
        pointsFirst: pointsFirst,
        pointsSecond: pointsSecond,
        pointsThird: pointsThird,
        pointsParticipation: pointsParticipation,
      );
    }
  }

  /// Delete a point configuration
  Future<void> deletePointConfig(String miniActivityId, String leaderboardId) async {
    await _db.client.delete(
      'mini_activity_point_config',
      filters: {
        'mini_activity_id': 'eq.$miniActivityId',
        'leaderboard_id': 'eq.$leaderboardId',
      },
    );
  }
}
