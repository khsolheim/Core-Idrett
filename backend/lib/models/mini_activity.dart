class ActivityTemplate {
  final String id;
  final String teamId;
  final String name;
  final String type; // 'individual' or 'team'
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

  factory ActivityTemplate.fromRow(Map<String, dynamic> row) {
    return ActivityTemplate(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      name: row['name'] as String,
      type: row['type'] as String,
      defaultPoints: row['default_points'] as int? ?? 1,
      createdAt: row['created_at'] as DateTime,
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
    };
  }
}

class MiniActivity {
  final String id;
  final String instanceId;
  final String? templateId;
  final String name;
  final String type; // 'individual' or 'team'
  final String? divisionMethod; // 'random', 'ranked', 'age'
  final DateTime createdAt;

  MiniActivity({
    required this.id,
    required this.instanceId,
    this.templateId,
    required this.name,
    required this.type,
    this.divisionMethod,
    required this.createdAt,
  });

  factory MiniActivity.fromRow(Map<String, dynamic> row) {
    return MiniActivity(
      id: row['id'] as String,
      instanceId: row['instance_id'] as String,
      templateId: row['template_id'] as String?,
      name: row['name'] as String,
      type: row['type'] as String,
      divisionMethod: row['division_method'] as String?,
      createdAt: row['created_at'] as DateTime,
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
      'created_at': createdAt.toIso8601String(),
    };
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
}
