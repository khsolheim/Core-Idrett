import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/document.dart';

void main() {
  group('TeamDocument', () {
    test('roundtrip med alle felt populert', () {
      final original = TeamDocument(
        id: 'doc-1',
        teamId: 'team-1',
        uploadedBy: 'user-1',
        name: 'Treningsplan_2024.pdf',
        description: 'Komplett treningsplan for vårsesong',
        filePath: 'teams/team-1/documents/plan.pdf',
        fileSize: 2048576,
        mimeType: 'application/pdf',
        category: 'training',
        isDeleted: false,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        uploaderName: 'Ola Nordmann',
        uploaderAvatarUrl: 'https://example.com/avatars/ola.jpg',
      );

      final json = original.toJson();
      final decoded = TeamDocument.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = TeamDocument(
        id: 'doc-2',
        teamId: 'team-1',
        uploadedBy: 'user-1',
        name: 'Bilde.jpg',
        filePath: 'teams/team-1/documents/image.jpg',
        fileSize: 512000,
        mimeType: 'image/jpeg',
        isDeleted: false,
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final json = original.toJson();
      final decoded = TeamDocument.fromJson(json);

      expect(decoded, equals(original));
    });
  });

  group('DocumentCategoryCount', () {
    test('roundtrip med alle felt populert', () {
      final original = DocumentCategoryCount(
        category: 'training',
        displayName: 'Trening',
        count: 15,
      );

      final jsonMap = {
        'category': original.category,
        'display_name': original.displayName,
        'count': original.count,
      };
      final decoded = DocumentCategoryCount.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      // DocumentCategoryCount har ingen valgfrie felt
      final original = DocumentCategoryCount(
        category: 'general',
        displayName: 'Generelt',
        count: 0,
      );

      final jsonMap = {
        'category': original.category,
        'display_name': original.displayName,
        'count': original.count,
      };
      final decoded = DocumentCategoryCount.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });
}
