import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/document.dart';

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.watch(apiClientProvider));
});

class DocumentRepository {
  final ApiClient _client;

  DocumentRepository(this._client);

  /// Get all documents for a team
  Future<List<TeamDocument>> getDocuments(
    String teamId, {
    String? category,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (category != null) queryParams['category'] = category;

    final response = await _client.get(
      '/documents/teams/$teamId',
      queryParameters: queryParams,
    );
    final data = response.data['documents'] as List;
    return data.map((d) => TeamDocument.fromJson(d as Map<String, dynamic>)).toList();
  }

  /// Get a single document
  Future<TeamDocument> getDocument(String documentId) async {
    final response = await _client.get('/documents/$documentId');
    return TeamDocument.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get document categories for a team
  Future<List<DocumentCategoryCount>> getCategories(String teamId) async {
    final response = await _client.get('/documents/teams/$teamId/categories');
    final data = response.data['categories'] as List;
    return data.map((c) => DocumentCategoryCount.fromJson(c as Map<String, dynamic>)).toList();
  }

  /// Create a document record (after uploading to storage)
  Future<TeamDocument> createDocument({
    required String teamId,
    required String name,
    required String filePath,
    required int fileSize,
    required String mimeType,
    String? description,
    String? category,
  }) async {
    final response = await _client.post('/documents/teams/$teamId', data: {
      'name': name,
      'file_path': filePath,
      'file_size': fileSize,
      'mime_type': mimeType,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
    });
    return TeamDocument.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update document metadata
  Future<TeamDocument> updateDocument({
    required String documentId,
    String? name,
    String? description,
    String? category,
  }) async {
    final response = await _client.patch('/documents/$documentId', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
    });
    return TeamDocument.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a document
  Future<void> deleteDocument(String documentId) async {
    await _client.delete('/documents/$documentId');
  }

  /// Get download URL for a document
  Future<String> getDownloadUrl(String documentId) async {
    final response = await _client.get('/documents/$documentId/download');
    return response.data['url'] as String;
  }

  /// Upload a file via the backend API
  Future<TeamDocument> uploadDocument({
    required String teamId,
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
    String? description,
    String? category,
  }) async {
    // Encode file as base64 and send to backend
    final base64Content = base64Encode(fileBytes);

    final response = await _client.post('/documents/teams/$teamId/upload', data: {
      'file_name': fileName,
      'file_content': base64Content,
      'mime_type': mimeType,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
    });

    return TeamDocument.fromJson(response.data as Map<String, dynamic>);
  }
}
