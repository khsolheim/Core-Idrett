// Mini-Activity Models
// Tasks: BM-001 to BM-023

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

class ActivityTemplate {
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

  ActivityTemplate({
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

  factory ActivityTemplate.fromRow(Map<String, dynamic> row) {
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

class MiniActivity {
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

  MiniActivity({
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

  factory MiniActivity.fromRow(Map<String, dynamic> row) {
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

class MiniActivityTeam {
  final String id;
  final String miniActivityId;
  final String? name;
  final int? finalScore;

  MiniActivityTeam({
    required this.id,
    required this.miniActivityId,
    this.name,
    this.finalScore,
  });

  factory MiniActivityTeam.fromRow(Map<String, dynamic> row) {
    return MiniActivityTeam(
      id: row['id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      name: row['name'] as String?,
      finalScore: row['final_score'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'name': name,
      'final_score': finalScore,
    };
  }

  MiniActivityTeam copyWith({
    String? id,
    String? miniActivityId,
    String? name,
    int? finalScore,
  }) {
    return MiniActivityTeam(
      id: id ?? this.id,
      miniActivityId: miniActivityId ?? this.miniActivityId,
      name: name ?? this.name,
      finalScore: finalScore ?? this.finalScore,
    );
  }
}

class MiniActivityParticipant {
  final String id;
  final String? miniTeamId;
  final String miniActivityId;
  final String userId;
  final int points;

  MiniActivityParticipant({
    required this.id,
    this.miniTeamId,
    required this.miniActivityId,
    required this.userId,
    required this.points,
  });

  factory MiniActivityParticipant.fromRow(Map<String, dynamic> row) {
    return MiniActivityParticipant(
      id: row['id'] as String,
      miniTeamId: row['mini_team_id'] as String?,
      miniActivityId: row['mini_activity_id'] as String,
      userId: row['user_id'] as String,
      points: row['points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_team_id': miniTeamId,
      'mini_activity_id': miniActivityId,
      'user_id': userId,
      'points': points,
    };
  }

  MiniActivityParticipant copyWith({
    String? id,
    String? miniTeamId,
    String? miniActivityId,
    String? userId,
    int? points,
  }) {
    return MiniActivityParticipant(
      id: id ?? this.id,
      miniTeamId: miniTeamId ?? this.miniTeamId,
      miniActivityId: miniActivityId ?? this.miniActivityId,
      userId: userId ?? this.userId,
      points: points ?? this.points,
    );
  }
}

// Adjustment model (BM-013 to BM-015)
class MiniActivityAdjustment {
  final String id;
  final String miniActivityId;
  final String? teamId;
  final String? userId;
  final int points;
  final String? reason;
  final String createdBy;
  final DateTime createdAt;

  MiniActivityAdjustment({
    required this.id,
    required this.miniActivityId,
    this.teamId,
    this.userId,
    required this.points,
    this.reason,
    required this.createdBy,
    required this.createdAt,
  });

  factory MiniActivityAdjustment.fromRow(Map<String, dynamic> row) {
    return MiniActivityAdjustment(
      id: row['id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      teamId: row['team_id'] as String?,
      userId: row['user_id'] as String?,
      points: row['points'] as int,
      reason: row['reason'] as String?,
      createdBy: row['created_by'] as String,
      createdAt: _parseDateTime(row['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'team_id': teamId,
      'user_id': userId,
      'points': points,
      'reason': reason,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isTeamAdjustment => teamId != null;
  bool get isUserAdjustment => userId != null;
  bool get isBonus => points > 0;
  bool get isPenalty => points < 0;
}

// Handicap model (BM-016)
class MiniActivityHandicap {
  final String id;
  final String miniActivityId;
  final String userId;
  final double handicapValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  MiniActivityHandicap({
    required this.id,
    required this.miniActivityId,
    required this.userId,
    required this.handicapValue,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MiniActivityHandicap.fromRow(Map<String, dynamic> row) {
    return MiniActivityHandicap(
      id: row['id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      userId: row['user_id'] as String,
      handicapValue: (row['handicap_value'] as num).toDouble(),
      createdAt: _parseDateTime(row['created_at']),
      updatedAt: _parseDateTime(row['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'user_id': userId,
      'handicap_value': handicapValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
