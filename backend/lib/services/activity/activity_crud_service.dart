import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/activity.dart';
import '../../helpers/parsing_helpers.dart';

class ActivityCrudService {
  final Database _db;
  final _uuid = const Uuid();

  ActivityCrudService(this._db);

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
      final userId = safeString(member, 'user_id');
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

  Future<String?> getTeamIdForActivity(String activityId) async {
    final result = await _db.client.select(
      'activities',
      select: 'team_id',
      filters: {'id': 'eq.$activityId'},
    );
    if (result.isEmpty) return null;
    return safeStringNullable(result.first, 'team_id');
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

    return Activity.fromJson(result.first);
  }

  /// Get team members to notify about activity changes
  Future<List<String>> getTeamMemberIds(String teamId) async {
    final members = await _db.client.select(
      'team_members',
      select: 'user_id',
      filters: {'team_id': 'eq.$teamId'},
    );
    return members.map((m) => safeString(m, 'user_id')).toList();
  }
}
