import '../../db/database.dart';
import '../../helpers/collection_helpers.dart';
import '../user_service.dart';
import '../../helpers/parsing_helpers.dart';

class ActivityQueryService {
  final Database _db;
  final UserService _userService;

  ActivityQueryService(this._db, this._userService);

  Future<List<Map<String, dynamic>>> getActivitiesForTeam(String teamId) async {
    // Get activities
    final activities = await _db.client.select(
      'activities',
      filters: {'team_id': 'eq.$teamId'},
      order: 'created_at.desc',
    );

    if (activities.isEmpty) return [];

    // Get instance counts for each activity
    final activityIds = activities.map((a) => safeString(a, 'id')).toList();
    final instances = await _db.client.select(
      'activity_instances',
      select: 'activity_id',
      filters: {'activity_id': 'in.(${activityIds.join(',')})'},
    );

    // Count instances per activity
    final instanceCounts = groupByCount(instances, 'activity_id');

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
      final id = safeString(a, 'id');
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
    final instanceIds = instances.map((i) => safeString(i, 'id')).toList();

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
      final iId = safeString(r, 'instance_id');
      final resp = safeStringNullable(r, 'response');
      responseCounts[iId] ??= {'yes': 0, 'no': 0, 'maybe': 0};
      if (resp != null && responseCounts[iId]!.containsKey(resp)) {
        responseCounts[iId]![resp] = (responseCounts[iId]![resp] ?? 0) + 1;
      }
    }

    return instances.map((i) {
      final activity = activityMap[i['activity_id']] ?? {};
      final iId = safeString(i, 'id');
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
    final userIds = responses.map((r) => safeString(r, 'user_id')).toList();
    final userMap = await _userService.getUserMap(userIds);

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
      final id = safeString(a, 'id');
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
      final date = safeString(i, 'date');
      return date.compareTo(toDate) <= 0;
    }).toList();

    // Get all responses for these instances in one query
    final instanceIds = filteredInstances.map((i) => safeString(i, 'id')).toList();
    final allResponses = instanceIds.isNotEmpty
        ? await _db.client.select(
            'activity_responses',
            filters: {
              'instance_id': 'in.(${instanceIds.join(',')})',
            },
          )
        : <Map<String, dynamic>>[];

    // Create user response lookup (filter in memory)
    final responseMap = <String, String?>{};
    for (final r in allResponses) {
      if (r['user_id'] == userId) {
        responseMap[safeString(r, 'instance_id')] = safeStringNullable(r, 'response');
      }
    }

    // Count responses per instance
    final responseCounts = <String, Map<String, int>>{};
    for (final r in allResponses) {
      final iId = safeString(r, 'instance_id');
      final resp = safeStringNullable(r, 'response');
      responseCounts[iId] ??= {'yes': 0, 'no': 0, 'maybe': 0};
      if (resp != null && responseCounts[iId]!.containsKey(resp)) {
        responseCounts[iId]![resp] = (responseCounts[iId]![resp] ?? 0) + 1;
      }
    }

    return filteredInstances.map((i) {
      final activity = activityMap[i['activity_id']] ?? {};
      final iId = safeString(i, 'id');
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
}
