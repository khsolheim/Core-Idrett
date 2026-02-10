// Aggregate and summary statistics models for mini-activity tracking
// Leaderboard point sources, player aggregates, and team stats

import 'mini_activity_statistics_enums.dart';
import 'package:equatable/equatable.dart';
import 'mini_activity_statistics_core.dart';

/// Source of points for a leaderboard entry
class LeaderboardPointSource extends Equatable {
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
  const LeaderboardPointSource({
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
    return
  LeaderboardPointSource(
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
    return
  LeaderboardPointSource(
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


  @override
  List<Object?> get props => [id, leaderboardEntryId, userId, sourceType, sourceId, points, description, recordedAt, sourceName];
}

/// Aggregated player stats with multiple stat types
class PlayerStatsAggregate extends Equatable {
  final MiniActivityPlayerStats? overallStats;
  final MiniActivityPlayerStats? seasonStats;
  final List<HeadToHeadStats> headToHeadRecords;
  final List<MiniActivityTeamHistory> recentHistory;
  final List<LeaderboardPointSource> recentPointSources;
  const PlayerStatsAggregate({
    this.overallStats,
    this.seasonStats,
    this.headToHeadRecords = const [],
    this.recentHistory = const [],
    this.recentPointSources = const [],
  });

  factory PlayerStatsAggregate.fromJson(Map<String, dynamic> json) {
    return
  PlayerStatsAggregate(
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


  @override
  List<Object?> get props => [overallStats, seasonStats, headToHeadRecords, recentHistory, recentPointSources];
}

/// Mini-activity stats summary for a team
class TeamMiniActivityStats extends Equatable {
  final String teamId;
  final int totalMiniActivities;
  final int totalParticipations;
  final int completedMiniActivities;
  final int activeMiniActivities;
  final DateTime? lastActivityAt;
  final List<MiniActivityPlayerStats> topPlayers;
  const TeamMiniActivityStats({
    required this.teamId,
    this.totalMiniActivities = 0,
    this.totalParticipations = 0,
    this.completedMiniActivities = 0,
    this.activeMiniActivities = 0,
    this.lastActivityAt,
    this.topPlayers = const [],
  });

  factory TeamMiniActivityStats.fromJson(Map<String, dynamic> json) {
    return
  TeamMiniActivityStats(
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
    return
  TeamMiniActivityStats(
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


  @override
  List<Object?> get props => [teamId, totalMiniActivities, totalParticipations, completedMiniActivities, activeMiniActivities, lastActivityAt, topPlayers];
}
