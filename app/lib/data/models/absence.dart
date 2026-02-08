import 'package:equatable/equatable.dart';

/// Status of an absence record
enum AbsenceStatus {
  pending,
  approved,
  rejected,
  autoApproved;

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

  String toJsonString() {
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

  String get displayName {
    switch (this) {
      case AbsenceStatus.pending:
        return 'Venter på godkjenning';
      case AbsenceStatus.approved:
        return 'Godkjent';
      case AbsenceStatus.rejected:
        return 'Avvist';
      case AbsenceStatus.autoApproved:
        return 'Automatisk godkjent';
    }
  }
}

/// Category for absence (e.g., sickness, work, family)
class AbsenceCategory extends Equatable {
  final String id;
  final String teamId;
  final String name;
  final bool requiresApproval;
  final bool countsAsValid;
  final int sortOrder;
  final DateTime createdAt;
  AbsenceCategory({
    required this.id,
    required this.teamId,
    required this.name,
    this.requiresApproval = false,
    this.countsAsValid = true,
    this.sortOrder = 0,
    required this.createdAt,
  });

  factory AbsenceCategory.fromJson(Map<String, dynamic> json) {
    return
  AbsenceCategory(
      id: json['id'],
      teamId: json['team_id'],
      name: json['name'],
      requiresApproval: json['requires_approval'] ?? false,
      countsAsValid: json['counts_as_valid'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'requires_approval': requiresApproval,
        'counts_as_valid': countsAsValid,
        'sort_order': sortOrder,
        'created_at': createdAt.toIso8601String(),
      };

  AbsenceCategory copyWith({
    String? id,
    String? teamId,
    String? name,
    bool? requiresApproval,
    bool? countsAsValid,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return
  AbsenceCategory(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      countsAsValid: countsAsValid ?? this.countsAsValid,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }


  @override
  List<Object?> get props => [id, teamId, name, requiresApproval, countsAsValid, sortOrder, createdAt];
}

/// Individual absence record for a specific activity instance
class AbsenceRecord extends Equatable {
  final String id;
  final String userId;
  final String instanceId;
  final String? categoryId;
  final String? reason;
  final AbsenceStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  // Joined fields
  final String? userName;
  final String? userAvatarUrl;
  final String? categoryName;
  final bool? categoryCountsAsValid;
  final String? activityName;
  final DateTime? activityDate;
  final String? approvedByName;
  AbsenceRecord({
    required this.id,
    required this.userId,
    required this.instanceId,
    this.categoryId,
    this.reason,
    this.status = AbsenceStatus.pending,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    this.userName,
    this.userAvatarUrl,
    this.categoryName,
    this.categoryCountsAsValid,
    this.activityName,
    this.activityDate,
    this.approvedByName,
  });

  bool get isPending => status == AbsenceStatus.pending;
  bool get isApproved =>
      status == AbsenceStatus.approved || status == AbsenceStatus.autoApproved;
  bool get isRejected => status == AbsenceStatus.rejected;
  bool get countsAsValid => categoryCountsAsValid ?? true;

  factory AbsenceRecord.fromJson(Map<String, dynamic> json) {
    return
  AbsenceRecord(
      id: json['id'],
      userId: json['user_id'],
      instanceId: json['instance_id'],
      categoryId: json['category_id'],
      reason: json['reason'],
      status: AbsenceStatus.fromString(json['status'] ?? 'pending'),
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      categoryName: json['category_name'],
      categoryCountsAsValid: json['counts_as_valid'],
      activityName: json['activity_name'],
      activityDate: json['activity_date'] != null
          ? DateTime.parse(json['activity_date'])
          : null,
      approvedByName: json['approved_by_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'instance_id': instanceId,
        'category_id': categoryId,
        'reason': reason,
        'status': status.toJsonString(),
        'approved_by': approvedBy,
        'approved_at': approvedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'category_name': categoryName,
        'counts_as_valid': categoryCountsAsValid,
        'activity_name': activityName,
        'activity_date': activityDate?.toIso8601String(),
        'approved_by_name': approvedByName,
      };

  AbsenceRecord copyWith({
    String? id,
    String? userId,
    String? instanceId,
    String? categoryId,
    String? reason,
    AbsenceStatus? status,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    String? userName,
    String? userAvatarUrl,
    String? categoryName,
    bool? categoryCountsAsValid,
    String? activityName,
    DateTime? activityDate,
    String? approvedByName,
  }) {
    return
  AbsenceRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      instanceId: instanceId ?? this.instanceId,
      categoryId: categoryId ?? this.categoryId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      categoryName: categoryName ?? this.categoryName,
      categoryCountsAsValid:
          categoryCountsAsValid ?? this.categoryCountsAsValid,
      activityName: activityName ?? this.activityName,
      activityDate: activityDate ?? this.activityDate,
      approvedByName: approvedByName ?? this.approvedByName,
    );
  }


  @override
  List<Object?> get props => [id, userId, instanceId, categoryId, reason, status, approvedBy, approvedAt, createdAt, userName, userAvatarUrl, categoryName, categoryCountsAsValid, activityName, activityDate, approvedByName];
}

/// Summary of pending absences for admin view
class AbsenceSummary extends Equatable {
  final String teamId;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final List<AbsenceRecord> pendingAbsences;
  AbsenceSummary({
    required this.teamId,
    this.pendingCount = 0,
    this.approvedCount = 0,
    this.rejectedCount = 0,
    this.pendingAbsences = const [],
  });

  int get totalCount => pendingCount + approvedCount + rejectedCount;

  factory AbsenceSummary.fromJson(Map<String, dynamic> json) {
    return
  AbsenceSummary(
      teamId: json['team_id'],
      pendingCount: json['pending_count'] ?? 0,
      approvedCount: json['approved_count'] ?? 0,
      rejectedCount: json['rejected_count'] ?? 0,
      pendingAbsences: json['pending_absences'] != null
          ? (json['pending_absences'] as List)
              .map((e) => AbsenceRecord.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'pending_count': pendingCount,
        'approved_count': approvedCount,
        'rejected_count': rejectedCount,
        'pending_absences': pendingAbsences.map((e) => e.toJson()).toList(),
      };


  @override
  List<Object?> get props => [teamId, pendingCount, approvedCount, rejectedCount, pendingAbsences];
}
