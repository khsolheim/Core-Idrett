import 'package:equatable/equatable.dart';

/// Custom trainer type defined by each team
class TrainerType extends Equatable {
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

  @override
  List<Object?> get props => [id, teamId, name, displayOrder, createdAt];
}

class Team extends Equatable {
  final String id;
  final String name;
  final String? sport;
  final String? inviteCode;
  final DateTime createdAt;

  /// Whether the current user is an admin of this team
  final bool userIsAdmin;

  /// Whether the current user can manage fines
  final bool userIsFineBoss;

  /// Whether the current user is a coach (can manage activities)
  final bool userIsCoach;

  /// Current user's trainer type (if any)
  final TrainerType? userTrainerType;

  const Team({
    required this.id,
    required this.name,
    this.sport,
    this.inviteCode,
    required this.createdAt,
    this.userIsAdmin = false,
    this.userIsFineBoss = false,
    this.userIsCoach = false,
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
      userIsAdmin: json['user_is_admin'] as bool? ??
          (json['user_role'] == 'admin'),
      userIsFineBoss: json['user_is_fine_boss'] as bool? ??
          (json['user_role'] == 'fine_boss' || json['user_role'] == 'admin'),
      userIsCoach: json['user_is_coach'] as bool? ?? false,
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

  /// Check if current user can manage activities (admin or coach)
  bool get canManageActivities => userIsAdmin || userIsCoach;

  /// Check if current user is a trainer
  bool get isTrainer => userTrainerType != null;

  /// Get display string for the current user's role in this team
  String get userRoleDisplayName {
    final roles = <String>[];
    if (userIsAdmin) roles.add('Administrator');
    if (userIsCoach && !userIsAdmin) roles.add('Trener');
    if (userIsFineBoss && !userIsAdmin) roles.add('Botesjef');
    if (userTrainerType != null) roles.add(userTrainerType!.name);
    if (roles.isEmpty) roles.add('Medlem');
    return roles.join(', ');
  }

  /// Get a color hint for the user's primary role (for UI badges)
  /// Returns 'admin', 'coach', 'fineBoss', or 'member'
  String get userRoleColorKey {
    if (userIsAdmin) return 'admin';
    if (userIsCoach) return 'coach';
    if (userIsFineBoss) return 'fineBoss';
    return 'member';
  }

  @override
  List<Object?> get props => [id, name, sport, inviteCode, createdAt, userIsAdmin, userIsFineBoss, userIsCoach, userTrainerType];
}

class TeamMember extends Equatable {
  final String id;
  final String userId;
  final String teamId;
  final String userName;
  final String? userAvatarUrl;
  final DateTime? userBirthDate;

  /// Whether this member has admin privileges
  final bool isAdmin;

  /// Whether this member can manage fines (Botesjef)
  final bool isFineBoss;

  /// Whether this member has coach privileges (can manage activities)
  final bool isCoach;

  /// Trainer type (if member is a trainer)
  final TrainerType? trainerType;

  /// Whether this member is active (false = deactivated)
  final bool isActive;

  /// Whether this member is currently injured (excluded from opt_out auto-responses)
  final bool isInjured;

  final DateTime joinedAt;

  const TeamMember({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.userName,
    this.userAvatarUrl,
    this.userBirthDate,
    this.isAdmin = false,
    this.isFineBoss = false,
    this.isCoach = false,
    this.trainerType,
    this.isActive = true,
    this.isInjured = false,
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
    final isCoach = json['is_coach'] as bool? ?? false;

    return TeamMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      teamId: json['team_id'] as String,
      userName: json['user_name'] as String,
      userAvatarUrl: json['user_avatar_url'] as String?,
      userBirthDate: json['user_birth_date'] != null
          ? DateTime.parse(json['user_birth_date'] as String)
          : null,
      isAdmin: isAdmin,
      isFineBoss: isFineBoss,
      isCoach: isCoach,
      trainerType: trainerType,
      isActive: json['is_active'] as bool? ?? true,
      isInjured: json['is_injured'] as bool? ?? false,
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
      'is_admin': isAdmin,
      'is_fine_boss': isFineBoss,
      'is_coach': isCoach,
      'trainer_type': trainerType?.toJson(),
      'is_active': isActive,
      'is_injured': isInjured,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Check if member has any administrative privileges
  bool get hasAdminPrivileges => isAdmin;

  /// Check if member can manage fines
  bool get canManageFines => isAdmin || isFineBoss;

  /// Check if member can manage activities (admin or coach)
  bool get canManageActivities => isAdmin || isCoach;

  /// Check if member is a trainer (any type)
  bool get isTrainer => trainerType != null;

  /// Get display string for member's roles
  String get roleDisplayName {
    final roles = <String>[];
    if (isAdmin) roles.add('Administrator');
    if (isCoach && !isAdmin) roles.add('Trener');
    if (isFineBoss && !isAdmin) roles.add('Botesjef');
    if (trainerType != null) roles.add(trainerType!.name);
    if (roles.isEmpty) roles.add('Medlem');
    return roles.join(', ');
  }

  /// Create a copy with updated fields
  TeamMember copyWith({
    bool? isAdmin,
    bool? isFineBoss,
    bool? isCoach,
    TrainerType? trainerType,
    bool clearTrainerType = false,
    bool? isActive,
    bool? isInjured,
  }) {
    return TeamMember(
      id: id,
      userId: userId,
      teamId: teamId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userBirthDate: userBirthDate,
      isAdmin: isAdmin ?? this.isAdmin,
      isFineBoss: isFineBoss ?? this.isFineBoss,
      isCoach: isCoach ?? this.isCoach,
      trainerType: clearTrainerType ? null : (trainerType ?? this.trainerType),
      isActive: isActive ?? this.isActive,
      isInjured: isInjured ?? this.isInjured,
      joinedAt: joinedAt,
    );
  }

  @override
  List<Object?> get props => [id, userId, teamId, userName, userAvatarUrl, userBirthDate, isAdmin, isFineBoss, isCoach, trainerType, isActive, isInjured, joinedAt];
}

class TeamSettings extends Equatable {
  final String teamId;
  final int attendancePoints;
  final int winPoints;
  final int drawPoints;
  final int lossPoints;
  final double appealFee;
  final double gameDayMultiplier;

  const TeamSettings({
    required this.teamId,
    required this.attendancePoints,
    required this.winPoints,
    required this.drawPoints,
    required this.lossPoints,
    this.appealFee = 0,
    this.gameDayMultiplier = 1.0,
  });

  factory TeamSettings.fromJson(Map<String, dynamic> json) {
    return TeamSettings(
      teamId: json['team_id'] as String,
      attendancePoints: json['attendance_points'] as int? ?? 1,
      winPoints: json['win_points'] as int? ?? 3,
      drawPoints: json['draw_points'] as int? ?? 1,
      lossPoints: json['loss_points'] as int? ?? 0,
      appealFee: (json['appeal_fee'] as num?)?.toDouble() ?? 0,
      gameDayMultiplier: (json['game_day_multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'team_id': teamId,
      'attendance_points': attendancePoints,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      'appeal_fee': appealFee,
      'game_day_multiplier': gameDayMultiplier,
    };
  }

  TeamSettings copyWith({
    int? attendancePoints,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    double? appealFee,
    double? gameDayMultiplier,
  }) {
    return TeamSettings(
      teamId: teamId,
      attendancePoints: attendancePoints ?? this.attendancePoints,
      winPoints: winPoints ?? this.winPoints,
      drawPoints: drawPoints ?? this.drawPoints,
      lossPoints: lossPoints ?? this.lossPoints,
      appealFee: appealFee ?? this.appealFee,
      gameDayMultiplier: gameDayMultiplier ?? this.gameDayMultiplier,
    );
  }

  @override
  List<Object?> get props => [teamId, attendancePoints, winPoints, drawPoints, lossPoints, appealFee, gameDayMultiplier];
}
