import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

class Message extends Equatable {
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

  const Message({
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

  @override
  List<Object?> get props => [
        id,
        teamId,
        recipientId,
        userId,
        content,
        replyToId,
        isEdited,
        isDeleted,
        createdAt,
        updatedAt,
        userName,
        userAvatarUrl,
        recipientName,
        recipientAvatarUrl,
        replyTo,
      ];

  factory Message.fromJson(Map<String, dynamic> row) {
    return Message(
      id: safeString(row, 'id'),
      teamId: safeStringNullable(row, 'team_id'),
      recipientId: safeStringNullable(row, 'recipient_id'),
      userId: safeString(row, 'user_id'),
      content: safeString(row, 'content'),
      replyToId: safeStringNullable(row, 'reply_to_id'),
      isEdited: safeBool(row, 'is_edited', defaultValue: false),
      isDeleted: safeBool(row, 'is_deleted', defaultValue: false),
      createdAt: requireDateTime(row, 'created_at'),
      updatedAt: requireDateTime(row, 'updated_at'),
      userName: safeStringNullable(row, 'user_name'),
      userAvatarUrl: safeStringNullable(row, 'user_avatar_url'),
      recipientName: safeStringNullable(row, 'recipient_name'),
      recipientAvatarUrl: safeStringNullable(row, 'recipient_avatar_url'),
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
