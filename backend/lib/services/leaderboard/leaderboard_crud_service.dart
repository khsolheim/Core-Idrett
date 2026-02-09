import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/season.dart';
import '../../models/mini_activity_statistics.dart';
import '../leaderboard_entry_service.dart';
import '../../helpers/parsing_helpers.dart';

class LeaderboardCrudService {
  final Database _db;
  final LeaderboardEntryService entryService;
  final _uuid = const Uuid();

  LeaderboardCrudService(this._db, this.entryService);

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
    return safeStringNullable(result.first, 'team_id');
  }
}
