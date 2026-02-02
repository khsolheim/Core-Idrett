// Mini-Activity Models for Frontend

enum MiniActivityType {
  individual,
  team;

  String get displayName {
    switch (this) {
      case MiniActivityType.individual:
        return 'Individuell';
      case MiniActivityType.team:
        return 'Lag';
    }
  }

  static MiniActivityType fromString(String type) {
    switch (type) {
      case 'team':
        return MiniActivityType.team;
      default:
        return MiniActivityType.individual;
    }
  }

  String toApiString() => name;
}

enum DivisionMethod {
  random,
  ranked,
  age,
  gmo,
  cup,
  manual;

  String get displayName {
    switch (this) {
      case DivisionMethod.random:
        return 'Tilfeldig';
      case DivisionMethod.ranked:
        return 'Etter rating';
      case DivisionMethod.age:
        return 'Etter alder';
      case DivisionMethod.gmo:
        return 'Gamle mot unge';
      case DivisionMethod.cup:
        return 'Cup (flere lag)';
      case DivisionMethod.manual:
        return 'Manuell';
    }
  }

  String get description {
    switch (this) {
      case DivisionMethod.random:
        return 'Spillerne fordeles tilfeldig pa lagene';
      case DivisionMethod.ranked:
        return 'Spillerne fordeles etter intern rating (snake draft)';
      case DivisionMethod.age:
        return 'Spillerne fordeles etter alder';
      case DivisionMethod.gmo:
        return 'De eldste mot de yngste';
      case DivisionMethod.cup:
        return 'Rettferdig fordeling pa flere lag (snake draft)';
      case DivisionMethod.manual:
        return 'Du velger selv hvem som skal pa hvert lag';
    }
  }

  bool get supportsMultipleTeams {
    return this == DivisionMethod.cup;
  }

  static DivisionMethod fromString(String? method) {
    switch (method) {
      case 'ranked':
        return DivisionMethod.ranked;
      case 'age':
        return DivisionMethod.age;
      case 'gmo':
        return DivisionMethod.gmo;
      case 'cup':
        return DivisionMethod.cup;
      case 'manual':
        return DivisionMethod.manual;
      default:
        return DivisionMethod.random;
    }
  }

  String toApiString() => name;
}

class ActivityTemplate {
  final String id;
  final String teamId;
  final String name;
  final MiniActivityType type;
  final int defaultPoints;
  final DateTime createdAt;
  // New fields
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

  factory ActivityTemplate.fromJson(Map<String, dynamic> json) {
    return ActivityTemplate(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      type: MiniActivityType.fromString(json['type'] as String),
      defaultPoints: json['default_points'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      sportType: json['sport_type'] as String?,
      suggestedRules: json['suggested_rules'] as Map<String, dynamic>?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      winPoints: json['win_points'] as int? ?? 3,
      drawPoints: json['draw_points'] as int? ?? 1,
      lossPoints: json['loss_points'] as int? ?? 0,
      leaderboardId: json['leaderboard_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'type': type.toApiString(),
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
    MiniActivityType? type,
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
  final String? instanceId; // Nullable for standalone activities
  final String? templateId;
  final String name;
  final MiniActivityType type;
  final DivisionMethod? divisionMethod;
  final int numTeams;
  final DateTime createdAt;
  final int? teamCount;
  final int? participantCount;
  final List<MiniActivityTeam>? teams;
  final List<MiniActivityParticipant>? participants;
  // New fields
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

  MiniActivity({
    required this.id,
    this.instanceId,
    this.templateId,
    required this.name,
    required this.type,
    this.divisionMethod,
    this.numTeams = 2,
    required this.createdAt,
    this.teamCount,
    this.participantCount,
    this.teams,
    this.participants,
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
  });

  factory MiniActivity.fromJson(Map<String, dynamic> json) {
    List<MiniActivityTeam>? teams;
    if (json['teams'] != null) {
      teams = (json['teams'] as List)
          .map((t) => MiniActivityTeam.fromJson(
              t is Map<String, dynamic> ? t : Map<String, dynamic>.from(t as Map)))
          .toList();
    }

    List<MiniActivityParticipant>? participants;
    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((p) => MiniActivityParticipant.fromJson(
              p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList();
    }

    return MiniActivity(
      id: json['id'] as String,
      instanceId: json['instance_id'] as String?,
      templateId: json['template_id'] as String?,
      name: json['name'] as String,
      type: MiniActivityType.fromString(json['type'] as String),
      divisionMethod: json['division_method'] != null
          ? DivisionMethod.fromString(json['division_method'] as String?)
          : null,
      numTeams: json['num_teams'] as int? ?? 2,
      createdAt: DateTime.parse(json['created_at'] as String),
      teamCount: json['team_count'] as int?,
      participantCount: json['participant_count'] as int?,
      teams: teams,
      participants: participants,
      teamId: json['team_id'] as String?,
      leaderboardId: json['leaderboard_id'] as String?,
      enableLeaderboard: json['enable_leaderboard'] as bool? ?? true,
      winPoints: json['win_points'] as int? ?? 3,
      drawPoints: json['draw_points'] as int? ?? 1,
      lossPoints: json['loss_points'] as int? ?? 0,
      description: json['description'] as String?,
      maxParticipants: json['max_participants'] as int?,
      handicapEnabled: json['handicap_enabled'] as bool? ?? false,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instance_id': instanceId,
      'template_id': templateId,
      'name': name,
      'type': type.toApiString(),
      'division_method': divisionMethod?.toApiString(),
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
    };
  }

  bool get hasTeams => teams != null && teams!.isNotEmpty;
  bool get isTeamBased => type == MiniActivityType.team;
  bool get isStandalone => instanceId == null && teamId != null;
  bool get isArchived => archivedAt != null;

  MiniActivity copyWith({
    String? id,
    String? instanceId,
    String? templateId,
    String? name,
    MiniActivityType? type,
    DivisionMethod? divisionMethod,
    int? numTeams,
    DateTime? createdAt,
    int? teamCount,
    int? participantCount,
    List<MiniActivityTeam>? teams,
    List<MiniActivityParticipant>? participants,
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
      teamCount: teamCount ?? this.teamCount,
      participantCount: participantCount ?? this.participantCount,
      teams: teams ?? this.teams,
      participants: participants ?? this.participants,
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
    );
  }
}

class MiniActivityTeam {
  final String id;
  final String? name;
  final int? finalScore;
  final List<MiniActivityParticipant>? participants;

  MiniActivityTeam({
    required this.id,
    this.name,
    this.finalScore,
    this.participants,
  });

  factory MiniActivityTeam.fromJson(Map<String, dynamic> json) {
    List<MiniActivityParticipant>? participants;
    if (json['participants'] != null && json['participants'] is List) {
      final list = json['participants'] as List;
      // Filter out null entries that might come from LEFT JOIN
      participants = list
          .where((p) => p != null && p is Map && p['user_id'] != null)
          .map((p) => MiniActivityParticipant.fromJson(
              p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList();
    }

    return MiniActivityTeam(
      id: json['id'] as String,
      name: json['name'] as String?,
      finalScore: json['final_score'] as int?,
      participants: participants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'final_score': finalScore,
      'participants': participants?.map((p) => p.toJson()).toList(),
    };
  }

  MiniActivityTeam copyWith({
    String? id,
    String? name,
    int? finalScore,
    List<MiniActivityParticipant>? participants,
  }) {
    return MiniActivityTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      finalScore: finalScore ?? this.finalScore,
      participants: participants ?? this.participants,
    );
  }
}

class MiniActivityParticipant {
  final String id;
  final String userId;
  final int points;
  final String? userName;
  final String? userAvatarUrl;

  MiniActivityParticipant({
    required this.id,
    required this.userId,
    required this.points,
    this.userName,
    this.userAvatarUrl,
  });

  factory MiniActivityParticipant.fromJson(Map<String, dynamic> json) {
    return MiniActivityParticipant(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      points: json['points'] as int? ?? 0,
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
    };
  }

  MiniActivityParticipant copyWith({
    String? id,
    String? userId,
    int? points,
    String? userName,
    String? userAvatarUrl,
  }) {
    return MiniActivityParticipant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}

// Adjustment model for bonus/penalty points
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

  factory MiniActivityAdjustment.fromJson(Map<String, dynamic> json) {
    return MiniActivityAdjustment(
      id: json['id'] as String,
      miniActivityId: json['mini_activity_id'] as String,
      teamId: json['team_id'] as String?,
      userId: json['user_id'] as String?,
      points: json['points'] as int,
      reason: json['reason'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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

  String get displayDescription => reason ?? (isBonus ? 'Bonus' : 'Straff');

  String get targetDisplay {
    if (isTeamAdjustment) {
      return 'Lag';
    } else if (isUserAdjustment) {
      return 'Spiller';
    }
    return 'Ukjent';
  }

  String get formattedPoints {
    if (points >= 0) {
      return '+$points';
    }
    return '$points';
  }
}

// Handicap model for player handicaps
class MiniActivityHandicap {
  final String id;
  final String miniActivityId;
  final String userId;
  final double handicapValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;

  MiniActivityHandicap({
    required this.id,
    required this.miniActivityId,
    required this.userId,
    required this.handicapValue,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
  });

  factory MiniActivityHandicap.fromJson(Map<String, dynamic> json) {
    return MiniActivityHandicap(
      id: json['id'] as String,
      miniActivityId: json['mini_activity_id'] as String,
      userId: json['user_id'] as String,
      handicapValue: (json['handicap_value'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
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
      'user_name': userName,
    };
  }

  String get formattedHandicap {
    if (handicapValue >= 0) {
      return '+${handicapValue.toStringAsFixed(1)}';
    }
    return handicapValue.toStringAsFixed(1);
  }
}
