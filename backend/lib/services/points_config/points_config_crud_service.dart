import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/points_config.dart';

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

/// Service for points config CRUD and opt-out management
class PointsConfigCrudService {
  final Database _db;
  final _uuid = const Uuid();

  PointsConfigCrudService(this._db);

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

    final optOutValue = result.first['leaderboard_opt_out'];
    if (optOutValue is bool) return optOutValue;
    return false;
  }
}
