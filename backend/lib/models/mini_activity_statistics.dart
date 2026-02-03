// Mini-Activity Statistics Models
// Tasks: BM-046 to BM-050

// BM-046: Player stats model
class MiniActivityPlayerStats {
  final String id;
  final String userId;
  final String teamId;
  final String? seasonId;
  final int totalParticipations;
  final int totalWins;
  final int totalLosses;
  final int totalDraws;
  final int totalPoints;
  final int firstPlaceCount;
  final int secondPlaceCount;
  final int thirdPlaceCount;
  final int bestStreak;
  final int currentStreak;
  final double? averagePlacement;
  final DateTime updatedAt;

  MiniActivityPlayerStats({
    required this.id,
    required this.userId,
    required this.teamId,
    this.seasonId,
    this.totalParticipations = 0,
    this.totalWins = 0,
    this.totalLosses = 0,
    this.totalDraws = 0,
    this.totalPoints = 0,
    this.firstPlaceCount = 0,
    this.secondPlaceCount = 0,
    this.thirdPlaceCount = 0,
    this.bestStreak = 0,
    this.currentStreak = 0,
    this.averagePlacement,
    required this.updatedAt,
  });

  factory MiniActivityPlayerStats.fromRow(Map<String, dynamic> row) {
    return MiniActivityPlayerStats(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      teamId: row['team_id'] as String,
      seasonId: row['season_id'] as String?,
      totalParticipations: row['total_participations'] as int? ?? 0,
      totalWins: row['total_wins'] as int? ?? 0,
      totalLosses: row['total_losses'] as int? ?? 0,
      totalDraws: row['total_draws'] as int? ?? 0,
      totalPoints: row['total_points'] as int? ?? 0,
      firstPlaceCount: row['first_place_count'] as int? ?? 0,
      secondPlaceCount: row['second_place_count'] as int? ?? 0,
      thirdPlaceCount: row['third_place_count'] as int? ?? 0,
      bestStreak: row['best_streak'] as int? ?? 0,
      currentStreak: row['current_streak'] as int? ?? 0,
      averagePlacement: (row['average_placement'] as num?)?.toDouble(),
      updatedAt: row['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'team_id': teamId,
      'season_id': seasonId,
      'total_participations': totalParticipations,
      'total_wins': totalWins,
      'total_losses': totalLosses,
      'total_draws': totalDraws,
      'total_points': totalPoints,
      'first_place_count': firstPlaceCount,
      'second_place_count': secondPlaceCount,
      'third_place_count': thirdPlaceCount,
      'best_streak': bestStreak,
      'current_streak': currentStreak,
      'average_placement': averagePlacement,
      'win_rate': winRate,
      'podium_rate': podiumRate,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // BM-047: Win rate getter
  double get winRate {
    if (totalParticipations == 0) return 0.0;
    return (totalWins / totalParticipations) * 100;
  }

  int get totalPodiums => firstPlaceCount + secondPlaceCount + thirdPlaceCount;

  double get podiumRate {
    if (totalParticipations == 0) return 0.0;
    return (totalPodiums / totalParticipations) * 100;
  }

  bool get isOnWinningStreak => currentStreak > 0;
  bool get isOnLosingStreak => currentStreak < 0;
}

// BM-048: Head-to-head stats model
class HeadToHeadStats {
  final String id;
  final String teamId;
  final String user1Id;
  final String user2Id;
  final int user1Wins;
  final int user2Wins;
  final int draws;
  final int totalMatchups;
  final DateTime? lastMatchupAt;
  final DateTime updatedAt;

  HeadToHeadStats({
    required this.id,
    required this.teamId,
    required this.user1Id,
    required this.user2Id,
    this.user1Wins = 0,
    this.user2Wins = 0,
    this.draws = 0,
    this.totalMatchups = 0,
    this.lastMatchupAt,
    required this.updatedAt,
  });

  factory HeadToHeadStats.fromRow(Map<String, dynamic> row) {
    return HeadToHeadStats(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      user1Id: row['user1_id'] as String,
      user2Id: row['user2_id'] as String,
      user1Wins: row['user1_wins'] as int? ?? 0,
      user2Wins: row['user2_wins'] as int? ?? 0,
      draws: row['draws'] as int? ?? 0,
      totalMatchups: row['total_matchups'] as int? ?? 0,
      lastMatchupAt: row['last_matchup_at'] as DateTime?,
      updatedAt: row['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'user1_wins': user1Wins,
      'user2_wins': user2Wins,
      'draws': draws,
      'total_matchups': totalMatchups,
      'user1_win_rate': getWinRateForUser(user1Id),
      'user2_win_rate': getWinRateForUser(user2Id),
      'last_matchup_at': lastMatchupAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get win rate for a specific user
  double getWinRateForUser(String userId) {
    if (totalMatchups == 0) return 0.0;
    final wins = userId == user1Id ? user1Wins : user2Wins;
    return (wins / totalMatchups) * 100;
  }

  /// Get the leader (user with more wins)
  String? get leaderId {
    if (user1Wins > user2Wins) return user1Id;
    if (user2Wins > user1Wins) return user2Id;
    return null; // It's a tie
  }

  bool get isTied => user1Wins == user2Wins;
}

// Team history model
class MiniActivityTeamHistory {
  final String id;
  final String userId;
  final String miniActivityId;
  final String? miniTeamId;
  final String? teamName;
  final List<Map<String, dynamic>>? teammates;
  final int? placement;
  final int pointsEarned;
  final bool wasWinner;
  final DateTime recordedAt;

  MiniActivityTeamHistory({
    required this.id,
    required this.userId,
    required this.miniActivityId,
    this.miniTeamId,
    this.teamName,
    this.teammates,
    this.placement,
    this.pointsEarned = 0,
    this.wasWinner = false,
    required this.recordedAt,
  });

  factory MiniActivityTeamHistory.fromRow(Map<String, dynamic> row) {
    return MiniActivityTeamHistory(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      miniTeamId: row['mini_team_id'] as String?,
      teamName: row['team_name'] as String?,
      teammates: (row['teammates'] as List<dynamic>?)?.cast<Map<String, dynamic>>(),
      placement: row['placement'] as int?,
      pointsEarned: row['points_earned'] as int? ?? 0,
      wasWinner: row['was_winner'] as bool? ?? false,
      recordedAt: row['recorded_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mini_activity_id': miniActivityId,
      'mini_team_id': miniTeamId,
      'team_name': teamName,
      'teammates': teammates,
      'placement': placement,
      'points_earned': pointsEarned,
      'was_winner': wasWinner,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  bool get isPodium => placement != null && placement! <= 3;
}

// BM-049: Leaderboard point source model
enum PointSourceType {
  miniActivity,
  tournament,
  attendance,
  testResult,
  manualAdjustment,
  bonus,
  penalty;

  String get value {
    switch (this) {
      case PointSourceType.miniActivity:
        return 'mini_activity';
      case PointSourceType.tournament:
        return 'tournament';
      case PointSourceType.attendance:
        return 'attendance';
      case PointSourceType.testResult:
        return 'test_result';
      case PointSourceType.manualAdjustment:
        return 'manual_adjustment';
      case PointSourceType.bonus:
        return 'bonus';
      case PointSourceType.penalty:
        return 'penalty';
    }
  }

  static PointSourceType fromString(String value) {
    switch (value) {
      case 'mini_activity':
        return PointSourceType.miniActivity;
      case 'tournament':
        return PointSourceType.tournament;
      case 'attendance':
        return PointSourceType.attendance;
      case 'test_result':
        return PointSourceType.testResult;
      case 'manual_adjustment':
        return PointSourceType.manualAdjustment;
      case 'bonus':
        return PointSourceType.bonus;
      case 'penalty':
        return PointSourceType.penalty;
      default:
        throw ArgumentError('Unknown point source type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case PointSourceType.miniActivity:
        return 'Mini-aktivitet';
      case PointSourceType.tournament:
        return 'Turnering';
      case PointSourceType.attendance:
        return 'Oppmøte';
      case PointSourceType.testResult:
        return 'Testresultat';
      case PointSourceType.manualAdjustment:
        return 'Manuell justering';
      case PointSourceType.bonus:
        return 'Bonus';
      case PointSourceType.penalty:
        return 'Straff';
    }
  }
}

class LeaderboardPointSource {
  final String id;
  final String leaderboardEntryId;
  final String userId;
  final PointSourceType sourceType;
  final String sourceId;
  final int points;
  final String? description;
  final DateTime recordedAt;

  LeaderboardPointSource({
    required this.id,
    required this.leaderboardEntryId,
    required this.userId,
    required this.sourceType,
    required this.sourceId,
    required this.points,
    this.description,
    required this.recordedAt,
  });

  factory LeaderboardPointSource.fromRow(Map<String, dynamic> row) {
    return LeaderboardPointSource(
      id: row['id'] as String,
      leaderboardEntryId: row['leaderboard_entry_id'] as String,
      userId: row['user_id'] as String,
      sourceType: PointSourceType.fromString(row['source_type'] as String),
      sourceId: row['source_id'] as String,
      points: row['points'] as int,
      description: row['description'] as String?,
      recordedAt: row['recorded_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaderboard_entry_id': leaderboardEntryId,
      'user_id': userId,
      'source_type': sourceType.value,
      'source_type_display': sourceType.displayName,
      'source_id': sourceId,
      'points': points,
      'description': description,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  bool get isPositive => points > 0;
  bool get isNegative => points < 0;
}

// Aggregated stats for display
class PlayerStatsAggregate {
  final MiniActivityPlayerStats stats;
  final List<HeadToHeadStats> headToHead;
  final List<MiniActivityTeamHistory> recentHistory;
  final List<LeaderboardPointSource> pointSources;

  PlayerStatsAggregate({
    required this.stats,
    this.headToHead = const [],
    this.recentHistory = const [],
    this.pointSources = const [],
  });

  int get totalPointsFromSources => pointSources.fold(0, (sum, s) => sum + s.points);

  Map<String, dynamic> toJson() {
    return {
      'stats': stats.toJson(),
      'head_to_head': headToHead.map((h) => h.toJson()).toList(),
      'recent_history': recentHistory.map((h) => h.toJson()).toList(),
      'point_sources': pointSources.map((s) => s.toJson()).toList(),
    };
  }
}
