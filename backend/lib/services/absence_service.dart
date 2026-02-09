import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/absence.dart';
import '../helpers/parsing_helpers.dart';

/// Service for managing absence categories and records
class AbsenceService {
  final Database _db;
  final _uuid = const Uuid();

  AbsenceService(this._db);

  // ============ ABSENCE CATEGORIES ============

  /// Get all absence categories for a team
  Future<List<AbsenceCategory>> getCategories(
    String teamId, {
    bool activeOnly = true,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (activeOnly) {
      filters['is_active'] = 'eq.true';
    }

    final result = await _db.client.select(
      'absence_categories',
      filters: filters,
      order: 'sort_order.asc,name.asc',
    );

    return result.map((row) => AbsenceCategory.fromJson(row)).toList();
  }

  /// Get a category by ID
  Future<AbsenceCategory?> getCategoryById(String categoryId) async {
    final result = await _db.client.select(
      'absence_categories',
      filters: {'id': 'eq.$categoryId'},
    );

    if (result.isEmpty) return null;
    return AbsenceCategory.fromJson(result.first);
  }

  /// Create a new absence category
  Future<AbsenceCategory> createCategory({
    required String teamId,
    required String name,
    String? description,
    bool requiresApproval = false,
    bool countsAsValid = true,
    int sortOrder = 0,
  }) async {
    final id = _uuid.v4();

    await _db.client.insert('absence_categories', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'description': description,
      'requires_approval': requiresApproval,
      'counts_as_valid': countsAsValid,
      'sort_order': sortOrder,
    });

    return AbsenceCategory(
      id: id,
      teamId: teamId,
      name: name,
      description: description,
      requiresApproval: requiresApproval,
      countsAsValid: countsAsValid,
      sortOrder: sortOrder,
      createdAt: DateTime.now(),
    );
  }

  /// Update an absence category
  Future<AbsenceCategory?> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    bool? requiresApproval,
    bool? countsAsValid,
    bool? isActive,
    int? sortOrder,
    bool clearDescription = false,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (clearDescription) {
      updates['description'] = null;
    } else if (description != null) {
      updates['description'] = description;
    }
    if (requiresApproval != null) updates['requires_approval'] = requiresApproval;
    if (countsAsValid != null) updates['counts_as_valid'] = countsAsValid;
    if (isActive != null) updates['is_active'] = isActive;
    if (sortOrder != null) updates['sort_order'] = sortOrder;

    if (updates.isEmpty) {
      return getCategoryById(categoryId);
    }

    await _db.client.update(
      'absence_categories',
      updates,
      filters: {'id': 'eq.$categoryId'},
    );

    return getCategoryById(categoryId);
  }

  /// Delete an absence category
  Future<void> deleteCategory(String categoryId) async {
    await _db.client.delete(
      'absence_categories',
      filters: {'id': 'eq.$categoryId'},
    );
  }

  // ============ ABSENCE RECORDS ============

  /// Register an absence for a user
  Future<AbsenceRecord> registerAbsence({
    required String userId,
    required String instanceId,
    String? categoryId,
    String? reason,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    // Check if already registered
    final existing = await _db.client.select(
      'absence_records',
      filters: {
        'user_id': 'eq.$userId',
        'instance_id': 'eq.$instanceId',
      },
    );

    if (existing.isNotEmpty) {
      // Update existing record
      await _db.client.update(
        'absence_records',
        {
          'category_id': categoryId,
          'reason': reason,
          'updated_at': now.toIso8601String(),
        },
        filters: {
          'user_id': 'eq.$userId',
          'instance_id': 'eq.$instanceId',
        },
      );

      final updated = await getAbsenceById(safeString(existing.first, 'id'));
      return updated!;
    }

    // Insert new record (trigger will auto-approve if category doesn't require it)
    await _db.client.insert('absence_records', {
      'id': id,
      'user_id': userId,
      'instance_id': instanceId,
      'category_id': categoryId,
      'reason': reason,
    });

    return AbsenceRecord(
      id: id,
      userId: userId,
      instanceId: instanceId,
      categoryId: categoryId,
      reason: reason,
      status: AbsenceStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Get an absence record by ID (with full details from view)
  Future<AbsenceRecord?> getAbsenceById(String absenceId) async {
    final result = await _db.client.select(
      'v_absence_details',
      filters: {'id': 'eq.$absenceId'},
    );

    if (result.isEmpty) return null;
    return AbsenceRecord.fromJson(result.first);
  }

  /// Get absence records with full details (from view)
  Future<List<AbsenceRecord>> getAbsenceDetails({
    String? teamId,
    String? userId,
    String? instanceId,
    AbsenceStatus? status,
    int? limit,
    int offset = 0,
  }) async {
    final filters = <String, String>{};
    if (teamId != null) filters['team_id'] = 'eq.$teamId';
    if (userId != null) filters['user_id'] = 'eq.$userId';
    if (instanceId != null) filters['instance_id'] = 'eq.$instanceId';
    if (status != null) filters['status'] = 'eq.${status.value}';

    final result = await _db.client.select(
      'v_absence_details',
      filters: filters,
      order: 'created_at.desc',
      limit: limit,
      offset: offset,
    );

    return result.map((row) => AbsenceRecord.fromJson(row)).toList();
  }

  /// Get pending absences for approval
  Future<List<AbsenceRecord>> getPendingAbsences(String teamId) async {
    return getAbsenceDetails(teamId: teamId, status: AbsenceStatus.pending);
  }

  /// Approve an absence
  Future<AbsenceRecord?> approveAbsence({
    required String absenceId,
    required String approverId,
  }) async {
    final now = DateTime.now();

    await _db.client.update(
      'absence_records',
      {
        'status': AbsenceStatus.approved.value,
        'approved_by': approverId,
        'approved_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      },
      filters: {'id': 'eq.$absenceId'},
    );

    return getAbsenceById(absenceId);
  }

  /// Reject an absence
  Future<AbsenceRecord?> rejectAbsence({
    required String absenceId,
    required String approverId,
    String? rejectionReason,
  }) async {
    final now = DateTime.now();

    await _db.client.update(
      'absence_records',
      {
        'status': AbsenceStatus.rejected.value,
        'approved_by': approverId,
        'approved_at': now.toIso8601String(),
        'rejection_reason': rejectionReason,
        'updated_at': now.toIso8601String(),
      },
      filters: {'id': 'eq.$absenceId'},
    );

    return getAbsenceById(absenceId);
  }

  /// Delete an absence record
  Future<void> deleteAbsence(String absenceId) async {
    await _db.client.delete(
      'absence_records',
      filters: {'id': 'eq.$absenceId'},
    );
  }

  /// Get absence record for a user/instance
  Future<AbsenceRecord?> getAbsenceForInstance(
      String userId, String instanceId) async {
    final result = await _db.client.select(
      'absence_records',
      filters: {
        'user_id': 'eq.$userId',
        'instance_id': 'eq.$instanceId',
      },
    );

    if (result.isEmpty) return null;
    return AbsenceRecord.fromJson(result.first);
  }

  /// Check if user has valid absence for instance
  Future<bool> hasValidAbsence(String userId, String instanceId) async {
    final result = await _db.client.select(
      'v_absence_details',
      select: 'id,status,counts_as_valid',
      filters: {
        'user_id': 'eq.$userId',
        'instance_id': 'eq.$instanceId',
      },
    );

    if (result.isEmpty) return false;

    final status = AbsenceStatus.fromString(safeString(result.first, 'status'));
    final countsAsValid = safeBool(result.first, 'counts_as_valid', defaultValue: false);

    return status.isApproved && countsAsValid;
  }

  /// Count valid absences for a user in a team/season
  Future<int> countValidAbsences(
    String userId,
    String teamId, {
    String? seasonId,
  }) async {
    final result = await getAbsenceDetails(
      userId: userId,
      teamId: teamId,
    );

    return result.where((r) => r.isApproved && (r.countsAsValid ?? false)).length;
  }

  /// Get team ID for an absence (for authorization checks)
  Future<String?> getTeamIdForAbsence(String absenceId) async {
    final result = await _db.client.select(
      'v_absence_details',
      select: 'team_id',
      filters: {'id': 'eq.$absenceId'},
    );

    if (result.isEmpty) return null;
    return safeStringNullable(result.first, 'team_id');
  }

  /// Get team ID for a category (for authorization checks)
  Future<String?> getTeamIdForCategory(String categoryId) async {
    final result = await _db.client.select(
      'absence_categories',
      select: 'team_id',
      filters: {'id': 'eq.$categoryId'},
    );

    if (result.isEmpty) return null;
    return safeStringNullable(result.first, 'team_id');
  }

  /// Get absence summary for a team
  Future<Map<String, dynamic>> getAbsenceSummary(
    String teamId, {
    String? seasonId,
  }) async {
    final absences = await getAbsenceDetails(teamId: teamId);

    int totalAbsences = absences.length;
    int pendingCount = 0;
    int approvedCount = 0;
    int rejectedCount = 0;
    int validAbsenceCount = 0;

    // Count by category
    final categoryCounts = <String, int>{};

    for (final absence in absences) {
      switch (absence.status) {
        case AbsenceStatus.pending:
          pendingCount++;
          break;
        case AbsenceStatus.approved:
        case AbsenceStatus.autoApproved:
          approvedCount++;
          if (absence.countsAsValid ?? false) {
            validAbsenceCount++;
          }
          break;
        case AbsenceStatus.rejected:
          rejectedCount++;
          break;
      }

      if (absence.categoryName != null) {
        categoryCounts[absence.categoryName!] =
            (categoryCounts[absence.categoryName!] ?? 0) + 1;
      }
    }

    return {
      'total_absences': totalAbsences,
      'pending_count': pendingCount,
      'approved_count': approvedCount,
      'rejected_count': rejectedCount,
      'valid_absence_count': validAbsenceCount,
      'by_category': categoryCounts,
    };
  }
}
