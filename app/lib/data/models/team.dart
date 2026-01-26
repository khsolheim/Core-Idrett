enum TeamRole {
  admin,
  fineBoss,
  player;

  String get displayName {
    switch (this) {
      case TeamRole.admin:
        return 'Administrator';
      case TeamRole.fineBoss:
        return 'Botesjef';
      case TeamRole.player:
        return 'Spiller';
    }
  }

  static TeamRole fromString(String role) {
    switch (role) {
      case 'admin':
        return TeamRole.admin;
      case 'fine_boss':
        return TeamRole.fineBoss;
      case 'player':
      default:
        return TeamRole.player;
    }
  }

  String toApiString() {
    switch (this) {
      case TeamRole.admin:
        return 'admin';
      case TeamRole.fineBoss:
        return 'fine_boss';
      case TeamRole.player:
        return 'player';
    }
  }
}

class Team {
  final String id;
  final String name;
  final String? sport;
  final String? inviteCode;
  final DateTime createdAt;
  final TeamRole? userRole;

  Team({
    required this.id,
    required this.name,
    this.sport,
    this.inviteCode,
    required this.createdAt,
    this.userRole,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      sport: json['sport'] as String?,
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userRole: json['user_role'] != null
          ? TeamRole.fromString(json['user_role'] as String)
          : null,
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
  final String userName;
  final String? userAvatarUrl;
  final TeamRole role;
  final DateTime joinedAt;

  TeamMember({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.userName,
    this.userAvatarUrl,
    required this.role,
    required this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      teamId: json['team_id'] as String,
      userName: json['user_name'] as String,
      userAvatarUrl: json['user_avatar_url'] as String?,
      role: TeamRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class TeamSettings {
  final String teamId;
  final int attendancePoints;
  final int winPoints;
  final int drawPoints;
  final int lossPoints;

  TeamSettings({
    required this.teamId,
    required this.attendancePoints,
    required this.winPoints,
    required this.drawPoints,
    required this.lossPoints,
  });

  factory TeamSettings.fromJson(Map<String, dynamic> json) {
    return TeamSettings(
      teamId: json['team_id'] as String,
      attendancePoints: json['attendance_points'] as int? ?? 1,
      winPoints: json['win_points'] as int? ?? 3,
      drawPoints: json['draw_points'] as int? ?? 1,
      lossPoints: json['loss_points'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'attendance_points': attendancePoints,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
    };
  }

  TeamSettings copyWith({
    int? attendancePoints,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
  }) {
    return TeamSettings(
      teamId: teamId,
      attendancePoints: attendancePoints ?? this.attendancePoints,
      winPoints: winPoints ?? this.winPoints,
      drawPoints: drawPoints ?? this.drawPoints,
      lossPoints: lossPoints ?? this.lossPoints,
    );
  }
}
