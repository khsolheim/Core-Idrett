import 'package:test/test.dart';
import 'package:core_idrett_backend/models/document.dart';

void main() {
  group('Document', () {
    test('roundtrip med alle felt populert', () {
      final original = Document(
        id: 'doc-1',
        teamId: 'team-1',
        uploadedBy: 'user-1',
        name: 'Treningsplan Vår 2024.pdf',
        description: 'Detaljert treningsplan for vårsesongen',
        filePath: '/documents/team-1/treningsplan-var-2024.pdf',
        fileSize: 2048576,
        mimeType: 'application/pdf',
        category: 'training',
        isDeleted: false,
        createdAt: DateTime.parse('2024-03-01T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-01T10:00:00.000Z'),
        uploaderName: 'Ola Nordmann',
        uploaderAvatarUrl: 'https://example.com/avatars/ola.jpg',
      );

      final json = original.toJson();
      final decoded = Document.fromMap(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Document(
        id: 'doc-2',
        teamId: 'team-2',
        uploadedBy: 'user-2',
        name: 'Kampoppsett.xlsx',
        // description is null
        filePath: '/documents/team-2/kampoppsett.xlsx',
        fileSize: 512000,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        // category is null
        isDeleted: false,
        createdAt: DateTime.parse('2024-03-05T14:30:00.000Z'),
        updatedAt: DateTime.parse('2024-03-05T14:30:00.000Z'),
        // uploaderName is null
        // uploaderAvatarUrl is null
      );

      final json = original.toJson();
      final decoded = Document.fromMap(json);

      expect(decoded, equals(original));
    });
  });

  group('DocumentCategory', () {
    test('displayName returnerer norske navn', () {
      expect(DocumentCategory.displayName('general'), equals('Generelt'));
      expect(DocumentCategory.displayName('rules'), equals('Regler'));
      expect(DocumentCategory.displayName('schedule'), equals('Terminliste'));
      expect(DocumentCategory.displayName('training'), equals('Trening'));
      expect(DocumentCategory.displayName('medical'), equals('Medisinsk'));
      expect(DocumentCategory.displayName('administrative'), equals('Administrativt'));
      expect(DocumentCategory.displayName('unknown'), equals('unknown'));
    });

    test('all inneholder alle kategorier', () {
      expect(DocumentCategory.all, hasLength(6));
      expect(DocumentCategory.all, contains('general'));
      expect(DocumentCategory.all, contains('rules'));
      expect(DocumentCategory.all, contains('schedule'));
      expect(DocumentCategory.all, contains('training'));
      expect(DocumentCategory.all, contains('medical'));
      expect(DocumentCategory.all, contains('administrative'));
    });
  });
}
