import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

class DeviceToken extends Equatable {
  final String id;
  final String userId;
  final String token;
  final String platform;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  const DeviceToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    required this.createdAt,
    required this.lastUsedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        token,
        platform,
        createdAt,
        lastUsedAt,
      ];

  factory DeviceToken.fromJson(Map<String, dynamic> row) {
    return DeviceToken(
      id: safeString(row, 'id'),
      userId: safeString(row, 'user_id'),
      token: safeString(row, 'token'),
      platform: safeString(row, 'platform'),
      createdAt: requireDateTime(row, 'created_at'),
      lastUsedAt: requireDateTime(row, 'last_used_at'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'token': token,
        'platform': platform,
        'created_at': createdAt.toIso8601String(),
        'last_used_at': lastUsedAt.toIso8601String(),
      };
}

class NotificationPreferences extends Equatable {
  final String id;
  final String userId;
  final String? teamId;
  final bool newActivity;
  final bool activityReminder;
  final bool activityCancelled;
  final bool activityUpdated;
  final bool newFine;
  final bool fineDecision;
  final bool teamMessage;

  const NotificationPreferences({
    required this.id,
    required this.userId,
    this.teamId,
    required this.newActivity,
    required this.activityReminder,
    required this.activityCancelled,
    required this.activityUpdated,
    required this.newFine,
    required this.fineDecision,
    required this.teamMessage,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        teamId,
        newActivity,
        activityReminder,
        activityCancelled,
        activityUpdated,
        newFine,
        fineDecision,
        teamMessage,
      ];

  factory NotificationPreferences.fromJson(Map<String, dynamic> row) {
    return NotificationPreferences(
      id: safeString(row, 'id'),
      userId: safeString(row, 'user_id'),
      teamId: safeStringNullable(row, 'team_id'),
      newActivity: safeBool(row, 'new_activity', defaultValue: true),
      activityReminder: safeBool(row, 'activity_reminder', defaultValue: true),
      activityCancelled: safeBool(row, 'activity_cancelled', defaultValue: true),
      activityUpdated: safeBool(row, 'activity_updated', defaultValue: true),
      newFine: safeBool(row, 'new_fine', defaultValue: true),
      fineDecision: safeBool(row, 'fine_decision', defaultValue: true),
      teamMessage: safeBool(row, 'team_message', defaultValue: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'team_id': teamId,
        'new_activity': newActivity,
        'activity_reminder': activityReminder,
        'activity_cancelled': activityCancelled,
        'activity_updated': activityUpdated,
        'new_fine': newFine,
        'fine_decision': fineDecision,
        'team_message': teamMessage,
      };

  NotificationPreferences copyWith({
    bool? newActivity,
    bool? activityReminder,
    bool? activityCancelled,
    bool? activityUpdated,
    bool? newFine,
    bool? fineDecision,
    bool? teamMessage,
  }) {
    return NotificationPreferences(
      id: id,
      userId: userId,
      teamId: teamId,
      newActivity: newActivity ?? this.newActivity,
      activityReminder: activityReminder ?? this.activityReminder,
      activityCancelled: activityCancelled ?? this.activityCancelled,
      activityUpdated: activityUpdated ?? this.activityUpdated,
      newFine: newFine ?? this.newFine,
      fineDecision: fineDecision ?? this.fineDecision,
      teamMessage: teamMessage ?? this.teamMessage,
    );
  }
}

enum NotificationType {
  newActivity,
  activityReminder,
  activityCancelled,
  activityUpdated,
  newFine,
  fineDecision,
  teamMessage;

  String get prefKey {
    switch (this) {
      case NotificationType.newActivity:
        return 'new_activity';
      case NotificationType.activityReminder:
        return 'activity_reminder';
      case NotificationType.activityCancelled:
        return 'activity_cancelled';
      case NotificationType.activityUpdated:
        return 'activity_updated';
      case NotificationType.newFine:
        return 'new_fine';
      case NotificationType.fineDecision:
        return 'fine_decision';
      case NotificationType.teamMessage:
        return 'team_message';
    }
  }
}
