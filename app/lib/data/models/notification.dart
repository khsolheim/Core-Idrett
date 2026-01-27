class NotificationPreferences {
  final String id;
  final String userId;
  final String? teamId;
  final bool newActivity;
  final bool activityReminder;
  final bool activityCancelled;
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
    required this.newFine,
    required this.fineDecision,
    required this.teamMessage,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      teamId: json['team_id'] as String?,
      newActivity: json['new_activity'] as bool? ?? true,
      activityReminder: json['activity_reminder'] as bool? ?? true,
      activityCancelled: json['activity_cancelled'] as bool? ?? true,
      newFine: json['new_fine'] as bool? ?? true,
      fineDecision: json['fine_decision'] as bool? ?? true,
      teamMessage: json['team_message'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'team_id': teamId,
        'new_activity': newActivity,
        'activity_reminder': activityReminder,
        'activity_cancelled': activityCancelled,
        'new_fine': newFine,
        'fine_decision': fineDecision,
        'team_message': teamMessage,
      };

  NotificationPreferences copyWith({
    bool? newActivity,
    bool? activityReminder,
    bool? activityCancelled,
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
      newFine: newFine ?? this.newFine,
      fineDecision: fineDecision ?? this.fineDecision,
      teamMessage: teamMessage ?? this.teamMessage,
    );
  }
}

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

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      token: json['token'] as String,
      platform: json['platform'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsedAt: DateTime.parse(json['last_used_at'] as String),
    );
  }
}
