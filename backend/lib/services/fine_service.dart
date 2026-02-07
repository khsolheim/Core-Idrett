import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/fine.dart';
import 'team_service.dart';
import 'user_service.dart';

class FineService {
  final Database _db;
  final UserService _userService;
  final TeamService _teamService;
  final _uuid = const Uuid();

  FineService(this._db, this._userService, this._teamService);

  // Fine Rules
  Future<List<FineRule>> getFineRules(String teamId, {bool? activeOnly}) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (activeOnly == true) {
      filters['active'] = 'eq.true';
    }

    final result = await _db.client.select(
      'fine_rules',
      filters: filters,
      order: 'name.asc',
    );

    return result.map((row) => FineRule.fromJson(row)).toList();
  }

  Future<FineRule> createFineRule({
    required String teamId,
    required String name,
    required double amount,
    String? description,
  }) async {
    final id = _uuid.v4();

    final result = await _db.client.insert('fine_rules', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'amount': amount,
      'description': description,
    });

    return FineRule.fromJson(result.first);
  }

  Future<FineRule?> updateFineRule({
    required String ruleId,
    String? name,
    double? amount,
    String? description,
    bool? active,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (amount != null) updates['amount'] = amount;
    if (description != null) updates['description'] = description;
    if (active != null) updates['active'] = active;

    if (updates.isEmpty) return null;

    final result = await _db.client.update(
      'fine_rules',
      updates,
      filters: {'id': 'eq.$ruleId'},
    );

    if (result.isEmpty) return null;
    return FineRule.fromJson(result.first);
  }

  Future<bool> deleteFineRule(String ruleId) async {
    try {
      await _db.client.delete(
        'fine_rules',
        filters: {'id': 'eq.$ruleId'},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // Fines
  Future<List<Fine>> getFines(
    String teamId, {
    String? status,
    String? offenderId,
    int limit = 50,
    int offset = 0,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (status != null) filters['status'] = 'eq.$status';
    if (offenderId != null) filters['offender_id'] = 'eq.$offenderId';

    final fines = await _db.client.select(
      'fines',
      filters: filters,
      order: 'created_at.desc',
      limit: limit,
      offset: offset,
    );

    if (fines.isEmpty) return [];

    // Get all related data
    final offenderIds = fines.map((f) => f['offender_id'] as String).toSet().toList();
    final reporterIds = fines.map((f) => f['reporter_id'] as String?).whereType<String>().toSet().toList();
    final ruleIds = fines.map((f) => f['rule_id'] as String?).whereType<String>().toSet().toList();
    final fineIds = fines.map((f) => f['id'] as String).toList();

    // Get users
    final allUserIds = {...offenderIds, ...reporterIds}.toList();
    final userMap = await _userService.getUserMap(allUserIds);

    // Get rules
    final rules = ruleIds.isNotEmpty
        ? await _db.client.select(
            'fine_rules',
            select: 'id,name',
            filters: {'id': 'in.(${ruleIds.join(',')})'},
          )
        : <Map<String, dynamic>>[];

    final ruleMap = <String, Map<String, dynamic>>{};
    for (final r in rules) {
      ruleMap[r['id'] as String] = r;
    }

    // Get payments
    final payments = await _db.client.select(
      'fine_payments',
      select: 'fine_id,amount',
      filters: {'fine_id': 'in.(${fineIds.join(',')})'},
    );

    final paymentTotals = <String, double>{};
    for (final p in payments) {
      final fineId = p['fine_id'] as String;
      paymentTotals[fineId] = (paymentTotals[fineId] ?? 0) + (p['amount'] as num).toDouble();
    }

    return fines.map((f) {
      final offender = userMap[f['offender_id']] ?? {};
      final reporter = f['reporter_id'] != null ? userMap[f['reporter_id']] ?? {} : {};
      final rule = f['rule_id'] != null ? ruleMap[f['rule_id']] ?? {} : {};

      return Fine.fromJson({
        ...f,
        'offender_name': offender['name'],
        'offender_avatar_url': offender['avatar_url'],
        'reporter_name': reporter['name'],
        'rule_name': rule['name'],
        'paid_amount': paymentTotals[f['id']] ?? 0,
      });
    }).toList();
  }

  Future<Fine?> getFine(String fineId) async {
    final fines = await _db.client.select(
      'fines',
      filters: {'id': 'eq.$fineId'},
    );

    if (fines.isEmpty) return null;
    final fine = fines.first;

    // Batch fetch users (offender + reporter in one query)
    final userIds = <String>[
      fine['offender_id'] as String,
      if (fine['reporter_id'] != null) fine['reporter_id'] as String,
    ];
    final userMap = await _userService.getUserMap(userIds);
    final offender = userMap[fine['offender_id']] ?? {};
    final reporter = fine['reporter_id'] != null
        ? userMap[fine['reporter_id']] ?? {}
        : <String, dynamic>{};

    // Get rule
    Map<String, dynamic> rule = {};
    if (fine['rule_id'] != null) {
      final rules = await _db.client.select(
        'fine_rules',
        select: 'id,name',
        filters: {'id': 'eq.${fine['rule_id']}'},
      );
      rule = rules.isNotEmpty ? rules.first : {};
    }

    // Get payments total
    final payments = await _db.client.select(
      'fine_payments',
      select: 'amount',
      filters: {'fine_id': 'eq.$fineId'},
    );
    final paidAmount = payments.fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());

    // Get appeal if exists
    final appeals = await _db.client.select(
      'fine_appeals',
      filters: {'fine_id': 'eq.$fineId'},
    );

    final fineData = {
      ...fine,
      'offender_name': offender['name'],
      'offender_avatar_url': offender['avatar_url'],
      'reporter_name': reporter['name'],
      'rule_name': rule['name'],
      'paid_amount': paidAmount,
    };

    if (appeals.isNotEmpty) {
      fineData['appeal'] = appeals.first;
    }

    return Fine.fromJson(fineData);
  }

  Future<Fine> createFine({
    required String teamId,
    required String offenderId,
    required String reporterId,
    String? ruleId,
    required double amount,
    String? description,
    String? evidenceUrl,
    bool isGameDay = false,
  }) async {
    final id = _uuid.v4();

    await _db.client.insert('fines', {
      'id': id,
      'team_id': teamId,
      'offender_id': offenderId,
      'reporter_id': reporterId,
      'rule_id': ruleId,
      'amount': amount,
      'description': description,
      'evidence_url': evidenceUrl,
      'is_game_day': isGameDay,
    });

    return (await getFine(id))!;
  }

  Future<Fine?> approveFine(String fineId, String approvedBy) async {
    // Check current status
    final existing = await _db.client.select(
      'fines',
      select: 'status',
      filters: {'id': 'eq.$fineId'},
    );

    if (existing.isEmpty || existing.first['status'] != 'pending') {
      return null;
    }

    await _db.client.update(
      'fines',
      {
        'status': 'approved',
        'approved_by': approvedBy,
        'resolved_at': DateTime.now().toIso8601String(),
      },
      filters: {'id': 'eq.$fineId'},
    );

    return getFine(fineId);
  }

  Future<Fine?> rejectFine(String fineId, String approvedBy) async {
    // Check current status
    final existing = await _db.client.select(
      'fines',
      select: 'status',
      filters: {'id': 'eq.$fineId'},
    );

    if (existing.isEmpty || existing.first['status'] != 'pending') {
      return null;
    }

    await _db.client.update(
      'fines',
      {
        'status': 'rejected',
        'approved_by': approvedBy,
        'resolved_at': DateTime.now().toIso8601String(),
      },
      filters: {'id': 'eq.$fineId'},
    );

    return getFine(fineId);
  }

  // Appeals
  Future<FineAppeal?> createAppeal({
    required String fineId,
    required String reason,
  }) async {
    // Check current status
    final existing = await _db.client.select(
      'fines',
      select: 'status',
      filters: {'id': 'eq.$fineId'},
    );

    if (existing.isEmpty || existing.first['status'] != 'approved') {
      return null;
    }

    // Update fine status
    await _db.client.update(
      'fines',
      {'status': 'appealed'},
      filters: {'id': 'eq.$fineId'},
    );

    final id = _uuid.v4();
    final result = await _db.client.insert('fine_appeals', {
      'id': id,
      'fine_id': fineId,
      'reason': reason,
    });

    return FineAppeal.fromJson(result.first);
  }

  Future<FineAppeal?> resolveAppeal({
    required String appealId,
    required String decidedBy,
    required bool accepted,
    double? extraFee,
  }) async {
    // Check current status
    final existing = await _db.client.select(
      'fine_appeals',
      filters: {'id': 'eq.$appealId'},
    );

    if (existing.isEmpty || existing.first['status'] != 'pending') {
      return null;
    }

    final newStatus = accepted ? 'accepted' : 'rejected';

    final result = await _db.client.update(
      'fine_appeals',
      {
        'status': newStatus,
        'decided_by': decidedBy,
        'decided_at': DateTime.now().toIso8601String(),
        'extra_fee': extraFee,
      },
      filters: {'id': 'eq.$appealId'},
    );

    if (result.isEmpty) return null;

    final appeal = FineAppeal.fromJson(result.first);

    // Update fine status and amount based on appeal result
    if (accepted) {
      await _db.client.update(
        'fines',
        {'status': 'rejected'},
        filters: {'id': 'eq.${appeal.fineId}'},
      );
    } else {
      // Appeal rejected - add extra fee if applicable
      if (extraFee != null && extraFee > 0) {
        // Get current amount
        final fineResult = await _db.client.select(
          'fines',
          select: 'amount',
          filters: {'id': 'eq.${appeal.fineId}'},
        );

        if (fineResult.isNotEmpty) {
          final currentAmount = (fineResult.first['amount'] as num).toDouble();
          await _db.client.update(
            'fines',
            {
              'status': 'approved',
              'amount': currentAmount + extraFee,
            },
            filters: {'id': 'eq.${appeal.fineId}'},
          );
        }
      } else {
        await _db.client.update(
          'fines',
          {'status': 'approved'},
          filters: {'id': 'eq.${appeal.fineId}'},
        );
      }
    }

    return appeal;
  }

  Future<List<FineAppeal>> getPendingAppeals(String teamId) async {
    // Get fines for team
    final fines = await _db.client.select(
      'fines',
      select: 'id',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (fines.isEmpty) return [];

    final fineIds = fines.map((f) => f['id'] as String).toList();

    // Get pending appeals for these fines
    final appeals = await _db.client.select(
      'fine_appeals',
      filters: {
        'fine_id': 'in.(${fineIds.join(',')})',
        'status': 'eq.pending',
      },
      order: 'created_at.asc',
    );

    return appeals.map((row) => FineAppeal.fromJson(row)).toList();
  }

  // Payments
  Future<FinePayment> recordPayment({
    required String fineId,
    required double amount,
    required String registeredBy,
  }) async {
    final id = _uuid.v4();

    final result = await _db.client.insert('fine_payments', {
      'id': id,
      'fine_id': fineId,
      'amount': amount,
      'registered_by': registeredBy,
    });

    // Check if fine is fully paid
    final fineResult = await _db.client.select(
      'fines',
      select: 'amount',
      filters: {'id': 'eq.$fineId'},
    );

    if (fineResult.isNotEmpty) {
      final fineAmount = (fineResult.first['amount'] as num).toDouble();

      // Get total paid
      final payments = await _db.client.select(
        'fine_payments',
        select: 'amount',
        filters: {'fine_id': 'eq.$fineId'},
      );

      final paidAmount = payments.fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());

      if (paidAmount >= fineAmount) {
        await _db.client.update(
          'fines',
          {'status': 'paid'},
          filters: {'id': 'eq.$fineId'},
        );
      }
    }

    return FinePayment.fromJson(result.first);
  }

  // Summary
  Future<TeamFinesSummary> getTeamSummary(String teamId) async {
    final fines = await _db.client.select(
      'fines',
      filters: {'team_id': 'eq.$teamId'},
    );

    int fineCount = fines.length;
    int pendingCount = 0;
    int paidCount = 0;
    double totalFines = 0;
    double totalPending = 0;

    for (final f in fines) {
      final status = f['status'] as String?;
      final amount = (f['amount'] as num).toDouble();

      if (status == 'pending' || status == 'appealed') {
        pendingCount++;
        totalPending += amount;
      }
      if (status == 'paid') {
        paidCount++;
      }
      // Only count approved/appealed fines in total (not pending or rejected)
      if (status == 'approved' || status == 'appealed') {
        totalFines += amount;
      }
    }

    // Get total paid
    final fineIds = fines.map((f) => f['id'] as String).toList();
    double totalPaid = 0;

    if (fineIds.isNotEmpty) {
      final payments = await _db.client.select(
        'fine_payments',
        select: 'amount',
        filters: {'fine_id': 'in.(${fineIds.join(',')})'},
      );

      totalPaid = payments.fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble());
    }

    return TeamFinesSummary(
      teamId: teamId,
      fineCount: fineCount,
      pendingCount: pendingCount,
      paidCount: paidCount,
      totalFines: totalFines,
      totalPending: totalPending,
      totalPaid: totalPaid,
    );
  }

  Future<List<UserFinesSummary>> getUserSummaries(String teamId) async {
    // Get team members
    final userIds = await _teamService.getTeamMemberUserIds(teamId);

    if (userIds.isEmpty) return [];

    // Get users
    final userMap = await _userService.getUserMap(userIds);

    // Get fines for team
    final fines = await _db.client.select(
      'fines',
      filters: {'team_id': 'eq.$teamId'},
    );

    // Get all payments
    final fineIds = fines.map((f) => f['id'] as String).toList();
    final payments = fineIds.isNotEmpty
        ? await _db.client.select(
            'fine_payments',
            select: 'fine_id,amount',
            filters: {'fine_id': 'in.(${fineIds.join(',')})'},
          )
        : <Map<String, dynamic>>[];

    // Build payment totals per fine
    final paymentsByFine = <String, double>{};
    for (final p in payments) {
      final fineId = p['fine_id'] as String;
      paymentsByFine[fineId] = (paymentsByFine[fineId] ?? 0) + (p['amount'] as num).toDouble();
    }

    // Calculate per-user summaries
    final summaries = <String, _UserFineData>{};
    for (final userId in userIds) {
      summaries[userId] = _UserFineData();
    }

    for (final f in fines) {
      final offenderId = f['offender_id'] as String;
      final status = f['status'] as String?;
      final amount = (f['amount'] as num).toDouble();
      final fineId = f['id'] as String;

      if (summaries.containsKey(offenderId)) {
        summaries[offenderId]!.fineCount++;
        // Only count approved/appealed fines as owed (not pending or rejected)
        if (status == 'approved' || status == 'appealed' || status == 'paid') {
          summaries[offenderId]!.totalFines += amount;
          summaries[offenderId]!.totalPaid += paymentsByFine[fineId] ?? 0;
        }
      }
    }

    // Build results
    final results = <UserFinesSummary>[];
    for (final userId in userIds) {
      final user = userMap[userId] ?? {};
      final data = summaries[userId]!;

      results.add(UserFinesSummary(
        userId: userId,
        userName: user['name'] as String? ?? '',
        userAvatarUrl: user['avatar_url'] as String?,
        fineCount: data.fineCount,
        totalFines: data.totalFines,
        totalPaid: data.totalPaid,
      ));
    }

    // Sort by unpaid amount (descending)
    results.sort((a, b) => (b.totalFines - b.totalPaid).compareTo(a.totalFines - a.totalPaid));

    return results;
  }
}

class _UserFineData {
  int fineCount = 0;
  double totalFines = 0;
  double totalPaid = 0;
}
