class DeviceToken {
  final String id;
  final String userId;
  final String token;
  final String platform;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  DeviceToken({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    required this.createdAt,
    required this.lastUsedAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> row) {
    return DeviceToken(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      token: row['token'] as String,
      platform: row['platform'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      lastUsedAt: DateTime.parse(row['last_used_at'] as String),
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

class NotificationPreferences {
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

  NotificationPreferences({
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

  factory NotificationPreferences.fromJson(Map<String, dynamic> row) {
    return NotificationPreferences(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      teamId: row['team_id'] as String?,
      newActivity: row['new_activity'] as bool? ?? true,
      activityReminder: row['activity_reminder'] as bool? ?? true,
      activityCancelled: row['activity_cancelled'] as bool? ?? true,
      activityUpdated: row['activity_updated'] as bool? ?? true,
      newFine: row['new_fine'] as bool? ?? true,
      fineDecision: row['fine_decision'] as bool? ?? true,
      teamMessage: row['team_message'] as bool? ?? true,
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
