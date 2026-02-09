import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

class MatchStats extends Equatable {
  final String id;
  final String instanceId;
  final String userId;
  final int goals;
  final int assists;
  final int minutesPlayed;
  final int yellowCards;
  final int redCards;

  // Joined fields
  final String? userName;
  final String? userAvatarUrl;

  const MatchStats({
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

  @override
  List<Object?> get props => [
        id,
        instanceId,
        userId,
        goals,
        assists,
        minutesPlayed,
        yellowCards,
        redCards,
        userName,
        userAvatarUrl,
      ];

  factory MatchStats.fromJson(Map<String, dynamic> json) {
    return MatchStats(
      id: safeString(json, 'id'),
      instanceId: safeString(json, 'instance_id'),
      userId: safeString(json, 'user_id'),
      goals: safeInt(json, 'goals', defaultValue: 0),
      assists: safeInt(json, 'assists', defaultValue: 0),
      minutesPlayed: safeInt(json, 'minutes_played', defaultValue: 0),
      yellowCards: safeInt(json, 'yellow_cards', defaultValue: 0),
      redCards: safeInt(json, 'red_cards', defaultValue: 0),
      userName: safeStringNullable(json, 'user_name'),
      userAvatarUrl: safeStringNullable(json, 'user_avatar_url'),
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

class PlayerRating extends Equatable {
  final String id;
  final String userId;
  final String teamId;
  final double rating;
  final int wins;
  final int losses;
  final int draws;
  final DateTime updatedAt;

  // Joined fields
  final String? userName;
  final String? userAvatarUrl;

  const PlayerRating({
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

  @override
  List<Object?> get props => [
        id,
        userId,
        teamId,
        rating,
        wins,
        losses,
        draws,
        updatedAt,
        userName,
        userAvatarUrl,
      ];

  factory PlayerRating.fromJson(Map<String, dynamic> json) {
    return PlayerRating(
      id: safeString(json, 'id'),
      userId: safeString(json, 'user_id'),
      teamId: safeString(json, 'team_id'),
      rating: safeDouble(json, 'rating', defaultValue: 1000.0),
      wins: safeInt(json, 'wins', defaultValue: 0),
      losses: safeInt(json, 'losses', defaultValue: 0),
      draws: safeInt(json, 'draws', defaultValue: 0),
      updatedAt: requireDateTime(json, 'updated_at'),
      userName: safeStringNullable(json, 'user_name'),
      userAvatarUrl: safeStringNullable(json, 'user_avatar_url'),
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

class SeasonStats extends Equatable {
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

  // Joined fields
  final String? userName;
  final String? userAvatarUrl;

  const SeasonStats({
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

  @override
  List<Object?> get props => [
        id,
        userId,
        teamId,
        seasonYear,
        attendanceCount,
        totalPoints,
        totalGoals,
        totalAssists,
        totalWins,
        totalLosses,
        totalDraws,
        userName,
        userAvatarUrl,
      ];

  factory SeasonStats.fromJson(Map<String, dynamic> json) {
    return SeasonStats(
      id: safeString(json, 'id'),
      userId: safeString(json, 'user_id'),
      teamId: safeString(json, 'team_id'),
      seasonYear: safeInt(json, 'season_year'),
      attendanceCount: safeInt(json, 'attendance_count', defaultValue: 0),
      totalPoints: safeInt(json, 'total_points', defaultValue: 0),
      totalGoals: safeInt(json, 'total_goals', defaultValue: 0),
      totalAssists: safeInt(json, 'total_assists', defaultValue: 0),
      totalWins: safeInt(json, 'total_wins', defaultValue: 0),
      totalLosses: safeInt(json, 'total_losses', defaultValue: 0),
      totalDraws: safeInt(json, 'total_draws', defaultValue: 0),
      userName: safeStringNullable(json, 'user_name'),
      userAvatarUrl: safeStringNullable(json, 'user_avatar_url'),
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

class PlayerStatistics extends Equatable {
  final String userId;
  final String teamId;
  final String userName;
  final String? userAvatarUrl;
  final PlayerRating? rating;
  final SeasonStats? currentSeason;
  final int totalActivities;
  final int attendedActivities;
  final double attendancePercentage;

  const PlayerStatistics({
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

  @override
  List<Object?> get props => [
        userId,
        teamId,
        userName,
        userAvatarUrl,
        rating,
        currentSeason,
        totalActivities,
        attendedActivities,
        attendancePercentage,
      ];

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

class LeaderboardEntry extends Equatable {
  final int rank;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int totalPoints;
  final double rating;
  final int wins;
  final int losses;
  final int draws;

  const LeaderboardEntry({
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

  @override
  List<Object?> get props => [
        rank,
        userId,
        userName,
        userAvatarUrl,
        totalPoints,
        rating,
        wins,
        losses,
        draws,
      ];

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

class AttendanceRecord extends Equatable {
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int totalActivities;
  final int attended;
  final int missed;
  final double percentage;

  const AttendanceRecord({
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    this.totalActivities = 0,
    this.attended = 0,
    this.missed = 0,
    this.percentage = 0.0,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        userAvatarUrl,
        totalActivities,
        attended,
        missed,
        percentage,
      ];

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
