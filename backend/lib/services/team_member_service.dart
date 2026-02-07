import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/team.dart';

class TeamMemberService {
  final Database _db;
  final _uuid = const Uuid();

  TeamMemberService(this._db);

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

  /// Set whether a member is injured
  Future<void> setMemberInjuredStatus(String memberId, bool isInjured) async {
    // Get member details first
    final memberResult = await _db.client.select(
      'team_members',
      select: 'user_id,team_id',
      filters: {'id': 'eq.$memberId'},
    );

    if (memberResult.isEmpty) {
      throw Exception('Member not found');
    }

    final userId = memberResult.first['user_id'] as String;
    final teamId = memberResult.first['team_id'] as String;

    // Update the injured status
    await _db.client.update(
      'team_members',
      {'is_injured': isInjured},
      filters: {'id': 'eq.$memberId'},
    );

    // Get today's date for filtering future instances
    final today = DateTime.now().toIso8601String().split('T').first;

    // Get all activities for this team that are opt_out
    final activities = await _db.client.select(
      'activities',
      select: 'id',
      filters: {
        'team_id': 'eq.$teamId',
        'response_type': 'eq.opt_out',
      },
    );

    if (activities.isEmpty) return;

    final activityIds = activities.map((a) => a['id'] as String).toList();

    // Get future instances for these activities
    final futureInstances = await _db.client.select(
      'activity_instances',
      select: 'id',
      filters: {
        'activity_id': 'in.(${activityIds.join(',')})',
        'date': 'gte.$today',
        'status': 'eq.scheduled',
      },
    );

    if (futureInstances.isEmpty) return;

    final instanceIds = futureInstances.map((i) => i['id'] as String).toList();

    if (isInjured) {
      // Delete future opt_out responses for this member
      await _db.client.delete(
        'activity_responses',
        filters: {
          'instance_id': 'in.(${instanceIds.join(',')})',
          'user_id': 'eq.$userId',
        },
      );
    } else {
      // Create 'yes' responses for future opt_out instances where member has no response
      for (final instanceId in instanceIds) {
        // Check if response already exists
        final existing = await _db.client.select(
          'activity_responses',
          select: 'id',
          filters: {
            'instance_id': 'eq.$instanceId',
            'user_id': 'eq.$userId',
          },
        );

        if (existing.isEmpty) {
          await _db.client.insert('activity_responses', {
            'id': _uuid.v4(),
            'instance_id': instanceId,
            'user_id': userId,
            'response': 'yes',
          });
        }
      }
    }
  }

  /// Remove a member completely (hard delete)
  Future<void> removeMember(String memberId) async {
    await _db.client.delete(
      'team_members',
      filters: {'id': 'eq.$memberId'},
    );
  }
}
