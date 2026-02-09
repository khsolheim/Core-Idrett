import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/points_config.dart';
import '../../helpers/parsing_helpers.dart';

/// Service for attendance point operations
class AttendancePointsService {
  final Database _db;
  final _uuid = const Uuid();

  AttendancePointsService(this._db);

  // ============ ATTENDANCE POINTS ============

  /// Award attendance points for a user/instance
  Future<AttendancePoints> awardAttendancePoints({
    required String teamId,
    required String userId,
    required String instanceId,
    required String activityType,
    String? seasonId,
    required int basePoints,
    required double weightedPoints,
  }) async {
    final id = _uuid.v4();

    // Check if already awarded
    final existing = await _db.client.select(
      'attendance_points',
      filters: {
        'user_id': 'eq.$userId',
        'instance_id': 'eq.$instanceId',
      },
    );

    if (existing.isNotEmpty) {
      return AttendancePoints.fromJson(existing.first);
    }

    await _db.client.insert('attendance_points', {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'instance_id': instanceId,
      'season_id': seasonId,
      'activity_type': activityType,
      'base_points': basePoints,
      'weighted_points': weightedPoints,
    });

    return AttendancePoints(
      id: id,
      teamId: teamId,
      userId: userId,
      instanceId: instanceId,
      seasonId: seasonId,
      activityType: activityType,
      basePoints: basePoints,
      weightedPoints: weightedPoints,
      awardedAt: DateTime.now(),
    );
  }

  /// Get attendance points for a user
  Future<List<AttendancePoints>> getUserAttendancePoints(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final filters = <String, String>{'user_id': 'eq.$userId'};
    if (teamId != null) filters['team_id'] = 'eq.$teamId';
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'attendance_points',
      filters: filters,
      order: 'awarded_at.desc',
    );

    return result.map((row) => AttendancePoints.fromJson(row)).toList();
  }

  /// Get attendance points for an instance
  Future<List<AttendancePoints>> getInstanceAttendancePoints(
      String instanceId) async {
    final result = await _db.client.select(
      'attendance_points',
      filters: {'instance_id': 'eq.$instanceId'},
    );

    return result.map((row) => AttendancePoints.fromJson(row)).toList();
  }

  /// Check if attendance points have been awarded for an instance
  Future<bool> hasAttendancePoints(String userId, String instanceId) async {
    final result = await _db.client.select(
      'attendance_points',
      select: 'id',
      filters: {
        'user_id': 'eq.$userId',
        'instance_id': 'eq.$instanceId',
      },
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get total attendance points for a user in a period
  Future<Map<String, dynamic>> getUserAttendanceStats(
    String userId,
    String teamId, {
    String? seasonId,
    int? year,
    int? month,
  }) async {
    final filters = <String, String>{
      'user_id': 'eq.$userId',
      'team_id': 'eq.$teamId',
    };
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'attendance_points',
      filters: filters,
    );

    var filteredResults = result;
    if (year != null || month != null) {
      filteredResults = result.where((row) {
        final awardedAt = requireDateTime(row, 'awarded_at');
        if (year != null && awardedAt.year != year) return false;
        if (month != null && awardedAt.month != month) return false;
        return true;
      }).toList();
    }

    final totalBase = filteredResults.fold<int>(
        0, (sum, row) => sum + (safeInt(row, 'base_points', defaultValue: 0)));
    final totalWeighted = filteredResults.fold<double>(
        0.0,
        (sum, row) =>
            sum + ((row['weighted_points'] as num?)?.toDouble() ?? 0.0));

    final byType = <String, int>{};
    for (final row in filteredResults) {
      final type = safeString(row, 'activity_type');
      byType[type] = (byType[type] ?? 0) + (safeInt(row, 'base_points', defaultValue: 0));
    }

    return {
      'total_base_points': totalBase,
      'total_weighted_points': totalWeighted,
      'count': filteredResults.length,
      'by_type': byType,
    };
  }
}
