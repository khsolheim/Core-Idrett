import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/user.dart';

void main() {
  group('User', () {
    test('roundtrip med alle felt populert', () {
      final original = User(
        id: 'user-1',
        email: 'ola.nordmann@example.no',
        name: 'Ola Nordmann',
        avatarUrl: 'https://example.com/avatars/ola.jpg',
        birthDate: DateTime.parse('1995-03-15T00:00:00.000Z'),
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
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      final json = original.toJson();
      final decoded = User.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
