import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/message_service.dart';
import '../services/team_service.dart';

class MessagesHandler {
  final MessageService _messageService;
  final AuthService _authService;
  final TeamService _teamService;

  MessagesHandler(this._messageService, this._authService, this._teamService);

  Router get router {
    final router = Router();

    router.get('/teams/<teamId>', _getMessages);
    router.post('/teams/<teamId>', _sendMessage);
    router.patch('/<messageId>', _editMessage);
    router.delete('/<messageId>', _deleteMessage);
    router.post('/teams/<teamId>/read', _markAsRead);
    router.get('/teams/<teamId>/unread', _getUnreadCount);

    return router;
  }

  Future<String?> _getUserId(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    final token = authHeader.substring(7);
    final user = await _authService.getUserFromToken(token);
    return user?.id;
  }

  Future<bool> _isTeamMember(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    return team != null;
  }

  Future<bool> _isTeamAdmin(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    return team != null && team['user_role'] == 'admin';
  }

  Future<Response> _getMessages(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final limitParam = request.url.queryParameters['limit'];
      final before = request.url.queryParameters['before'];
      final after = request.url.queryParameters['after'];
      final limit = limitParam != null ? int.tryParse(limitParam) ?? 50 : 50;

      final messages = await _messageService.getMessages(
        teamId,
        limit: limit,
        before: before,
        after: after,
      );

      return Response.ok(jsonEncode({'messages': messages}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _sendMessage(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final content = data['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Meldingen kan ikke være tom'}));
      }

      final message = await _messageService.sendMessage(
        teamId: teamId,
        userId: userId,
        content: content.trim(),
        replyToId: data['reply_to_id'] as String?,
      );

      return Response.ok(jsonEncode(message));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _editMessage(Request request, String messageId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final content = data['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Meldingen kan ikke være tom'}));
      }

      final message = await _messageService.editMessage(
        messageId: messageId,
        userId: userId,
        content: content.trim(),
      );

      if (message == null) {
        return Response(404, body: jsonEncode({'error': 'Melding ikke funnet eller du har ikke tilgang'}));
      }

      return Response.ok(jsonEncode(message));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteMessage(Request request, String messageId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      // Get teamId from query parameter to check admin status
      final teamId = request.url.queryParameters['team_id'];
      final isAdmin = teamId != null && await _isTeamAdmin(userId, teamId);

      final success = await _messageService.deleteMessage(
        messageId: messageId,
        userId: userId,
        isAdmin: isAdmin,
      );

      if (!success) {
        return Response(404, body: jsonEncode({'error': 'Melding ikke funnet eller du har ikke tilgang'}));
      }

      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _markAsRead(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      await _messageService.markAsRead(userId, teamId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getUnreadCount(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final count = await _messageService.getUnreadCount(userId, teamId);
      return Response.ok(jsonEncode({'unread_count': count}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }
}
