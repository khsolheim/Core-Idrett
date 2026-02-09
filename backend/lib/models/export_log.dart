import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

class ExportLog extends Equatable {
  final String id;
  final String teamId;
  final String userId;
  final String exportType;
  final String fileFormat;
  final Map<String, dynamic>? parameters;
  final DateTime createdAt;

  // Joined data
  final String? userName;

  const ExportLog({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.exportType,
    required this.fileFormat,
    this.parameters,
    required this.createdAt,
    this.userName,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        userId,
        exportType,
        fileFormat,
        parameters,
        createdAt,
        userName,
      ];

  factory ExportLog.fromMap(Map<String, dynamic> map) {
    return ExportLog(
      id: safeString(map, 'id'),
      teamId: safeString(map, 'team_id'),
      userId: safeString(map, 'user_id'),
      exportType: safeString(map, 'export_type'),
      fileFormat: safeString(map, 'file_format'),
      parameters: safeMapNullable(map, 'parameters'),
      createdAt: requireDateTime(map, 'created_at'),
      userName: safeStringNullable(map, 'user_name'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'team_id': teamId,
    'user_id': userId,
    'export_type': exportType,
    'file_format': fileFormat,
    'parameters': parameters,
    'created_at': createdAt.toIso8601String(),
    'user_name': userName,
  };
}

/// Export types
class ExportType {
  static const String leaderboard = 'leaderboard';
  static const String attendance = 'attendance';
  static const String fines = 'fines';
  static const String activities = 'activities';
  static const String members = 'members';

  static List<String> get all => [
    leaderboard,
    attendance,
    fines,
    activities,
    members,
  ];

  static String displayName(String type) {
    switch (type) {
      case leaderboard: return 'Poengtabell';
      case attendance: return 'Oppmote';
      case fines: return 'Boter';
      case activities: return 'Aktiviteter';
      case members: return 'Medlemmer';
      default: return type;
    }
  }
}

/// Export file formats
class ExportFormat {
  static const String csv = 'csv';
  static const String xlsx = 'xlsx';
  static const String pdf = 'pdf';

  static List<String> get all => [csv, xlsx, pdf];

  static String displayName(String format) {
    switch (format) {
      case csv: return 'CSV';
      case xlsx: return 'Excel';
      case pdf: return 'PDF';
      default: return format.toUpperCase();
    }
  }
}
