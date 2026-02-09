import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/export_log.dart';
import '../../helpers/parsing_helpers.dart';

class ExportUtilityService {
  final Database _db;
  final _uuid = const Uuid();

  ExportUtilityService(this._db);

  /// Generate CSV content from export data
  String generateCsv(Map<String, dynamic> exportData) {
    final columns = exportData['columns'] as List<dynamic>;
    final data = exportData['data'] as List<dynamic>;

    final buffer = StringBuffer();

    // Header row
    buffer.writeln(columns.join(';'));

    // Data rows
    for (final row in data) {
      final rowMap = row as Map<String, dynamic>;
      final values = rowMap.values.map((v) {
        if (v == null) return '';
        if (v is bool) return v ? 'Ja' : 'Nei';
        final str = v.toString();
        // Escape quotes and wrap in quotes if contains delimiter
        if (str.contains(';') || str.contains('"') || str.contains('\n')) {
          return '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).toList();
      buffer.writeln(values.join(';'));
    }

    return buffer.toString();
  }

  /// Log an export
  Future<ExportLog> logExport({
    required String teamId,
    required String userId,
    required String exportType,
    required String fileFormat,
    Map<String, dynamic>? parameters,
  }) async {
    final result = await _db.client.insert('export_logs', {
      'id': _uuid.v4(),
      'team_id': teamId,
      'user_id': userId,
      'export_type': exportType,
      'file_format': fileFormat,
      'parameters': parameters != null ? jsonEncode(parameters) : null,
    });

    return ExportLog.fromMap(result.first);
  }

  /// Get export history for a team
  Future<List<ExportLog>> getExportHistory(
    String teamId, {
    int limit = 50,
  }) async {
    final logs = await _db.client.select(
      'export_logs',
      filters: {'team_id': 'eq.$teamId'},
      order: 'created_at.desc',
      limit: limit,
    );

    if (logs.isEmpty) return [];

    // Get user names
    final userIds = logs.map((l) => safeString(l, 'user_id')).toSet().toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, String>{};
    for (final u in users) {
      userMap[safeString(u, 'id')] = safeString(u, 'name');
    }

    return logs.map((l) => ExportLog.fromMap({
      ...l,
      'user_name': userMap[l['user_id']],
    })).toList();
  }
}
