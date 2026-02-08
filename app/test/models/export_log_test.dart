import 'package:flutter_test/flutter_test.dart';
import 'package:core_idrett/data/models/export_log.dart';

void main() {
  group('ExportLog', () {
    test('roundtrip med alle felt populert', () {
      final original = ExportLog(
        id: 'log-1',
        teamId: 'team-1',
        userId: 'user-1',
        exportType: 'leaderboard',
        fileFormat: 'csv',
        parameters: {
          'season': '2024',
          'include_inactive': false,
        },
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        userName: 'Ola Nordmann',
      );

      final jsonMap = {
        'id': original.id,
        'team_id': original.teamId,
        'user_id': original.userId,
        'export_type': original.exportType,
        'file_format': original.fileFormat,
        'parameters': original.parameters,
        'created_at': original.createdAt.toIso8601String(),
        'user_name': original.userName,
      };
      final decoded = ExportLog.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ExportLog(
        id: 'log-2',
        teamId: 'team-1',
        userId: 'user-2',
        exportType: 'attendance',
        fileFormat: 'json',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
      );

      final jsonMap = {
        'id': original.id,
        'team_id': original.teamId,
        'user_id': original.userId,
        'export_type': original.exportType,
        'file_format': original.fileFormat,
        'created_at': original.createdAt.toIso8601String(),
      };
      final decoded = ExportLog.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });

  group('ExportData', () {
    test('roundtrip med alle felt populert', () {
      final original = ExportData(
        type: 'leaderboard',
        columns: ['navn', 'poeng', 'oppmote'],
        data: [
          {'navn': 'Ola Nordmann', 'poeng': 150, 'oppmote': 0.95},
          {'navn': 'Kari Hansen', 'poeng': 145, 'oppmote': 0.92},
        ],
        summary: {
          'total_members': 2,
          'average_points': 147.5,
        },
      );

      final jsonMap = {
        'type': original.type,
        'columns': original.columns,
        'data': original.data,
        'summary': original.summary,
      };
      final decoded = ExportData.fromJson(jsonMap);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = ExportData(
        type: 'attendance',
        columns: ['navn', 'prosent'],
        data: [
          {'navn': 'Ola Nordmann', 'prosent': 0.95},
        ],
      );

      final jsonMap = {
        'type': original.type,
        'columns': original.columns,
        'data': original.data,
      };
      final decoded = ExportData.fromJson(jsonMap);

      expect(decoded, equals(original));
    });
  });
}
