/// Type of conversation
enum ConversationType {
  team,
  direct,
}

/// Unified conversation model for both team chat and direct messages
class ChatConversation {
  final ConversationType type;
  final String? teamId;
  final String? recipientId;
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ChatConversation({
    required this.type,
    this.teamId,
    this.recipientId,
    required this.name,
    this.avatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  /// Unique identifier for the conversation
  String get id => teamId ?? recipientId ?? '';

  /// Whether this is a team chat
  bool get isTeamChat => type == ConversationType.team;

  /// Whether this is a direct message conversation
  bool get isDirectMessage => type == ConversationType.direct;

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      type: json['type'] == 'team' ? ConversationType.team : ConversationType.direct,
      teamId: json['team_id'] as String?,
      recipientId: json['recipient_id'] as String?,
      name: json['name'] as String? ?? 'Ukjent',
      avatarUrl: json['avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type == ConversationType.team ? 'team' : 'direct',
        'team_id': teamId,
        'recipient_id': recipientId,
        'name': name,
        'avatar_url': avatarUrl,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'unread_count': unreadCount,
      };
}

/// Legacy conversation model for backwards compatibility with existing DM code
class Conversation {
  final String oderId;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  Conversation({
    required this.oderId,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      oderId: json['oder_id'] as String,
      recipientId: json['recipient_id'] as String,
      recipientName: json['recipient_name'] as String? ?? 'Ukjent',
      recipientAvatarUrl: json['recipient_avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'oder_id': oderId,
        'recipient_id': recipientId,
        'recipient_name': recipientName,
        'recipient_avatar_url': recipientAvatarUrl,
        'last_message': lastMessage,
        'last_message_at': lastMessageAt?.toIso8601String(),
        'unread_count': unreadCount,
      };
}
