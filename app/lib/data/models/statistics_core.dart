import 'package:equatable/equatable.dart';

// Core statistics models: seasons, leaderboards, tests

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

  factory Season.fromJson(Map<String, dynamic> json) {
    return
  Season(
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


  @override
  List<Object?> get props => [id, teamId, name, startDate, endDate, isActive, createdAt];
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
  final DateTime createdAt;
  final List<NewLeaderboardEntry>? entries;
  const Leaderboard({
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
    return
  Leaderboard(
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


  @override
  List<Object?> get props => [id, teamId, seasonId, name, description, isMain, sortOrder, createdAt, entries];
}

/// New leaderboard entry model for the new leaderboard system
class NewLeaderboardEntry extends Equatable {
  final String id;
  final String leaderboardId;
  final String userId;
  final int points;
  final DateTime updatedAt;
  final String? userName;
  final String? userAvatarUrl;
  final int? rank;
  const NewLeaderboardEntry({
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
    return
  NewLeaderboardEntry(
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


  @override
  List<Object?> get props => [id, leaderboardId, userId, points, updatedAt, userName, userAvatarUrl, rank];
}

/// Test template model
class TestTemplate extends Equatable {
  final String id;
  final String teamId;
  final String name;
  final String? description;
  final String unit;
  final bool higherIsBetter;
  final DateTime createdAt;
  const TestTemplate({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    required this.unit,
    required this.higherIsBetter,
    required this.createdAt,
  });

  factory TestTemplate.fromJson(Map<String, dynamic> json) {
    return
  TestTemplate(
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


  @override
  List<Object?> get props => [id, teamId, name, description, unit, higherIsBetter, createdAt];
}

/// Test result model
class TestResult extends Equatable {
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
  const TestResult({
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
    return
  TestResult(
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


  @override
  List<Object?> get props => [id, testTemplateId, userId, instanceId, value, recordedAt, notes, userName, userAvatarUrl, testName, testUnit];
}
