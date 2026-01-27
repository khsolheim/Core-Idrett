import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/document.dart';

class DocumentService {
  final Database _db;
  final _uuid = const Uuid();

  DocumentService(this._db);

  /// Get all documents for a team
  Future<List<Document>> getDocuments(
    String teamId, {
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final filters = <String, String>{
      'team_id': 'eq.$teamId',
      'is_deleted': 'eq.false',
    };

    if (category != null) {
      filters['category'] = 'eq.$category';
    }

    final result = await _db.client.select(
      'documents',
      filters: filters,
      order: 'created_at.desc',
      limit: limit,
      offset: offset,
    );

    // Get uploader details
    if (result.isNotEmpty) {
      final uploaderIds = result.map((d) => d['uploaded_by'] as String).toSet().toList();
      final users = await _db.client.select(
        'users',
        select: 'id,name,avatar_url',
        filters: {'id': 'in.(${uploaderIds.join(',')})'},
      );

      final userMap = <String, Map<String, dynamic>>{};
      for (final u in users) {
        userMap[u['id'] as String] = u;
      }

      return result.map((row) {
        final user = userMap[row['uploaded_by']] ?? {};
        return Document.fromMap({
          ...row,
          'uploader_name': user['name'],
          'uploader_avatar_url': user['avatar_url'],
        });
      }).toList();
    }

    return [];
  }

  /// Get a single document by ID
  Future<Document?> getDocument(String documentId) async {
    final result = await _db.client.select(
      'documents',
      filters: {
        'id': 'eq.$documentId',
        'is_deleted': 'eq.false',
      },
    );

    if (result.isEmpty) return null;

    final doc = result.first;

    // Get uploader details
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'eq.${doc['uploaded_by']}'},
    );

    final user = users.isNotEmpty ? users.first : <String, dynamic>{};

    return Document.fromMap({
      ...doc,
      'uploader_name': user['name'],
      'uploader_avatar_url': user['avatar_url'],
    });
  }

  /// Create a new document record (after file upload)
  Future<Document> createDocument({
    required String teamId,
    required String uploadedBy,
    required String name,
    String? description,
    required String filePath,
    required int fileSize,
    required String mimeType,
    String? category,
  }) async {
    final result = await _db.client.insert('documents', {
      'id': _uuid.v4(),
      'team_id': teamId,
      'uploaded_by': uploadedBy,
      'name': name,
      'description': description,
      'file_path': filePath,
      'file_size': fileSize,
      'mime_type': mimeType,
      'category': category,
      'is_deleted': false,
    });

    // Fetch with joined data
    return (await getDocument(result.first['id'] as String))!;
  }

  /// Update document metadata
  Future<Document?> updateDocument({
    required String documentId,
    String? name,
    String? description,
    String? category,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (category != null) updates['category'] = category;

    if (updates.isEmpty) return getDocument(documentId);

    await _db.client.update(
      'documents',
      updates,
      filters: {
        'id': 'eq.$documentId',
        'is_deleted': 'eq.false',
      },
    );

    return getDocument(documentId);
  }

  /// Soft delete a document
  Future<bool> deleteDocument(String documentId) async {
    final result = await _db.client.update(
      'documents',
      {'is_deleted': true},
      filters: {
        'id': 'eq.$documentId',
        'is_deleted': 'eq.false',
      },
    );

    return result.isNotEmpty;
  }

  /// Get document categories used by a team
  Future<List<Map<String, dynamic>>> getCategories(String teamId) async {
    final result = await _db.client.select(
      'documents',
      select: 'category',
      filters: {
        'team_id': 'eq.$teamId',
        'is_deleted': 'eq.false',
        'category': 'not.is.null',
      },
    );

    // Count categories manually since REST API doesn't support GROUP BY
    final categoryCounts = <String, int>{};
    for (final row in result) {
      final cat = row['category'] as String?;
      if (cat != null) {
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      }
    }

    return categoryCounts.entries.map((e) => {
      'category': e.key,
      'count': e.value,
    }).toList()..sort((a, b) => (a['category'] as String).compareTo(b['category'] as String));
  }

  /// Check if user can manage documents (is admin or uploader)
  Future<bool> canManageDocument(String documentId, String userId) async {
    // Get the document
    final docs = await _db.client.select(
      'documents',
      filters: {'id': 'eq.$documentId'},
    );

    if (docs.isEmpty) return false;

    final doc = docs.first;

    // Check if user is the uploader
    if (doc['uploaded_by'] == userId) return true;

    // Check if user is admin in the team
    final membership = await _db.client.select(
      'team_members',
      select: 'is_admin',
      filters: {
        'team_id': 'eq.${doc['team_id']}',
        'user_id': 'eq.$userId',
        'is_active': 'eq.true',
      },
    );

    if (membership.isNotEmpty && membership.first['is_admin'] == true) {
      return true;
    }

    return false;
  }

  /// Generate signed URL for file access (valid for 1 hour)
  Future<String> getDownloadUrl(String filePath) async {
    return await _db.client.createSignedUrl('documents', filePath, 3600);
  }

  /// Upload a file to storage and create document record
  Future<Document> uploadDocument({
    required String teamId,
    required String uploadedBy,
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
    String? description,
    String? category,
  }) async {
    // Generate unique path
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$teamId/${timestamp}_$fileName';

    // Upload to Supabase Storage
    await _db.client.uploadFile('documents', storagePath, fileBytes, mimeType);

    // Create document record in database
    return createDocument(
      teamId: teamId,
      uploadedBy: uploadedBy,
      name: fileName,
      filePath: storagePath,
      fileSize: fileBytes.length,
      mimeType: mimeType,
      description: description,
      category: category,
    );
  }

  /// Delete document file from storage
  Future<void> deleteDocumentFile(String filePath) async {
    await _db.client.deleteFile('documents', filePath);
  }
}
