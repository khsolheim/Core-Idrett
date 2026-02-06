import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/mini_activity_statistics.dart';
import 'leaderboard_service.dart';
import 'season_service.dart';

class ActivityInstanceService {
  final Database _db;
  final LeaderboardService _leaderboardService;
  final SeasonService _seasonService;
  final _uuid = const Uuid();

  ActivityInstanceService(this._db, this._leaderboardService, this._seasonService);

  Future<void> respond({
    required String instanceId,
    required String userId,
    required String? response,
    String? comment,
  }) async {
    // Check for existing response
    final existing = await _db.client.select(
      'activity_responses',
      filters: {
        'instance_id': 'eq.$instanceId',
        'user_id': 'eq.$userId',
      },
    );

    if (existing.isNotEmpty) {
      // Update existing response
      await _db.client.update(
        'activity_responses',
        {
          'response': response,
          'comment': comment,
          'responded_at': DateTime.now().toIso8601String(),
        },
        filters: {
          'instance_id': 'eq.$instanceId',
          'user_id': 'eq.$userId',
        },
      );
    } else {
      // Insert new response
      await _db.client.insert('activity_responses', {
        'id': _uuid.v4(),
        'instance_id': instanceId,
        'user_id': userId,
        'response': response,
        'comment': comment,
      });
    }
  }

  Future<void> updateInstanceStatus(String instanceId, String status, {String? reason}) async {
    await _db.client.update(
      'activity_instances',
      {
        'status': status,
        'cancelled_reason': reason,
      },
      filters: {'id': 'eq.$instanceId'},
    );
  }

  // ============ SERIES MANAGEMENT ============

  /// Edit a single instance (detaches it from the series)
  Future<Map<String, dynamic>> editSingleInstance({
    required String instanceId,
    required String userId,
    String? title,
    String? location,
    String? description,
    String? startTime,
    String? endTime,
    DateTime? date,
  }) async {
    // Get current instance to validate
    final instances = await _db.client.select(
      'activity_instances',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instances.isEmpty) {
      throw Exception('Instance not found');
    }

    final instance = instances.first;

    // Build update map with overrides
    final updates = <String, dynamic>{
      'is_detached': true,
      'edited_at': DateTime.now().toIso8601String(),
      'edited_by': userId,
    };

    if (title != null) updates['title_override'] = title;
    if (location != null) updates['location_override'] = location;
    if (description != null) updates['description_override'] = description;
    if (startTime != null) updates['start_time_override'] = startTime;
    if (endTime != null) updates['end_time_override'] = endTime;
    if (date != null) {
      updates['date_override'] = date.toIso8601String().split('T').first;
    }

    await _db.client.update(
      'activity_instances',
      updates,
      filters: {'id': 'eq.$instanceId'},
    );

    // Reset responses for this instance
    await resetResponses([instanceId]);

    return {
      'updated_count': 1,
      'affected_instance_ids': [instanceId],
      'activity_id': instance['activity_id'],
    };
  }

  /// Edit this instance and all future instances in the series
  Future<Map<String, dynamic>> editFutureInstances({
    required String instanceId,
    required String userId,
    String? title,
    String? location,
    String? description,
    String? startTime,
    String? endTime,
  }) async {
    // Get the instance to find the series and date
    final instances = await _db.client.select(
      'activity_instances',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instances.isEmpty) {
      throw Exception('Instance not found');
    }

    final instance = instances.first;
    final activityId = instance['activity_id'] as String;
    final instanceDate = instance['date'] as String;

    // Update template fields on the parent activity if provided
    if (title != null || location != null || description != null) {
      final activityUpdates = <String, dynamic>{};
      if (title != null) activityUpdates['title'] = title;
      if (location != null) activityUpdates['location'] = location;
      if (description != null) activityUpdates['description'] = description;

      await _db.client.update(
        'activities',
        activityUpdates,
        filters: {'id': 'eq.$activityId'},
      );
    }

    // Find all future instances (from this date onwards) that are not detached
    final futureInstances = await _db.client.select(
      'activity_instances',
      select: 'id',
      filters: {
        'activity_id': 'eq.$activityId',
        'date': 'gte.$instanceDate',
        'is_detached': 'eq.false',
      },
    );

    final affectedIds = futureInstances.map((i) => i['id'] as String).toList();

    if (affectedIds.isEmpty) {
      return {
        'updated_count': 0,
        'affected_instance_ids': <String>[],
        'activity_id': activityId,
      };
    }

    // Update time fields on all affected instances
    if (startTime != null || endTime != null) {
      final timeUpdates = <String, dynamic>{
        'edited_at': DateTime.now().toIso8601String(),
        'edited_by': userId,
      };
      if (startTime != null) timeUpdates['start_time'] = startTime;
      if (endTime != null) timeUpdates['end_time'] = endTime;

      // Clear any overrides since we're setting the base values
      timeUpdates['start_time_override'] = null;
      timeUpdates['end_time_override'] = null;

      await _db.client.update(
        'activity_instances',
        timeUpdates,
        filters: {'id': 'in.(${affectedIds.join(',')})'},
      );
    }

    // Also clear title/location/description overrides on non-detached instances
    // since the parent activity was updated
    if (title != null || location != null || description != null) {
      final clearOverrides = <String, dynamic>{};
      if (title != null) clearOverrides['title_override'] = null;
      if (location != null) clearOverrides['location_override'] = null;
      if (description != null) clearOverrides['description_override'] = null;

      await _db.client.update(
        'activity_instances',
        clearOverrides,
        filters: {'id': 'in.(${affectedIds.join(',')})'},
      );
    }

    // Reset responses for all affected instances
    await resetResponses(affectedIds);

    return {
      'updated_count': affectedIds.length,
      'affected_instance_ids': affectedIds,
      'activity_id': activityId,
    };
  }

  /// Delete a single instance
  Future<Map<String, dynamic>> deleteSingleInstance({
    required String instanceId,
    required String userId,
  }) async {
    // Get instance to validate and get activity_id
    final instances = await _db.client.select(
      'activity_instances',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instances.isEmpty) {
      throw Exception('Instance not found');
    }

    final instance = instances.first;
    final instanceDate = DateTime.parse(instance['date'] as String);
    final today = DateTime.now();

    // Verify date is not in the past
    if (instanceDate.isBefore(DateTime(today.year, today.month, today.day))) {
      throw Exception('Cannot delete past instances');
    }

    final activityId = instance['activity_id'] as String;

    // Delete the instance (CASCADE will delete responses)
    await _db.client.delete(
      'activity_instances',
      filters: {'id': 'eq.$instanceId'},
    );

    return {
      'deleted_count': 1,
      'affected_instance_ids': [instanceId],
      'activity_id': activityId,
    };
  }

  /// Delete this instance and all future instances in the series
  Future<Map<String, dynamic>> deleteFutureInstances({
    required String instanceId,
    required String userId,
  }) async {
    // Get the instance to find the series and date
    final instances = await _db.client.select(
      'activity_instances',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instances.isEmpty) {
      throw Exception('Instance not found');
    }

    final instance = instances.first;
    final activityId = instance['activity_id'] as String;
    final instanceDate = instance['date'] as String;
    final today = DateTime.now().toIso8601String().split('T').first;

    // Verify the start date is not in the past
    if (instanceDate.compareTo(today) < 0) {
      throw Exception('Cannot delete past instances');
    }

    // Find all future instances
    final futureInstances = await _db.client.select(
      'activity_instances',
      select: 'id,date',
      filters: {
        'activity_id': 'eq.$activityId',
        'date': 'gte.$instanceDate',
      },
    );

    // Verify none are in the past
    for (final i in futureInstances) {
      final date = i['date'] as String;
      if (date.compareTo(today) < 0) {
        throw Exception('Cannot delete past instances');
      }
    }

    final affectedIds = futureInstances.map((i) => i['id'] as String).toList();

    if (affectedIds.isEmpty) {
      return {
        'deleted_count': 0,
        'affected_instance_ids': <String>[],
        'activity_id': activityId,
      };
    }

    // Delete all future instances (CASCADE will delete responses)
    await _db.client.delete(
      'activity_instances',
      filters: {'id': 'in.(${affectedIds.join(',')})'},
    );

    return {
      'deleted_count': affectedIds.length,
      'affected_instance_ids': affectedIds,
      'activity_id': activityId,
    };
  }

  /// Reset responses for given instance IDs
  Future<void> resetResponses(List<String> instanceIds) async {
    if (instanceIds.isEmpty) return;

    await _db.client.update(
      'activity_responses',
      {
        'response': null,
        'comment': null,
        'responded_at': DateTime.now().toIso8601String(),
      },
      filters: {'instance_id': 'in.(${instanceIds.join(',')})'},
    );
  }

  /// Get instance info for authorization checks
  Future<Map<String, dynamic>?> getInstanceInfo(String instanceId) async {
    final instances = await _db.client.select(
      'activity_instances',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instances.isEmpty) return null;
    final instance = instances.first;

    final activities = await _db.client.select(
      'activities',
      filters: {'id': 'eq.${instance['activity_id']}'},
    );

    if (activities.isEmpty) return null;
    final activity = activities.first;

    return {
      'instance_id': instanceId,
      'activity_id': activity['id'],
      'team_id': activity['team_id'],
      'created_by': activity['created_by'],
      'date': instance['date'],
    };
  }

  // ============ ATTENDANCE POINTS ============

  /// Award attendance points for a completed activity instance
  /// Returns the number of users who received points
  Future<int> awardAttendancePoints(String instanceId) async {
    // Get instance details
    final instances = await _db.client.select(
      'activity_instances',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instances.isEmpty) {
      throw Exception('Instance not found');
    }

    final instance = instances.first;
    final instanceDate = DateTime.parse(instance['date'] as String);
    final now = DateTime.now();

    // Check that date has passed
    if (instanceDate.isAfter(DateTime(now.year, now.month, now.day))) {
      throw Exception('Cannot award points for future activities');
    }

    // Check that instance is not cancelled
    if (instance['status'] == 'cancelled') {
      throw Exception('Cannot award points for cancelled activities');
    }

    // Get the activity to find team_id
    final activities = await _db.client.select(
      'activities',
      filters: {'id': 'eq.${instance['activity_id']}'},
    );

    if (activities.isEmpty) {
      throw Exception('Activity not found');
    }

    final activity = activities.first;
    final teamId = activity['team_id'] as String;

    // Get team settings for attendance points value
    final settingsResult = await _db.client.select(
      'team_settings',
      filters: {'team_id': 'eq.$teamId'},
    );

    final attendancePoints = settingsResult.isNotEmpty
        ? (settingsResult.first['attendance_points'] as int? ?? 1)
        : 1;

    // Get the active season for this team
    final activeSeason = await _seasonService.getActiveSeason(teamId);
    if (activeSeason == null) {
      throw Exception('No active season found for team');
    }

    // Get the main leaderboard for this season
    final mainLeaderboard = await _leaderboardService.getMainLeaderboard(teamId);
    if (mainLeaderboard == null) {
      throw Exception('No main leaderboard found for team');
    }

    // Get all 'yes' responses for this instance
    final responses = await _db.client.select(
      'activity_responses',
      filters: {
        'instance_id': 'eq.$instanceId',
        'response': 'eq.yes',
      },
    );

    int pointsAwarded = 0;
    final effectiveTitle = instance['title_override'] ?? activity['title'];

    for (final response in responses) {
      final userId = response['user_id'] as String;

      // Check if points were already awarded for this instance
      final alreadyAwarded = await _leaderboardService.hasPointsForSource(
        userId: userId,
        sourceType: PointSourceType.attendance,
        sourceId: instanceId,
      );

      if (alreadyAwarded) {
        continue;
      }

      // Award points with source tracking
      await _leaderboardService.addPointsWithSource(
        leaderboardId: mainLeaderboard.id,
        userId: userId,
        points: attendancePoints,
        sourceType: PointSourceType.attendance,
        sourceId: instanceId,
        description: 'Oppmøte: $effectiveTitle',
      );

      pointsAwarded++;
    }

    // Mark instance as completed if not already
    if (instance['status'] != 'completed') {
      await updateInstanceStatus(instanceId, 'completed');
    }

    return pointsAwarded;
  }
}
