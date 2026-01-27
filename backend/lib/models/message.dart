class Message {
  final String id;
  final String teamId;
  final String userId;
  final String content;
  final String? replyToId;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;
  final String? userAvatarUrl;
  final Message? replyTo;

  Message({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.content,
    this.replyToId,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
    this.replyTo,
  });

  factory Message.fromRow(Map<String, dynamic> row) {
    return Message(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      userId: row['user_id'] as String,
      content: row['content'] as String,
      replyToId: row['reply_to_id'] as String?,
      isEdited: row['is_edited'] as bool? ?? false,
      isDeleted: row['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: DateTime.parse(row['updated_at'] as String),
      userName: row['user_name'] as String?,
      userAvatarUrl: row['user_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'user_id': userId,
        'content': isDeleted ? '[Slettet melding]' : content,
        'reply_to_id': replyToId,
        'is_edited': isEdited,
        'is_deleted': isDeleted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
        if (replyTo != null) 'reply_to': replyTo!.toJson(),
      };
}

class MessageRead {
  final String id;
  final String userId;
  final String teamId;
  final DateTime lastReadAt;

  MessageRead({
    required this.id,
    required this.userId,
    required this.teamId,
    required this.lastReadAt,
  });

  factory MessageRead.fromRow(Map<String, dynamic> row) {
    return MessageRead(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      teamId: row['team_id'] as String,
      lastReadAt: DateTime.parse(row['last_read_at'] as String),
    );
  }
}
