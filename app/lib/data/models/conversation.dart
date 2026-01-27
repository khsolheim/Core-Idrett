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
