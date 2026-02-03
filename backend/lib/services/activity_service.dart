import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/activity.dart';
import '../models/mini_activity_statistics.dart';
import 'leaderboard_service.dart';
import 'season_service.dart';

class ActivityService {
  final Database _db;
  final LeaderboardService _leaderboardService;
  final SeasonService _seasonService;
  final _uuid = const Uuid();

  ActivityService(this._db, this._leaderboardService, this._seasonService);

  Future<Activity> createActivity({
    required String teamId,
    required String title,
    required String type,
    String? location,
    String? description,
    required String recurrenceType,
    DateTime? recurrenceEndDate,
    required String responseType,
    int? responseDeadlineHours,
    required String createdBy,
    required DateTime firstDate,
    String? startTime,
    String? endTime,
  }) async {
    final activityId = _uuid.v4();

    await _db.client.insert('activities', {
      'id': activityId,
      'team_id': teamId,
      'title': title,
      'type': type,
      'location': location,
      'description': description,
      'recurrence_type': recurrenceType,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'response_type': responseType,
      'response_deadline_hours': responseDeadlineHours,
      'created_by': createdBy,
    });

    // Generate instances based on recurrence
    await _generateInstances(
      activityId: activityId,
      teamId: teamId,
      recurrenceType: recurrenceType,
      firstDate: firstDate,
      endDate: recurrenceEndDate,
      startTime: startTime,
      endTime: endTime,
      responseType: responseType,
    );

    return Activity(
      id: activityId,
      teamId: teamId,
      title: title,
      type: type,
      location: location,
      description: description,
      recurrenceType: recurrenceType,
      recurrenceEndDate: recurrenceEndDate,
      responseType: responseType,
      responseDeadlineHours: responseDeadlineHours,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _generateInstances({
    required String activityId,
    required String teamId,
    required String recurrenceType,
    required DateTime firstDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    required String responseType,
  }) async {
    final dates = _calculateDates(recurrenceType, firstDate, endDate);
    final instanceIds = <String>[];

    for (final date in dates) {
      final instanceId = _uuid.v4();
      instanceIds.add(instanceId);
      await _db.client.insert('activity_instances', {
        'id': instanceId,
        'activity_id': activityId,
        'date': date.toIso8601String().split('T').first,
        'start_time': startTime,
        'end_time': endTime,
        'status': 'scheduled',
      });
    }

    // For opt_out activities, create default 'yes' responses for active, non-injured members
    if (responseType == 'opt_out' && instanceIds.isNotEmpty) {
      await _createDefaultResponses(instanceIds, teamId);
    }
  }

  /// Create default 'yes' responses for opt_out activity instances
  /// Only for active, non-injured team members
  Future<void> _createDefaultResponses(List<String> instanceIds, String teamId) async {
    // Get active, non-injured team members
    final members = await _db.client.select(
      'team_members',
      select: 'user_id',
      filters: {
        'team_id': 'eq.$teamId',
        'is_active': 'eq.true',
        'is_injured': 'eq.false',
      },
    );

    if (members.isEmpty) return;

    // Build all responses in memory, then batch insert
    final responses = <Map<String, dynamic>>[];
    for (final member in members) {
      final userId = member['user_id'] as String;
      for (final instanceId in instanceIds) {
        responses.add({
          'id': _uuid.v4(),
          'instance_id': instanceId,
          'user_id': userId,
          'response': 'yes',
        });
      }
    }

    // Batch insert all responses at once
    await _db.client.insertMany('activity_responses', responses);
  }

  List<DateTime> _calculateDates(String recurrenceType, DateTime firstDate, DateTime? endDate) {
    final dates = <DateTime>[firstDate];

    if (recurrenceType == 'once') {
      return dates;
    }

    final effectiveEndDate = endDate ?? firstDate.add(const Duration(days: 365));
    var currentDate = firstDate;

    while (currentDate.isBefore(effectiveEndDate)) {
      switch (recurrenceType) {
        case 'weekly':
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case 'biweekly':
          currentDate = currentDate.add(const Duration(days: 14));
          break;
        case 'monthly':
          currentDate = DateTime(
            currentDate.month == 12 ? currentDate.year + 1 : currentDate.year,
            currentDate.month == 12 ? 1 : currentDate.month + 1,
            currentDate.day,
          );
          break;
        default:
          return dates;
      }

      if (currentDate.isBefore(effectiveEndDate) || currentDate.isAtSameMomentAs(effectiveEndDate)) {
        dates.add(currentDate);
      }
    }

    return dates;
  }

  Future<List<Map<String, dynamic>>> getActivitiesForTeam(String teamId) async {
    // Get activities
    final activities = await _db.client.select(
      'activities',
      filters: {'team_id': 'eq.$teamId'},
      order: 'created_at.desc',
    );

    if (activities.isEmpty) return [];

    // Get instance counts for each activity
    final activityIds = activities.map((a) => a['id'] as String).toList();
    final instances = await _db.client.select(
      'activity_instances',
      select: 'activity_id',
      filters: {'activity_id': 'in.(${activityIds.join(',')})'},
    );

    // Count instances per activity
    final instanceCounts = <String, int>{};
    for (final instance in instances) {
      final activityId = instance['activity_id'] as String;
      instanceCounts[activityId] = (instanceCounts[activityId] ?? 0) + 1;
    }

    return activities.map((a) {
      return {
        'id': a['id'],
        'team_id': a['team_id'],
        'title': a['title'],
        'type': a['type'],
        'location': a['location'],
        'description': a['description'],
        'recurrence_type': a['recurrence_type'],
        'recurrence_end_date': a['recurrence_end_date'],
        'response_type': a['response_type'],
        'response_deadline_hours': a['response_deadline_hours'],
        'created_at': a['created_at'],
        'instance_count': instanceCounts[a['id']] ?? 0,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getUpcomingInstances(String teamId, {int limit = 20}) async {
    // Get activities for team
    final activities = await _db.client.select(
      'activities',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (activities.isEmpty) return [];

    // Create activity lookup
    final activityMap = <String, Map<String, dynamic>>{};
    final activityIds = <String>[];
    for (final a in activities) {
      final id = a['id'] as String;
      activityMap[id] = a;
      activityIds.add(id);
    }

    // Get upcoming instances
    final today = DateTime.now().toIso8601String().split('T').first;
    final instances = await _db.client.select(
      'activity_instances',
      filters: {
        'activity_id': 'in.(${activityIds.join(',')})',
        'date': 'gte.$today',
        'status': 'neq.cancelled',
      },
      order: 'date.asc,start_time.asc',
      limit: limit,
    );

    // Get instance IDs for response count lookup
    final instanceIds = instances.map((i) => i['id'] as String).toList();

    // Get all responses for these instances
    final allResponses = instanceIds.isNotEmpty
        ? await _db.client.select(
            'activity_responses',
            filters: {
              'instance_id': 'in.(${instanceIds.join(',')})',
            },
          )
        : <Map<String, dynamic>>[];

    // Count responses per instance
    final responseCounts = <String, Map<String, int>>{};
    for (final r in allResponses) {
      final iId = r['instance_id'] as String;
      final resp = r['response'] as String?;
      responseCounts[iId] ??= {'yes': 0, 'no': 0, 'maybe': 0};
      if (resp != null && responseCounts[iId]!.containsKey(resp)) {
        responseCounts[iId]![resp] = (responseCounts[iId]![resp] ?? 0) + 1;
      }
    }

    return instances.map((i) {
      final activity = activityMap[i['activity_id']] ?? {};
      final iId = i['id'] as String;
      final counts = responseCounts[iId] ?? {'yes': 0, 'no': 0, 'maybe': 0};
      // Use effective values (override if exists, otherwise activity value)
      final effectiveTitle = i['title_override'] ?? activity['title'];
      final effectiveLocation = i['location_override'] ?? activity['location'];
      final effectiveStartTime = i['start_time_override'] ?? i['start_time'];
      final effectiveEndTime = i['end_time_override'] ?? i['end_time'];
      final effectiveDate = i['date_override'] ?? i['date'];
      return {
        'id': iId,
        'activity_id': i['activity_id'],
        'date': effectiveDate,
        'start_time': effectiveStartTime,
        'end_time': effectiveEndTime,
        'status': i['status'],
        'title': effectiveTitle,
        'type': activity['type'],
        'location': effectiveLocation,
        'response_type': activity['response_type'],
        'response_deadline_hours': activity['response_deadline_hours'],
        'yes_count': counts['yes'],
        'no_count': counts['no'],
        'maybe_count': counts['maybe'],
        'is_detached': i['is_detached'] ?? false,
        'series_info': {
          'activity_id': activity['id'],
          'total_instances': 0,
          'instance_number': 0,
          'recurrence_type': activity['recurrence_type'],
        },
      };
    }).toList();
  }

  Future<Map<String, dynamic>?> getInstanceWithResponses(String instanceId, String userId) async {
    // Get instance
    final instances = await _db.client.select(
      'activity_instances',
      filters: {'id': 'eq.$instanceId'},
    );

    if (instances.isEmpty) return null;
    final instance = instances.first;

    // Get activity
    final activities = await _db.client.select(
      'activities',
      filters: {'id': 'eq.${instance['activity_id']}'},
    );

    if (activities.isEmpty) return null;
    final activity = activities.first;

    // Get responses for this instance
    final responses = await _db.client.select(
      'activity_responses',
      filters: {'instance_id': 'eq.$instanceId'},
      order: 'responded_at.asc',
    );

    // Get user info for responders
    final userIds = responses.map((r) => r['user_id'] as String).toList();
    final users = userIds.isNotEmpty
        ? await _db.client.select(
            'users',
            select: 'id,name,avatar_url',
            filters: {'id': 'in.(${userIds.join(',')})'},
          )
        : <Map<String, dynamic>>[];

    // Create user lookup
    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    // Build response list with user info
    final responseList = responses.map((r) {
      final user = userMap[r['user_id']] ?? {};
      return {
        'id': r['id'],
        'user_id': r['user_id'],
        'response': r['response'],
        'comment': r['comment'],
        'responded_at': r['responded_at'],
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
      };
    }).toList();

    // Get user's own response
    final userResponse = responseList.where((r) => r['user_id'] == userId).firstOrNull;

    // Count responses
    final yesCount = responseList.where((r) => r['response'] == 'yes').length;
    final noCount = responseList.where((r) => r['response'] == 'no').length;
    final maybeCount = responseList.where((r) => r['response'] == 'maybe').length;

    // Get series info: count total instances and find position
    final allInstancesInSeries = await _db.client.select(
      'activity_instances',
      select: 'id,date',
      filters: {'activity_id': 'eq.${instance['activity_id']}'},
      order: 'date.asc',
    );

    final totalInstances = allInstancesInSeries.length;
    final instanceNumber = allInstancesInSeries
            .indexWhere((i) => i['id'] == instance['id']) +
        1;

    // Use effective values (override if exists, otherwise activity value)
    final effectiveTitle =
        instance['title_override'] ?? activity['title'];
    final effectiveLocation =
        instance['location_override'] ?? activity['location'];
    final effectiveDescription =
        instance['description_override'] ?? activity['description'];
    final effectiveStartTime =
        instance['start_time_override'] ?? instance['start_time'];
    final effectiveEndTime =
        instance['end_time_override'] ?? instance['end_time'];
    final effectiveDate = instance['date_override'] ?? instance['date'];

    return {
      'id': instance['id'],
      'activity_id': instance['activity_id'],
      'team_id': activity['team_id'],
      'date': effectiveDate,
      'start_time': effectiveStartTime,
      'end_time': effectiveEndTime,
      'status': instance['status'],
      'title': effectiveTitle,
      'type': activity['type'],
      'location': effectiveLocation,
      'description': effectiveDescription,
      'response_type': activity['response_type'],
      'response_deadline_hours': activity['response_deadline_hours'],
      'responses': responseList,
      'user_response': userResponse?['response'],
      'yes_count': yesCount,
      'no_count': noCount,
      'maybe_count': maybeCount,
      'is_detached': instance['is_detached'] ?? false,
      'created_by': activity['created_by'],
      'series_info': {
        'activity_id': activity['id'],
        'total_instances': totalInstances,
        'instance_number': instanceNumber,
        'recurrence_type': activity['recurrence_type'],
      },
      // Include raw override values for edit form
      'title_override': instance['title_override'],
      'location_override': instance['location_override'],
      'description_override': instance['description_override'],
      'start_time_override': instance['start_time_override'],
      'end_time_override': instance['end_time_override'],
      'date_override': instance['date_override'],
    };
  }

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

  Future<String?> getTeamIdForActivity(String activityId) async {
    final result = await _db.client.select(
      'activities',
      select: 'team_id',
      filters: {'id': 'eq.$activityId'},
    );
    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
  }

  Future<void> deleteActivity(String activityId) async {
    await _db.client.delete(
      'activities',
      filters: {'id': 'eq.$activityId'},
    );
  }

  Future<Activity> updateActivity({
    required String activityId,
    required String title,
    required String type,
    String? location,
    String? description,
  }) async {
    final result = await _db.client.update(
      'activities',
      {
        'title': title,
        'type': type,
        'location': location,
        'description': description,
      },
      filters: {'id': 'eq.$activityId'},
    );

    return Activity.fromRow(result.first);
  }

  Future<List<Map<String, dynamic>>> getInstancesByDateRange(
    String teamId, {
    required DateTime from,
    required DateTime to,
    required String userId,
  }) async {
    // Get activities for team
    final activities = await _db.client.select(
      'activities',
      filters: {'team_id': 'eq.$teamId'},
    );

    if (activities.isEmpty) return [];

    // Create activity lookup
    final activityMap = <String, Map<String, dynamic>>{};
    final activityIds = <String>[];
    for (final a in activities) {
      final id = a['id'] as String;
      activityMap[id] = a;
      activityIds.add(id);
    }

    // Get instances within date range
    final fromDate = from.toIso8601String().split('T').first;
    final toDate = to.toIso8601String().split('T').first;

    final instances = await _db.client.select(
      'activity_instances',
      filters: {
        'activity_id': 'in.(${activityIds.join(',')})',
        'date': 'gte.$fromDate',
      },
      order: 'date.asc,start_time.asc',
    );

    // Filter by to date manually (since we need both gte and lte)
    final filteredInstances = instances.where((i) {
      final date = i['date'] as String;
      return date.compareTo(toDate) <= 0;
    }).toList();

    // Get user responses for these instances
    final instanceIds = filteredInstances.map((i) => i['id'] as String).toList();
    final responses = instanceIds.isNotEmpty
        ? await _db.client.select(
            'activity_responses',
            filters: {
              'instance_id': 'in.(${instanceIds.join(',')})',
              'user_id': 'eq.$userId',
            },
          )
        : <Map<String, dynamic>>[];

    // Create response lookup
    final responseMap = <String, String?>{};
    for (final r in responses) {
      responseMap[r['instance_id'] as String] = r['response'] as String?;
    }

    // Get response counts for all instances
    final allResponses = instanceIds.isNotEmpty
        ? await _db.client.select(
            'activity_responses',
            filters: {
              'instance_id': 'in.(${instanceIds.join(',')})',
            },
          )
        : <Map<String, dynamic>>[];

    // Count responses per instance
    final responseCounts = <String, Map<String, int>>{};
    for (final r in allResponses) {
      final iId = r['instance_id'] as String;
      final resp = r['response'] as String?;
      responseCounts[iId] ??= {'yes': 0, 'no': 0, 'maybe': 0};
      if (resp != null && responseCounts[iId]!.containsKey(resp)) {
        responseCounts[iId]![resp] = (responseCounts[iId]![resp] ?? 0) + 1;
      }
    }

    return filteredInstances.map((i) {
      final activity = activityMap[i['activity_id']] ?? {};
      final iId = i['id'] as String;
      final counts = responseCounts[iId] ?? {'yes': 0, 'no': 0, 'maybe': 0};
      // Use effective values
      final effectiveTitle = i['title_override'] ?? activity['title'];
      final effectiveLocation = i['location_override'] ?? activity['location'];
      final effectiveStartTime = i['start_time_override'] ?? i['start_time'];
      final effectiveEndTime = i['end_time_override'] ?? i['end_time'];
      final effectiveDate = i['date_override'] ?? i['date'];
      return {
        'id': iId,
        'activity_id': i['activity_id'],
        'date': effectiveDate,
        'start_time': effectiveStartTime,
        'end_time': effectiveEndTime,
        'status': i['status'],
        'title': effectiveTitle,
        'type': activity['type'],
        'location': effectiveLocation,
        'response_type': activity['response_type'],
        'user_response': responseMap[iId],
        'yes_count': counts['yes'],
        'no_count': counts['no'],
        'maybe_count': counts['maybe'],
        'is_detached': i['is_detached'] ?? false,
        'series_info': {
          'activity_id': activity['id'],
          'total_instances': 0,
          'instance_number': 0,
          'recurrence_type': activity['recurrence_type'],
        },
      };
    }).toList();
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

  /// Get team members to notify about activity changes
  Future<List<String>> getTeamMemberIds(String teamId) async {
    final members = await _db.client.select(
      'team_members',
      select: 'user_id',
      filters: {'team_id': 'eq.$teamId'},
    );
    return members.map((m) => m['user_id'] as String).toList();
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
