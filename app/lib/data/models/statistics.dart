/// Season model for organizing activities and statistics per time period
class Season {
  final String id;
  final String teamId;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  Season({
    required this.id,
    required this.teamId,
    required this.name,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'],
      teamId: json['team_id'],
      name: json['name'],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : null,
      isActive: json['is_active'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'start_date': startDate?.toIso8601String().split('T').first,
        'end_date': endDate?.toIso8601String().split('T').first,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Leaderboard model for tracking different competition types
class Leaderboard {
  final String id;
  final String teamId;
  final String? seasonId;
  final String name;
  final String? description;
  final bool isMain;
  final int sortOrder;
  final DateTime createdAt;
  final List<NewLeaderboardEntry>? entries;

  Leaderboard({
    required this.id,
    required this.teamId,
    this.seasonId,
    required this.name,
    this.description,
    required this.isMain,
    required this.sortOrder,
    required this.createdAt,
    this.entries,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      id: json['id'],
      teamId: json['team_id'],
      seasonId: json['season_id'],
      name: json['name'],
      description: json['description'],
      isMain: json['is_main'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      entries: json['entries'] != null
          ? (json['entries'] as List)
              .map((e) => NewLeaderboardEntry.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'season_id': seasonId,
        'name': name,
        'description': description,
        'is_main': isMain,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
        if (entries != null) 'entries': entries!.map((e) => e.toJson()).toList(),
      };
}

/// New leaderboard entry model for the new leaderboard system
class NewLeaderboardEntry {
  final String id;
  final String leaderboardId;
  final String userId;
  final int points;
  final DateTime updatedAt;
  final String? userName;
  final String? userAvatarUrl;
  final int? rank;

  NewLeaderboardEntry({
    required this.id,
    required this.leaderboardId,
    required this.userId,
    required this.points,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
    this.rank,
  });

  factory NewLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return NewLeaderboardEntry(
      id: json['id'],
      leaderboardId: json['leaderboard_id'],
      userId: json['user_id'],
      points: json['points'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      rank: json['rank'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leaderboard_id': leaderboardId,
        'user_id': userId,
        'points': points,
        'updated_at': updatedAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'rank': rank,
      };
}

/// Test template model
class TestTemplate {
  final String id;
  final String teamId;
  final String name;
  final String? description;
  final String unit;
  final bool higherIsBetter;
  final DateTime createdAt;

  TestTemplate({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    required this.unit,
    required this.higherIsBetter,
    required this.createdAt,
  });

  factory TestTemplate.fromJson(Map<String, dynamic> json) {
    return TestTemplate(
      id: json['id'],
      teamId: json['team_id'],
      name: json['name'],
      description: json['description'],
      unit: json['unit'],
      higherIsBetter: json['higher_is_better'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'description': description,
        'unit': unit,
        'higher_is_better': higherIsBetter,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Test result model
class TestResult {
  final String id;
  final String testTemplateId;
  final String userId;
  final String? instanceId;
  final double value;
  final DateTime recordedAt;
  final String? notes;
  final String? userName;
  final String? userAvatarUrl;
  final String? testName;
  final String? testUnit;

  TestResult({
    required this.id,
    required this.testTemplateId,
    required this.userId,
    this.instanceId,
    required this.value,
    required this.recordedAt,
    this.notes,
    this.userName,
    this.userAvatarUrl,
    this.testName,
    this.testUnit,
  });

  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      testTemplateId: json['test_template_id'],
      userId: json['user_id'],
      instanceId: json['instance_id'],
      value: (json['value'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at']),
      notes: json['notes'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      testName: json['test_name'],
      testUnit: json['test_unit'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'test_template_id': testTemplateId,
        'user_id': userId,
        'instance_id': instanceId,
        'value': value,
        'recorded_at': recordedAt.toIso8601String(),
        'notes': notes,
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'test_name': testName,
        'test_unit': testUnit,
      };
}

class MatchStats {
  final String id;
  final String instanceId;
  final String userId;
  final int goals;
  final int assists;
  final int minutesPlayed;
  final int yellowCards;
  final int redCards;
  final String? userName;
  final String? userAvatarUrl;

  MatchStats({
    required this.id,
    required this.instanceId,
    required this.userId,
    this.goals = 0,
    this.assists = 0,
    this.minutesPlayed = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.userName,
    this.userAvatarUrl,
  });

  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      id: json['id'],
      instanceId: json['instance_id'],
      userId: json['user_id'],
      goals: json['goals'] ?? 0,
      assists: json['assists'] ?? 0,
      minutesPlayed: json['minutes_played'] ?? 0,
      yellowCards: json['yellow_cards'] ?? 0,
      redCards: json['red_cards'] ?? 0,
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'instance_id': instanceId,
        'user_id': userId,
        'goals': goals,
        'assists': assists,
        'minutes_played': minutesPlayed,
        'yellow_cards': yellowCards,
        'red_cards': redCards,
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
      };
}

class PlayerRating {
  final String id;
  final String userId;
  final String teamId;
  final double rating;
  final int wins;
  final int losses;
  final int draws;
  final DateTime updatedAt;
  final String? userName;
  final String? userAvatarUrl;

  PlayerRating({
    required this.id,
    required this.userId,
    required this.teamId,
    this.rating = 1000.0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  int get totalGames => wins + losses + draws;
  double get winRate => totalGames > 0 ? wins / totalGames * 100 : 0;

  factory PlayerRating.fromJson(Map<String, dynamic> json) {
    return PlayerRating(
      id: json['id'],
      userId: json['user_id'],
      teamId: json['team_id'],
      rating: (json['rating'] as num?)?.toDouble() ?? 1000.0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'team_id': teamId,
        'rating': rating,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'updated_at': updatedAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
      };
}

class SeasonStats {
  final String id;
  final String userId;
  final String teamId;
  final int seasonYear;
  final int attendanceCount;
  final int totalPoints;
  final int totalGoals;
  final int totalAssists;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final String? userName;
  final String? userAvatarUrl;

  SeasonStats({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.seasonYear,
    this.attendanceCount = 0,
    this.totalPoints = 0,
    this.totalGoals = 0,
    this.totalAssists = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalDraws = 0,
    this.userName,
    this.userAvatarUrl,
  });

  factory SeasonStats.fromJson(Map<String, dynamic> json) {
    return SeasonStats(
      id: json['id'],
      userId: json['user_id'],
      teamId: json['team_id'],
      seasonYear: json['season_year'],
      attendanceCount: json['attendance_count'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      totalGoals: json['total_goals'] ?? 0,
      totalAssists: json['total_assists'] ?? 0,
      totalWins: json['total_wins'] ?? 0,
      totalLosses: json['total_losses'] ?? 0,
      totalDraws: json['total_draws'] ?? 0,
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'team_id': teamId,
        'season_year': seasonYear,
        'attendance_count': attendanceCount,
        'total_points': totalPoints,
        'total_goals': totalGoals,
        'total_assists': totalAssists,
        'total_wins': totalWins,
        'total_losses': totalLosses,
        'total_draws': totalDraws,
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
      };
}

class PlayerStatistics {
  final String userId;
  final String teamId;
  final String userName;
  final String? userAvatarUrl;
  final PlayerRating? rating;
  final SeasonStats? currentSeason;
  final int totalActivities;
  final int attendedActivities;
  final double attendancePercentage;

  PlayerStatistics({
    required this.userId,
    required this.teamId,
    required this.userName,
    this.userAvatarUrl,
    this.rating,
    this.currentSeason,
    this.totalActivities = 0,
    this.attendedActivities = 0,
    this.attendancePercentage = 0.0,
  });

  factory PlayerStatistics.fromJson(Map<String, dynamic> json) {
    return PlayerStatistics(
      userId: json['user_id'],
      teamId: json['team_id'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      rating: json['rating'] != null ? PlayerRating.fromJson(json['rating']) : null,
      currentSeason: json['current_season'] != null ? SeasonStats.fromJson(json['current_season']) : null,
      totalActivities: json['total_activities'] ?? 0,
      attendedActivities: json['attended_activities'] ?? 0,
      attendancePercentage: (json['attendance_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'team_id': teamId,
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'rating': rating?.toJson(),
        'current_season': currentSeason?.toJson(),
        'total_activities': totalActivities,
        'attended_activities': attendedActivities,
        'attendance_percentage': attendancePercentage,
      };
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int totalPoints;
  final double rating;
  final int wins;
  final int losses;
  final int draws;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.totalPoints = 0,
    this.rating = 1000.0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  int get totalGames => wins + losses + draws;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      totalPoints: json['total_points'] ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 1000.0,
      wins: json['wins'] ?? 0,
      losses: json['losses'] ?? 0,
      draws: json['draws'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'user_id': userId,
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'total_points': totalPoints,
        'rating': rating,
        'wins': wins,
        'losses': losses,
        'draws': draws,
      };
}

class AttendanceRecord {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int totalActivities;
  final int attended;
  final int missed;
  final double percentage;

  AttendanceRecord({
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.totalActivities = 0,
    this.attended = 0,
    this.missed = 0,
    this.percentage = 0.0,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      totalActivities: json['total_activities'] ?? 0,
      attended: json['attended'] ?? 0,
      missed: json['missed'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'total_activities': totalActivities,
        'attended': attended,
        'missed': missed,
        'percentage': percentage,
      };
}
