import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/season.dart';
import '../models/mini_activity_statistics.dart';
import 'leaderboard_entry_service.dart';
import 'team_service.dart';

class LeaderboardService {
  final Database _db;
  final LeaderboardEntryService entryService;
  final TeamService _teamService;
  final _uuid = const Uuid();

  LeaderboardService(this._db, this.entryService, this._teamService);

  // ============ FORWARDING METHODS (delegate to entryService) ============

  Future<List<LeaderboardEntry>> getLeaderboardEntries(
    String leaderboardId, {
    int? limit,
    int offset = 0,
  }) =>
      entryService.getLeaderboardEntries(leaderboardId, limit: limit, offset: offset);

  Future<LeaderboardEntry?> getUserEntry(String leaderboardId, String userId) =>
      entryService.getUserEntry(leaderboardId, userId);

  Future<LeaderboardEntry> upsertEntry({
    required String leaderboardId,
    required String userId,
    required int points,
    bool addToExisting = true,
  }) =>
      entryService.upsertEntry(
        leaderboardId: leaderboardId,
        userId: userId,
        points: points,
        addToExisting: addToExisting,
      );

  Future<void> addPointsToUsers({
    required String leaderboardId,
    required Map<String, int> userPoints,
  }) =>
      entryService.addPointsToUsers(leaderboardId: leaderboardId, userPoints: userPoints);

  Future<void> resetLeaderboard(String leaderboardId) =>
      entryService.resetLeaderboard(leaderboardId);

  Future<LeaderboardEntry> addPointsWithSource({
    required String leaderboardId,
    required String userId,
    required int points,
    required PointSourceType sourceType,
    required String sourceId,
    String? description,
  }) =>
      entryService.addPointsWithSource(
        leaderboardId: leaderboardId,
        userId: userId,
        points: points,
        sourceType: sourceType,
        sourceId: sourceId,
        description: description,
      );

  Future<bool> hasPointsForSource({
    required String userId,
    required PointSourceType sourceType,
    required String sourceId,
  }) =>
      entryService.hasPointsForSource(
        userId: userId,
        sourceType: sourceType,
        sourceId: sourceId,
      );

  Future<List<MiniActivityPointConfig>> getPointConfigsForMiniActivity(
    String miniActivityId,
  ) =>
      entryService.getPointConfigsForMiniActivity(miniActivityId);

  Future<MiniActivityPointConfig> upsertPointConfig({
    required String miniActivityId,
    required String leaderboardId,
    String distributionType = 'winner_only',
    int pointsFirst = 5,
    int pointsSecond = 3,
    int pointsThird = 1,
    int pointsParticipation = 0,
  }) =>
      entryService.upsertPointConfig(
        miniActivityId: miniActivityId,
        leaderboardId: leaderboardId,
        distributionType: distributionType,
        pointsFirst: pointsFirst,
        pointsSecond: pointsSecond,
        pointsThird: pointsThird,
        pointsParticipation: pointsParticipation,
      );

  Future<void> deletePointConfig(String miniActivityId, String leaderboardId) =>
      entryService.deletePointConfig(miniActivityId, leaderboardId);

  // ============ LEADERBOARDS ============

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

    return result.map((row) => Leaderboard.fromJson(row)).toList();
  }

  Future<Leaderboard?> getLeaderboardById(String leaderboardId) async {
    final result = await _db.client.select(
      'leaderboards',
      filters: {'id': 'eq.$leaderboardId'},
    );

    if (result.isEmpty) return null;
    return Leaderboard.fromJson(result.first);
  }

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
    return Leaderboard.fromJson(result.first);
  }

  Future<Leaderboard> createLeaderboard({
    required String teamId,
    String? seasonId,
    required String name,
    String? description,
    bool isMain = false,
    int sortOrder = 0,
  }) async {
    final id = _uuid.v4();

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

  Future<void> deleteLeaderboard(String leaderboardId) async {
    await _db.client.delete(
      'leaderboards',
      filters: {'id': 'eq.$leaderboardId'},
    );
  }

  Future<String?> getTeamIdForLeaderboard(String leaderboardId) async {
    final result = await _db.client.select(
      'leaderboards',
      select: 'team_id',
      filters: {'id': 'eq.$leaderboardId'},
    );

    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
  }

  // ============ CATEGORY-BASED LEADERBOARDS ============

  Future<Leaderboard?> getLeaderboardByCategory(
    String teamId,
    LeaderboardCategory category, {
    String? seasonId,
  }) async {
    final filters = <String, String>{
      'team_id': 'eq.$teamId',
      'category': 'eq.${category.value}',
    };
    if (seasonId != null) {
      filters['season_id'] = 'eq.$seasonId';
    }

    final result = await _db.client.select(
      'leaderboards',
      filters: filters,
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Leaderboard.fromJson(result.first);
  }

  Future<Leaderboard> getOrCreateCategoryLeaderboard(
    String teamId,
    LeaderboardCategory category, {
    String? seasonId,
  }) async {
    var leaderboard = await getLeaderboardByCategory(
      teamId,
      category,
      seasonId: seasonId,
    );

    if (leaderboard != null) return leaderboard;

    final id = _uuid.v4();
    final name = category.displayName;

    await _db.client.insert('leaderboards', {
      'id': id,
      'team_id': teamId,
      'season_id': seasonId,
      'name': name,
      'category': category.value,
      'is_main': category == LeaderboardCategory.total,
      'sort_order': category.index,
    });

    return Leaderboard(
      id: id,
      teamId: teamId,
      seasonId: seasonId,
      name: name,
      category: category,
      isMain: category == LeaderboardCategory.total,
      sortOrder: category.index,
      createdAt: DateTime.now(),
    );
  }

  Future<Map<LeaderboardCategory, Leaderboard>> getCategoryLeaderboards(
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
      order: 'sort_order.asc',
    );

    final map = <LeaderboardCategory, Leaderboard>{};
    for (final row in result) {
      final leaderboard = Leaderboard.fromJson(row);
      map[leaderboard.category] = leaderboard;
    }

    return map;
  }

  // ============ RANKED LEADERBOARD VIEW ============

  Future<List<LeaderboardEntry>> getRankedEntries(
    String teamId, {
    LeaderboardCategory? category,
    String? seasonId,
    bool excludeOptedOut = true,
    int? limit,
    int offset = 0,
  }) async {
    Leaderboard? leaderboard;
    if (category != null) {
      leaderboard = await getLeaderboardByCategory(
        teamId,
        category,
        seasonId: seasonId,
      );
    } else {
      leaderboard = await getMainLeaderboard(teamId);
    }

    if (leaderboard == null) return [];

    final filters = <String, String>{
      'leaderboard_id': 'eq.${leaderboard.id}',
    };
    if (excludeOptedOut) {
      filters['leaderboard_opt_out'] = 'eq.false';
    }

    final result = await _db.client.select(
      'v_leaderboard_ranked',
      filters: filters,
      order: 'rank.asc',
      limit: limit,
      offset: offset,
    );

    final userIds = result.map((r) => r['user_id'] as String).toSet().toList();
    final users = await _db.client.select(
      'users',
      select: 'id,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );
    final avatarMap = <String, String?>{};
    for (final u in users) {
      avatarMap[u['id'] as String] = u['avatar_url'] as String?;
    }

    return result.map((row) {
      return LeaderboardEntry(
        id: row['user_id'] as String,
        leaderboardId: leaderboard!.id,
        userId: row['user_id'] as String,
        points: row['points'] as int? ?? 0,
        updatedAt: DateTime.now(),
        userName: row['user_name'] as String?,
        userAvatarUrl: avatarMap[row['user_id'] as String],
        rank: row['rank'] as int?,
        attendanceRate: (row['attendance_rate'] as num?)?.toDouble(),
        currentStreak: row['current_streak'] as int?,
        optedOut: row['leaderboard_opt_out'] as bool?,
      );
    }).toList();
  }

  Future<LeaderboardEntry?> getUserRankedPosition(
    String teamId,
    String userId, {
    LeaderboardCategory? category,
    String? seasonId,
  }) async {
    Leaderboard? leaderboard;
    if (category != null) {
      leaderboard = await getLeaderboardByCategory(
        teamId,
        category,
        seasonId: seasonId,
      );
    } else {
      leaderboard = await getMainLeaderboard(teamId);
    }

    if (leaderboard == null) return null;

    final result = await _db.client.select(
      'v_leaderboard_ranked',
      filters: {
        'leaderboard_id': 'eq.${leaderboard.id}',
        'user_id': 'eq.$userId',
      },
    );

    if (result.isEmpty) return null;

    final row = result.first;
    return LeaderboardEntry(
      id: row['user_id'] as String,
      leaderboardId: leaderboard.id,
      userId: row['user_id'] as String,
      points: row['points'] as int? ?? 0,
      updatedAt: DateTime.now(),
      userName: row['user_name'] as String?,
      rank: row['rank'] as int?,
      attendanceRate: (row['attendance_rate'] as num?)?.toDouble(),
      currentStreak: row['current_streak'] as int?,
      optedOut: row['leaderboard_opt_out'] as bool?,
    );
  }

  // ============ MONTHLY STATS INTEGRATION ============

  Future<List<LeaderboardEntry>> getLeaderboardWithTrends(
    String teamId, {
    LeaderboardCategory? category,
    String? seasonId,
    int? limit,
  }) async {
    final entries = await getRankedEntries(
      teamId,
      category: category,
      seasonId: seasonId,
      limit: limit,
    );

    final userIds = entries.map((e) => e.userId).toList();
    if (userIds.isEmpty) return entries;

    final trends = await _db.client.select(
      'v_monthly_trends',
      filters: {
        'team_id': 'eq.$teamId',
        'user_id': 'in.(${userIds.join(',')})',
        'year': 'eq.${DateTime.now().year}',
        'month': 'eq.${DateTime.now().month}',
      },
    );

    final trendMap = <String, Map<String, dynamic>>{};
    for (final t in trends) {
      trendMap[t['user_id'] as String] = t;
    }

    return entries.map((entry) {
      final trend = trendMap[entry.userId];
      if (trend == null) return entry;

      return LeaderboardEntry(
        id: entry.id,
        leaderboardId: entry.leaderboardId,
        userId: entry.userId,
        points: entry.points,
        updatedAt: entry.updatedAt,
        userName: entry.userName,
        userAvatarUrl: entry.userAvatarUrl,
        rank: entry.rank,
        attendanceRate: entry.attendanceRate,
        currentStreak: entry.currentStreak,
        optedOut: entry.optedOut,
        trend: trend['trend'] as String?,
        rankChange: (trend['point_change'] as num?)?.toInt(),
      );
    }).toList();
  }

  Future<double> calculateWeightedTotal(
    String userId,
    String teamId, {
    String? seasonId,
  }) async {
    final configResult = await _db.client.select(
      'team_points_config',
      filters: {'team_id': 'eq.$teamId'},
      limit: 1,
    );

    double trainingWeight = 1.0;
    double matchWeight = 1.5;
    double socialWeight = 0.5;
    double competitionWeight = 1.0;

    if (configResult.isNotEmpty) {
      final config = configResult.first;
      trainingWeight = (config['training_weight'] as num?)?.toDouble() ?? 1.0;
      matchWeight = (config['match_weight'] as num?)?.toDouble() ?? 1.5;
      socialWeight = (config['social_weight'] as num?)?.toDouble() ?? 0.5;
      competitionWeight =
          (config['competition_weight'] as num?)?.toDouble() ?? 1.0;
    }

    final categoryLeaderboards = await getCategoryLeaderboards(
      teamId,
      seasonId: seasonId,
    );

    double total = 0.0;

    for (final entry in categoryLeaderboards.entries) {
      final categoryEntry = await getUserEntry(entry.value.id, userId);
      if (categoryEntry == null) continue;

      final points = categoryEntry.points.toDouble();
      switch (entry.key) {
        case LeaderboardCategory.training:
          total += points * trainingWeight;
          break;
        case LeaderboardCategory.match:
          total += points * matchWeight;
          break;
        case LeaderboardCategory.social:
          total += points * socialWeight;
          break;
        case LeaderboardCategory.competition:
          total += points * competitionWeight;
          break;
        default:
          total += points;
      }
    }

    return total;
  }

  Future<void> syncTotalLeaderboard(
    String teamId, {
    String? seasonId,
  }) async {
    final totalLeaderboard = await getOrCreateCategoryLeaderboard(
      teamId,
      LeaderboardCategory.total,
      seasonId: seasonId,
    );

    final memberUserIds = await _teamService.getTeamMemberUserIds(teamId);

    for (final userId in memberUserIds) {
      final weightedTotal = await calculateWeightedTotal(
        userId,
        teamId,
        seasonId: seasonId,
      );

      await upsertEntry(
        leaderboardId: totalLeaderboard.id,
        userId: userId,
        points: weightedTotal.round(),
        addToExisting: false,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getUserMonthlyStats(
    String teamId,
    String userId, {
    int? year,
    int? month,
    int? limit,
  }) async {
    final filters = <String, String>{
      'team_id': 'eq.$teamId',
      'user_id': 'eq.$userId',
    };

    if (year != null) filters['year'] = 'eq.$year';
    if (month != null) filters['month'] = 'eq.$month';

    final result = await _db.client.select(
      'monthly_user_stats',
      filters: filters,
      order: 'year.desc,month.desc',
      limit: limit,
    );

    return result;
  }
}
