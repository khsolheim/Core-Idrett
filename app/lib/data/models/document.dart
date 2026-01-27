class TeamDocument {
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
  final String? uploaderName;
  final String? uploaderAvatarUrl;

  TeamDocument({
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

  factory TeamDocument.fromJson(Map<String, dynamic> json) {
    return TeamDocument(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      filePath: json['file_path'] as String,
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String,
      category: json['category'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      uploaderName: json['uploader_name'] as String?,
      uploaderAvatarUrl: json['uploader_avatar_url'] as String?,
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

  /// Get file extension
  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  /// Check if this is an image
  bool get isImage => mimeType.startsWith('image/');

  /// Check if this is a PDF
  bool get isPdf => mimeType == 'application/pdf';

  /// Check if this is a video
  bool get isVideo => mimeType.startsWith('video/');

  /// Check if this is an audio file
  bool get isAudio => mimeType.startsWith('audio/');
}

/// Document categories
enum DocumentCategory {
  general,
  rules,
  schedule,
  training,
  medical,
  administrative;

  String get value {
    return name;
  }

  String get displayName {
    switch (this) {
      case DocumentCategory.general:
        return 'Generelt';
      case DocumentCategory.rules:
        return 'Regler';
      case DocumentCategory.schedule:
        return 'Terminliste';
      case DocumentCategory.training:
        return 'Trening';
      case DocumentCategory.medical:
        return 'Medisinsk';
      case DocumentCategory.administrative:
        return 'Administrativt';
    }
  }

  static DocumentCategory? fromString(String? value) {
    if (value == null) return null;
    try {
      return DocumentCategory.values.firstWhere((e) => e.value == value);
    } catch (_) {
      return null;
    }
  }
}

/// Category with count (from API)
class DocumentCategoryCount {
  final String category;
  final String displayName;
  final int count;

  DocumentCategoryCount({
    required this.category,
    required this.displayName,
    required this.count,
  });

  factory DocumentCategoryCount.fromJson(Map<String, dynamic> json) {
    return DocumentCategoryCount(
      category: json['category'] as String,
      displayName: json['display_name'] as String,
      count: json['count'] as int,
    );
  }
}
