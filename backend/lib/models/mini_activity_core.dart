// Mini-Activity Models
// Tasks: BM-001 to BM-023

import 'package:equatable/equatable.dart';

// Helper to parse DateTime from database (may come as String or DateTime)
DateTime _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}

DateTime? _parseDateTimeNullable(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return null;
}

class ActivityTemplate extends Equatable {
  final String id;
  final String teamId;
  final String name;
  final String type; // 'individual' or 'team'
  final int defaultPoints;
  final DateTime createdAt;
  // New fields (BM-017 to BM-023)
  final String? description;
  final String? instructions;
  final String? sportType;
  final Map<String, dynamic>? suggestedRules;
  final bool isFavorite;
  final int winPoints;
  final int drawPoints;
  final int lossPoints;
  final String? leaderboardId;

  const ActivityTemplate({
    required this.id,
    required this.teamId,
    required this.name,
    required this.type,
    required this.defaultPoints,
    required this.createdAt,
    this.description,
    this.instructions,
    this.sportType,
    this.suggestedRules,
    this.isFavorite = false,
    this.winPoints = 3,
    this.drawPoints = 1,
    this.lossPoints = 0,
    this.leaderboardId,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        name,
        type,
        defaultPoints,
        createdAt,
        description,
        instructions,
        sportType,
        suggestedRules,
        isFavorite,
        winPoints,
        drawPoints,
        lossPoints,
        leaderboardId,
      ];

  factory ActivityTemplate.fromJson(Map<String, dynamic> row) {
    return ActivityTemplate(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      name: row['name'] as String,
      type: row['type'] as String,
      defaultPoints: row['default_points'] as int? ?? 1,
      createdAt: _parseDateTime(row['created_at']),
      description: row['description'] as String?,
      instructions: row['instructions'] as String?,
      sportType: row['sport_type'] as String?,
      suggestedRules: row['suggested_rules'] as Map<String, dynamic>?,
      isFavorite: row['is_favorite'] as bool? ?? false,
      winPoints: row['win_points'] as int? ?? 3,
      drawPoints: row['draw_points'] as int? ?? 1,
      lossPoints: row['loss_points'] as int? ?? 0,
      leaderboardId: row['leaderboard_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'type': type,
      'default_points': defaultPoints,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'instructions': instructions,
      'sport_type': sportType,
      'suggested_rules': suggestedRules,
      'is_favorite': isFavorite,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      'leaderboard_id': leaderboardId,
    };
  }

  ActivityTemplate copyWith({
    String? id,
    String? teamId,
    String? name,
    String? type,
    int? defaultPoints,
    DateTime? createdAt,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    bool? isFavorite,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
  }) {
    return ActivityTemplate(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultPoints: defaultPoints ?? this.defaultPoints,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      sportType: sportType ?? this.sportType,
      suggestedRules: suggestedRules ?? this.suggestedRules,
      isFavorite: isFavorite ?? this.isFavorite,
      winPoints: winPoints ?? this.winPoints,
      drawPoints: drawPoints ?? this.drawPoints,
      lossPoints: lossPoints ?? this.lossPoints,
      leaderboardId: leaderboardId ?? this.leaderboardId,
    );
  }
}

class MiniActivity extends Equatable {
  final String id;
  final String? instanceId; // Now nullable for standalone activities (BM-011)
  final String? templateId;
  final String name;
  final String type; // 'individual' or 'team'
  final String? divisionMethod; // 'random', 'ranked', 'age', 'gmo', 'cup', 'manual'
  final int numTeams; // Number of teams for CUP mode (default 2)
  final DateTime createdAt;
  // New fields (BM-001 to BM-010)
  final String? teamId; // For standalone mini-activities
  final String? leaderboardId;
  final bool enableLeaderboard;
  final int winPoints;
  final int drawPoints;
  final int lossPoints;
  final String? description;
  final int? maxParticipants;
  final bool handicapEnabled;
  final DateTime? archivedAt;
  final String? winnerTeamId; // Manually set winner (null = draw or no result)

  const MiniActivity({
    required this.id,
    this.instanceId,
    this.templateId,
    required this.name,
    required this.type,
    this.divisionMethod,
    this.numTeams = 2,
    required this.createdAt,
    this.teamId,
    this.leaderboardId,
    this.enableLeaderboard = true,
    this.winPoints = 3,
    this.drawPoints = 1,
    this.lossPoints = 0,
    this.description,
    this.maxParticipants,
    this.handicapEnabled = false,
    this.archivedAt,
    this.winnerTeamId,
  });

  @override
  List<Object?> get props => [
        id,
        instanceId,
        templateId,
        name,
        type,
        divisionMethod,
        numTeams,
        createdAt,
        teamId,
        leaderboardId,
        enableLeaderboard,
        winPoints,
        drawPoints,
        lossPoints,
        description,
        maxParticipants,
        handicapEnabled,
        archivedAt,
        winnerTeamId,
      ];

  factory MiniActivity.fromJson(Map<String, dynamic> row) {
    return MiniActivity(
      id: row['id'] as String,
      instanceId: row['instance_id'] as String?,
      templateId: row['template_id'] as String?,
      name: row['name'] as String,
      type: row['type'] as String,
      divisionMethod: row['division_method'] as String?,
      numTeams: row['num_teams'] as int? ?? 2,
      createdAt: _parseDateTime(row['created_at']),
      teamId: row['team_id'] as String?,
      leaderboardId: row['leaderboard_id'] as String?,
      enableLeaderboard: row['enable_leaderboard'] as bool? ?? true,
      winPoints: row['win_points'] as int? ?? 3,
      drawPoints: row['draw_points'] as int? ?? 1,
      lossPoints: row['loss_points'] as int? ?? 0,
      description: row['description'] as String?,
      maxParticipants: row['max_participants'] as int?,
      handicapEnabled: row['handicap_enabled'] as bool? ?? false,
      archivedAt: _parseDateTimeNullable(row['archived_at']),
      winnerTeamId: row['winner_team_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instance_id': instanceId,
      'template_id': templateId,
      'name': name,
      'type': type,
      'division_method': divisionMethod,
      'num_teams': numTeams,
      'created_at': createdAt.toIso8601String(),
      'team_id': teamId,
      'leaderboard_id': leaderboardId,
      'enable_leaderboard': enableLeaderboard,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      'description': description,
      'max_participants': maxParticipants,
      'handicap_enabled': handicapEnabled,
      'archived_at': archivedAt?.toIso8601String(),
      'winner_team_id': winnerTeamId,
    };
  }

  bool get isStandalone => instanceId == null && teamId != null;
  bool get isArchived => archivedAt != null;
  bool get hasResult => winnerTeamId != null;

  MiniActivity copyWith({
    String? id,
    String? instanceId,
    String? templateId,
    String? name,
    String? type,
    String? divisionMethod,
    int? numTeams,
    DateTime? createdAt,
    String? teamId,
    String? leaderboardId,
    bool? enableLeaderboard,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? description,
    int? maxParticipants,
    bool? handicapEnabled,
    DateTime? archivedAt,
    String? winnerTeamId,
  }) {
    return MiniActivity(
      id: id ?? this.id,
      instanceId: instanceId ?? this.instanceId,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      type: type ?? this.type,
      divisionMethod: divisionMethod ?? this.divisionMethod,
      numTeams: numTeams ?? this.numTeams,
      createdAt: createdAt ?? this.createdAt,
      teamId: teamId ?? this.teamId,
      leaderboardId: leaderboardId ?? this.leaderboardId,
      enableLeaderboard: enableLeaderboard ?? this.enableLeaderboard,
      winPoints: winPoints ?? this.winPoints,
      drawPoints: drawPoints ?? this.drawPoints,
      lossPoints: lossPoints ?? this.lossPoints,
      description: description ?? this.description,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      handicapEnabled: handicapEnabled ?? this.handicapEnabled,
      archivedAt: archivedAt ?? this.archivedAt,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
    );
  }
}
