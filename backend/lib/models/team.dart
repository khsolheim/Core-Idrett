import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final String? sport;
  final String? inviteCode;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    this.sport,
    this.inviteCode,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, sport, inviteCode, createdAt];

  factory Team.fromJson(Map<String, dynamic> row) {
    return Team(
      id: safeString(row, 'id'),
      name: safeString(row, 'name'),
      sport: safeStringNullable(row, 'sport'),
      inviteCode: safeStringNullable(row, 'invite_code'),
      createdAt: requireDateTime(row, 'created_at'),
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

  @override
  List<Object?> get props => [id, teamId, name, displayOrder, createdAt];

  factory TrainerType.fromJson(Map<String, dynamic> row) {
    return TrainerType(
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      name: safeString(row, 'name'),
      displayOrder: safeInt(row, 'display_order', defaultValue: 0),
      createdAt: requireDateTime(row, 'created_at'),
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

class TeamMember extends Equatable {
  final String id;
  final String userId;
  final String teamId;

  /// @deprecated Use isAdmin and isFineBoss flags instead
  final String role;

  /// Whether this member has admin privileges
  final bool isAdmin;

  /// Whether this member can manage fines (Botesjef)
  final bool isFineBoss;

  /// Whether this member has coach privileges (can manage activities)
  final bool isCoach;

  /// Optional trainer type ID (if member is a trainer)
  final String? trainerTypeId;

  /// Trainer type name (populated via join)
  final String? trainerTypeName;

  /// Whether this member is active (false = soft deleted)
  final bool isActive;

  /// Whether this member is currently injured (excluded from opt_out auto-responses)
  final bool isInjured;

  final DateTime joinedAt;

  const TeamMember({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.role,
    required this.isAdmin,
    required this.isFineBoss,
    required this.isCoach,
    this.trainerTypeId,
    this.trainerTypeName,
    required this.isActive,
    required this.isInjured,
    required this.joinedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        teamId,
        role,
        isAdmin,
        isFineBoss,
        isCoach,
        trainerTypeId,
        trainerTypeName,
        isActive,
        isInjured,
        joinedAt,
      ];

  factory TeamMember.fromJson(Map<String, dynamic> row) {
    return TeamMember(
      id: safeString(row, 'id'),
      userId: safeString(row, 'user_id'),
      teamId: safeString(row, 'team_id'),
      role: safeString(row, 'role', defaultValue: 'player'),
      isAdmin: safeBool(row, 'is_admin', defaultValue: false),
      isFineBoss: safeBool(row, 'is_fine_boss', defaultValue: false),
      isCoach: safeBool(row, 'is_coach', defaultValue: false),
      trainerTypeId: safeStringNullable(row, 'trainer_type_id'),
      trainerTypeName: safeStringNullable(row, 'trainer_type_name'),
      isActive: safeBool(row, 'is_active', defaultValue: true),
      isInjured: safeBool(row, 'is_injured', defaultValue: false),
      joinedAt: requireDateTime(row, 'joined_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'team_id': teamId,
      'role': role,
      'is_admin': isAdmin,
      'is_fine_boss': isFineBoss,
      'is_coach': isCoach,
      'trainer_type_id': trainerTypeId,
      'trainer_type_name': trainerTypeName,
      'is_active': isActive,
      'is_injured': isInjured,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  /// Determines the legacy role string based on flags
  /// Admin takes precedence, then fine_boss, then player
  String get effectiveRole {
    if (isAdmin) return 'admin';
    if (isFineBoss) return 'fine_boss';
    return 'player';
  }

  /// Check if member has any administrative privileges
  bool get hasAdminPrivileges => isAdmin;

  /// Check if member can manage fines
  bool get canManageFines => isAdmin || isFineBoss;

  /// Check if member is a trainer (any type)
  bool get isTrainer => trainerTypeId != null;

  /// Check if member can manage activities (admin or coach)
  bool get canManageActivities => isAdmin || isCoach;
}
