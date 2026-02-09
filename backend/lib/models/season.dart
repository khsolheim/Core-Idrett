import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

/// Season model for organizing activities and statistics per time period
class Season extends Equatable {
  final String id;
  final String teamId;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  const Season({
    required this.id,
    required this.teamId,
    required this.name,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        name,
        startDate,
        endDate,
        isActive,
        createdAt,
      ];

  factory Season.fromJson(Map<String, dynamic> row) {
    return Season(
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      name: safeString(row, 'name'),
      startDate: safeDateTimeNullable(row, 'start_date'),
      endDate: safeDateTimeNullable(row, 'end_date'),
      isActive: safeBool(row, 'is_active', defaultValue: false),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'start_date': startDate?.toIso8601String().split('T').first,
      'end_date': endDate?.toIso8601String().split('T').first,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Leaderboard category enum
enum LeaderboardCategory {
  total,
  attendance,
  competition,
  training,
  match,
  social;

  String get value {
    switch (this) {
      case LeaderboardCategory.total:
        return 'total';
      case LeaderboardCategory.attendance:
        return 'attendance';
      case LeaderboardCategory.competition:
        return 'competition';
      case LeaderboardCategory.training:
        return 'training';
      case LeaderboardCategory.match:
        return 'match';
      case LeaderboardCategory.social:
        return 'social';
    }
  }

  static LeaderboardCategory fromString(String value) {
    switch (value) {
      case 'total':
        return LeaderboardCategory.total;
      case 'attendance':
        return LeaderboardCategory.attendance;
      case 'competition':
        return LeaderboardCategory.competition;
      case 'training':
        return LeaderboardCategory.training;
      case 'match':
        return LeaderboardCategory.match;
      case 'social':
        return LeaderboardCategory.social;
      default:
        return LeaderboardCategory.total;
    }
  }

  String get displayName {
    switch (this) {
      case LeaderboardCategory.total:
        return 'Total';
      case LeaderboardCategory.attendance:
        return 'Oppmøte';
      case LeaderboardCategory.competition:
        return 'Konkurranse';
      case LeaderboardCategory.training:
        return 'Trening';
      case LeaderboardCategory.match:
        return 'Kamp';
      case LeaderboardCategory.social:
        return 'Sosialt';
    }
  }
}

/// Leaderboard model for tracking different competition types
class Leaderboard extends Equatable {
  final String id;
  final String teamId;
  final String? seasonId;
  final String name;
  final String? description;
  final bool isMain;
  final int sortOrder;
  final LeaderboardCategory category;
  final DateTime createdAt;

  const Leaderboard({
    required this.id,
    required this.teamId,
    this.seasonId,
    required this.name,
    this.description,
    required this.isMain,
    required this.sortOrder,
    this.category = LeaderboardCategory.total,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        seasonId,
        name,
        description,
        isMain,
        sortOrder,
        category,
        createdAt,
      ];

  factory Leaderboard.fromJson(Map<String, dynamic> row) {
    return Leaderboard(
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      seasonId: safeStringNullable(row, 'season_id'),
      name: safeString(row, 'name'),
      description: safeStringNullable(row, 'description'),
      isMain: safeBool(row, 'is_main', defaultValue: false),
      sortOrder: safeInt(row, 'sort_order', defaultValue: 0),
      category: LeaderboardCategory.fromString(
          safeString(row, 'category', defaultValue: 'total')),
      createdAt: requireDateTime(row, 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'season_id': seasonId,
      'name': name,
      'description': description,
      'is_main': isMain,
      'sort_order': sortOrder,
      'category': category.value,
      'category_display': category.displayName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Leaderboard entry model for user points in a leaderboard
class LeaderboardEntry extends Equatable {
  final String id;
  final String leaderboardId;
  final String userId;
  final int points;
  final DateTime updatedAt;

  // Optional joined fields
  final String? userName;
  final String? userAvatarUrl;
  final int? rank;

  // Extended stats from ranked view
  final double? attendanceRate;
  final int? currentStreak;
  final bool? optedOut;
  final String? trend; // 'up', 'down', 'same'
  final int? rankChange;

  const LeaderboardEntry({
    required this.id,
    required this.leaderboardId,
    required this.userId,
    required this.points,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
    this.rank,
    this.attendanceRate,
    this.currentStreak,
    this.optedOut,
    this.trend,
    this.rankChange,
  });

  @override
  List<Object?> get props => [
        id,
        leaderboardId,
        userId,
        points,
        updatedAt,
        userName,
        userAvatarUrl,
        rank,
        attendanceRate,
        currentStreak,
        optedOut,
        trend,
        rankChange,
      ];

  factory LeaderboardEntry.fromJson(Map<String, dynamic> row, {int? rank}) {
    return LeaderboardEntry(
      id: safeString(row, 'id'),
      leaderboardId: safeString(row, 'leaderboard_id'),
      userId: safeString(row, 'user_id'),
      points: safeInt(row, 'points', defaultValue: 0),
      updatedAt: requireDateTime(row, 'updated_at'),
      userName: safeStringNullable(row, 'user_name'),
      userAvatarUrl: safeStringNullable(row, 'user_avatar_url'),
      rank: rank ?? safeIntNullable(row, 'rank'),
      attendanceRate: safeDoubleNullable(row, 'attendance_rate'),
      currentStreak: safeIntNullable(row, 'current_streak'),
      optedOut: safeBoolNullable(row, 'opted_out'),
      trend: safeStringNullable(row, 'trend'),
      rankChange: safeIntNullable(row, 'rank_change'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leaderboard_id': leaderboardId,
      'user_id': userId,
      'points': points,
      'updated_at': updatedAt.toIso8601String(),
      if (userName != null) 'user_name': userName,
      if (userAvatarUrl != null) 'user_avatar_url': userAvatarUrl,
      if (rank != null) 'rank': rank,
      if (attendanceRate != null) 'attendance_rate': attendanceRate,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (optedOut != null) 'opted_out': optedOut,
      if (trend != null) 'trend': trend,
      if (rankChange != null) 'rank_change': rankChange,
    };
  }
}

/// Configuration for how points are distributed from mini-activities to leaderboards
class MiniActivityPointConfig extends Equatable {
  final String id;
  final String miniActivityId;
  final String leaderboardId;
  final String distributionType; // 'winner_only', 'top_three', 'all_participants', 'custom'
  final int pointsFirst;
  final int pointsSecond;
  final int pointsThird;
  final int pointsParticipation;

  const MiniActivityPointConfig({
    required this.id,
    required this.miniActivityId,
    required this.leaderboardId,
    required this.distributionType,
    required this.pointsFirst,
    required this.pointsSecond,
    required this.pointsThird,
    required this.pointsParticipation,
  });

  @override
  List<Object?> get props => [
        id,
        miniActivityId,
        leaderboardId,
        distributionType,
        pointsFirst,
        pointsSecond,
        pointsThird,
        pointsParticipation,
      ];

  factory MiniActivityPointConfig.fromJson(Map<String, dynamic> row) {
    return MiniActivityPointConfig(
      id: safeString(row, 'id'),
      miniActivityId: safeString(row, 'mini_activity_id'),
      leaderboardId: safeString(row, 'leaderboard_id'),
      distributionType: safeString(row, 'distribution_type', defaultValue: 'winner_only'),
      pointsFirst: safeInt(row, 'points_first', defaultValue: 5),
      pointsSecond: safeInt(row, 'points_second', defaultValue: 3),
      pointsThird: safeInt(row, 'points_third', defaultValue: 1),
      pointsParticipation: safeInt(row, 'points_participation', defaultValue: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'leaderboard_id': leaderboardId,
      'distribution_type': distributionType,
      'points_first': pointsFirst,
      'points_second': pointsSecond,
      'points_third': pointsThird,
      'points_participation': pointsParticipation,
    };
  }
}
