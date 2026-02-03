// Statistics models for mini-activity tracking
// Tracks player stats, head-to-head records, team history, and leaderboard sources

// Point source type enum
enum PointSourceType {
  miniActivityWin,
  miniActivityDraw,
  miniActivityLoss,
  tournamentPlacement,
  bonusPoints,
  penaltyPoints,
  attendance,
  manual;

  static PointSourceType fromString(String value) {
    switch (value) {
      case 'mini_activity_win':
        return PointSourceType.miniActivityWin;
      case 'mini_activity_draw':
        return PointSourceType.miniActivityDraw;
      case 'mini_activity_loss':
        return PointSourceType.miniActivityLoss;
      case 'tournament_placement':
        return PointSourceType.tournamentPlacement;
      case 'bonus_points':
        return PointSourceType.bonusPoints;
      case 'penalty_points':
        return PointSourceType.penaltyPoints;
      case 'attendance':
        return PointSourceType.attendance;
      case 'manual':
        return PointSourceType.manual;
      default:
        return PointSourceType.manual;
    }
  }

  String toJson() {
    switch (this) {
      case PointSourceType.miniActivityWin:
        return 'mini_activity_win';
      case PointSourceType.miniActivityDraw:
        return 'mini_activity_draw';
      case PointSourceType.miniActivityLoss:
        return 'mini_activity_loss';
      case PointSourceType.tournamentPlacement:
        return 'tournament_placement';
      case PointSourceType.bonusPoints:
        return 'bonus_points';
      case PointSourceType.penaltyPoints:
        return 'penalty_points';
      case PointSourceType.attendance:
        return 'attendance';
      case PointSourceType.manual:
        return 'manual';
    }
  }

  String get displayName {
    switch (this) {
      case PointSourceType.miniActivityWin:
        return 'Seier';
      case PointSourceType.miniActivityDraw:
        return 'Uavgjort';
      case PointSourceType.miniActivityLoss:
        return 'Tap';
      case PointSourceType.tournamentPlacement:
        return 'Turneringsplassering';
      case PointSourceType.bonusPoints:
        return 'Bonuspoeng';
      case PointSourceType.penaltyPoints:
        return 'Straffepoeng';
      case PointSourceType.attendance:
        return 'Oppmøte';
      case PointSourceType.manual:
        return 'Manuell';
    }
  }

  bool get isPositive =>
      this == PointSourceType.miniActivityWin ||
      this == PointSourceType.tournamentPlacement ||
      this == PointSourceType.bonusPoints ||
      this == PointSourceType.attendance;
}

/// Player statistics across mini-activities
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
  final DateTime updatedAt;

  // Joined data
  final String? userName;
  final String? userProfileImageUrl;
  final String? seasonName;

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
    required this.updatedAt,
    this.userName,
    this.userProfileImageUrl,
    this.seasonName,
  });

  factory MiniActivityPlayerStats.fromJson(Map<String, dynamic> json) {
    return MiniActivityPlayerStats(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      teamId: json['team_id'] as String,
      seasonId: json['season_id'] as String?,
      totalParticipations: json['total_participations'] as int? ?? 0,
      totalWins: json['total_wins'] as int? ?? 0,
      totalLosses: json['total_losses'] as int? ?? 0,
      totalDraws: json['total_draws'] as int? ?? 0,
      totalPoints: json['total_points'] as int? ?? 0,
      firstPlaceCount: json['first_place_count'] as int? ?? 0,
      secondPlaceCount: json['second_place_count'] as int? ?? 0,
      thirdPlaceCount: json['third_place_count'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userProfileImageUrl: json['user_profile_image_url'] as String?,
      seasonName: json['season_name'] as String?,
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
      'updated_at': updatedAt.toIso8601String(),
      'user_name': userName,
      'user_profile_image_url': userProfileImageUrl,
      'season_name': seasonName,
    };
  }

  MiniActivityPlayerStats copyWith({
    String? id,
    String? userId,
    String? teamId,
    String? seasonId,
    int? totalParticipations,
    int? totalWins,
    int? totalLosses,
    int? totalDraws,
    int? totalPoints,
    int? firstPlaceCount,
    int? secondPlaceCount,
    int? thirdPlaceCount,
    DateTime? updatedAt,
    String? userName,
    String? userProfileImageUrl,
    String? seasonName,
  }) {
    return MiniActivityPlayerStats(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      teamId: teamId ?? this.teamId,
      seasonId: seasonId ?? this.seasonId,
      totalParticipations: totalParticipations ?? this.totalParticipations,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      totalDraws: totalDraws ?? this.totalDraws,
      totalPoints: totalPoints ?? this.totalPoints,
      firstPlaceCount: firstPlaceCount ?? this.firstPlaceCount,
      secondPlaceCount: secondPlaceCount ?? this.secondPlaceCount,
      thirdPlaceCount: thirdPlaceCount ?? this.thirdPlaceCount,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      seasonName: seasonName ?? this.seasonName,
    );
  }

  /// Calculate win rate percentage
  double get winRate {
    if (totalParticipations == 0) return 0.0;
    return (totalWins / totalParticipations) * 100;
  }

  /// Formatted win rate string
  String get formattedWinRate => '${winRate.toStringAsFixed(1)}%';

  /// Win-Draw-Loss record string
  String get record => '$totalWins-$totalDraws-$totalLosses';

  /// Total podium finishes
  int get podiumCount => firstPlaceCount + secondPlaceCount + thirdPlaceCount;

  /// Average points per participation
  double get averagePoints {
    if (totalParticipations == 0) return 0.0;
    return totalPoints / totalParticipations;
  }

  /// Formatted average points
  String get formattedAveragePoints => averagePoints.toStringAsFixed(1);
}

/// Head-to-head statistics between two players
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

  // Joined data
  final String? user1Name;
  final String? user2Name;
  final String? user1ProfileImageUrl;
  final String? user2ProfileImageUrl;

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
    this.user1Name,
    this.user2Name,
    this.user1ProfileImageUrl,
    this.user2ProfileImageUrl,
  });

  factory HeadToHeadStats.fromJson(Map<String, dynamic> json) {
    return HeadToHeadStats(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      user1Wins: json['user1_wins'] as int? ?? 0,
      user2Wins: json['user2_wins'] as int? ?? 0,
      draws: json['draws'] as int? ?? 0,
      totalMatchups: json['total_matchups'] as int? ?? 0,
      lastMatchupAt: json['last_matchup_at'] != null ? DateTime.parse(json['last_matchup_at'] as String) : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      user1Name: json['user1_name'] as String?,
      user2Name: json['user2_name'] as String?,
      user1ProfileImageUrl: json['user1_profile_image_url'] as String?,
      user2ProfileImageUrl: json['user2_profile_image_url'] as String?,
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
      'last_matchup_at': lastMatchupAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user1_name': user1Name,
      'user2_name': user2Name,
      'user1_profile_image_url': user1ProfileImageUrl,
      'user2_profile_image_url': user2ProfileImageUrl,
    };
  }

  HeadToHeadStats copyWith({
    String? id,
    String? teamId,
    String? user1Id,
    String? user2Id,
    int? user1Wins,
    int? user2Wins,
    int? draws,
    int? totalMatchups,
    DateTime? lastMatchupAt,
    DateTime? updatedAt,
    String? user1Name,
    String? user2Name,
    String? user1ProfileImageUrl,
    String? user2ProfileImageUrl,
  }) {
    return HeadToHeadStats(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      user1Wins: user1Wins ?? this.user1Wins,
      user2Wins: user2Wins ?? this.user2Wins,
      draws: draws ?? this.draws,
      totalMatchups: totalMatchups ?? this.totalMatchups,
      lastMatchupAt: lastMatchupAt ?? this.lastMatchupAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user1Name: user1Name ?? this.user1Name,
      user2Name: user2Name ?? this.user2Name,
      user1ProfileImageUrl: user1ProfileImageUrl ?? this.user1ProfileImageUrl,
      user2ProfileImageUrl: user2ProfileImageUrl ?? this.user2ProfileImageUrl,
    );
  }

  /// Get record string (e.g., "5-2-3")
  String get record => '$user1Wins-$draws-$user2Wins';

  /// Get leading user ID (null if tied)
  String? get leadingUserId {
    if (user1Wins > user2Wins) return user1Id;
    if (user2Wins > user1Wins) return user2Id;
    return null;
  }

  /// Check if it's a rivalry (close record)
  bool get isRivalry {
    if (totalMatchups < 3) return false;
    final diff = (user1Wins - user2Wins).abs();
    return diff <= totalMatchups * 0.2; // Within 20% of matches
  }

  /// Get wins for a specific user
  int winsFor(String userId) {
    if (userId == user1Id) return user1Wins;
    if (userId == user2Id) return user2Wins;
    return 0;
  }

  /// Get losses for a specific user
  int lossesFor(String userId) {
    if (userId == user1Id) return user2Wins;
    if (userId == user2Id) return user1Wins;
    return 0;
  }

  /// Get opponent's ID for a given user
  String opponentOf(String userId) {
    return userId == user1Id ? user2Id : user1Id;
  }

  /// Get opponent's name for a given user
  String? opponentNameOf(String userId) {
    return userId == user1Id ? user2Name : user1Name;
  }
}

/// History of a user's team assignments in mini-activities
class MiniActivityTeamHistory {
  final String id;
  final String userId;
  final String miniActivityId;
  final String miniTeamId;
  final String? teamName;
  final int? placement;
  final int pointsEarned;
  final bool wasWinner;
  final DateTime recordedAt;

  // Joined data
  final String? userName;
  final String? miniActivityName;

  MiniActivityTeamHistory({
    required this.id,
    required this.userId,
    required this.miniActivityId,
    required this.miniTeamId,
    this.teamName,
    this.placement,
    this.pointsEarned = 0,
    this.wasWinner = false,
    required this.recordedAt,
    this.userName,
    this.miniActivityName,
  });

  factory MiniActivityTeamHistory.fromJson(Map<String, dynamic> json) {
    return MiniActivityTeamHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      miniActivityId: json['mini_activity_id'] as String,
      miniTeamId: json['mini_team_id'] as String,
      teamName: json['team_name'] as String?,
      placement: json['placement'] as int?,
      pointsEarned: json['points_earned'] as int? ?? 0,
      wasWinner: json['was_winner'] as bool? ?? false,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      userName: json['user_name'] as String?,
      miniActivityName: json['mini_activity_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'mini_activity_id': miniActivityId,
      'mini_team_id': miniTeamId,
      'team_name': teamName,
      'placement': placement,
      'points_earned': pointsEarned,
      'was_winner': wasWinner,
      'recorded_at': recordedAt.toIso8601String(),
      'user_name': userName,
      'mini_activity_name': miniActivityName,
    };
  }

  MiniActivityTeamHistory copyWith({
    String? id,
    String? userId,
    String? miniActivityId,
    String? miniTeamId,
    String? teamName,
    int? placement,
    int? pointsEarned,
    bool? wasWinner,
    DateTime? recordedAt,
    String? userName,
    String? miniActivityName,
  }) {
    return MiniActivityTeamHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      miniActivityId: miniActivityId ?? this.miniActivityId,
      miniTeamId: miniTeamId ?? this.miniTeamId,
      teamName: teamName ?? this.teamName,
      placement: placement ?? this.placement,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      wasWinner: wasWinner ?? this.wasWinner,
      recordedAt: recordedAt ?? this.recordedAt,
      userName: userName ?? this.userName,
      miniActivityName: miniActivityName ?? this.miniActivityName,
    );
  }

  /// Get placement display (1st, 2nd, 3rd, etc.)
  String get placementDisplay {
    if (placement == null) return '-';
    switch (placement) {
      case 1:
        return '1.';
      case 2:
        return '2.';
      case 3:
        return '3.';
      default:
        return '$placement.';
    }
  }

  /// Get medal emoji for placement
  String? get medalEmoji {
    switch (placement) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }
}

/// Source of points for a leaderboard entry
class LeaderboardPointSource {
  final String id;
  final String leaderboardEntryId;
  final String userId;
  final PointSourceType sourceType;
  final String? sourceId;
  final int points;
  final String? description;
  final DateTime recordedAt;

  // Joined data
  final String? sourceName;

  LeaderboardPointSource({
    required this.id,
    required this.leaderboardEntryId,
    required this.userId,
    required this.sourceType,
    this.sourceId,
    required this.points,
    this.description,
    required this.recordedAt,
    this.sourceName,
  });

  factory LeaderboardPointSource.fromJson(Map<String, dynamic> json) {
    return LeaderboardPointSource(
      id: json['id'] as String,
      leaderboardEntryId: json['leaderboard_entry_id'] as String,
      userId: json['user_id'] as String,
      sourceType: PointSourceType.fromString(json['source_type'] as String? ?? 'manual'),
      sourceId: json['source_id'] as String?,
      points: json['points'] as int,
      description: json['description'] as String?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      sourceName: json['source_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaderboard_entry_id': leaderboardEntryId,
      'user_id': userId,
      'source_type': sourceType.toJson(),
      'source_id': sourceId,
      'points': points,
      'description': description,
      'recorded_at': recordedAt.toIso8601String(),
      'source_name': sourceName,
    };
  }

  LeaderboardPointSource copyWith({
    String? id,
    String? leaderboardEntryId,
    String? userId,
    PointSourceType? sourceType,
    String? sourceId,
    int? points,
    String? description,
    DateTime? recordedAt,
    String? sourceName,
  }) {
    return LeaderboardPointSource(
      id: id ?? this.id,
      leaderboardEntryId: leaderboardEntryId ?? this.leaderboardEntryId,
      userId: userId ?? this.userId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      points: points ?? this.points,
      description: description ?? this.description,
      recordedAt: recordedAt ?? this.recordedAt,
      sourceName: sourceName ?? this.sourceName,
    );
  }

  /// Formatted points with sign
  String get formattedPoints => points >= 0 ? '+$points' : '$points';

  /// Get display description
  String get displayDescription => description ?? sourceType.displayName;

  /// Check if this is a penalty (negative points)
  bool get isPenalty => points < 0;
}

/// Aggregated player stats with multiple stat types
class PlayerStatsAggregate {
  final MiniActivityPlayerStats? overallStats;
  final MiniActivityPlayerStats? seasonStats;
  final List<HeadToHeadStats> headToHeadRecords;
  final List<MiniActivityTeamHistory> recentHistory;
  final List<LeaderboardPointSource> recentPointSources;

  PlayerStatsAggregate({
    this.overallStats,
    this.seasonStats,
    this.headToHeadRecords = const [],
    this.recentHistory = const [],
    this.recentPointSources = const [],
  });

  factory PlayerStatsAggregate.fromJson(Map<String, dynamic> json) {
    return PlayerStatsAggregate(
      overallStats: json['overall_stats'] != null
          ? MiniActivityPlayerStats.fromJson(json['overall_stats'] as Map<String, dynamic>)
          : null,
      seasonStats: json['season_stats'] != null
          ? MiniActivityPlayerStats.fromJson(json['season_stats'] as Map<String, dynamic>)
          : null,
      headToHeadRecords: json['head_to_head_records'] != null
          ? (json['head_to_head_records'] as List)
              .map((h) => HeadToHeadStats.fromJson(h as Map<String, dynamic>))
              .toList()
          : [],
      recentHistory: json['recent_history'] != null
          ? (json['recent_history'] as List)
              .map((h) => MiniActivityTeamHistory.fromJson(h as Map<String, dynamic>))
              .toList()
          : [],
      recentPointSources: json['recent_point_sources'] != null
          ? (json['recent_point_sources'] as List)
              .map((p) => LeaderboardPointSource.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_stats': overallStats?.toJson(),
      'season_stats': seasonStats?.toJson(),
      'head_to_head_records': headToHeadRecords.map((h) => h.toJson()).toList(),
      'recent_history': recentHistory.map((h) => h.toJson()).toList(),
      'recent_point_sources': recentPointSources.map((p) => p.toJson()).toList(),
    };
  }

  /// Get current stats (season if available, otherwise overall)
  MiniActivityPlayerStats? get currentStats => seasonStats ?? overallStats;

  /// Total points from recent sources
  int get recentPointsTotal =>
      recentPointSources.fold(0, (sum, source) => sum + source.points);

  /// Number of wins from recent history
  int get recentWins =>
      recentHistory.where((h) => h.wasWinner).length;

  /// Most common opponent (by total matchups)
  HeadToHeadStats? get topRival {
    if (headToHeadRecords.isEmpty) return null;
    return headToHeadRecords.reduce((a, b) =>
        a.totalMatchups > b.totalMatchups ? a : b);
  }
}

/// Mini-activity stats summary for a team
class TeamMiniActivityStats {
  final String teamId;
  final int totalMiniActivities;
  final int totalParticipations;
  final int completedMiniActivities;
  final int activeMiniActivities;
  final DateTime? lastActivityAt;
  final List<MiniActivityPlayerStats> topPlayers;

  TeamMiniActivityStats({
    required this.teamId,
    this.totalMiniActivities = 0,
    this.totalParticipations = 0,
    this.completedMiniActivities = 0,
    this.activeMiniActivities = 0,
    this.lastActivityAt,
    this.topPlayers = const [],
  });

  factory TeamMiniActivityStats.fromJson(Map<String, dynamic> json) {
    return TeamMiniActivityStats(
      teamId: json['team_id'] as String,
      totalMiniActivities: json['total_mini_activities'] as int? ?? 0,
      totalParticipations: json['total_participations'] as int? ?? 0,
      completedMiniActivities: json['completed_mini_activities'] as int? ?? 0,
      activeMiniActivities: json['active_mini_activities'] as int? ?? 0,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      topPlayers: json['top_players'] != null
          ? (json['top_players'] as List)
              .map((p) => MiniActivityPlayerStats.fromJson(p as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'total_mini_activities': totalMiniActivities,
      'total_participations': totalParticipations,
      'completed_mini_activities': completedMiniActivities,
      'active_mini_activities': activeMiniActivities,
      'last_activity_at': lastActivityAt?.toIso8601String(),
      'top_players': topPlayers.map((p) => p.toJson()).toList(),
    };
  }

  TeamMiniActivityStats copyWith({
    String? teamId,
    int? totalMiniActivities,
    int? totalParticipations,
    int? completedMiniActivities,
    int? activeMiniActivities,
    DateTime? lastActivityAt,
    List<MiniActivityPlayerStats>? topPlayers,
  }) {
    return TeamMiniActivityStats(
      teamId: teamId ?? this.teamId,
      totalMiniActivities: totalMiniActivities ?? this.totalMiniActivities,
      totalParticipations: totalParticipations ?? this.totalParticipations,
      completedMiniActivities: completedMiniActivities ?? this.completedMiniActivities,
      activeMiniActivities: activeMiniActivities ?? this.activeMiniActivities,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      topPlayers: topPlayers ?? this.topPlayers,
    );
  }

  /// Completion rate percentage
  double get completionRate {
    if (totalMiniActivities == 0) return 0.0;
    return (completedMiniActivities / totalMiniActivities) * 100;
  }

  /// Formatted completion rate
  String get formattedCompletionRate => '${completionRate.toStringAsFixed(0)}%';

  /// Average participations per mini-activity
  double get averageParticipations {
    if (totalMiniActivities == 0) return 0.0;
    return totalParticipations / totalMiniActivities;
  }
}
