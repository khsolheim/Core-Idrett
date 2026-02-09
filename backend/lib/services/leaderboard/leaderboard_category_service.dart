import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/season.dart';

class LeaderboardCategoryService {
  final Database _db;
  final _uuid = const Uuid();

  LeaderboardCategoryService(this._db);

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
}
