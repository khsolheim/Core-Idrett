import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/activity.dart';

void main() {
  group('SeriesInfo', () {
    test('roundtrip med alle felt populert', () {
      final original = SeriesInfo(
        activityId: 'activity-1',
        totalInstances: 10,
        instanceNumber: 3,
        recurrenceType: RecurrenceType.weekly,
      );

      // SeriesInfo doesn't have toJson(), so we need to manually construct it
      final jsonMap = {
        'activity_id': original.activityId,
        'total_instances': original.totalInstances,
        'instance_number': original.instanceNumber,
        'recurrence_type': original.recurrenceType.toApiString(),
      };
      final decoded = SeriesInfo.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // SeriesInfo har ingen valgfrie felt
      final original = SeriesInfo(
        activityId: 'activity-2',
        totalInstances: 1,
        instanceNumber: 1,
        recurrenceType: RecurrenceType.once,
      );

      final jsonMap = {
        'activity_id': original.activityId,
        'total_instances': original.totalInstances,
        'instance_number': original.instanceNumber,
        'recurrence_type': original.recurrenceType.toApiString(),
      };
      final decoded = SeriesInfo.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });

  group('Activity', () {
    test('roundtrip med alle felt populert', () {
      final original = Activity(
        id: 'activity-1',
        teamId: 'team-1',
        title: 'Onsdagstrening',
        type: ActivityType.training,
        location: 'Lerkendal Stadion',
        description: 'Intensiv økt med fokus på teknikk',
        recurrenceType: RecurrenceType.weekly,
        recurrenceEndDate: DateTime.parse('2024-12-31T00:00:00.000Z'),
        responseType: ResponseType.yesNoMaybe,
        responseDeadlineHours: 24,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        instanceCount: 48,
      );

      // Activity doesn't have toJson(), so we need to manually construct it
      final jsonMap = {
        'id': original.id,
        'team_id': original.teamId,
        'title': original.title,
        'type': original.type.toApiString(),
        'location': original.location,
        'description': original.description,
        'recurrence_type': original.recurrenceType.toApiString(),
        'recurrence_end_date': original.recurrenceEndDate?.toIso8601String(),
        'response_type': original.responseType.toApiString(),
        'response_deadline_hours': original.responseDeadlineHours,
        'created_at': original.createdAt.toIso8601String(),
        'instance_count': original.instanceCount,
      };
      final decoded = Activity.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Activity(
        id: 'activity-2',
        teamId: 'team-1',
        title: 'Kamp mot Viking',
        type: ActivityType.match,
        recurrenceType: RecurrenceType.once,
        responseType: ResponseType.yesNo,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final jsonMap = {
        'id': original.id,
        'team_id': original.teamId,
        'title': original.title,
        'type': original.type.toApiString(),
        'recurrence_type': original.recurrenceType.toApiString(),
        'response_type': original.responseType.toApiString(),
        'created_at': original.createdAt.toIso8601String(),
      };
      final decoded = Activity.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });

  group('ActivityResponseItem', () {
    test('roundtrip med alle felt populert', () {
      final original = ActivityResponseItem(
        id: 'response-1',
        userId: 'user-1',
        response: UserResponse.yes,
        comment: 'Kommer definitivt!',
        respondedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
      );

      // ActivityResponseItem doesn't have toJson(), construct manually
      final jsonMap = {
        'id': original.id,
        'user_id': original.userId,
        'response': original.response?.toApiString(),
        'comment': original.comment,
        'responded_at': original.respondedAt.toIso8601String(),
        'user_name': original.userName,
        'user_avatar_url': original.userAvatarUrl,
      };
      final decoded = ActivityResponseItem.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ActivityResponseItem(
        id: 'response-2',
        userId: 'user-2',
        respondedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      final jsonMap = {
        'id': original.id,
        'user_id': original.userId,
        'responded_at': original.respondedAt.toIso8601String(),
      };
      final decoded = ActivityResponseItem.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });

  group('ActivityInstance', () {
    test('roundtrip med alle felt populert', () {
      final responses = [
        ActivityResponseItem(
          id: 'response-1',
          userId: 'user-1',
          response: UserResponse.yes,
          respondedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
          userName: 'Ola Nordmann',
        ),
      ];

      final seriesInfo = SeriesInfo(
        activityId: 'activity-1',
        totalInstances: 10,
        instanceNumber: 3,
        recurrenceType: RecurrenceType.weekly,
      );

      final original = ActivityInstance(
        id: 'instance-1',
        activityId: 'activity-1',
        teamId: 'team-1',
        date: DateTime.parse('2024-01-17T00:00:00.000Z'),
        startTime: '18:00',
        endTime: '20:00',
        status: InstanceStatus.scheduled,
        cancelledReason: null,
        title: 'Onsdagstrening',
        type: ActivityType.training,
        location: 'Lerkendal Stadion',
        description: 'Intensiv økt',
        responseType: ResponseType.yesNoMaybe,
        responseDeadlineHours: 24,
        responses: responses,
        userResponse: UserResponse.yes,
        yesCount: 15,
        noCount: 2,
        maybeCount: 3,
        isDetached: false,
        seriesInfo: seriesInfo,
        createdBy: 'user-admin',
        titleOverride: 'Endret tittel',
        locationOverride: 'Ny lokasjon',
        descriptionOverride: 'Endret beskrivelse',
        startTimeOverride: '17:30',
        endTimeOverride: '19:30',
        dateOverride: '2024-01-18',
      );

      // ActivityInstance doesn't have toJson(), construct manually
      final jsonMap = {
        'id': original.id,
        'activity_id': original.activityId,
        'team_id': original.teamId,
        'date': original.date.toIso8601String(),
        'start_time': original.startTime,
        'end_time': original.endTime,
        'status': original.status.name,
        'cancelled_reason': original.cancelledReason,
        'title': original.title,
        'type': original.type?.toApiString(),
        'location': original.location,
        'description': original.description,
        'response_type': original.responseType?.toApiString(),
        'response_deadline_hours': original.responseDeadlineHours,
        'responses': responses.map((r) => {
          'id': r.id,
          'user_id': r.userId,
          'response': r.response?.toApiString(),
          'comment': r.comment,
          'responded_at': r.respondedAt.toIso8601String(),
          'user_name': r.userName,
          'user_avatar_url': r.userAvatarUrl,
        }).toList(),
        'user_response': original.userResponse?.toApiString(),
        'yes_count': original.yesCount,
        'no_count': original.noCount,
        'maybe_count': original.maybeCount,
        'is_detached': original.isDetached,
        'series_info': {
          'activity_id': seriesInfo.activityId,
          'total_instances': seriesInfo.totalInstances,
          'instance_number': seriesInfo.instanceNumber,
          'recurrence_type': seriesInfo.recurrenceType.toApiString(),
        },
        'created_by': original.createdBy,
        'title_override': original.titleOverride,
        'location_override': original.locationOverride,
        'description_override': original.descriptionOverride,
        'start_time_override': original.startTimeOverride,
        'end_time_override': original.endTimeOverride,
        'date_override': original.dateOverride,
      };
      final decoded = ActivityInstance.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ActivityInstance(
        id: 'instance-2',
        activityId: 'activity-2',
        date: DateTime.parse('2024-01-17T00:00:00.000Z'),
        status: InstanceStatus.scheduled,
      );

      final jsonMap = {
        'id': original.id,
        'activity_id': original.activityId,
        'date': original.date.toIso8601String(),
        'status': original.status.name,
      };
      final decoded = ActivityInstance.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });

  group('InstanceOperationResult', () {
    test('roundtrip med alle felt populert', () {
      final original = InstanceOperationResult(
        affectedCount: 5,
        affectedInstanceIds: ['inst-1', 'inst-2', 'inst-3', 'inst-4', 'inst-5'],
        activityId: 'activity-1',
      );

      final jsonMap = {
        'updated_count': original.affectedCount,
        'affected_instance_ids': original.affectedInstanceIds,
        'activity_id': original.activityId,
      };
      final decoded = InstanceOperationResult.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // InstanceOperationResult har ingen valgfrie felt
      final original = InstanceOperationResult(
        affectedCount: 1,
        affectedInstanceIds: ['inst-1'],
        activityId: 'activity-2',
      );

      final jsonMap = {
        'deleted_count': original.affectedCount,
        'affected_instance_ids': original.affectedInstanceIds,
        'activity_id': original.activityId,
      };
      final decoded = InstanceOperationResult.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });
}
