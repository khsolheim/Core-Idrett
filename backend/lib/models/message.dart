class Message {
  final String id;
  final String? teamId;
  final String? recipientId;
  final String userId;
  final String content;
  final String? replyToId;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;
  final String? userAvatarUrl;
  final String? recipientName;
  final String? recipientAvatarUrl;
  final Message? replyTo;

  Message({
    required this.id,
    this.teamId,
    this.recipientId,
    required this.userId,
    required this.content,
    this.replyToId,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
    this.recipientName,
    this.recipientAvatarUrl,
    this.replyTo,
  });

  factory Message.fromJson(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as String,
      teamId: row['team_id'] as String?,
      recipientId: row['recipient_id'] as String?,
      userId: row['user_id'] as String,
      content: row['content'] as String,
      replyToId: row['reply_to_id'] as String?,
      isEdited: row['is_edited'] as bool? ?? false,
      isDeleted: row['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      userName: row['user_name'] as String?,
      userAvatarUrl: row['user_avatar_url'] as String?,
      recipientName: row['recipient_name'] as String?,
      recipientAvatarUrl: row['recipient_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (teamId != null) 'team_id': teamId,
        if (recipientId != null) 'recipient_id': recipientId,
        'user_id': userId,
        'content': isDeleted ? '[Slettet melding]' : content,
        'reply_to_id': replyToId,
        'is_edited': isEdited,
        'is_deleted': isDeleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        if (recipientName != null) 'recipient_name': recipientName,
        if (recipientAvatarUrl != null) 'recipient_avatar_url': recipientAvatarUrl,
        if (replyTo != null) 'reply_to': replyTo!.toJson(),
      };
}

class MessageRead {
  final String id;
  final String userId;
  final String? teamId;
  final String? recipientId;
  final DateTime lastReadAt;

  MessageRead({
    required this.id,
    required this.userId,
    this.teamId,
    this.recipientId,
    required this.lastReadAt,
  });

  factory MessageRead.fromJson(Map<String, dynamic> row) {
    return MessageRead(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      teamId: row['team_id'] as String?,
      recipientId: row['recipient_id'] as String?,
      lastReadAt: DateTime.parse(row['last_read_at'] as String),
    );
  }
}

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
