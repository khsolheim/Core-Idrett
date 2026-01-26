import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/activity.dart';

class ActivityService {
  final Database _db;
  final _uuid = const Uuid();

  ActivityService(this._db);

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
      recurrenceType: recurrenceType,
      firstDate: firstDate,
      endDate: recurrenceEndDate,
      startTime: startTime,
      endTime: endTime,
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
    required String recurrenceType,
    required DateTime firstDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
  }) async {
    final dates = _calculateDates(recurrenceType, firstDate, endDate);

    for (final date in dates) {
      await _db.client.insert('activity_instances', {
        'id': _uuid.v4(),
        'activity_id': activityId,
        'date': date.toIso8601String().split('T').first,
        'start_time': startTime,
        'end_time': endTime,
        'status': 'scheduled',
      });
    }
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

    return instances.map((i) {
      final activity = activityMap[i['activity_id']] ?? {};
      return {
        'id': i['id'],
        'activity_id': i['activity_id'],
        'date': i['date'],
        'start_time': i['start_time'],
        'end_time': i['end_time'],
        'status': i['status'],
        'title': activity['title'],
        'type': activity['type'],
        'location': activity['location'],
        'response_type': activity['response_type'],
        'response_deadline_hours': activity['response_deadline_hours'],
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

    return {
      'id': instance['id'],
      'activity_id': instance['activity_id'],
      'team_id': activity['team_id'],
      'date': instance['date'],
      'start_time': instance['start_time'],
      'end_time': instance['end_time'],
      'status': instance['status'],
      'title': activity['title'],
      'type': activity['type'],
      'location': activity['location'],
      'description': activity['description'],
      'response_type': activity['response_type'],
      'response_deadline_hours': activity['response_deadline_hours'],
      'responses': responseList,
      'user_response': userResponse?['response'],
      'yes_count': yesCount,
      'no_count': noCount,
      'maybe_count': maybeCount,
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
      select: '*',
    );

    return Activity.fromRow(result.first);
  }
}
