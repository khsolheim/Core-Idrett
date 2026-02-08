import 'package:test/test.dart';
import 'package:core_idrett_backend/models/export_log.dart';

void main() {
  group('ExportLog', () {
    test('roundtrip med alle felt populert', () {
      final original = ExportLog(
        id: 'export-1',
        teamId: 'team-1',
        userId: 'user-1',
        exportType: 'leaderboard',
        fileFormat: 'csv',
        parameters: {
          'season_id': 'season-1',
          'category': 'total',
        },
        createdAt: DateTime.parse('2024-03-15T10:00:00.000Z'),
        userName: 'Ola Nordmann',
      );

      final json = original.toJson();
      final decoded = ExportLog.fromMap(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ExportLog(
        id: 'export-2',
        teamId: 'team-2',
        userId: 'user-2',
        exportType: 'attendance',
        fileFormat: 'xlsx',
        // parameters is null
        createdAt: DateTime.parse('2024-03-16T14:30:00.000Z'),
        // userName is null
      );

      final json = original.toJson();
      final decoded = ExportLog.fromMap(json);

      expect(decoded, equals(original));
    });
  });

  group('ExportType', () {
    test('displayName returnerer norske navn', () {
      expect(ExportType.displayName('leaderboard'), equals('Poengtabell'));
      expect(ExportType.displayName('attendance'), equals('Oppmote'));
      expect(ExportType.displayName('fines'), equals('Boter'));
      expect(ExportType.displayName('activities'), equals('Aktiviteter'));
      expect(ExportType.displayName('members'), equals('Medlemmer'));
      expect(ExportType.displayName('unknown'), equals('unknown'));
    });

    test('all inneholder alle typer', () {
      expect(ExportType.all, hasLength(5));
      expect(ExportType.all, contains('leaderboard'));
      expect(ExportType.all, contains('attendance'));
      expect(ExportType.all, contains('fines'));
      expect(ExportType.all, contains('activities'));
      expect(ExportType.all, contains('members'));
    });
  });

  group('ExportFormat', () {
    test('displayName returnerer korrekt format', () {
      expect(ExportFormat.displayName('csv'), equals('CSV'));
      expect(ExportFormat.displayName('xlsx'), equals('Excel'));
      expect(ExportFormat.displayName('pdf'), equals('PDF'));
      expect(ExportFormat.displayName('json'), equals('JSON'));
    });

    test('all inneholder alle formater', () {
      expect(ExportFormat.all, hasLength(3));
      expect(ExportFormat.all, contains('csv'));
      expect(ExportFormat.all, contains('xlsx'));
      expect(ExportFormat.all, contains('pdf'));
    });
  });
}
