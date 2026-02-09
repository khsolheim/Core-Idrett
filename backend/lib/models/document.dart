import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

class Document extends Equatable {
  final String id;
  final String teamId;
  final String uploadedBy;
  final String name;
  final String? description;
  final String filePath;
  final int fileSize;
  final String mimeType;
  final String? category;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined data
  final String? uploaderName;
  final String? uploaderAvatarUrl;

  const Document({
    required this.id,
    required this.teamId,
    required this.uploadedBy,
    required this.name,
    this.description,
    required this.filePath,
    required this.fileSize,
    required this.mimeType,
    this.category,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.uploaderName,
    this.uploaderAvatarUrl,
  });

  @override
  List<Object?> get props => [
        id,
        teamId,
        uploadedBy,
        name,
        description,
        filePath,
        fileSize,
        mimeType,
        category,
        isDeleted,
        createdAt,
        updatedAt,
        uploaderName,
        uploaderAvatarUrl,
      ];

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: safeString(map, 'id'),
      teamId: safeString(map, 'team_id'),
      uploadedBy: safeString(map, 'uploaded_by'),
      name: safeString(map, 'name'),
      description: safeStringNullable(map, 'description'),
      filePath: safeString(map, 'file_path'),
      fileSize: safeInt(map, 'file_size'),
      mimeType: safeString(map, 'mime_type'),
      category: safeStringNullable(map, 'category'),
      isDeleted: safeBool(map, 'is_deleted', defaultValue: false),
      createdAt: requireDateTime(map, 'created_at'),
      updatedAt: requireDateTime(map, 'updated_at'),
      uploaderName: safeStringNullable(map, 'uploader_name'),
      uploaderAvatarUrl: safeStringNullable(map, 'uploader_avatar_url'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'team_id': teamId,
    'uploaded_by': uploadedBy,
    'name': name,
    'description': description,
    'file_path': filePath,
    'file_size': fileSize,
    'mime_type': mimeType,
    'category': category,
    'is_deleted': isDeleted,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'uploader_name': uploaderName,
    'uploader_avatar_url': uploaderAvatarUrl,
  };

  /// Get human-readable file size
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Document categories
class DocumentCategory {
  static const String general = 'general';
  static const String rules = 'rules';
  static const String schedule = 'schedule';
  static const String training = 'training';
  static const String medical = 'medical';
  static const String administrative = 'administrative';

  static List<String> get all => [
    general,
    rules,
    schedule,
    training,
    medical,
    administrative,
  ];

  static String displayName(String category) {
    switch (category) {
      case general: return 'Generelt';
      case rules: return 'Regler';
      case schedule: return 'Terminliste';
      case training: return 'Trening';
      case medical: return 'Medisinsk';
      case administrative: return 'Administrativt';
      default: return category;
    }
  }
}
