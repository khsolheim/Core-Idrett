import 'package:test/test.dart';
import 'package:core_idrett_backend/models/message.dart';

void main() {
  group('Message', () {
    test('roundtrip med alle felt populert', () {
      final original = Message(
        id: 'msg-1',
        teamId: 'team-1',
        recipientId: null,
        userId: 'user-1',
        content: 'Hei alle sammen! Gleder meg til kampen på lørdag.',
        replyToId: null,
        isEdited: false,
        isDeleted: false,
        createdAt: DateTime.parse('2024-03-10T10:30:00.000Z'),
        updatedAt: DateTime.parse('2024-03-10T10:30:00.000Z'),
        userName: 'Ola Nordmann',
        userAvatarUrl: 'https://example.com/avatars/ola.jpg',
        recipientName: null,
        recipientAvatarUrl: null,
        replyTo: null,
      );

      final json = original.toJson();
      final decoded = Message.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Message(
        id: 'msg-2',
        // teamId is null (direct message)
        recipientId: 'user-2',
        userId: 'user-1',
        content: 'Hei! Kan du sende meg treningsplanen?',
        // replyToId is null
        isEdited: false,
        isDeleted: false,
        createdAt: DateTime.parse('2024-03-11T14:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-11T14:00:00.000Z'),
        // userName is null
        // userAvatarUrl is null
        // recipientName is null
        // recipientAvatarUrl is null
        // replyTo is null
      );

      final json = original.toJson();
      final decoded = Message.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med redigert melding', () {
      final original = Message(
        id: 'msg-3',
        teamId: 'team-1',
        recipientId: null,
        userId: 'user-1',
        content: 'Oppdatert melding her',
        replyToId: null,
        isEdited: true,
        isDeleted: false,
        createdAt: DateTime.parse('2024-03-12T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-12T10:15:00.000Z'),
        userName: 'Kari Hansen',
        userAvatarUrl: null,
        recipientName: null,
        recipientAvatarUrl: null,
        replyTo: null,
      );

      final json = original.toJson();
      final decoded = Message.fromJson(json);

      expect(decoded, equals(original));
    });

    test('slettet melding viser placeholder i toJson', () {
      final original = Message(
        id: 'msg-4',
        teamId: 'team-1',
        recipientId: null,
        userId: 'user-1',
        content: 'Original innhold',
        replyToId: null,
        isEdited: false,
        isDeleted: true,
        createdAt: DateTime.parse('2024-03-13T12:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-13T12:30:00.000Z'),
        userName: 'Ole Olsen',
        userAvatarUrl: null,
        recipientName: null,
        recipientAvatarUrl: null,
        replyTo: null,
      );

      final json = original.toJson();

      // toJson returns '[Slettet melding]' for deleted messages
      expect(json['content'], equals('[Slettet melding]'));
      expect(json['is_deleted'], equals(true));

      // When we decode, we get the placeholder text, not original
      final decoded = Message.fromJson(json);
      expect(decoded.isDeleted, equals(true));
      expect(decoded.content, equals('[Slettet melding]'));
    });
  });
}
