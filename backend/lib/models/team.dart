class Team {
  final String id;
  final String name;
  final String? sport;
  final String? inviteCode;
  final DateTime createdAt;

  Team({
    required this.id,
    required this.name,
    this.sport,
    this.inviteCode,
    required this.createdAt,
  });

  factory Team.fromRow(Map<String, dynamic> row) {
    return Team(
      id: row['id'] as String,
      name: row['name'] as String,
      sport: row['sport'] as String?,
      inviteCode: row['invite_code'] as String?,
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class TeamMember {
  final String id;
  final String userId;
  final String teamId;
  final String role;
  final DateTime joinedAt;

  TeamMember({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMember.fromRow(Map<String, dynamic> row) {
    return TeamMember(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      teamId: row['team_id'] as String,
      role: row['role'] as String,
      joinedAt: row['joined_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'team_id': teamId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
