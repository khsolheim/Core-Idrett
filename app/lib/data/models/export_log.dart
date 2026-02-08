import 'package:equatable/equatable.dart';

class ExportLog extends Equatable {
  final String id;
  final String teamId;
  final String userId;
  final String exportType;
  final String fileFormat;
  final Map<String, dynamic>? parameters;
  final DateTime createdAt;
  final String? userName;
  ExportLog({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.exportType,
    required this.fileFormat,
    this.parameters,
    required this.createdAt,
    this.userName,
  });

  factory ExportLog.fromJson(Map<String, dynamic> json) {
    return
  ExportLog(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      userId: json['user_id'] as String,
      exportType: json['export_type'] as String,
      fileFormat: json['file_format'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
    );
  }


  @override
  List<Object?> get props => [id, teamId, userId, exportType, fileFormat, parameters, createdAt, userName];
}

/// Export types
enum ExportType {
  leaderboard,
  attendance,
  fines,
  activities,
  members;

  String get value => name;

  String get displayName {
    switch (this) {
      case ExportType.leaderboard:
        return 'Poengtabell';
      case ExportType.attendance:
        return 'Oppmote';
      case ExportType.fines:
        return 'Boter';
      case ExportType.activities:
        return 'Aktiviteter';
      case ExportType.members:
        return 'Medlemmer';
    }
  }

  String get description {
    switch (this) {
      case ExportType.leaderboard:
        return 'Eksporter poengtabell med plasseringer';
      case ExportType.attendance:
        return 'Eksporter oppmotestatistikk for alle medlemmer';
      case ExportType.fines:
        return 'Eksporter boteregnskap';
      case ExportType.activities:
        return 'Eksporter aktivitetsoversikt';
      case ExportType.members:
        return 'Eksporter medlemsliste (kun admin)';
    }
  }

  static ExportType? fromString(String? value) {
    if (value == null) return null;
    try {
      return ExportType.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

/// Export file formats
enum ExportFormat {
  csv,
  json;

  String get value => name;

  String get displayName {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
    }
  }

  String get description {
    switch (this) {
      case ExportFormat.csv:
        return 'Kommaseparert fil (Excel-kompatibel)';
      case ExportFormat.json:
        return 'JSON-data for programmatisk bruk';
    }
  }
}

/// Export data result
class ExportData extends Equatable {
  final String type;
  final List<String> columns;
  final List<Map<String, dynamic>> data;
  final Map<String, dynamic>? summary;
  ExportData({
    required this.type,
    required this.columns,
    required this.data,
    this.summary,
  });

  factory ExportData.fromJson(Map<String, dynamic> json) {
    return
  ExportData(
      type: json['type'] as String,
      columns: (json['columns'] as List).cast<String>(),
      data: (json['data'] as List).cast<Map<String, dynamic>>(),
      summary: json['summary'] as Map<String, dynamic>?,
    );
  }


  @override
  List<Object?> get props => [type, columns, data, summary];
}
