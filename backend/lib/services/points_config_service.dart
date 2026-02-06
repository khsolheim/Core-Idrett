import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/points_config.dart';

/// Adjustment types for manual point adjustments
enum AdjustmentType {
  bonus,
  penalty,
  correction;

  String get value => name;

  static AdjustmentType fromString(String value) {
    return AdjustmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdjustmentType.bonus,
    );
  }
}

/// Service for managing team point configuration
class PointsConfigService {
  final Database _db;
  final _uuid = const Uuid();

  PointsConfigService(this._db);

  // ============ TEAM POINTS CONFIG ============

  /// Get point configuration for a team (optionally for a specific season)
  Future<TeamPointsConfig?> getConfig(
    String teamId, {
    String? seasonId,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};

    if (seasonId != null) {
      filters['season_id'] = 'eq.$seasonId';
    }

    final result = await _db.client.select(
      'team_points_config',
      filters: filters,
      order: 'season_id.nullslast',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return TeamPointsConfig.fromJson(result.first);
  }

  /// Get point configuration by ID
  Future<TeamPointsConfig?> getConfigById(String configId) async {
    final result = await _db.client.select(
      'team_points_config',
      filters: {'id': 'eq.$configId'},
      limit: 1,
    );

    if (result.isEmpty) return null;
    return TeamPointsConfig.fromJson(result.first);
  }

  /// Get or create default configuration for a team
  Future<TeamPointsConfig> getOrCreateConfig(
    String teamId, {
    String? seasonId,
  }) async {
    var config = await getConfig(teamId, seasonId: seasonId);
    if (config != null) return config;

    // Create default config
    return await createConfig(teamId: teamId, seasonId: seasonId);
  }

  /// Create a new point configuration
  Future<TeamPointsConfig> createConfig({
    required String teamId,
    String? seasonId,
    int trainingPoints = 1,
    int matchPoints = 2,
    int socialPoints = 1,
    double trainingWeight = 1.0,
    double matchWeight = 1.5,
    double socialWeight = 0.5,
    double competitionWeight = 1.0,
    String miniActivityDistribution = 'top_three',
    bool autoAwardAttendance = true,
    String visibility = 'all',
    bool allowOptOut = false,
    bool requireAbsenceReason = false,
    bool requireAbsenceApproval = false,
    bool excludeValidAbsenceFromPercentage = true,
    String newPlayerStartMode = 'from_join',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.client.insert('team_points_config', {
      'id': id,
      'team_id': teamId,
      'season_id': seasonId,
      'training_points': trainingPoints,
      'match_points': matchPoints,
      'social_points': socialPoints,
      'training_weight': trainingWeight,
      'match_weight': matchWeight,
      'social_weight': socialWeight,
      'competition_weight': competitionWeight,
      'mini_activity_distribution': miniActivityDistribution,
      'auto_award_attendance': autoAwardAttendance,
      'visibility': visibility,
      'allow_opt_out': allowOptOut,
      'require_absence_reason': requireAbsenceReason,
      'require_absence_approval': requireAbsenceApproval,
      'exclude_valid_absence_from_percentage': excludeValidAbsenceFromPercentage,
      'new_player_start_mode': newPlayerStartMode,
    });

    return TeamPointsConfig(
      id: id,
      teamId: teamId,
      seasonId: seasonId,
      trainingPoints: trainingPoints,
      matchPoints: matchPoints,
      socialPoints: socialPoints,
      trainingWeight: trainingWeight,
      matchWeight: matchWeight,
      socialWeight: socialWeight,
      competitionWeight: competitionWeight,
      miniActivityDistribution: miniActivityDistribution,
      autoAwardAttendance: autoAwardAttendance,
      visibility: visibility,
      allowOptOut: allowOptOut,
      requireAbsenceReason: requireAbsenceReason,
      requireAbsenceApproval: requireAbsenceApproval,
      excludeValidAbsenceFromPercentage: excludeValidAbsenceFromPercentage,
      newPlayerStartMode: newPlayerStartMode,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update point configuration
  Future<TeamPointsConfig?> updateConfig({
    required String configId,
    int? trainingPoints,
    int? matchPoints,
    int? socialPoints,
    double? trainingWeight,
    double? matchWeight,
    double? socialWeight,
    double? competitionWeight,
    String? miniActivityDistribution,
    bool? autoAwardAttendance,
    String? visibility,
    bool? allowOptOut,
    bool? requireAbsenceReason,
    bool? requireAbsenceApproval,
    bool? excludeValidAbsenceFromPercentage,
    String? newPlayerStartMode,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (trainingPoints != null) updates['training_points'] = trainingPoints;
    if (matchPoints != null) updates['match_points'] = matchPoints;
    if (socialPoints != null) updates['social_points'] = socialPoints;
    if (trainingWeight != null) updates['training_weight'] = trainingWeight;
    if (matchWeight != null) updates['match_weight'] = matchWeight;
    if (socialWeight != null) updates['social_weight'] = socialWeight;
    if (competitionWeight != null) {
      updates['competition_weight'] = competitionWeight;
    }
    if (miniActivityDistribution != null) {
      updates['mini_activity_distribution'] = miniActivityDistribution;
    }
    if (autoAwardAttendance != null) {
      updates['auto_award_attendance'] = autoAwardAttendance;
    }
    if (visibility != null) updates['visibility'] = visibility;
    if (allowOptOut != null) updates['allow_opt_out'] = allowOptOut;
    if (requireAbsenceReason != null) {
      updates['require_absence_reason'] = requireAbsenceReason;
    }
    if (requireAbsenceApproval != null) {
      updates['require_absence_approval'] = requireAbsenceApproval;
    }
    if (excludeValidAbsenceFromPercentage != null) {
      updates['exclude_valid_absence_from_percentage'] =
          excludeValidAbsenceFromPercentage;
    }
    if (newPlayerStartMode != null) {
      updates['new_player_start_mode'] = newPlayerStartMode;
    }

    await _db.client.update(
      'team_points_config',
      updates,
      filters: {'id': 'eq.$configId'},
    );

    // Fetch and return updated config
    final result = await _db.client.select(
      'team_points_config',
      filters: {'id': 'eq.$configId'},
    );

    if (result.isEmpty) return null;
    return TeamPointsConfig.fromJson(result.first);
  }

  /// Delete point configuration
  Future<void> deleteConfig(String configId) async {
    await _db.client.delete(
      'team_points_config',
      filters: {'id': 'eq.$configId'},
    );
  }

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
        final awardedAt = DateTime.parse(row['awarded_at'] as String);
        if (year != null && awardedAt.year != year) return false;
        if (month != null && awardedAt.month != month) return false;
        return true;
      }).toList();
    }

    final totalBase = filteredResults.fold<int>(
        0, (sum, row) => sum + (row['base_points'] as int? ?? 0));
    final totalWeighted = filteredResults.fold<double>(
        0.0,
        (sum, row) =>
            sum + ((row['weighted_points'] as num?)?.toDouble() ?? 0.0));

    final byType = <String, int>{};
    for (final row in filteredResults) {
      final type = row['activity_type'] as String;
      byType[type] = (byType[type] ?? 0) + (row['base_points'] as int? ?? 0);
    }

    return {
      'total_base_points': totalBase,
      'total_weighted_points': totalWeighted,
      'count': filteredResults.length,
      'by_type': byType,
    };
  }

  // ============ OPT-OUT ============

  /// Set leaderboard opt-out status for a user
  Future<void> setOptOut(String userId, String teamId, bool optOut) async {
    await _db.client.update(
      'team_members',
      {'leaderboard_opt_out': optOut},
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );
  }

  /// Check if user has opted out
  Future<bool> hasOptedOut(String userId, String teamId) async {
    final result = await _db.client.select(
      'team_members',
      select: 'leaderboard_opt_out',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );

    if (result.isEmpty) return false;
    return result.first['leaderboard_opt_out'] as bool? ?? false;
  }

  // ============ MANUAL POINT ADJUSTMENTS ============

  /// Create a manual point adjustment (bonus, penalty, or correction)
  Future<ManualPointAdjustment> createAdjustment({
    required String teamId,
    required String userId,
    required int points,
    required AdjustmentType adjustmentType,
    required String reason,
    required String createdBy,
    String? seasonId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.client.insert('manual_point_adjustments', {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'season_id': seasonId,
      'points': points,
      'adjustment_type': adjustmentType.value,
      'reason': reason,
      'created_by': createdBy,
    });

    return ManualPointAdjustment(
      id: id,
      teamId: teamId,
      userId: userId,
      seasonId: seasonId,
      points: points,
      adjustmentType: adjustmentType.value,
      reason: reason,
      createdBy: createdBy,
      createdAt: now,
    );
  }

  /// Get all manual point adjustments for a user
  Future<List<ManualPointAdjustment>> getUserAdjustments(
    String userId, {
    String? teamId,
    String? seasonId,
  }) async {
    final filters = <String, String>{'user_id': 'eq.$userId'};
    if (teamId != null) filters['team_id'] = 'eq.$teamId';
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'v_manual_point_adjustments',
      filters: filters,
      order: 'created_at.desc',
    );

    return result.map((row) => ManualPointAdjustment.fromJson(row)).toList();
  }

  /// Get all manual point adjustments for a team
  Future<List<ManualPointAdjustment>> getTeamAdjustments(
    String teamId, {
    String? seasonId,
    int? limit,
  }) async {
    final filters = <String, String>{'team_id': 'eq.$teamId'};
    if (seasonId != null) filters['season_id'] = 'eq.$seasonId';

    final result = await _db.client.select(
      'v_manual_point_adjustments',
      filters: filters,
      order: 'created_at.desc',
      limit: limit,
    );

    return result.map((row) => ManualPointAdjustment.fromJson(row)).toList();
  }

  /// Get total manual adjustment points for a user
  Future<int> getUserAdjustmentTotal(
    String userId,
    String teamId, {
    String? seasonId,
  }) async {
    final adjustments = await getUserAdjustments(
      userId,
      teamId: teamId,
      seasonId: seasonId,
    );

    return adjustments.fold<int>(0, (sum, adj) => sum + adj.points);
  }
}
