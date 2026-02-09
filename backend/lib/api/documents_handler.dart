import 'dart:convert';
import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/document_service.dart';
import '../services/team_service.dart';
import '../models/document.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class DocumentsHandler {
  final DocumentService _documentService;
  final TeamService _teamService;

  DocumentsHandler(this._documentService, this._teamService);

  Router get router {
    final router = Router();

    // Team document routes
    router.get('/teams/<teamId>', _getDocuments);
    router.post('/teams/<teamId>', _createDocument);
    router.post('/teams/<teamId>/upload', _uploadDocument);
    router.get('/teams/<teamId>/categories', _getCategories);

    // Single document routes
    router.get('/<documentId>', _getDocument);
    router.patch('/<documentId>', _updateDocument);
    router.delete('/<documentId>', _deleteDocument);
    router.get('/<documentId>/download', _getDownloadUrl);

    return router;
  }

  /// Get all documents for a team
  Future<Response> _getDocuments(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final membership = await _teamService.getMembership(teamId, userId);
      if (membership == null) {
        return resp.forbidden('Not a team member');
      }

      // Parse query parameters
      final params = request.url.queryParameters;
      final category = params['category'];
      final limit = int.tryParse(params['limit'] ?? '50') ?? 50;
      final offset = int.tryParse(params['offset'] ?? '0') ?? 0;

      final documents = await _documentService.getDocuments(
        teamId,
        category: category,
        limit: limit,
        offset: offset,
      );

      return resp.ok({
        'documents': documents.map((d) => d.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Failed to get documents');
    }
  }

  /// Create a new document record (after file is uploaded to storage)
  Future<Response> _createDocument(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final membership = await _teamService.getMembership(teamId, userId);
      if (membership == null) {
        return resp.forbidden('Not a team member');
      }

      final body = await parseBody(request);

      // Validate required fields
      final name = safeStringNullable(body, 'name');
      final filePath = safeStringNullable(body, 'file_path');
      final fileSize = safeIntNullable(body, 'file_size');
      final mimeType = safeStringNullable(body, 'mime_type');

      if (name == null || filePath == null || fileSize == null || mimeType == null) {
        return resp.badRequest('name, file_path, file_size, and mime_type are required');
      }

      final document = await _documentService.createDocument(
        teamId: teamId,
        uploadedBy: userId,
        name: name,
        description: safeStringNullable(body, 'description'),
        filePath: filePath,
        fileSize: fileSize,
        mimeType: mimeType,
        category: safeStringNullable(body, 'category'),
      );

      return resp.ok(document.toJson());
    } catch (e) {
      return resp.serverError('Failed to create document');
    }
  }

  /// Get document categories for a team
  Future<Response> _getCategories(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final membership = await _teamService.getMembership(teamId, userId);
      if (membership == null) {
        return resp.forbidden('Not a team member');
      }

      final categories = await _documentService.getCategories(teamId);

      // Add display names
      final result = categories.map((c) => {
        ...c,
        'display_name': DocumentCategory.displayName(c['category'] as String),
      }).toList();

      return resp.ok({'categories': result});
    } catch (e) {
      return resp.serverError('Failed to get categories');
    }
  }

  /// Get a single document
  Future<Response> _getDocument(Request request, String documentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final document = await _documentService.getDocument(documentId);
      if (document == null) {
        return resp.notFound('Document not found');
      }

      // Verify team membership
      final membership = await _teamService.getMembership(document.teamId, userId);
      if (membership == null) {
        return resp.forbidden('Not a team member');
      }

      return resp.ok(document.toJson());
    } catch (e) {
      return resp.serverError('Failed to get document');
    }
  }

  /// Update document metadata
  Future<Response> _updateDocument(Request request, String documentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Check permissions
      final canManage = await _documentService.canManageDocument(documentId, userId);
      if (!canManage) {
        return resp.forbidden('Not authorized to update this document');
      }

      final body = await parseBody(request);

      final document = await _documentService.updateDocument(
        documentId: documentId,
        name: safeStringNullable(body, 'name'),
        description: safeStringNullable(body, 'description'),
        category: safeStringNullable(body, 'category'),
      );

      if (document == null) {
        return resp.notFound('Document not found');
      }

      return resp.ok(document.toJson());
    } catch (e) {
      return resp.serverError('Failed to update document');
    }
  }

  /// Delete a document
  Future<Response> _deleteDocument(Request request, String documentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Check permissions
      final canManage = await _documentService.canManageDocument(documentId, userId);
      if (!canManage) {
        return resp.forbidden('Not authorized to delete this document');
      }

      final success = await _documentService.deleteDocument(documentId);
      if (!success) {
        return resp.notFound('Document not found');
      }

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Failed to delete document');
    }
  }

  /// Upload a document (file + metadata)
  Future<Response> _uploadDocument(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final membership = await _teamService.getMembership(teamId, userId);
      if (membership == null) {
        return resp.forbidden('Not a team member');
      }

      // Parse multipart form data or JSON with base64 content
      final contentType = request.headers['content-type'] ?? '';

      if (contentType.contains('application/json')) {
        // JSON with base64 encoded file
        final body = await parseBody(request);

        final fileName = safeStringNullable(body, 'file_name');
        final fileContent = safeStringNullable(body, 'file_content'); // base64 encoded
        final mimeType = safeStringNullable(body, 'mime_type');

        if (fileName == null || fileContent == null || mimeType == null) {
          return resp.badRequest('file_name, file_content (base64), and mime_type are required');
        }

        // Decode base64 content
        final fileBytes = base64Decode(fileContent);

        final document = await _documentService.uploadDocument(
          teamId: teamId,
          uploadedBy: userId,
          fileName: fileName,
          fileBytes: fileBytes,
          mimeType: mimeType,
          description: safeStringNullable(body, 'description'),
          category: safeStringNullable(body, 'category'),
        );

        return resp.ok(document.toJson());
      } else {
        return resp.badRequest('Content-Type must be application/json with base64-encoded file_content');
      }
    } catch (e) {
      return resp.serverError('Failed to upload document');
    }
  }

  /// Get download URL for a document
  Future<Response> _getDownloadUrl(Request request, String documentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final document = await _documentService.getDocument(documentId);
      if (document == null) {
        return resp.notFound('Document not found');
      }

      // Verify team membership
      final membership = await _teamService.getMembership(document.teamId, userId);
      if (membership == null) {
        return resp.forbidden('Not a team member');
      }

      final url = await _documentService.getDownloadUrl(document.filePath);

      return resp.ok({'url': url});
    } catch (e) {
      return resp.serverError('Failed to get download URL');
    }
  }
}
