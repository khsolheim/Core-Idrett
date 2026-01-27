import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/document_service.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../models/document.dart';

class DocumentsHandler {
  final DocumentService _documentService;
  final AuthService _authService;
  final TeamService _teamService;

  DocumentsHandler(this._documentService, this._authService, this._teamService);

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
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      // Verify team membership
      final membership = await _teamService.getMembership(teamId, userId);
      if (membership == null) {
        return Response.forbidden(jsonEncode({'error': 'Not a team member'}));
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

      return Response.ok(
        jsonEncode({
          'documents': documents.map((d) => d.toJson()).toList(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get documents: $e'}),
      );
    }
  }

  /// Create a new document record (after file is uploaded to storage)
  Future<Response> _createDocument(Request request, String teamId) async {
    try {
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      // Verify team membership
      final membership = await _teamService.getMembership(teamId, userId);
      if (membership == null) {
        return Response.forbidden(jsonEncode({'error': 'Not a team member'}));
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      // Validate required fields
      final name = body['name'] as String?;
      final filePath = body['file_path'] as String?;
      final fileSize = body['file_size'] as int?;
      final mimeType = body['mime_type'] as String?;

      if (name == null || filePath == null || fileSize == null || mimeType == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'name, file_path, file_size, and mime_type are required'}),
        );
      }

      final document = await _documentService.createDocument(
        teamId: teamId,
        uploadedBy: userId,
        name: name,
        description: body['description'] as String?,
        filePath: filePath,
        fileSize: fileSize,
        mimeType: mimeType,
        category: body['category'] as String?,
      );

      return Response.ok(
        jsonEncode(document.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create document: $e'}),
      );
    }
  }

  /// Get document categories for a team
  Future<Response> _getCategories(Request request, String teamId) async {
    try {
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      // Verify team membership
      final membership = await _teamService.getMembership(teamId, userId);
      if (membership == null) {
        return Response.forbidden(jsonEncode({'error': 'Not a team member'}));
      }

      final categories = await _documentService.getCategories(teamId);

      // Add display names
      final result = categories.map((c) => {
        ...c,
        'display_name': DocumentCategory.displayName(c['category'] as String),
      }).toList();

      return Response.ok(
        jsonEncode({'categories': result}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get categories: $e'}),
      );
    }
  }

  /// Get a single document
  Future<Response> _getDocument(Request request, String documentId) async {
    try {
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      final document = await _documentService.getDocument(documentId);
      if (document == null) {
        return Response.notFound(jsonEncode({'error': 'Document not found'}));
      }

      // Verify team membership
      final membership = await _teamService.getMembership(document.teamId, userId);
      if (membership == null) {
        return Response.forbidden(jsonEncode({'error': 'Not a team member'}));
      }

      return Response.ok(
        jsonEncode(document.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get document: $e'}),
      );
    }
  }

  /// Update document metadata
  Future<Response> _updateDocument(Request request, String documentId) async {
    try {
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      // Check permissions
      final canManage = await _documentService.canManageDocument(documentId, userId);
      if (!canManage) {
        return Response.forbidden(jsonEncode({'error': 'Not authorized to update this document'}));
      }

      final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

      final document = await _documentService.updateDocument(
        documentId: documentId,
        name: body['name'] as String?,
        description: body['description'] as String?,
        category: body['category'] as String?,
      );

      if (document == null) {
        return Response.notFound(jsonEncode({'error': 'Document not found'}));
      }

      return Response.ok(
        jsonEncode(document.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update document: $e'}),
      );
    }
  }

  /// Delete a document
  Future<Response> _deleteDocument(Request request, String documentId) async {
    try {
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      // Check permissions
      final canManage = await _documentService.canManageDocument(documentId, userId);
      if (!canManage) {
        return Response.forbidden(jsonEncode({'error': 'Not authorized to delete this document'}));
      }

      final success = await _documentService.deleteDocument(documentId);
      if (!success) {
        return Response.notFound(jsonEncode({'error': 'Document not found'}));
      }

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete document: $e'}),
      );
    }
  }

  /// Upload a document (file + metadata)
  Future<Response> _uploadDocument(Request request, String teamId) async {
    try {
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      // Verify team membership
      final membership = await _teamService.getMembership(teamId, userId);
      if (membership == null) {
        return Response.forbidden(jsonEncode({'error': 'Not a team member'}));
      }

      // Parse multipart form data or JSON with base64 content
      final contentType = request.headers['content-type'] ?? '';

      if (contentType.contains('application/json')) {
        // JSON with base64 encoded file
        final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

        final fileName = body['file_name'] as String?;
        final fileContent = body['file_content'] as String?; // base64 encoded
        final mimeType = body['mime_type'] as String?;

        if (fileName == null || fileContent == null || mimeType == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'file_name, file_content (base64), and mime_type are required'}),
          );
        }

        // Decode base64 content
        final fileBytes = base64Decode(fileContent);

        final document = await _documentService.uploadDocument(
          teamId: teamId,
          uploadedBy: userId,
          fileName: fileName,
          fileBytes: fileBytes,
          mimeType: mimeType,
          description: body['description'] as String?,
          category: body['category'] as String?,
        );

        return Response.ok(
          jsonEncode(document.toJson()),
          headers: {'content-type': 'application/json'},
        );
      } else {
        return Response.badRequest(
          body: jsonEncode({'error': 'Content-Type must be application/json with base64-encoded file_content'}),
        );
      }
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to upload document: $e'}),
      );
    }
  }

  /// Get download URL for a document
  Future<Response> _getDownloadUrl(Request request, String documentId) async {
    try {
      final userId = request.context['userId'] as String?;
      if (userId == null) {
        return Response.unauthorized(jsonEncode({'error': 'Unauthorized'}));
      }

      final document = await _documentService.getDocument(documentId);
      if (document == null) {
        return Response.notFound(jsonEncode({'error': 'Document not found'}));
      }

      // Verify team membership
      final membership = await _teamService.getMembership(document.teamId, userId);
      if (membership == null) {
        return Response.forbidden(jsonEncode({'error': 'Not a team member'}));
      }

      final url = await _documentService.getDownloadUrl(document.filePath);

      return Response.ok(
        jsonEncode({'url': url}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to get download URL: $e'}),
      );
    }
  }
}
