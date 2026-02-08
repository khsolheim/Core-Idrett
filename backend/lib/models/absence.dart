/// Absence tracking models
/// Categories and records for tracking valid absences

import 'package:equatable/equatable.dart';

/// Absence category (team-specific)
class AbsenceCategory extends Equatable {
  final String id;
  final String teamId;
  final String name;
  final String? description;
  final bool requiresApproval;
  final bool countsAsValid;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;

  const AbsenceCategory({
    required this.id,
    required this.teamId,
    required this.name,
    this.description,
    this.requiresApproval = false,
    this.countsAsValid = true,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        name,
        description,
        requiresApproval,
        countsAsValid,
        isActive,
        sortOrder,
        createdAt,
      ];

  factory AbsenceCategory.fromJson(Map<String, dynamic> row) {
    return AbsenceCategory(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      name: row['name'] as String,
      description: row['description'] as String?,
      requiresApproval: row['requires_approval'] as bool? ?? false,
      countsAsValid: row['counts_as_valid'] as bool? ?? true,
      isActive: row['is_active'] as bool? ?? true,
      sortOrder: row['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'description': description,
      'requires_approval': requiresApproval,
      'counts_as_valid': countsAsValid,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Absence status enum
enum AbsenceStatus {
  pending,
  approved,
  rejected,
  autoApproved;

  String get value {
    switch (this) {
      case AbsenceStatus.pending:
        return 'pending';
      case AbsenceStatus.approved:
        return 'approved';
      case AbsenceStatus.rejected:
        return 'rejected';
      case AbsenceStatus.autoApproved:
        return 'auto_approved';
    }
  }

  static AbsenceStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return AbsenceStatus.pending;
      case 'approved':
        return AbsenceStatus.approved;
      case 'rejected':
        return AbsenceStatus.rejected;
      case 'auto_approved':
        return AbsenceStatus.autoApproved;
      default:
        return AbsenceStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case AbsenceStatus.pending:
        return 'Venter';
      case AbsenceStatus.approved:
        return 'Godkjent';
      case AbsenceStatus.rejected:
        return 'Avvist';
      case AbsenceStatus.autoApproved:
        return 'Automatisk godkjent';
    }
  }

  bool get isApproved =>
      this == AbsenceStatus.approved || this == AbsenceStatus.autoApproved;
}

/// Absence record
class AbsenceRecord extends Equatable {
  final String id;
  final String userId;
  final String instanceId;
  final String? categoryId;
  final String? reason;
  final AbsenceStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? userName;
  final String? categoryName;
  final bool? countsAsValid;
  final String? approverName;
  final String? activityTitle;
  final DateTime? activityDate;
  final String? activityType;
  final String? teamId;

  const AbsenceRecord({
    required this.id,
    required this.userId,
    required this.instanceId,
    this.categoryId,
    this.reason,
    this.status = AbsenceStatus.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.categoryName,
    this.countsAsValid,
    this.approverName,
    this.activityTitle,
    this.activityDate,
    this.activityType,
    this.teamId,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        instanceId,
        categoryId,
        reason,
        status,
        approvedBy,
        approvedAt,
        rejectionReason,
        createdAt,
        updatedAt,
        userName,
        categoryName,
        countsAsValid,
        approverName,
        activityTitle,
        activityDate,
        activityType,
        teamId,
      ];

  factory AbsenceRecord.fromJson(Map<String, dynamic> row) {
    return AbsenceRecord(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      instanceId: row['instance_id'] as String,
      categoryId: row['category_id'] as String?,
      reason: row['reason'] as String?,
      status: AbsenceStatus.fromString(row['status'] as String? ?? 'pending'),
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null
          ? DateTime.parse(row['approved_at'] as String)
          : null,
      rejectionReason: row['rejection_reason'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      // Joined fields from view
      userName: row['user_name'] as String?,
      categoryName: row['category_name'] as String?,
      countsAsValid: row['counts_as_valid'] as bool?,
      approverName: row['approver_name'] as String?,
      activityTitle: row['activity_title'] as String?,
      activityDate: row['activity_date'] != null
          ? DateTime.parse(row['activity_date'] as String)
          : null,
      activityType: row['activity_type'] as String?,
      teamId: row['team_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'instance_id': instanceId,
      'category_id': categoryId,
      'reason': reason,
      'status': status.value,
      'status_display': status.displayName,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (userName != null) 'user_name': userName,
      if (categoryName != null) 'category_name': categoryName,
      if (countsAsValid != null) 'counts_as_valid': countsAsValid,
      if (approverName != null) 'approver_name': approverName,
      if (activityTitle != null) 'activity_title': activityTitle,
      if (activityDate != null)
        'activity_date': activityDate!.toIso8601String().split('T').first,
      if (activityType != null) 'activity_type': activityType,
      if (teamId != null) 'team_id': teamId,
    };
  }

  bool get isPending => status == AbsenceStatus.pending;
  bool get isApproved => status.isApproved;
  bool get isRejected => status == AbsenceStatus.rejected;
}
