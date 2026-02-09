import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/mini_activity_statistics.dart';

class MiniActivityPlayerStatsService {
  final Database _db;
  final _uuid = const Uuid();

  MiniActivityPlayerStatsService(this._db);

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
}
