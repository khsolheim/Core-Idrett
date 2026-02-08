import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/conversation.dart';

void main() {
  group('ChatConversation', () {
    test('roundtrip med alle felt populert', () {
      final original = ChatConversation(
        type: ConversationType.team,
        teamId: 'team-1',
        recipientId: 'user-1',
        name: 'Rosenborg BK',
        avatarUrl: 'https://example.com/teams/rosenborg.jpg',
        lastMessage: 'Siste melding i samtalen',
        lastMessageAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        unreadCount: 3,
      );

      // ChatConversation doesn't have toJson(), construct manually
      final jsonMap = {
        'type': 'team',
        'team_id': original.teamId,
        'recipient_id': original.recipientId,
        'name': original.name,
        'avatar_url': original.avatarUrl,
        'last_message': original.lastMessage,
        'last_message_at': original.lastMessageAt?.toIso8601String(),
        'unread_count': original.unreadCount,
      };
      final decoded = ChatConversation.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ChatConversation(
        type: ConversationType.direct,
        name: 'Ola Nordmann',
        unreadCount: 0,
      );

      // ChatConversation doesn't have toJson(), construct manually
      final jsonMap = {
        'type': 'direct',
        'name': original.name,
        'unread_count': original.unreadCount,
      };
      final decoded = ChatConversation.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });
}
