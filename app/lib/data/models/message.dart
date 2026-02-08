import 'package:equatable/equatable.dart';

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

  bool get isDirectMessage => recipientId != null;
  bool get isTeamMessage => teamId != null;

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      teamId: json['team_id'] as String?,
      recipientId: json['recipient_id'] as String?,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      replyToId: json['reply_to_id'] as String?,
      isEdited: json['is_edited'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
      recipientName: json['recipient_name'] as String?,
      recipientAvatarUrl: json['recipient_avatar_url'] as String?,
      replyTo: json['reply_to'] != null
          ? Message.fromJson(json['reply_to'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (teamId != null) 'team_id': teamId,
        if (recipientId != null) 'recipient_id': recipientId,
        'user_id': userId,
        'content': content,
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

  String get displayContent => isDeleted ? '[Slettet melding]' : content;

  @override
  List<Object?> get props => [
    id, teamId, recipientId, userId, content, replyToId, isEdited, isDeleted,
    createdAt, updatedAt, userName, userAvatarUrl, recipientName, recipientAvatarUrl, replyTo
  ];
}
