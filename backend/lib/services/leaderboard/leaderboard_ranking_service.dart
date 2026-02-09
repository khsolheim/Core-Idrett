import '../../db/database.dart';
import '../../models/season.dart';
import '../team_service.dart';
import '../../helpers/parsing_helpers.dart';
import 'leaderboard_crud_service.dart';
import 'leaderboard_category_service.dart';

class LeaderboardRankingService {
  final Database _db;
  final LeaderboardCrudService _crudService;
  final LeaderboardCategoryService _categoryService;
  final TeamService _teamService;

  LeaderboardRankingService(
    this._db,
    this._crudService,
    this._categoryService,
    this._teamService,
  );

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
      leaderboard = await _categoryService.getLeaderboardByCategory(
        teamId,
        category,
        seasonId: seasonId,
      );
    } else {
      leaderboard = await _crudService.getMainLeaderboard(teamId);
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

    final userIds = result.map((r) => safeString(r, 'user_id')).toSet().toList();
    final users = await _db.client.select(
      'users',
      select: 'id,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );
    final avatarMap = <String, String?>{};
    for (final u in users) {
      avatarMap[safeString(u, 'id')] = safeStringNullable(u, 'avatar_url');
    }

    return result.map((row) {
      return LeaderboardEntry(
        id: safeString(row, 'user_id'),
        leaderboardId: leaderboard!.id,
        userId: safeString(row, 'user_id'),
        points: safeInt(row, 'points', defaultValue: 0),
        updatedAt: DateTime.now(),
        userName: safeStringNullable(row, 'user_name'),
        userAvatarUrl: avatarMap[safeString(row, 'user_id')],
        rank: safeIntNullable(row, 'rank'),
        attendanceRate: (row['attendance_rate'] as num?)?.toDouble(),
        currentStreak: safeIntNullable(row, 'current_streak'),
        optedOut: safeBoolNullable(row, 'leaderboard_opt_out'),
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
      leaderboard = await _categoryService.getLeaderboardByCategory(
        teamId,
        category,
        seasonId: seasonId,
      );
    } else {
      leaderboard = await _crudService.getMainLeaderboard(teamId);
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
      id: safeString(row, 'user_id'),
      leaderboardId: leaderboard.id,
      userId: safeString(row, 'user_id'),
      points: safeInt(row, 'points', defaultValue: 0),
      updatedAt: DateTime.now(),
      userName: safeStringNullable(row, 'user_name'),
      rank: safeIntNullable(row, 'rank'),
      attendanceRate: (row['attendance_rate'] as num?)?.toDouble(),
      currentStreak: safeIntNullable(row, 'current_streak'),
      optedOut: safeBoolNullable(row, 'leaderboard_opt_out'),
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
      trendMap[safeString(t, 'user_id')] = t;
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
        trend: safeStringNullable(trend, 'trend'),
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

    final categoryLeaderboards = await _categoryService.getCategoryLeaderboards(
      teamId,
      seasonId: seasonId,
    );

    double total = 0.0;

    for (final entry in categoryLeaderboards.entries) {
      final categoryEntry = await _crudService.getUserEntry(entry.value.id, userId);
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
    final totalLeaderboard = await _categoryService.getOrCreateCategoryLeaderboard(
      teamId,
      LeaderboardCategory.total,
      seasonId: seasonId,
    );

    final memberUserIds = await _teamService.getTeamMemberUserIds(teamId);
    if (memberUserIds.isEmpty) return;

    // Fetch weights once (shared across all users)
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

    // Fetch category leaderboards once (shared across all users)
    final categoryLeaderboards = await _categoryService.getCategoryLeaderboards(
      teamId,
      seasonId: seasonId,
    );

    if (categoryLeaderboards.isEmpty) {
      // No category leaderboards, set all to 0
      for (final userId in memberUserIds) {
        await _crudService.upsertEntry(
          leaderboardId: totalLeaderboard.id,
          userId: userId,
          points: 0,
          addToExisting: false,
        );
      }
      return;
    }

    // Batch fetch ALL entries for all category leaderboards at once
    final leaderboardIds = categoryLeaderboards.values.map((lb) => lb.id).toList();
    final allEntries = await _db.client.select(
      'leaderboard_entries',
      filters: {
        'leaderboard_id': 'in.(${leaderboardIds.join(',')})',
        'user_id': 'in.(${memberUserIds.join(',')})',
      },
    );

    // Build lookup: leaderboardId -> userId -> points
    final entryLookup = <String, Map<String, int>>{};
    for (final e in allEntries) {
      final lbId = safeString(e, 'leaderboard_id');
      final uId = safeString(e, 'user_id');
      final pts = safeInt(e, 'points', defaultValue: 0);
      entryLookup.putIfAbsent(lbId, () => {})[uId] = pts;
    }

    // Calculate weighted total per user in memory
    for (final userId in memberUserIds) {
      double total = 0.0;

      for (final entry in categoryLeaderboards.entries) {
        final lbId = entry.value.id;
        final points = (entryLookup[lbId]?[userId] ?? 0).toDouble();

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

      await _crudService.upsertEntry(
        leaderboardId: totalLeaderboard.id,
        userId: userId,
        points: total.round(),
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
