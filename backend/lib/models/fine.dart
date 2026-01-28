class FineRule {
  final String id;
  final String teamId;
  final String name;
  final double amount;
  final String? description;
  final bool active;
  final DateTime createdAt;

  FineRule({
    required this.id,
    required this.teamId,
    required this.name,
    required this.amount,
    this.description,
    this.active = true,
    required this.createdAt,
  });

  factory FineRule.fromJson(Map<String, dynamic> json) {
    return FineRule(
      id: json['id'],
      teamId: json['team_id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      active: json['active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'name': name,
        'amount': amount,
        'description': description,
        'active': active,
        'created_at': createdAt.toIso8601String(),
      };
}

class Fine {
  final String id;
  final String? ruleId;
  final String teamId;
  final String offenderId;
  final String reporterId;
  final String? approvedBy;
  final String status; // pending, approved, rejected, appealed, paid
  final double amount;
  final String? description;
  final String? evidenceUrl;
  final bool isGameDay;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  // Joined fields
  final String? offenderName;
  final String? offenderAvatarUrl;
  final String? reporterName;
  final String? ruleName;
  final FineAppeal? appeal;
  final double? paidAmount;

  Fine({
    required this.id,
    this.ruleId,
    required this.teamId,
    required this.offenderId,
    required this.reporterId,
    this.approvedBy,
    required this.status,
    required this.amount,
    this.description,
    this.evidenceUrl,
    this.isGameDay = false,
    required this.createdAt,
    this.resolvedAt,
    this.offenderName,
    this.offenderAvatarUrl,
    this.reporterName,
    this.ruleName,
    this.appeal,
    this.paidAmount,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isAppealed => status == 'appealed';
  bool get isPaid => status == 'paid';
  double get remainingAmount => amount - (paidAmount ?? 0);

  factory Fine.fromJson(Map<String, dynamic> json) {
    return Fine(
      id: json['id'],
      ruleId: json['rule_id'],
      teamId: json['team_id'],
      offenderId: json['offender_id'],
      reporterId: json['reporter_id'],
      approvedBy: json['approved_by'],
      status: json['status'] ?? 'pending',
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      evidenceUrl: json['evidence_url'],
      isGameDay: json['is_game_day'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      offenderName: json['offender_name'],
      offenderAvatarUrl: json['offender_avatar_url'],
      reporterName: json['reporter_name'],
      ruleName: json['rule_name'],
      appeal: json['appeal'] != null ? FineAppeal.fromJson(json['appeal']) : null,
      paidAmount: json['paid_amount'] != null ? (json['paid_amount'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rule_id': ruleId,
        'team_id': teamId,
        'offender_id': offenderId,
        'reporter_id': reporterId,
        'approved_by': approvedBy,
        'status': status,
        'amount': amount,
        'description': description,
        'evidence_url': evidenceUrl,
        'is_game_day': isGameDay,
        'created_at': createdAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
        'offender_name': offenderName,
        'offender_avatar_url': offenderAvatarUrl,
        'reporter_name': reporterName,
        'rule_name': ruleName,
        'appeal': appeal?.toJson(),
        'paid_amount': paidAmount,
      };
}

class FineAppeal {
  final String id;
  final String fineId;
  final String reason;
  final String status; // pending, accepted, rejected
  final double? extraFee;
  final String? decidedBy;
  final DateTime createdAt;
  final DateTime? decidedAt;
  final Fine? fine;

  FineAppeal({
    required this.id,
    required this.fineId,
    required this.reason,
    required this.status,
    this.extraFee,
    this.decidedBy,
    required this.createdAt,
    this.decidedAt,
    this.fine,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  factory FineAppeal.fromJson(Map<String, dynamic> json) {
    return FineAppeal(
      id: json['id'],
      fineId: json['fine_id'],
      reason: json['reason'],
      status: json['status'] ?? 'pending',
      extraFee: json['extra_fee'] != null ? (json['extra_fee'] as num).toDouble() : null,
      decidedBy: json['decided_by'],
      createdAt: DateTime.parse(json['created_at']),
      decidedAt: json['decided_at'] != null ? DateTime.parse(json['decided_at']) : null,
      fine: json['fine'] != null ? Fine.fromJson(json['fine']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fine_id': fineId,
        'reason': reason,
        'status': status,
        'extra_fee': extraFee,
        'decided_by': decidedBy,
        'created_at': createdAt.toIso8601String(),
        'decided_at': decidedAt?.toIso8601String(),
        'fine': fine?.toJson(),
      };
}

class FinePayment {
  final String id;
  final String fineId;
  final double amount;
  final DateTime paidAt;
  final String registeredBy;

  FinePayment({
    required this.id,
    required this.fineId,
    required this.amount,
    required this.paidAt,
    required this.registeredBy,
  });

  factory FinePayment.fromJson(Map<String, dynamic> json) {
    return FinePayment(
      id: json['id'],
      fineId: json['fine_id'],
      amount: (json['amount'] as num).toDouble(),
      paidAt: DateTime.parse(json['paid_at']),
      registeredBy: json['registered_by'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fine_id': fineId,
        'amount': amount,
        'paid_at': paidAt.toIso8601String(),
        'registered_by': registeredBy,
      };
}

class TeamFinesSummary {
  final String teamId;
  final double totalFines;
  final double totalPaid;
  final double totalPending;
  final int fineCount;
  final int pendingCount;
  final int paidCount;

  TeamFinesSummary({
    required this.teamId,
    this.totalFines = 0,
    this.totalPaid = 0,
    this.totalPending = 0,
    this.fineCount = 0,
    this.pendingCount = 0,
    this.paidCount = 0,
  });

  double get outstandingBalance => totalFines - totalPaid;

  Map<String, dynamic> toJson() => {
        'team_id': teamId,
        'total_fines': totalFines,
        'total_paid': totalPaid,
        'total_pending': totalPending,
        'outstanding_balance': outstandingBalance,
        'fine_count': fineCount,
        'pending_count': pendingCount,
        'paid_count': paidCount,
      };
}

class UserFinesSummary {
  final String oderId;
  final String userName;
  final String? userAvatarUrl;
  final double totalFines;
  final double totalPaid;
  final int fineCount;

  UserFinesSummary({
    required this.oderId,
    required this.userName,
    this.userAvatarUrl,
    this.totalFines = 0,
    this.totalPaid = 0,
    this.fineCount = 0,
  });

  double get outstandingBalance => totalFines - totalPaid;

  Map<String, dynamic> toJson() => {
        'user_id': oderId,
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        'total_fines': totalFines,
        'total_paid': totalPaid,
        'outstanding_balance': outstandingBalance,
        'fine_count': fineCount,
      };
}
