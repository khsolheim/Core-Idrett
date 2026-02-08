import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/message.dart';

void main() {
  group('Message', () {
    test('roundtrip med alle felt populert', () {
      final replyToMessage = Message(
        id: 'msg-reply',
        teamId: 'team-1',
        userId: 'user-2',
        content: 'Opprinnelig melding',
        isEdited: false,
        isDeleted: false,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        userName: 'Kari Hansen',
        userAvatarUrl: 'https://example.com/avatars/kari.jpg',
      );

      final original = Message(
        id: 'msg-1',
        teamId: 'team-1',
        recipientId: 'user-3',
        userId: 'user-1',
        content: 'Dette er en testmelding til laget',
        replyToId: 'msg-reply',
        isEdited: true,
        isDeleted: false,
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T11:00:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        recipientName: 'Per Olsen',
        recipientAvatarUrl: 'https://example.com/avatars/per.jpg',
        replyTo: replyToMessage,
      );

      final json = original.toJson();
      final decoded = Message.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Message(
        id: 'msg-2',
        userId: 'user-1',
        content: 'Enkel melding uten ekstra data',
        isEdited: false,
        isDeleted: false,
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      final json = original.toJson();
      final decoded = Message.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
