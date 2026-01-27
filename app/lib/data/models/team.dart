/// @deprecated Use isAdmin and isFineBoss flags on TeamMember instead
/// Kept for backwards compatibility
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

/// Custom trainer type defined by each team
class TrainerType {
  final String id;
  final String teamId;
  final String name;
  final int displayOrder;
  final DateTime createdAt;

  const TrainerType({
    required this.id,
    required this.teamId,
    required this.name,
    required this.displayOrder,
    required this.createdAt,
  });

  factory TrainerType.fromJson(Map<String, dynamic> json) {
    return TrainerType(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Team {
  final String id;
  final String name;
  final String? sport;
  final String? inviteCode;
  final DateTime createdAt;

  /// @deprecated Use userIsAdmin, userIsFineBoss instead
  final TeamRole? userRole;

  /// Whether the current user is an admin of this team
  final bool userIsAdmin;

  /// Whether the current user can manage fines
  final bool userIsFineBoss;

  /// Current user's trainer type (if any)
  final TrainerType? userTrainerType;

  Team({
    required this.id,
    required this.name,
    this.sport,
    this.inviteCode,
    required this.createdAt,
    this.userRole,
    this.userIsAdmin = false,
    this.userIsFineBoss = false,
    this.userTrainerType,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    // Parse trainer type if present
    TrainerType? trainerType;
    if (json['user_trainer_type'] != null) {
      trainerType = TrainerType.fromJson(json['user_trainer_type'] as Map<String, dynamic>);
    }

    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      sport: json['sport'] as String?,
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      // Support both old and new API format
      userRole: json['user_role'] != null
          ? TeamRole.fromString(json['user_role'] as String)
          : null,
      userIsAdmin: json['user_is_admin'] as bool? ??
          (json['user_role'] == 'admin'),
      userIsFineBoss: json['user_is_fine_boss'] as bool? ??
          (json['user_role'] == 'fine_boss' || json['user_role'] == 'admin'),
      userTrainerType: trainerType,
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

  /// Check if current user has admin privileges
  bool get hasAdminPrivileges => userIsAdmin;

  /// Check if current user can manage fines
  bool get canManageFines => userIsAdmin || userIsFineBoss;

  /// Check if current user is a trainer
  bool get isTrainer => userTrainerType != null;
}

class TeamMember {
  final String id;
  final String userId;
  final String teamId;
  final String userName;
  final String? userAvatarUrl;
  final DateTime? userBirthDate;

  /// @deprecated Use isAdmin, isFineBoss flags instead
  final TeamRole role;

  /// Whether this member has admin privileges
  final bool isAdmin;

  /// Whether this member can manage fines (Botesjef)
  final bool isFineBoss;

  /// Trainer type (if member is a trainer)
  final TrainerType? trainerType;

  /// Whether this member is active (false = deactivated)
  final bool isActive;

  final DateTime joinedAt;

  TeamMember({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.userName,
    this.userAvatarUrl,
    this.userBirthDate,
    required this.role,
    this.isAdmin = false,
    this.isFineBoss = false,
    this.trainerType,
    this.isActive = true,
    required this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    // Parse trainer type if present
    TrainerType? trainerType;
    if (json['trainer_type'] != null) {
      trainerType = TrainerType.fromJson(json['trainer_type'] as Map<String, dynamic>);
    } else if (json['trainer_type_id'] != null && json['trainer_type_name'] != null) {
      // Legacy format with separate fields
      trainerType = TrainerType(
        id: json['trainer_type_id'] as String,
        teamId: json['team_id'] as String,
        name: json['trainer_type_name'] as String,
        displayOrder: 0,
        createdAt: DateTime.now(),
      );
    }

    // Determine isAdmin and isFineBoss from new fields or legacy role
    final legacyRole = json['role'] as String? ?? 'player';
    final isAdmin = json['is_admin'] as bool? ?? (legacyRole == 'admin');
    final isFineBoss = json['is_fine_boss'] as bool? ?? (legacyRole == 'fine_boss');

    return TeamMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      teamId: json['team_id'] as String,
      userName: json['user_name'] as String,
      userAvatarUrl: json['user_avatar_url'] as String?,
      userBirthDate: json['user_birth_date'] != null
          ? DateTime.parse(json['user_birth_date'] as String)
          : null,
      role: TeamRole.fromString(legacyRole),
      isAdmin: isAdmin,
      isFineBoss: isFineBoss,
      trainerType: trainerType,
      isActive: json['is_active'] as bool? ?? true,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'team_id': teamId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'user_birth_date': userBirthDate?.toIso8601String(),
      'role': role.toApiString(),
      'is_admin': isAdmin,
      'is_fine_boss': isFineBoss,
      'trainer_type': trainerType?.toJson(),
      'is_active': isActive,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Check if member has any administrative privileges
  bool get hasAdminPrivileges => isAdmin;

  /// Check if member can manage fines
  bool get canManageFines => isAdmin || isFineBoss;

  /// Check if member is a trainer (any type)
  bool get isTrainer => trainerType != null;

  /// Get display string for member's roles
  String get roleDisplayName {
    final roles = <String>[];
    if (isAdmin) roles.add('Administrator');
    if (isFineBoss && !isAdmin) roles.add('Botesjef');
    if (trainerType != null) roles.add(trainerType!.name);
    if (roles.isEmpty) roles.add('Medlem');
    return roles.join(', ');
  }

  /// Create a copy with updated fields
  TeamMember copyWith({
    bool? isAdmin,
    bool? isFineBoss,
    TrainerType? trainerType,
    bool clearTrainerType = false,
    bool? isActive,
  }) {
    return TeamMember(
      id: id,
      userId: userId,
      teamId: teamId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userBirthDate: userBirthDate,
      role: role,
      isAdmin: isAdmin ?? this.isAdmin,
      isFineBoss: isFineBoss ?? this.isFineBoss,
      trainerType: clearTrainerType ? null : (trainerType ?? this.trainerType),
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt,
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
