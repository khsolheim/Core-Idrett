import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/fine.dart';
import '../user_service.dart';
import '../../helpers/parsing_helpers.dart';

class FineCrudService {
  final Database _db;
  final UserService _userService;
  final _uuid = const Uuid();

  FineCrudService(this._db, this._userService);

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
    final offenderIds = fines.map((f) => safeString(f, 'offender_id')).toSet().toList();
    final reporterIds = fines.map((f) => safeStringNullable(f, 'reporter_id')).whereType<String>().toSet().toList();
    final ruleIds = fines.map((f) => safeStringNullable(f, 'rule_id')).whereType<String>().toSet().toList();
    final fineIds = fines.map((f) => safeString(f, 'id')).toList();

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
      ruleMap[safeString(r, 'id')] = r;
    }

    // Get payments
    final payments = await _db.client.select(
      'fine_payments',
      select: 'fine_id,amount',
      filters: {'fine_id': 'in.(${fineIds.join(',')})'},
    );

    final paymentTotals = <String, double>{};
    for (final p in payments) {
      final fineId = safeString(p, 'fine_id');
      paymentTotals[fineId] = (paymentTotals[fineId] ?? 0) + safeDouble(p, 'amount');
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
      safeString(fine, 'offender_id'),
      if (fine['reporter_id'] != null) safeString(fine, 'reporter_id'),
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
    final paidAmount = payments.fold<double>(0, (sum, p) => sum + safeDouble(p, 'amount'));

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
          final currentAmount = safeDouble(fineResult.first, 'amount');
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

    final fineIds = fines.map((f) => safeString(f, 'id')).toList();

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
      final fineAmount = safeDouble(fineResult.first, 'amount');

      // Get total paid
      final payments = await _db.client.select(
        'fine_payments',
        select: 'amount',
        filters: {'fine_id': 'eq.$fineId'},
      );

      final paidAmount = payments.fold<double>(0, (sum, p) => sum + safeDouble(p, 'amount'));

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
}
