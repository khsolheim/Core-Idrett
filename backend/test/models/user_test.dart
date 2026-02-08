import 'package:test/test.dart';
import 'package:core_idrett_backend/models/user.dart';

void main() {
  group('User', () {
    test('roundtrip med alle felt populert', () {
      final original = User(
        id: 'user-1',
        email: 'ola.nordmann@example.no',
        name: 'Ola Nordmann',
        avatarUrl: 'https://example.com/avatars/ola.jpg',
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      final json = original.toJson();
      final decoded = User.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = User(
        id: 'user-2',
        email: 'kari.hansen@example.no',
        name: 'Kari Hansen',
        // avatarUrl is null
        createdAt: DateTime.parse('2024-02-20T14:45:00.000Z'),
      );

      final json = original.toJson();
      final decoded = User.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
