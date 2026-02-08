import 'package:test/test.dart';
import 'package:core_idrett_backend/models/activity.dart';

void main() {
  group('Activity', () {
    test('roundtrip med alle felt populert', () {
      final original = Activity(
        id: 'activity-1',
        teamId: 'team-1',
        title: 'Tirsdagstrening',
        type: 'training',
        location: 'Intility Arena',
        description: 'Teknisk trening med fokus på pasningsspill',
        recurrenceType: 'weekly',
        recurrenceEndDate: DateTime.parse('2024-06-30T00:00:00.000Z'),
        responseType: 'yes_no_maybe',
        responseDeadlineHours: 24,
        createdBy: 'user-1',
        createdAt: DateTime.parse('2024-01-10T10:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: Activity.fromJson expects DateTime objects
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      if (json['recurrence_end_date'] != null) {
        json['recurrence_end_date'] = DateTime.parse(json['recurrence_end_date'] as String);
      }
      final decoded = Activity.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Activity(
        id: 'activity-2',
        teamId: 'team-2',
        title: 'Søndagskamp',
        type: 'match',
        // location is null
        // description is null
        recurrenceType: 'once',
        // recurrenceEndDate is null
        responseType: 'yes_no',
        // responseDeadlineHours is null
        // createdBy is null
        createdAt: DateTime.parse('2024-02-15T14:30:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: Activity.fromJson expects DateTime object
      json['created_at'] = DateTime.parse(json['created_at'] as String);
      final decoded = Activity.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('ActivityInstance', () {
    test('roundtrip med alle felt populert', () {
      final original = ActivityInstance(
        id: 'instance-1',
        activityId: 'activity-1',
        date: DateTime(2024, 3, 12),
        startTime: '18:00',
        endTime: '20:00',
        status: 'scheduled',
        cancelledReason: null,
      );

      final json = original.toJson();
      // Fix DateTime: ActivityInstance.fromJson expects DateTime object
      json['date'] = DateTime.parse(json['date'] as String);
      final decoded = ActivityInstance.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ActivityInstance(
        id: 'instance-2',
        activityId: 'activity-2',
        date: DateTime(2024, 3, 15),
        // startTime is null
        // endTime is null
        status: 'completed',
        // cancelledReason is null
      );

      final json = original.toJson();
      // Fix DateTime: ActivityInstance.fromJson expects DateTime object
      json['date'] = DateTime.parse(json['date'] as String);
      final decoded = ActivityInstance.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('ActivityResponse', () {
    test('roundtrip med alle felt populert', () {
      final original = ActivityResponse(
        id: 'response-1',
        instanceId: 'instance-1',
        userId: 'user-1',
        response: 'yes',
        comment: 'Kommer gjerne!',
        respondedAt: DateTime.parse('2024-03-10T15:30:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: ActivityResponse.fromJson expects DateTime object
      json['responded_at'] = DateTime.parse(json['responded_at'] as String);
      final decoded = ActivityResponse.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ActivityResponse(
        id: 'response-2',
        instanceId: 'instance-2',
        userId: 'user-2',
        // response is null
        // comment is null
        respondedAt: DateTime.parse('2024-03-14T09:00:00.000Z'),
      );

      final json = original.toJson();
      // Fix DateTime: ActivityResponse.fromJson expects DateTime object
      json['responded_at'] = DateTime.parse(json['responded_at'] as String);
      final decoded = ActivityResponse.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
