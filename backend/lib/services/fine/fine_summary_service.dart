import '../../db/database.dart';
import '../../models/fine.dart';
import '../user_service.dart';
import '../team_service.dart';
import '../../helpers/parsing_helpers.dart';

class FineSummaryService {
  final Database _db;
  final UserService _userService;
  final TeamService _teamService;

  FineSummaryService(this._db, this._userService, this._teamService);

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
      final status = safeStringNullable(f, 'status');
      final amount = safeDouble(f, 'amount');

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
    final fineIds = fines.map((f) => safeString(f, 'id')).toList();
    double totalPaid = 0;

    if (fineIds.isNotEmpty) {
      final payments = await _db.client.select(
        'fine_payments',
        select: 'amount',
        filters: {'fine_id': 'in.(${fineIds.join(',')})'},
      );

      totalPaid = payments.fold<double>(0, (sum, p) => sum + safeDouble(p, 'amount'));
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
    final fineIds = fines.map((f) => safeString(f, 'id')).toList();
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
      final fineId = safeString(p, 'fine_id');
      paymentsByFine[fineId] = (paymentsByFine[fineId] ?? 0) + safeDouble(p, 'amount');
    }

    // Calculate per-user summaries
    final summaries = <String, _UserFineData>{};
    for (final userId in userIds) {
      summaries[userId] = _UserFineData();
    }

    for (final f in fines) {
      final offenderId = safeString(f, 'offender_id');
      final status = safeStringNullable(f, 'status');
      final amount = safeDouble(f, 'amount');
      final fineId = safeString(f, 'id');

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
        userName: safeStringNullable(user, 'name') ?? '',
        userAvatarUrl: safeStringNullable(user, 'avatar_url'),
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
