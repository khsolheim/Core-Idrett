import '../../db/database.dart';
import '../../helpers/parsing_helpers.dart';

class ExportDataService {
  final Database _db;

  ExportDataService(this._db);

  /// Export leaderboard data
  Future<Map<String, dynamic>> exportLeaderboard(
    String teamId, {
    String? seasonId,
    String? leaderboardId,
  }) async {
    // Get leaderboard entries
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (leaderboardId != null) {
      filters['leaderboard_id'] = 'eq.$leaderboardId';
    }

    final entries = await _db.client.select(
      'leaderboard_entries',
      filters: filters,
      order: 'points.desc',
    );

    if (entries.isEmpty) {
      return {
        'type': 'leaderboard',
        'columns': ['Plass', 'Bruker', 'Poeng'],
        'data': [],
      };
    }

    // Get user details
    final userIds = entries.map((e) => safeString(e, 'user_id')).toSet().toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, String>{};
    for (final u in users) {
      userMap[safeString(u, 'id')] = safeString(u, 'name');
    }

    final data = <Map<String, dynamic>>[];
    int rank = 1;
    for (final entry in entries) {
      data.add({
        'rank': rank,
        'user_id': entry['user_id'],
        'user_name': userMap[entry['user_id']] ?? 'Ukjent',
        'points': entry['points'],
      });
      rank++;
    }

    return {
      'type': 'leaderboard',
      'columns': ['Plass', 'Bruker', 'Poeng'],
      'data': data,
    };
  }

  /// Export attendance data
  Future<Map<String, dynamic>> exportAttendance(
    String teamId, {
    String? seasonId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    // Get team members
    final members = await _db.client.select(
      'team_members',
      filters: {
        'team_id': 'eq.$teamId',
        'is_active': 'eq.true',
      },
    );

    if (members.isEmpty) {
      return {
        'type': 'attendance',
        'columns': ['Bruker', 'Tilstede', 'Fravarende', 'Kanskje', 'Totalt', 'Oppmote %'],
        'data': [],
      };
    }

    // Get user details
    final userIds = members.map((m) => safeString(m, 'user_id')).toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, String>{};
    for (final u in users) {
      userMap[safeString(u, 'id')] = safeString(u, 'name');
    }

    // Get activities
    final activityFilters = <String, String>{'team_id': 'eq.$teamId'};
    if (fromDate != null) {
      activityFilters['start_time'] = 'gte.${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      activityFilters['start_time'] = 'lte.${toDate.toIso8601String()}';
    }

    final activities = await _db.client.select(
      'activity_instances',
      select: 'id',
      filters: activityFilters,
    );

    if (activities.isEmpty) {
      return {
        'type': 'attendance',
        'columns': ['Bruker', 'Tilstede', 'Fravarende', 'Kanskje', 'Totalt', 'Oppmote %'],
        'data': userIds.map((id) => {
          'user_id': id,
          'user_name': userMap[id] ?? 'Ukjent',
          'attended': 0,
          'absent': 0,
          'maybe': 0,
          'total_activities': 0,
          'attendance_rate': 0,
        }).toList(),
      };
    }

    // Get participation data
    final activityIds = activities.map((a) => safeString(a, 'id')).toList();
    final participants = await _db.client.select(
      'activity_participants',
      filters: {'instance_id': 'in.(${activityIds.join(',')})'},
    );

    // Calculate attendance per user
    final attendanceData = <String, Map<String, int>>{};
    for (final userId in userIds) {
      attendanceData[userId] = {'attending': 0, 'absent': 0, 'maybe': 0};
    }

    for (final p in participants) {
      final userId = safeString(p, 'user_id');
      final status = safeStringNullable(p, 'status');
      if (attendanceData.containsKey(userId) && status != null) {
        attendanceData[userId]![status] = (attendanceData[userId]![status] ?? 0) + 1;
      }
    }

    final totalActivities = activities.length;
    final data = userIds.map((userId) {
      final stats = attendanceData[userId]!;
      final attended = stats['attending'] ?? 0;
      final absent = stats['absent'] ?? 0;
      final maybe = stats['maybe'] ?? 0;
      final rate = totalActivities > 0 ? (attended / totalActivities * 100).round() : 0;

      return {
        'user_id': userId,
        'user_name': userMap[userId] ?? 'Ukjent',
        'attended': attended,
        'absent': absent,
        'maybe': maybe,
        'total_activities': totalActivities,
        'attendance_rate': rate,
      };
    }).toList();

    // Sort by attendance rate descending
    data.sort((a, b) => (safeInt(b, 'attendance_rate')).compareTo(safeInt(a, 'attendance_rate')));

    return {
      'type': 'attendance',
      'columns': ['Bruker', 'Tilstede', 'Fravarende', 'Kanskje', 'Totalt', 'Oppmote %'],
      'data': data,
    };
  }

  /// Export fines data
  Future<Map<String, dynamic>> exportFines(
    String teamId, {
    String? seasonId,
    bool? paidOnly,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final filters = <String, String>{
      'team_id': 'eq.$teamId',
      'status': 'eq.approved',
    };

    if (paidOnly == true) {
      filters['paid_at'] = 'not.is.null';
    } else if (paidOnly == false) {
      filters['paid_at'] = 'is.null';
    }

    final fines = await _db.client.select(
      'fines',
      filters: filters,
      order: 'created_at.desc',
    );

    if (fines.isEmpty) {
      return {
        'type': 'fines',
        'columns': ['Bruker', 'Regel', 'Belop', 'Betalt', 'Betalt dato', 'Opprettet'],
        'data': [],
        'summary': {
          'total_amount': 0,
          'paid_amount': 0,
          'unpaid_amount': 0,
          'total_count': 0,
        },
      };
    }

    // Get user details
    final userIds = fines.map((f) => safeString(f, 'user_id')).toSet().toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, String>{};
    for (final u in users) {
      userMap[safeString(u, 'id')] = safeString(u, 'name');
    }

    // Get fine rules
    final ruleIds = fines
        .where((f) => f['rule_id'] != null)
        .map((f) => safeString(f, 'rule_id'))
        .toSet()
        .toList();

    final ruleMap = <String, String>{};
    if (ruleIds.isNotEmpty) {
      final rules = await _db.client.select(
        'fine_rules',
        select: 'id,name',
        filters: {'id': 'in.(${ruleIds.join(',')})'},
      );
      for (final r in rules) {
        ruleMap[safeString(r, 'id')] = safeString(r, 'name');
      }
    }

    int totalAmount = 0;
    int paidAmount = 0;

    final data = fines.map((f) {
      final amount = (f['amount'] as num?)?.toInt() ?? 0;
      final isPaid = f['paid_at'] != null;

      totalAmount += amount;
      if (isPaid) paidAmount += amount;

      return {
        'id': f['id'],
        'user_name': userMap[f['user_id']] ?? 'Ukjent',
        'rule_name': f['rule_id'] != null ? ruleMap[f['rule_id']] ?? 'Ukjent' : 'Egendefinert',
        'amount': amount,
        'is_paid': isPaid,
        'paid_at': f['paid_at'],
        'created_at': f['created_at'],
      };
    }).toList();

    return {
      'type': 'fines',
      'columns': ['Bruker', 'Regel', 'Belop', 'Betalt', 'Betalt dato', 'Opprettet'],
      'data': data,
      'summary': {
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'unpaid_amount': totalAmount - paidAmount,
        'total_count': data.length,
      },
    };
  }

  /// Export team members
  Future<Map<String, dynamic>> exportMembers(String teamId) async {
    final members = await _db.client.select(
      'team_members',
      filters: {
        'team_id': 'eq.$teamId',
        'is_active': 'eq.true',
      },
      order: 'joined_at.asc',
    );

    if (members.isEmpty) {
      return {
        'type': 'members',
        'columns': ['Navn', 'E-post', 'Fodselsdato', 'Roller', 'Ble med'],
        'data': [],
      };
    }

    // Get user details
    final userIds = members.map((m) => safeString(m, 'user_id')).toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name,email,birth_date',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[safeString(u, 'id')] = u;
    }

    // Get trainer types
    final trainerTypeIds = members
        .where((m) => m['trainer_type_id'] != null)
        .map((m) => safeString(m, 'trainer_type_id'))
        .toSet()
        .toList();

    final trainerTypeMap = <String, String>{};
    if (trainerTypeIds.isNotEmpty) {
      final trainerTypes = await _db.client.select(
        'trainer_types',
        select: 'id,name',
        filters: {'id': 'in.(${trainerTypeIds.join(',')})'},
      );
      for (final tt in trainerTypes) {
        trainerTypeMap[safeString(tt, 'id')] = safeString(tt, 'name');
      }
    }

    final data = members.map((m) {
      final user = userMap[m['user_id']] ?? {};
      final roles = <String>[];

      if (m['is_admin'] == true) roles.add('Admin');
      if (m['is_fine_boss'] == true) roles.add('Botesjef');
      if (m['trainer_type_id'] != null) {
        roles.add(trainerTypeMap[m['trainer_type_id']] ?? 'Trener');
      }

      return {
        'user_id': m['user_id'],
        'name': user['name'] ?? 'Ukjent',
        'email': user['email'],
        'date_of_birth': user['birth_date'],
        'roles': roles.join(', '),
        'joined_at': m['joined_at'],
      };
    }).toList();

    // Sort by name
    data.sort((a, b) => ((safeStringNullable(a, 'name')) ?? '').compareTo((safeStringNullable(b, 'name')) ?? ''));

    return {
      'type': 'members',
      'columns': ['Navn', 'E-post', 'Fodselsdato', 'Roller', 'Ble med'],
      'data': data,
    };
  }

  /// Export activities
  Future<Map<String, dynamic>> exportActivities(
    String teamId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};

    if (fromDate != null) {
      filters['start_time'] = 'gte.${fromDate.toIso8601String()}';
    }
    if (toDate != null) {
      filters['start_time'] = 'lte.${toDate.toIso8601String()}';
    }

    final activities = await _db.client.select(
      'activity_instances',
      filters: filters,
      order: 'start_time.desc',
    );

    if (activities.isEmpty) {
      return {
        'type': 'activities',
        'columns': ['Aktivitet', 'Type', 'Starttid', 'Sluttid', 'Sted', 'Deltakere'],
        'data': [],
      };
    }

    // Get template details
    final templateIds = activities
        .where((a) => a['template_id'] != null)
        .map((a) => safeString(a, 'template_id'))
        .toSet()
        .toList();

    final templateMap = <String, Map<String, dynamic>>{};
    if (templateIds.isNotEmpty) {
      final templates = await _db.client.select(
        'activity_templates',
        select: 'id,name,type',
        filters: {'id': 'in.(${templateIds.join(',')})'},
      );
      for (final t in templates) {
        templateMap[safeString(t, 'id')] = t;
      }
    }

    // Get participant counts
    final activityIds = activities.map((a) => safeString(a, 'id')).toList();
    final participants = await _db.client.select(
      'activity_participants',
      select: 'instance_id,status',
      filters: {'instance_id': 'in.(${activityIds.join(',')})'},
    );

    final attendingCounts = <String, int>{};
    for (final p in participants) {
      if (p['status'] == 'attending') {
        final instanceId = safeString(p, 'instance_id');
        attendingCounts[instanceId] = (attendingCounts[instanceId] ?? 0) + 1;
      }
    }

    final data = activities.map((a) {
      final template = a['template_id'] != null ? templateMap[a['template_id']] : null;

      return {
        'id': a['id'],
        'title': a['title'] ?? template?['name'] ?? 'Aktivitet',
        'type': a['type'] ?? template?['type'] ?? 'other',
        'start_time': a['start_time'],
        'end_time': a['end_time'],
        'location': a['location'],
        'attending_count': attendingCounts[a['id']] ?? 0,
      };
    }).toList();

    return {
      'type': 'activities',
      'columns': ['Aktivitet', 'Type', 'Starttid', 'Sluttid', 'Sted', 'Deltakere'],
      'data': data,
    };
  }
}
