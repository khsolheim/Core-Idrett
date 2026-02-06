import 'dart:math' as math;
import '../db/database.dart';
import '../models/statistics.dart';

class StatisticsService {
  final Database _db;

  StatisticsService(this._db);

  // Match Stats
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
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    return stats.map((s) {
      final user = userMap[s['user_id']] ?? {};
      return MatchStats.fromJson({
        ...s,
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
      });
    }).toList();
  }

  // Player Ratings
  Future<PlayerRating?> getPlayerRating(String userId, String teamId) async {
    final result = await _db.client.select(
      'player_ratings',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );

    if (result.isEmpty) return null;

    // Get user info
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'eq.$userId'},
    );

    final user = users.isNotEmpty ? users.first : <String, dynamic>{};

    return PlayerRating.fromJson({
      ...result.first,
      'user_name': user['name'],
      'user_avatar_url': user['avatar_url'],
    });
  }

  Future<PlayerRating> getOrCreatePlayerRating(String userId, String teamId) async {
    var rating = await getPlayerRating(userId, teamId);
    if (rating != null) return rating;

    // Create new rating
    final result = await _db.client.insert('player_ratings', {
      'user_id': userId,
      'team_id': teamId,
    });

    // Get user info
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'eq.$userId'},
    );

    final user = users.isNotEmpty ? users.first : <String, dynamic>{};

    return PlayerRating.fromJson({
      ...result.first,
      'user_name': user['name'],
      'user_avatar_url': user['avatar_url'],
    });
  }

  Future<void> updateRatingsAfterMatch({
    required String teamId,
    required List<String> winnerIds,
    required List<String> loserIds,
    bool isDraw = false,
  }) async {
    const kFactor = 32.0;

    if (isDraw) {
      // Update draws for all participants
      for (final playerId in [...winnerIds, ...loserIds]) {
        final existing = await _db.client.select(
          'player_ratings',
          filters: {
            'user_id': 'eq.$playerId',
            'team_id': 'eq.$teamId',
          },
        );

        if (existing.isNotEmpty) {
          final current = existing.first;
          await _db.client.update(
            'player_ratings',
            {'draws': (current['draws'] as int? ?? 0) + 1},
            filters: {
              'user_id': 'eq.$playerId',
              'team_id': 'eq.$teamId',
            },
          );
        }
      }
      return;
    }

    // Calculate average ratings
    double winnerAvg = 0;
    double loserAvg = 0;

    for (final playerId in winnerIds) {
      final rating = await getOrCreatePlayerRating(playerId, teamId);
      winnerAvg += rating.rating;
    }
    winnerAvg /= winnerIds.length;

    for (final playerId in loserIds) {
      final rating = await getOrCreatePlayerRating(playerId, teamId);
      loserAvg += rating.rating;
    }
    loserAvg /= loserIds.length;

    // Calculate expected scores
    final expectedWinner = 1 / (1 + math.pow(10, (loserAvg - winnerAvg) / 400));
    final expectedLoser = 1 - expectedWinner;

    // Calculate rating changes
    final winnerChange = (kFactor * (1 - expectedWinner)).round();
    final loserChange = (kFactor * (0 - expectedLoser)).round();

    // Update winners
    for (final playerId in winnerIds) {
      final existing = await _db.client.select(
        'player_ratings',
        filters: {
          'user_id': 'eq.$playerId',
          'team_id': 'eq.$teamId',
        },
      );

      if (existing.isNotEmpty) {
        final current = existing.first;
        await _db.client.update(
          'player_ratings',
          {
            'rating': (current['rating'] as num? ?? 1000) + winnerChange,
            'wins': (current['wins'] as int? ?? 0) + 1,
          },
          filters: {
            'user_id': 'eq.$playerId',
            'team_id': 'eq.$teamId',
          },
        );
      }
    }

    // Update losers
    for (final playerId in loserIds) {
      final existing = await _db.client.select(
        'player_ratings',
        filters: {
          'user_id': 'eq.$playerId',
          'team_id': 'eq.$teamId',
        },
      );

      if (existing.isNotEmpty) {
        final current = existing.first;
        final newRating = math.max(100, (current['rating'] as num? ?? 1000) + loserChange);
        await _db.client.update(
          'player_ratings',
          {
            'rating': newRating,
            'losses': (current['losses'] as int? ?? 0) + 1,
          },
          filters: {
            'user_id': 'eq.$playerId',
            'team_id': 'eq.$teamId',
          },
        );
      }
    }
  }

  // Leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(String teamId, {int? seasonYear}) async {
    final year = seasonYear ?? DateTime.now().year;

    // Get team members
    final members = await _db.client.select(
      'team_members',
      select: 'user_id',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (members.isEmpty) return [];

    final userIds = members.map((m) => m['user_id'] as String).toList();

    // Get users
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    // Get season stats
    final seasonStats = await _db.client.select(
      'season_stats',
      filters: {
        'team_id': 'eq.$teamId',
        'season_year': 'eq.$year',
        'user_id': 'in.(${userIds.join(',')})',
      },
    );

    final seasonMap = <String, Map<String, dynamic>>{};
    for (final s in seasonStats) {
      seasonMap[s['user_id'] as String] = s;
    }

    // Get player ratings
    final ratings = await _db.client.select(
      'player_ratings',
      filters: {
        'team_id': 'eq.$teamId',
        'user_id': 'in.(${userIds.join(',')})',
      },
    );

    final ratingMap = <String, Map<String, dynamic>>{};
    for (final r in ratings) {
      ratingMap[r['user_id'] as String] = r;
    }

    // Build leaderboard entries
    final entries = <_LeaderboardData>[];
    for (final userId in userIds) {
      final user = userMap[userId] ?? {};
      final season = seasonMap[userId] ?? {};
      final rating = ratingMap[userId] ?? {};

      entries.add(_LeaderboardData(
        userId: userId,
        userName: user['name'] as String? ?? '',
        userAvatarUrl: user['avatar_url'] as String?,
        totalPoints: (season['total_points'] as num?)?.toInt() ?? 0,
        rating: (rating['rating'] as num?)?.toDouble() ?? 1000.0,
        wins: (rating['wins'] as num?)?.toInt() ?? 0,
        losses: (rating['losses'] as num?)?.toInt() ?? 0,
        draws: (rating['draws'] as num?)?.toInt() ?? 0,
      ));
    }

    // Sort by points then rating
    entries.sort((a, b) {
      final pointsCompare = b.totalPoints.compareTo(a.totalPoints);
      if (pointsCompare != 0) return pointsCompare;
      return b.rating.compareTo(a.rating);
    });

    // Add ranks
    final result = <LeaderboardEntry>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      result.add(LeaderboardEntry(
        rank: i + 1,
        userId: e.userId,
        userName: e.userName,
        userAvatarUrl: e.userAvatarUrl,
        totalPoints: e.totalPoints,
        rating: e.rating,
        wins: e.wins,
        losses: e.losses,
        draws: e.draws,
      ));
    }

    return result;
  }

  // Player Statistics
  Future<PlayerStatistics?> getPlayerStatistics(String userId, String teamId) async {
    // Get user info and verify membership
    final membership = await _db.client.select(
      'team_members',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );

    if (membership.isEmpty) return null;

    // Get user
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'eq.$userId'},
    );

    if (users.isEmpty) return null;
    final user = users.first;

    // Get rating
    final rating = await getPlayerRating(userId, teamId);

    // Get current season stats
    final seasonYear = DateTime.now().year;
    final seasonResult = await _db.client.select(
      'season_stats',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
        'season_year': 'eq.$seasonYear',
      },
    );

    SeasonStats? currentSeason;
    if (seasonResult.isNotEmpty) {
      currentSeason = SeasonStats.fromJson(seasonResult.first);
    }

    // Calculate attendance
    // Get team's activities
    final activities = await _db.client.select(
      'activities',
      select: 'id',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (activities.isEmpty) {
      return PlayerStatistics(
        userId: userId,
        teamId: teamId,
        userName: user['name'] as String,
        userAvatarUrl: user['avatar_url'] as String?,
        rating: rating,
        currentSeason: currentSeason,
        totalActivities: 0,
        attendedActivities: 0,
        attendancePercentage: 0.0,
      );
    }

    final activityIds = activities.map((a) => a['id'] as String).toList();
    final today = DateTime.now().toIso8601String().split('T').first;

    // Get past instances
    final instances = await _db.client.select(
      'activity_instances',
      select: 'id',
      filters: {
        'activity_id': 'in.(${activityIds.join(',')})',
        'date': 'lte.$today',
        'status': 'neq.cancelled',
      },
    );

    final totalActivities = instances.length;

    // Get user's 'yes' responses
    final instanceIds = instances.map((i) => i['id'] as String).toList();
    final yesResponses = instanceIds.isNotEmpty
        ? await _db.client.select(
            'activity_responses',
            filters: {
              'instance_id': 'in.(${instanceIds.join(',')})',
              'user_id': 'eq.$userId',
              'response': 'eq.yes',
            },
          )
        : <Map<String, dynamic>>[];

    final attendedActivities = yesResponses.length;
    final attendancePercentage = totalActivities > 0
        ? (attendedActivities / totalActivities * 100)
        : 0.0;

    return PlayerStatistics(
      userId: userId,
      teamId: teamId,
      userName: user['name'] as String,
      userAvatarUrl: user['avatar_url'] as String?,
      rating: rating,
      currentSeason: currentSeason,
      totalActivities: totalActivities,
      attendedActivities: attendedActivities,
      attendancePercentage: attendancePercentage,
    );
  }

  // Attendance
  Future<List<AttendanceRecord>> getTeamAttendance(String teamId, {DateTime? fromDate, DateTime? toDate}) async {
    final from = (fromDate ?? DateTime(DateTime.now().year, 1, 1)).toIso8601String().split('T').first;
    final to = (toDate ?? DateTime.now()).toIso8601String().split('T').first;

    // Get team members
    final members = await _db.client.select(
      'team_members',
      select: 'user_id',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (members.isEmpty) return [];

    final userIds = members.map((m) => m['user_id'] as String).toList();

    // Get users
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    // Get team's activities
    final activities = await _db.client.select(
      'activities',
      select: 'id',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (activities.isEmpty) {
      return userIds.map((userId) {
        final user = userMap[userId] ?? {};
        return AttendanceRecord(
          userId: userId,
          userName: user['name'] as String? ?? '',
          userAvatarUrl: user['avatar_url'] as String?,
          totalActivities: 0,
          attended: 0,
          missed: 0,
          percentage: 0.0,
        );
      }).toList();
    }

    final activityIds = activities.map((a) => a['id'] as String).toList();

    // Get instances in date range
    final instances = await _db.client.select(
      'activity_instances',
      select: 'id',
      filters: {
        'activity_id': 'in.(${activityIds.join(',')})',
        'date': 'gte.$from',
        'status': 'neq.cancelled',
      },
    );

    // Filter by end date manually (since we need two date filters)
    final filteredInstances = instances.where((i) {
      final dateStr = i['date'] as String?;
      if (dateStr == null) return false;
      return dateStr.compareTo(to) <= 0;
    }).toList();

    final totalActivities = filteredInstances.length;
    final instanceIds = filteredInstances.map((i) => i['id'] as String).toList();

    // Get all responses for these instances
    final responses = instanceIds.isNotEmpty
        ? await _db.client.select(
            'activity_responses',
            select: 'user_id,response,instance_id',
            filters: {
              'instance_id': 'in.(${instanceIds.join(',')})',
              'user_id': 'in.(${userIds.join(',')})',
            },
          )
        : <Map<String, dynamic>>[];

    // Build attendance per user
    final results = <AttendanceRecord>[];
    for (final userId in userIds) {
      final user = userMap[userId] ?? {};
      final userResponses = responses.where((r) => r['user_id'] == userId).toList();

      final attended = userResponses.where((r) => r['response'] == 'yes').length;
      final missed = userResponses.where((r) => r['response'] == 'no').length;

      results.add(AttendanceRecord(
        userId: userId,
        userName: user['name'] as String? ?? '',
        userAvatarUrl: user['avatar_url'] as String?,
        totalActivities: totalActivities,
        attended: attended,
        missed: missed,
        percentage: totalActivities > 0 ? (attended / totalActivities * 100) : 0.0,
      ));
    }

    // Sort by percentage descending
    results.sort((a, b) => b.percentage.compareTo(a.percentage));

    return results;
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

  // Helper: Add points to player's season stats
  Future<void> addPoints(String userId, String teamId, int points) async {
    final year = DateTime.now().year;

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
        {'total_points': (current['total_points'] as int? ?? 0) + points},
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
        'total_points': points,
      });
    }
  }

  // Helper: Record attendance
  Future<void> recordAttendance(String userId, String teamId) async {
    final year = DateTime.now().year;

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
        {'attendance_count': (current['attendance_count'] as int? ?? 0) + 1},
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
        'attendance_count': 1,
      });
    }
  }

  // Helper: Update win/loss/draw counts
  Future<void> recordMatchResult(String userId, String teamId, String result) async {
    final year = DateTime.now().year;

    String column;
    switch (result) {
      case 'win':
        column = 'total_wins';
        break;
      case 'loss':
        column = 'total_losses';
        break;
      case 'draw':
        column = 'total_draws';
        break;
      default:
        return;
    }

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
        {column: (current[column] as int? ?? 0) + 1},
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
        column: 1,
      });
    }
  }
}

class _LeaderboardData {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int totalPoints;
  final double rating;
  final int wins;
  final int losses;
  final int draws;

  _LeaderboardData({
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.totalPoints,
    required this.rating,
    required this.wins,
    required this.losses,
    required this.draws,
  });
}
