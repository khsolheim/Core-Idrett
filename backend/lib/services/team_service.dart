import 'dart:math';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/team.dart';

class TeamService {
  final Database _db;
  final _uuid = const Uuid();

  TeamService(this._db);

  /// Get membership for a user in a specific team
  Future<Map<String, dynamic>?> getMembership(String teamId, String userId) async {
    final result = await _db.client.select(
      'team_members',
      filters: {
        'team_id': 'eq.$teamId',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
      },
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<List<Map<String, dynamic>>> getTeamsForUser(String userId) async {
    // Get team memberships for user (only active)
    final memberships = await _db.client.select(
      'team_members',
      select: 'team_id,role,is_admin,is_fine_boss,is_coach,trainer_type_id,is_active',
      filters: {
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
      },
    );

    if (memberships.isEmpty) return [];

    // Get team IDs
    final teamIds = memberships.map((m) => m['team_id'] as String).toList();

    // Get teams
    final teams = await _db.client.select(
      'teams',
      filters: {'id': 'in.(${teamIds.join(',')})'},
      order: 'name.asc',
    );

    // Get trainer types for members who have one
    final trainerTypeIds = memberships
        .where((m) => m['trainer_type_id'] != null)
        .map((m) => m['trainer_type_id'] as String)
        .toList();

    Map<String, Map<String, dynamic>> trainerTypeMap = {};
    if (trainerTypeIds.isNotEmpty) {
      final trainerTypes = await _db.client.select(
        'trainer_types',
        filters: {'id': 'in.(${trainerTypeIds.join(',')})'},
      );
      for (final tt in trainerTypes) {
        trainerTypeMap[tt['id'] as String] = tt;
      }
    }

    // Create lookup for membership data
    final membershipMap = <String, Map<String, dynamic>>{};
    for (final m in memberships) {
      membershipMap[m['team_id'] as String] = m;
    }

    return teams.map((t) {
      final membership = membershipMap[t['id']] ?? {};
      final trainerTypeId = membership['trainer_type_id'] as String?;
      final trainerType = trainerTypeId != null ? trainerTypeMap[trainerTypeId] : null;

      return {
        'id': t['id'],
        'name': t['name'],
        'sport': t['sport'],
        'invite_code': t['invite_code'],
        'created_at': t['created_at'],
        // Legacy field for backwards compatibility
        'user_role': membership['role'] ?? 'player',
        // New fields
        'user_is_admin': membership['is_admin'] ?? false,
        'user_is_fine_boss': membership['is_fine_boss'] ?? false,
        'user_is_coach': membership['is_coach'] ?? false,
        'user_trainer_type': trainerType,
      };
    }).toList();
  }

  Future<Team> createTeam({
    required String name,
    String? sport,
    required String creatorId,
  }) async {
    final teamId = _uuid.v4();
    final inviteCode = _generateInviteCode();

    final result = await _db.client.insert('teams', {
      'id': teamId,
      'name': name,
      'sport': sport,
      'invite_code': inviteCode,
    });

    // Add creator as admin with new flags
    await _db.client.insert('team_members', {
      'id': _uuid.v4(),
      'user_id': creatorId,
      'team_id': teamId,
      'role': 'admin', // Keep for backwards compatibility
      'is_admin': true,
      'is_fine_boss': true, // Creator is also fine boss by default
      'is_active': true,
    });

    // Create default trainer types for the team
    final defaultTrainerTypes = [
      {'name': 'Hovedtrener', 'display_order': 1},
      {'name': 'Assistenttrener', 'display_order': 2},
      {'name': 'Keepertrener', 'display_order': 3},
      {'name': 'Fysioterapeut', 'display_order': 4},
    ];

    for (final tt in defaultTrainerTypes) {
      await _db.client.insert('trainer_types', {
        'id': _uuid.v4(),
        'team_id': teamId,
        'name': tt['name'],
        'display_order': tt['display_order'],
      });
    }

    // Create default team settings
    await _db.client.insert('team_settings', {
      'id': _uuid.v4(),
      'team_id': teamId,
    });

    final row = result.first;
    return Team(
      id: row['id'] as String,
      name: row['name'] as String,
      sport: row['sport'] as String?,
      inviteCode: row['invite_code'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<Map<String, dynamic>?> getTeamById(String teamId, String userId) async {
    // Check if user is active member
    final membership = await _db.client.select(
      'team_members',
      select: 'role,is_admin,is_fine_boss,is_coach,trainer_type_id,is_active',
      filters: {
        'team_id': 'eq.$teamId',
        'user_id': 'eq.$userId',
      },
    );

    if (membership.isEmpty) return null;

    final memberData = membership.first;
    if (memberData['is_active'] == false) return null;

    // Get team
    final teams = await _db.client.select(
      'teams',
      filters: {'id': 'eq.$teamId'},
    );

    if (teams.isEmpty) return null;

    // Get trainer type if present
    Map<String, dynamic>? trainerType;
    final trainerTypeId = memberData['trainer_type_id'] as String?;
    if (trainerTypeId != null) {
      final trainerTypes = await _db.client.select(
        'trainer_types',
        filters: {'id': 'eq.$trainerTypeId'},
      );
      if (trainerTypes.isNotEmpty) {
        trainerType = trainerTypes.first;
      }
    }

    final team = teams.first;
    return {
      'id': team['id'],
      'name': team['name'],
      'sport': team['sport'],
      'invite_code': team['invite_code'],
      'created_at': team['created_at'],
      // Legacy field
      'user_role': memberData['role'],
      // New fields
      'user_is_admin': memberData['is_admin'] ?? false,
      'user_is_fine_boss': memberData['is_fine_boss'] ?? false,
      'user_is_coach': memberData['is_coach'] ?? false,
      'user_trainer_type': trainerType,
    };
  }

  Future<List<Map<String, dynamic>>> getTeamMembers(String teamId, {bool includeInactive = false}) async {
    // Get memberships
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (!includeInactive) {
      filters['is_active'] = 'eq.true';
    }

    final memberships = await _db.client.select(
      'team_members',
      filters: filters,
      order: 'is_admin.desc,is_fine_boss.desc,joined_at.asc',
    );

    if (memberships.isEmpty) return [];

    // Get user IDs
    final userIds = memberships.map((m) => m['user_id'] as String).toList();

    // Get users (including birth_date for age-based features)
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url,birth_date',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    // Get trainer types for this team
    final trainerTypes = await _db.client.select(
      'trainer_types',
      filters: {'team_id': 'eq.$teamId'},
      order: 'display_order.asc',
    );

    // Create lookups
    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    final trainerTypeMap = <String, Map<String, dynamic>>{};
    for (final tt in trainerTypes) {
      trainerTypeMap[tt['id'] as String] = tt;
    }

    return memberships.map((m) {
      final user = userMap[m['user_id']] ?? {};
      final trainerTypeId = m['trainer_type_id'] as String?;
      final trainerType = trainerTypeId != null ? trainerTypeMap[trainerTypeId] : null;

      return {
        'id': m['id'],
        'user_id': m['user_id'],
        'team_id': m['team_id'],
        'role': m['role'] ?? 'player',
        'is_admin': m['is_admin'] ?? false,
        'is_fine_boss': m['is_fine_boss'] ?? false,
        'is_coach': m['is_coach'] ?? false,
        'trainer_type_id': trainerTypeId,
        'trainer_type_name': trainerType?['name'],
        'trainer_type': trainerType,
        'is_active': m['is_active'] ?? true,
        'joined_at': m['joined_at'],
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
        'user_birth_date': user['birth_date'],
      };
    }).toList();
  }

  // ============ Trainer Types ============

  Future<List<TrainerType>> getTrainerTypes(String teamId) async {
    final result = await _db.client.select(
      'trainer_types',
      filters: {'team_id': 'eq.$teamId'},
      order: 'display_order.asc',
    );

    return result.map((row) => TrainerType(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      name: row['name'] as String,
      displayOrder: row['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
    )).toList();
  }

  Future<TrainerType> createTrainerType({
    required String teamId,
    required String name,
    int? displayOrder,
  }) async {
    // Get max display_order if not provided
    int order = displayOrder ?? 0;
    if (displayOrder == null) {
      final existing = await _db.client.select(
        'trainer_types',
        select: 'display_order',
        filters: {'team_id': 'eq.$teamId'},
        order: 'display_order.desc',
        limit: 1,
      );
      if (existing.isNotEmpty) {
        order = (existing.first['display_order'] as int? ?? 0) + 1;
      }
    }

    final result = await _db.client.insert('trainer_types', {
      'id': _uuid.v4(),
      'team_id': teamId,
      'name': name,
      'display_order': order,
    });

    final row = result.first;
    return TrainerType(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      name: row['name'] as String,
      displayOrder: row['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Future<void> deleteTrainerType(String trainerTypeId) async {
    // First remove trainer_type_id from any members using it
    await _db.client.update(
      'team_members',
      {'trainer_type_id': null},
      filters: {'trainer_type_id': 'eq.$trainerTypeId'},
    );

    await _db.client.delete(
      'trainer_types',
      filters: {'id': 'eq.$trainerTypeId'},
    );
  }

  // ============ Member Role Management ============

  Future<String> regenerateInviteCode(String teamId) async {
    final inviteCode = _generateInviteCode();
    await _db.client.update(
      'teams',
      {'invite_code': inviteCode},
      filters: {'id': 'eq.$teamId'},
    );
    return inviteCode;
  }

  /// @deprecated Use updateMemberPermissions instead
  Future<void> updateMemberRole(String memberId, String role) async {
    // Update legacy role field and corresponding flags
    final isAdmin = role == 'admin';
    final isFineBoss = role == 'fine_boss' || role == 'admin';

    await _db.client.update(
      'team_members',
      {
        'role': role,
        'is_admin': isAdmin,
        'is_fine_boss': isFineBoss,
      },
      filters: {'id': 'eq.$memberId'},
    );
  }

  /// Update member permissions with the new flag-based system
  Future<void> updateMemberPermissions({
    required String memberId,
    bool? isAdmin,
    bool? isFineBoss,
    bool? isCoach,
    String? trainerTypeId,
    bool clearTrainerType = false,
  }) async {
    final updates = <String, dynamic>{};

    if (isAdmin != null) {
      updates['is_admin'] = isAdmin;
      // Update legacy role field for backwards compatibility
      if (isAdmin) {
        updates['role'] = 'admin';
      }
    }

    if (isFineBoss != null) {
      updates['is_fine_boss'] = isFineBoss;
      // Update legacy role field if not admin
      if (!updates.containsKey('role') && isFineBoss) {
        // Only set to fine_boss if not being set to admin
        final current = await _db.client.select(
          'team_members',
          select: 'is_admin',
          filters: {'id': 'eq.$memberId'},
        );
        if (current.isNotEmpty && !(current.first['is_admin'] as bool? ?? false)) {
          updates['role'] = 'fine_boss';
        }
      }
    }

    if (isCoach != null) {
      updates['is_coach'] = isCoach;
    }

    if (clearTrainerType) {
      updates['trainer_type_id'] = null;
    } else if (trainerTypeId != null) {
      updates['trainer_type_id'] = trainerTypeId;
    }

    // If removing admin/fine_boss, update legacy role
    if (isAdmin == false || isFineBoss == false) {
      final current = await _db.client.select(
        'team_members',
        select: 'is_admin,is_fine_boss',
        filters: {'id': 'eq.$memberId'},
      );
      if (current.isNotEmpty) {
        final currentIsAdmin = isAdmin ?? (current.first['is_admin'] as bool? ?? false);
        final currentIsFineBoss = isFineBoss ?? (current.first['is_fine_boss'] as bool? ?? false);

        if (!currentIsAdmin && !currentIsFineBoss) {
          updates['role'] = 'player';
        } else if (!currentIsAdmin && currentIsFineBoss) {
          updates['role'] = 'fine_boss';
        }
      }
    }

    if (updates.isNotEmpty) {
      await _db.client.update(
        'team_members',
        updates,
        filters: {'id': 'eq.$memberId'},
      );
    }
  }

  /// Deactivate a member (soft delete)
  Future<void> deactivateMember(String memberId) async {
    await _db.client.update(
      'team_members',
      {'is_active': false},
      filters: {'id': 'eq.$memberId'},
    );
  }

  /// Reactivate a previously deactivated member
  Future<void> reactivateMember(String memberId) async {
    await _db.client.update(
      'team_members',
      {'is_active': true},
      filters: {'id': 'eq.$memberId'},
    );
  }

  /// Remove a member completely (hard delete)
  Future<void> removeMember(String memberId) async {
    await _db.client.delete(
      'team_members',
      filters: {'id': 'eq.$memberId'},
    );
  }

  // ============ Team Management ============

  Future<Map<String, dynamic>?> updateTeam({
    required String teamId,
    String? name,
    String? sport,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (sport != null) updates['sport'] = sport;

    if (updates.isEmpty) return null;

    final result = await _db.client.update(
      'teams',
      updates,
      filters: {'id': 'eq.$teamId'},
    );

    if (result.isEmpty) return null;
    return result.first;
  }

  Future<Map<String, dynamic>> getTeamSettings(String teamId) async {
    final result = await _db.client.select(
      'team_settings',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (result.isEmpty) {
      // Return default settings
      return {
        'team_id': teamId,
        'attendance_points': 1,
        'win_points': 3,
        'draw_points': 1,
        'loss_points': 0,
        'appeal_fee': 0.0,
        'game_day_multiplier': 1.0,
      };
    }

    // Ensure appeal_fee and game_day_multiplier have default values
    final settings = result.first;
    settings['appeal_fee'] ??= 0.0;
    settings['game_day_multiplier'] ??= 1.0;

    return settings;
  }

  Future<Map<String, dynamic>> updateTeamSettings({
    required String teamId,
    int? attendancePoints,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    double? appealFee,
    double? gameDayMultiplier,
  }) async {
    // Check if settings exist
    final existing = await _db.client.select(
      'team_settings',
      filters: {'team_id': 'eq.$teamId'},
    );

    final settings = <String, dynamic>{};
    if (attendancePoints != null) settings['attendance_points'] = attendancePoints;
    if (winPoints != null) settings['win_points'] = winPoints;
    if (drawPoints != null) settings['draw_points'] = drawPoints;
    if (lossPoints != null) settings['loss_points'] = lossPoints;
    if (appealFee != null) settings['appeal_fee'] = appealFee;
    if (gameDayMultiplier != null) settings['game_day_multiplier'] = gameDayMultiplier;

    if (existing.isEmpty) {
      // Insert new settings
      settings['id'] = _uuid.v4();
      settings['team_id'] = teamId;
      await _db.client.insert('team_settings', settings);
    } else {
      // Update existing settings
      await _db.client.update(
        'team_settings',
        settings,
        filters: {'team_id': 'eq.$teamId'},
      );
    }

    return getTeamSettings(teamId);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ============ Dashboard ============

  Future<Map<String, dynamic>> getDashboardData(String teamId, String userId) async {
    // Get next upcoming activity
    Map<String, dynamic>? nextActivity;
    try {
      // Get today's date in YYYY-MM-DD format for comparison
      final today = DateTime.now().toIso8601String().split('T').first;

      // Query activity_instances with join to activities for team filtering
      final instances = await _db.client.select(
        'activity_instances',
        select: '*,activities!inner(team_id,title,type,location,description)',
        filters: {
          'activities.team_id': 'eq.$teamId',
          'date': 'gte.$today',
          'status': 'eq.scheduled',
        },
        order: 'date.asc,start_time.asc',
        limit: 1,
      );

      if (instances.isNotEmpty) {
        final instance = instances.first;
        final activity = instance['activities'] as Map<String, dynamic>?;

        // Build the response with activity details
        nextActivity = {
          'id': instance['id'],
          'activity_id': instance['activity_id'],
          'date': instance['date'],
          'start_time': instance['start_time'],
          'end_time': instance['end_time'],
          'status': instance['status'],
          'title': instance['title_override'] ?? activity?['title'],
          'type': activity?['type'],
          'location': instance['location_override'] ?? activity?['location'],
          'description': instance['description_override'] ?? activity?['description'],
        };
      }
    } catch (e) {
      // Ignore errors, return null for next activity
    }

    // Get top 3 leaderboard entries (main leaderboard)
    List<Map<String, dynamic>> leaderboard = [];
    try {
      final entries = await _db.client.select(
        'leaderboard_entries',
        select: 'user_id,points',
        filters: {'team_id': 'eq.$teamId'},
        order: 'points.desc',
        limit: 5,
      );

      if (entries.isNotEmpty) {
        // Get user details
        final userIds = entries.map((e) => e['user_id'] as String).toList();
        final users = await _db.client.select(
          'users',
          select: 'id,name,avatar_url',
          filters: {'id': 'in.(${userIds.join(',')})'},
        );

        final userMap = <String, Map<String, dynamic>>{};
        for (final u in users) {
          userMap[u['id'] as String] = u;
        }

        int rank = 1;
        for (final entry in entries) {
          final user = userMap[entry['user_id']];
          if (user != null) {
            leaderboard.add({
              'rank': rank,
              'user_name': user['name'],
              'avatar_url': user['avatar_url'],
              'points': entry['points'],
            });
            rank++;
          }
        }
      }
    } catch (e) {
      // Ignore errors, return empty leaderboard
    }

    // Get unread messages count
    int unreadMessages = 0;
    try {
      // Get last read timestamp for user
      final lastRead = await _db.client.select(
        'message_reads',
        select: 'last_read_at',
        filters: {
          'team_id': 'eq.$teamId',
          'user_id': 'eq.$userId',
        },
      );

      String? lastReadAt;
      if (lastRead.isNotEmpty) {
        lastReadAt = lastRead.first['last_read_at'] as String?;
      }

      // Count messages after last read
      final filters = <String, String>{
        'team_id': 'eq.$teamId',
        'user_id': 'neq.$userId', // Don't count own messages
      };
      if (lastReadAt != null) {
        filters['created_at'] = 'gt.$lastReadAt';
      }

      final messages = await _db.client.select(
        'messages',
        select: 'id',
        filters: filters,
      );
      unreadMessages = messages.length;
    } catch (e) {
      // Ignore errors, return 0
    }

    // Get fines summary
    int unpaidCount = 0;
    double unpaidAmount = 0;
    int pendingApproval = 0;
    try {
      // Get unpaid fines for user
      final unpaidFines = await _db.client.select(
        'fines',
        select: 'amount',
        filters: {
          'team_id': 'eq.$teamId',
          'user_id': 'eq.$userId',
          'status': 'eq.approved',
          'paid_at': 'is.null',
        },
      );

      unpaidCount = unpaidFines.length;
      for (final fine in unpaidFines) {
        unpaidAmount += (fine['amount'] as num?)?.toDouble() ?? 0;
      }

      // Get pending approval count (if user is fine boss)
      final membership = await _db.client.select(
        'team_members',
        select: 'is_fine_boss,is_admin',
        filters: {
          'team_id': 'eq.$teamId',
          'user_id': 'eq.$userId',
        },
      );

      if (membership.isNotEmpty) {
        final isFineBoss = membership.first['is_fine_boss'] == true ||
            membership.first['is_admin'] == true;
        if (isFineBoss) {
          final pendingFines = await _db.client.select(
            'fines',
            select: 'id',
            filters: {
              'team_id': 'eq.$teamId',
              'status': 'eq.pending',
            },
          );
          pendingApproval = pendingFines.length;
        }
      }
    } catch (e) {
      // Ignore errors
    }

    return {
      'next_activity': nextActivity,
      'leaderboard': leaderboard,
      'unread_messages': unreadMessages,
      'fines_summary': {
        'unpaid_count': unpaidCount,
        'unpaid_amount': unpaidAmount,
        'pending_approval': pendingApproval,
      },
    };
  }
}
