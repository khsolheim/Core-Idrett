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

  ActivityTemplate({
    required this.id,
    required this.teamId,
    required this.name,
    required this.type,
    required this.defaultPoints,
    required this.createdAt,
  });

  factory ActivityTemplate.fromJson(Map<String, dynamic> json) {
    return ActivityTemplate(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      type: MiniActivityType.fromString(json['type'] as String),
      defaultPoints: json['default_points'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class MiniActivity {
  final String id;
  final String instanceId;
  final String? templateId;
  final String name;
  final MiniActivityType type;
  final DivisionMethod? divisionMethod;
  final int numTeams; // Number of teams for CUP mode
  final DateTime createdAt;
  final int? teamCount;
  final int? participantCount;
  final List<MiniActivityTeam>? teams;
  final List<MiniActivityParticipant>? participants;

  MiniActivity({
    required this.id,
    required this.instanceId,
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
  });

  factory MiniActivity.fromJson(Map<String, dynamic> json) {
    List<MiniActivityTeam>? teams;
    if (json['teams'] != null) {
      teams = (json['teams'] as List)
          .map((t) => MiniActivityTeam.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    List<MiniActivityParticipant>? participants;
    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((p) => MiniActivityParticipant.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return MiniActivity(
      id: json['id'] as String,
      instanceId: json['instance_id'] as String,
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
    );
  }

  bool get hasTeams => teams != null && teams!.isNotEmpty;
  bool get isTeamBased => type == MiniActivityType.team;
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
          .map((p) => MiniActivityParticipant.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return MiniActivityTeam(
      id: json['id'] as String,
      name: json['name'] as String?,
      finalScore: json['final_score'] as int?,
      participants: participants,
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
}
