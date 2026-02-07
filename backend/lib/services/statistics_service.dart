import '../db/database.dart';
import '../models/statistics.dart';
import 'player_rating_service.dart';
import 'user_service.dart';
import 'team_service.dart';

class StatisticsService {
  final Database _db;
  final UserService _userService;
  final TeamService _teamService;
  final PlayerRatingService _playerRatingService;

  StatisticsService(this._db, this._userService, this._teamService, this._playerRatingService);

  // Leaderboard
  Future<List<LeaderboardEntry>> getLeaderboard(String teamId, {int? seasonYear}) async {
    final year = seasonYear ?? DateTime.now().year;

    // Get team members
    final userIds = await _teamService.getTeamMemberUserIds(teamId);

    if (userIds.isEmpty) return [];

    // Get users
    final userMap = await _userService.getUserMap(userIds);

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
    final rating = await _playerRatingService.getPlayerRating(userId, teamId);

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
    final userIds = await _teamService.getTeamMemberUserIds(teamId);

    if (userIds.isEmpty) return [];

    // Get users
    final userMap = await _userService.getUserMap(userIds);

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
