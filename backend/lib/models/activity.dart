class Activity {
  final String id;
  final String teamId;
  final String title;
  final String type;
  final String? location;
  final String? description;
  final String recurrenceType;
  final DateTime? recurrenceEndDate;
  final String responseType;
  final int? responseDeadlineHours;
  final String? createdBy;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.teamId,
    required this.title,
    required this.type,
    this.location,
    this.description,
    required this.recurrenceType,
    this.recurrenceEndDate,
    required this.responseType,
    this.responseDeadlineHours,
    this.createdBy,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> row) {
    return Activity(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      title: row['title'] as String,
      type: row['type'] as String,
      location: row['location'] as String?,
      description: row['description'] as String?,
      recurrenceType: row['recurrence_type'] as String? ?? 'once',
      recurrenceEndDate: row['recurrence_end_date'] as DateTime?,
      responseType: row['response_type'] as String? ?? 'yes_no',
      responseDeadlineHours: row['response_deadline_hours'] as int?,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ActivityInstance {
  final String id;
  final String activityId;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String status;
  final String? cancelledReason;

  ActivityInstance({
    required this.id,
    required this.activityId,
    required this.date,
    this.startTime,
    this.endTime,
    required this.status,
    this.cancelledReason,
  });

  factory ActivityInstance.fromJson(Map<String, dynamic> row) {
    return ActivityInstance(
      id: row['id'] as String,
      activityId: row['activity_id'] as String,
      date: row['date'] as DateTime,
      startTime: row['start_time']?.toString(),
      endTime: row['end_time']?.toString(),
      status: row['status'] as String? ?? 'scheduled',
      cancelledReason: row['cancelled_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'date': date.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'cancelled_reason': cancelledReason,
    };
  }
}

class ActivityResponse {
  final String id;
  final String instanceId;
  final String userId;
  final String? response;
  final String? comment;
  final DateTime respondedAt;

  ActivityResponse({
    required this.id,
    required this.instanceId,
    required this.userId,
    this.response,
    this.comment,
    required this.respondedAt,
  });

  factory ActivityResponse.fromJson(Map<String, dynamic> row) {
    return ActivityResponse(
      id: row['id'] as String,
      instanceId: row['instance_id'] as String,
      userId: row['user_id'] as String,
      response: row['response'] as String?,
      comment: row['comment'] as String?,
      respondedAt: row['responded_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instance_id': instanceId,
      'user_id': userId,
      'response': response,
      'comment': comment,
      'responded_at': respondedAt.toIso8601String(),
    };
  }
}
