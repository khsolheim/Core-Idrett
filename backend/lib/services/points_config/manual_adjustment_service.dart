import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/points_config.dart';
import 'points_config_crud_service.dart'; // For AdjustmentType enum

/// Service for manual point adjustments
class ManualAdjustmentService {
  final Database _db;
  final _uuid = const Uuid();

  ManualAdjustmentService(this._db);

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
