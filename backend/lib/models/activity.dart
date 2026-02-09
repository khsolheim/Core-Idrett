import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

class Activity extends Equatable {
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

  const Activity({
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

  @override
  List<Object?> get props => [
        id,
        teamId,
        title,
        type,
        location,
        description,
        recurrenceType,
        recurrenceEndDate,
        responseType,
        responseDeadlineHours,
        createdBy,
        createdAt,
      ];

  factory Activity.fromJson(Map<String, dynamic> row) {
    return Activity(
      id: safeString(row, 'id'),
      teamId: safeString(row, 'team_id'),
      title: safeString(row, 'title'),
      type: safeString(row, 'type'),
      location: safeStringNullable(row, 'location'),
      description: safeStringNullable(row, 'description'),
      recurrenceType: safeString(row, 'recurrence_type', defaultValue: 'once'),
      recurrenceEndDate: safeDateTimeNullable(row, 'recurrence_end_date'),
      responseType: safeString(row, 'response_type', defaultValue: 'yes_no'),
      responseDeadlineHours: safeIntNullable(row, 'response_deadline_hours'),
      createdBy: safeStringNullable(row, 'created_by'),
      createdAt: requireDateTime(row, 'created_at'),
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

class ActivityInstance extends Equatable {
  final String id;
  final String activityId;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final String status;
  final String? cancelledReason;

  const ActivityInstance({
    required this.id,
    required this.activityId,
    required this.date,
    this.startTime,
    this.endTime,
    required this.status,
    this.cancelledReason,
  });

  @override
  List<Object?> get props => [
        id,
        activityId,
        date,
        startTime,
        endTime,
        status,
        cancelledReason,
      ];

  factory ActivityInstance.fromJson(Map<String, dynamic> row) {
    return ActivityInstance(
      id: safeString(row, 'id'),
      activityId: safeString(row, 'activity_id'),
      date: requireDateTime(row, 'date'),
      startTime: row['start_time']?.toString(),
      endTime: row['end_time']?.toString(),
      status: safeString(row, 'status', defaultValue: 'scheduled'),
      cancelledReason: safeStringNullable(row, 'cancelled_reason'),
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

class ActivityResponse extends Equatable {
  final String id;
  final String instanceId;
  final String userId;
  final String? response;
  final String? comment;
  final DateTime respondedAt;

  const ActivityResponse({
    required this.id,
    required this.instanceId,
    required this.userId,
    this.response,
    this.comment,
    required this.respondedAt,
  });

  @override
  List<Object?> get props => [
        id,
        instanceId,
        userId,
        response,
        comment,
        respondedAt,
      ];

  factory ActivityResponse.fromJson(Map<String, dynamic> row) {
    return ActivityResponse(
      id: safeString(row, 'id'),
      instanceId: safeString(row, 'instance_id'),
      userId: safeString(row, 'user_id'),
      response: safeStringNullable(row, 'response'),
      comment: safeStringNullable(row, 'comment'),
      respondedAt: requireDateTime(row, 'responded_at'),
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
