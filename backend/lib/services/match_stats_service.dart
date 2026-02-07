import '../db/database.dart';
import '../models/statistics.dart';
import 'user_service.dart';

/// Service for recording and retrieving match statistics
class MatchStatsService {
  final Database _db;
  final UserService _userService;

  MatchStatsService(this._db, this._userService);

  Future<MatchStats?> recordMatchStats({
    required String instanceId,
    required String userId,
    int goals = 0,
    int assists = 0,
    int minutesPlayed = 0,
    int yellowCards = 0,
    int redCards = 0,
  }) async {
    // Check for existing stats
    final existing = await _db.client.select(
      'match_stats',
      filters: {
        'instance_id': 'eq.$instanceId',
        'user_id': 'eq.$userId',
      },
    );

    List<Map<String, dynamic>> result;
    if (existing.isNotEmpty) {
      // Update existing
      result = await _db.client.update(
        'match_stats',
        {
          'goals': goals,
          'assists': assists,
          'minutes_played': minutesPlayed,
          'yellow_cards': yellowCards,
          'red_cards': redCards,
        },
        filters: {
          'instance_id': 'eq.$instanceId',
          'user_id': 'eq.$userId',
        },
      );
    } else {
      // Insert new
      result = await _db.client.insert('match_stats', {
        'instance_id': instanceId,
        'user_id': userId,
        'goals': goals,
        'assists': assists,
        'minutes_played': minutesPlayed,
        'yellow_cards': yellowCards,
        'red_cards': redCards,
      });
    }

    if (result.isEmpty) return null;

    // Update season stats
    await _updateSeasonStats(userId, instanceId, goals, assists);

    return MatchStats.fromJson(result.first);
  }

  Future<List<MatchStats>> getMatchStats(String instanceId) async {
    // Get match stats
    final stats = await _db.client.select(
      'match_stats',
      filters: {'instance_id': 'eq.$instanceId'},
      order: 'goals.desc,assists.desc',
    );

    if (stats.isEmpty) return [];

    // Get user info
    final userIds = stats.map((s) => s['user_id'] as String).toList();
    final userMap = await _userService.getUserMap(userIds);

    return stats.map((s) {
      final user = userMap[s['user_id']] ?? {};
      return MatchStats.fromJson({
        ...s,
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
      });
    }).toList();
  }

  // Helper: Update season stats after match
  Future<void> _updateSeasonStats(String userId, String instanceId, int goals, int assists) async {
    // Get instance
    final instances = await _db.client.select(
      'activity_instances',
      select: 'activity_id',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instances.isEmpty) return;

    // Get activity to find team_id
    final activities = await _db.client.select(
      'activities',
      select: 'team_id',
      filters: {'id': 'eq.${instances.first['activity_id']}'},
    );

    if (activities.isEmpty) return;

    final teamId = activities.first['team_id'] as String;
    final year = DateTime.now().year;

    // Check for existing season stats
    final existing = await _db.client.select(
      'season_stats',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
        'season_year': 'eq.$year',
      },
    );

    if (existing.isNotEmpty) {
      final current = existing.first;
      await _db.client.update(
        'season_stats',
        {
          'total_goals': (current['total_goals'] as int? ?? 0) + goals,
          'total_assists': (current['total_assists'] as int? ?? 0) + assists,
        },
        filters: {
          'user_id': 'eq.$userId',
          'team_id': 'eq.$teamId',
          'season_year': 'eq.$year',
        },
      );
    } else {
      await _db.client.insert('season_stats', {
        'user_id': userId,
        'team_id': teamId,
        'season_year': year,
        'total_goals': goals,
        'total_assists': assists,
      });
    }
  }
}
