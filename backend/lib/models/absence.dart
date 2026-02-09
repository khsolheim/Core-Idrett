/// Absence tracking models
/// Categories and records for tracking valid absences

import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

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
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      name: safeString(row, 'name'),
      description: safeStringNullable(row, 'description'),
      requiresApproval: safeBool(row, 'requires_approval', defaultValue: false),
      countsAsValid: safeBool(row, 'counts_as_valid', defaultValue: true),
      isActive: safeBool(row, 'is_active', defaultValue: true),
      sortOrder: safeInt(row, 'sort_order', defaultValue: 0),
      createdAt: requireDateTime(row, 'created_at'),
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
      id: safeString(row, 'id'),
      userId: safeString(row, 'user_id'),
      instanceId: safeString(row, 'instance_id'),
      categoryId: safeStringNullable(row, 'category_id'),
      reason: safeStringNullable(row, 'reason'),
      status: AbsenceStatus.fromString(safeString(row, 'status', defaultValue: 'pending')),
      approvedBy: safeStringNullable(row, 'approved_by'),
      approvedAt: safeDateTimeNullable(row, 'approved_at'),
      rejectionReason: safeStringNullable(row, 'rejection_reason'),
      createdAt: requireDateTime(row, 'created_at'),
      updatedAt: requireDateTime(row, 'updated_at'),
      // Joined fields from view
      userName: safeStringNullable(row, 'user_name'),
      categoryName: safeStringNullable(row, 'category_name'),
      countsAsValid: safeBoolNullable(row, 'counts_as_valid'),
      approverName: safeStringNullable(row, 'approver_name'),
      activityTitle: safeStringNullable(row, 'activity_title'),
      activityDate: safeDateTimeNullable(row, 'activity_date'),
      activityType: safeStringNullable(row, 'activity_type'),
      teamId: safeStringNullable(row, 'team_id'),
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
