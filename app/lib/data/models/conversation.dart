import 'package:equatable/equatable.dart';

/// Type of conversation
enum ConversationType {
  team,
  direct,
}

/// Unified conversation model for both team chat and direct messages
class ChatConversation extends Equatable {
  final ConversationType type;
  final String? teamId;
  final String? recipientId;
  final String name;
  final String? avatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatConversation({
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

  @override
  List<Object?> get props => [type, teamId, recipientId, name, avatarUrl, lastMessage, lastMessageAt, unreadCount];
}
