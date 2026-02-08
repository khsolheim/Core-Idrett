import 'package:equatable/equatable.dart';

enum ActivityType {
  training,
  match,
  social,
  other;

  String get displayName {
    switch (this) {
      case ActivityType.training:
        return 'Trening';
      case ActivityType.match:
        return 'Kamp';
      case ActivityType.social:
        return 'Sosialt';
      case ActivityType.other:
        return 'Annet';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.training:
        return 'fitness_center';
      case ActivityType.match:
        return 'sports_soccer';
      case ActivityType.social:
        return 'celebration';
      case ActivityType.other:
        return 'event';
    }
  }

  static ActivityType fromString(String type) {
    switch (type) {
      case 'training':
        return ActivityType.training;
      case 'match':
        return ActivityType.match;
      case 'social':
        return ActivityType.social;
      default:
        return ActivityType.other;
    }
  }

  String toApiString() => name;
}

enum RecurrenceType {
  once,
  weekly,
  biweekly,
  monthly;

  String get displayName {
    switch (this) {
      case RecurrenceType.once:
        return 'Én gang';
      case RecurrenceType.weekly:
        return 'Ukentlig';
      case RecurrenceType.biweekly:
        return 'Annenhver uke';
      case RecurrenceType.monthly:
        return 'Månedlig';
    }
  }

  static RecurrenceType fromString(String type) {
    switch (type) {
      case 'weekly':
        return RecurrenceType.weekly;
      case 'biweekly':
        return RecurrenceType.biweekly;
      case 'monthly':
        return RecurrenceType.monthly;
      default:
        return RecurrenceType.once;
    }
  }

  String toApiString() => name;
}

enum ResponseType {
  yesNo,
  yesNoMaybe,
  withDeadline,
  optOut;

  String get displayName {
    switch (this) {
      case ResponseType.yesNo:
        return 'Ja/Nei';
      case ResponseType.yesNoMaybe:
        return 'Ja/Nei/Kanskje';
      case ResponseType.withDeadline:
        return 'Med frist';
      case ResponseType.optOut:
        return 'Meld fra ved forfall';
    }
  }

  static ResponseType fromString(String type) {
    switch (type) {
      case 'yes_no':
        return ResponseType.yesNo;
      case 'yes_no_maybe':
        return ResponseType.yesNoMaybe;
      case 'with_deadline':
        return ResponseType.withDeadline;
      case 'opt_out':
        return ResponseType.optOut;
      default:
        return ResponseType.yesNo;
    }
  }

  String toApiString() {
    switch (this) {
      case ResponseType.yesNo:
        return 'yes_no';
      case ResponseType.yesNoMaybe:
        return 'yes_no_maybe';
      case ResponseType.withDeadline:
        return 'with_deadline';
      case ResponseType.optOut:
        return 'opt_out';
    }
  }
}

enum InstanceStatus {
  scheduled,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case InstanceStatus.scheduled:
        return 'Planlagt';
      case InstanceStatus.completed:
        return 'Fullført';
      case InstanceStatus.cancelled:
        return 'Avlyst';
    }
  }

  static InstanceStatus fromString(String status) {
    switch (status) {
      case 'completed':
        return InstanceStatus.completed;
      case 'cancelled':
        return InstanceStatus.cancelled;
      default:
        return InstanceStatus.scheduled;
    }
  }
}

enum UserResponse {
  yes,
  no,
  maybe;

  String get displayName {
    switch (this) {
      case UserResponse.yes:
        return 'Ja';
      case UserResponse.no:
        return 'Nei';
      case UserResponse.maybe:
        return 'Kanskje';
    }
  }

  static UserResponse? fromString(String? response) {
    switch (response) {
      case 'yes':
        return UserResponse.yes;
      case 'no':
        return UserResponse.no;
      case 'maybe':
        return UserResponse.maybe;
      default:
        return null;
    }
  }

  String toApiString() => name;
}

/// Scope for editing/deleting activity instances in a series
enum EditScope {
  single,
  thisAndFuture;

  String get displayName {
    switch (this) {
      case EditScope.single:
        return 'Kun denne';
      case EditScope.thisAndFuture:
        return 'Denne og fremtidige';
    }
  }

  String get description {
    switch (this) {
      case EditScope.single:
        return 'Bare denne aktiviteten endres';
      case EditScope.thisAndFuture:
        return 'Denne og alle fremtidige aktiviteter i serien endres';
    }
  }

  String toApiString() {
    switch (this) {
      case EditScope.single:
        return 'single';
      case EditScope.thisAndFuture:
        return 'this_and_future';
    }
  }
}

/// Information about an instance's position in a series
class SeriesInfo extends Equatable {
  final String activityId;
  final int totalInstances;
  final int instanceNumber;
  final RecurrenceType recurrenceType;

  const SeriesInfo({
    required this.activityId,
    required this.totalInstances,
    required this.instanceNumber,
    required this.recurrenceType,
  });

  factory SeriesInfo.fromJson(Map<String, dynamic> json) {
    return SeriesInfo(
      activityId: json['activity_id'] as String,
      totalInstances: json['total_instances'] as int,
      instanceNumber: json['instance_number'] as int,
      recurrenceType: RecurrenceType.fromString(json['recurrence_type'] as String? ?? 'once'),
    );
  }

  /// Whether this instance is part of a recurring series
  bool get isPartOfSeries => recurrenceType != RecurrenceType.once;

  /// Display string like "3 av 10"
  String get positionText => '$instanceNumber av $totalInstances';

  @override
  List<Object?> get props => [activityId, totalInstances, instanceNumber, recurrenceType];
}

class Activity extends Equatable {
  final String id;
  final String teamId;
  final String title;
  final ActivityType type;
  final String? location;
  final String? description;
  final RecurrenceType recurrenceType;
  final DateTime? recurrenceEndDate;
  final ResponseType responseType;
  final int? responseDeadlineHours;
  final DateTime createdAt;
  final int? instanceCount;

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
    required this.createdAt,
    this.instanceCount,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      title: json['title'] as String,
      type: ActivityType.fromString(json['type'] as String),
      location: json['location'] as String?,
      description: json['description'] as String?,
      recurrenceType: RecurrenceType.fromString(json['recurrence_type'] as String? ?? 'once'),
      recurrenceEndDate: json['recurrence_end_date'] != null
          ? DateTime.parse(json['recurrence_end_date'] as String)
          : null,
      responseType: ResponseType.fromString(json['response_type'] as String? ?? 'yes_no'),
      responseDeadlineHours: json['response_deadline_hours'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      instanceCount: json['instance_count'] as int?,
    );
  }

  @override
  List<Object?> get props => [id, teamId, title, type, location, description, recurrenceType, recurrenceEndDate, responseType, responseDeadlineHours, createdAt, instanceCount];
}

class ActivityInstance extends Equatable {
  final String id;
  final String activityId;
  final String? teamId;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final InstanceStatus status;
  final String? cancelledReason;
  final String? title;
  final ActivityType? type;
  final String? location;
  final String? description;
  final ResponseType? responseType;
  final int? responseDeadlineHours;
  final List<ActivityResponseItem>? responses;
  final UserResponse? userResponse;
  final int? yesCount;
  final int? noCount;
  final int? maybeCount;

  // Series management fields
  final bool isDetached;
  final SeriesInfo? seriesInfo;
  final String? createdBy;

  // Raw override values (for edit form)
  final String? titleOverride;
  final String? locationOverride;
  final String? descriptionOverride;
  final String? startTimeOverride;
  final String? endTimeOverride;
  final String? dateOverride;

  const ActivityInstance({
    required this.id,
    required this.activityId,
    this.teamId,
    required this.date,
    this.startTime,
    this.endTime,
    required this.status,
    this.cancelledReason,
    this.title,
    this.type,
    this.location,
    this.description,
    this.responseType,
    this.responseDeadlineHours,
    this.responses,
    this.userResponse,
    this.yesCount,
    this.noCount,
    this.maybeCount,
    this.isDetached = false,
    this.seriesInfo,
    this.createdBy,
    this.titleOverride,
    this.locationOverride,
    this.descriptionOverride,
    this.startTimeOverride,
    this.endTimeOverride,
    this.dateOverride,
  });

  factory ActivityInstance.fromJson(Map<String, dynamic> json) {
    List<ActivityResponseItem>? responses;
    if (json['responses'] != null) {
      responses = (json['responses'] as List)
          .map((r) => ActivityResponseItem.fromJson(r as Map<String, dynamic>))
          .toList();
    }

    SeriesInfo? seriesInfo;
    if (json['series_info'] != null) {
      seriesInfo = SeriesInfo.fromJson(json['series_info'] as Map<String, dynamic>);
    }

    return ActivityInstance(
      id: json['id'] as String,
      activityId: json['activity_id'] as String,
      teamId: json['team_id'] as String?,
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      status: InstanceStatus.fromString(json['status'] as String? ?? 'scheduled'),
      cancelledReason: json['cancelled_reason'] as String?,
      title: json['title'] as String?,
      type: json['type'] != null ? ActivityType.fromString(json['type'] as String) : null,
      location: json['location'] as String?,
      description: json['description'] as String?,
      responseType: json['response_type'] != null
          ? ResponseType.fromString(json['response_type'] as String)
          : null,
      responseDeadlineHours: json['response_deadline_hours'] as int?,
      responses: responses,
      userResponse: UserResponse.fromString(json['user_response'] as String?),
      yesCount: json['yes_count'] as int?,
      noCount: json['no_count'] as int?,
      maybeCount: json['maybe_count'] as int?,
      isDetached: json['is_detached'] as bool? ?? false,
      seriesInfo: seriesInfo,
      createdBy: json['created_by'] as String?,
      titleOverride: json['title_override'] as String?,
      locationOverride: json['location_override'] as String?,
      descriptionOverride: json['description_override'] as String?,
      startTimeOverride: json['start_time_override'] as String?,
      endTimeOverride: json['end_time_override'] as String?,
      dateOverride: json['date_override'] as String?,
    );
  }

  String get formattedTime {
    if (startTime == null) return '';
    if (endTime == null) return startTime!;
    return '$startTime - $endTime';
  }

  /// Whether this instance is part of a recurring series
  bool get isPartOfSeries => seriesInfo?.isPartOfSeries ?? false;

  /// Whether this instance has any overrides from the parent activity
  bool get hasOverrides =>
      titleOverride != null ||
      locationOverride != null ||
      descriptionOverride != null ||
      startTimeOverride != null ||
      endTimeOverride != null ||
      dateOverride != null;

  @override
  List<Object?> get props => [
    id, activityId, teamId, date, startTime, endTime, status, cancelledReason,
    title, type, location, description, responseType, responseDeadlineHours,
    responses, userResponse, yesCount, noCount, maybeCount, isDetached,
    seriesInfo, createdBy, titleOverride, locationOverride, descriptionOverride,
    startTimeOverride, endTimeOverride, dateOverride
  ];
}

class ActivityResponseItem extends Equatable {
  final String id;
  final String userId;
  final UserResponse? response;
  final String? comment;
  final DateTime respondedAt;
  final String? userName;
  final String? userAvatarUrl;

  const ActivityResponseItem({
    required this.id,
    required this.userId,
    this.response,
    this.comment,
    required this.respondedAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory ActivityResponseItem.fromJson(Map<String, dynamic> json) {
    return ActivityResponseItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      response: UserResponse.fromString(json['response'] as String?),
      comment: json['comment'] as String?,
      respondedAt: DateTime.parse(json['responded_at'] as String),
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, userId, response, comment, respondedAt, userName, userAvatarUrl];
}

/// Result of an instance edit or delete operation
class InstanceOperationResult extends Equatable {
  final int affectedCount;
  final List<String> affectedInstanceIds;
  final String activityId;

  const InstanceOperationResult({
    required this.affectedCount,
    required this.affectedInstanceIds,
    required this.activityId,
  });

  factory InstanceOperationResult.fromJson(Map<String, dynamic> json) {
    return InstanceOperationResult(
      affectedCount: (json['updated_count'] ?? json['deleted_count']) as int,
      affectedInstanceIds: (json['affected_instance_ids'] as List).cast<String>(),
      activityId: json['activity_id'] as String,
    );
  }

  @override
  List<Object?> get props => [affectedCount, affectedInstanceIds, activityId];
}
