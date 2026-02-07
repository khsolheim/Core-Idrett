import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/message_service.dart';
import '../services/team_chat_service.dart';
import '../services/direct_message_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class MessagesHandler {
  final MessageService _messageService;
  final TeamChatService _teamChatService;
  final DirectMessageService _directMessageService;
  final TeamService _teamService;

  MessagesHandler(
    this._messageService,
    this._teamChatService,
    this._directMessageService,
    this._teamService,
  );

  Router get router {
    final router = Router();

    // Team messages (existing)
    router.get('/teams/<teamId>', _getMessages);
    router.post('/teams/<teamId>', _sendMessage);
    router.patch('/<messageId>', _editMessage);
    router.delete('/<messageId>', _deleteMessage);
    router.post('/teams/<teamId>/read', _markAsRead);
    router.get('/teams/<teamId>/unread', _getUnreadCount);

    // All conversations (team + DMs combined)
    router.get('/all-conversations', _getAllConversations);

    // Direct messages (new)
    router.get('/conversations', _getConversations);
    router.get('/direct/<recipientId>', _getDirectMessages);
    router.post('/direct/<recipientId>', _sendDirectMessage);
    router.post('/direct/<recipientId>/read', _markDirectAsRead);
    router.get('/direct/<recipientId>/unread', _getDirectUnreadCount);

    return router;
  }

  Future<Response> _getMessages(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final limitParam = request.url.queryParameters['limit'];
      final before = request.url.queryParameters['before'];
      final after = request.url.queryParameters['after'];
      final limit = limitParam != null ? int.tryParse(limitParam) ?? 50 : 50;

      final messages = await _teamChatService.getMessages(
        teamId,
        limit: limit,
        before: before,
        after: after,
      );

      return resp.ok({'messages': messages});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _sendMessage(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final data = await parseBody(request);

      final content = data['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return resp.badRequest('Meldingen kan ikke være tom');
      }

      final message = await _teamChatService.sendMessage(
        teamId: teamId,
        userId: userId,
        content: content.trim(),
        replyToId: data['reply_to_id'] as String?,
      );

      return resp.ok(message);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _editMessage(Request request, String messageId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final content = data['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return resp.badRequest('Meldingen kan ikke være tom');
      }

      final message = await _teamChatService.editMessage(
        messageId: messageId,
        userId: userId,
        content: content.trim(),
      );

      if (message == null) {
        return resp.notFound('Melding ikke funnet eller du har ikke tilgang');
      }

      return resp.ok(message);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _deleteMessage(Request request, String messageId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Get teamId from query parameter to check admin status
      final teamId = request.url.queryParameters['team_id'];
      var adminStatus = false;
      if (teamId != null) {
        final team = await requireTeamMember(_teamService, teamId, userId);
        if (team != null) {
          adminStatus = isAdmin(team);
        }
      }

      final success = await _teamChatService.deleteMessage(
        messageId: messageId,
        userId: userId,
        isAdmin: adminStatus,
      );

      if (!success) {
        return resp.notFound('Melding ikke funnet eller du har ikke tilgang');
      }

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _markAsRead(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      await _messageService.markAsRead(userId, teamId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getUnreadCount(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final count = await _messageService.getUnreadCount(userId, teamId);
      return resp.ok({'unread_count': count});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ All Conversations Handler ============

  Future<Response> _getAllConversations(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = request.url.queryParameters['team_id'];
      if (teamId == null) {
        return resp.badRequest('team_id er pakrevd');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final conversations = await _messageService.getAllConversations(userId, teamId);
      return resp.ok({'conversations': conversations});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ Direct Message Handlers ============

  Future<Response> _getConversations(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final conversations = await _messageService.getConversations(userId);
      return resp.ok({'conversations': conversations});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getDirectMessages(Request request, String recipientId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final limitParam = request.url.queryParameters['limit'];
      final before = request.url.queryParameters['before'];
      final after = request.url.queryParameters['after'];
      final limit = limitParam != null ? int.tryParse(limitParam) ?? 50 : 50;

      final messages = await _directMessageService.getDirectMessages(
        userId,
        recipientId,
        limit: limit,
        before: before,
        after: after,
      );

      return resp.ok({'messages': messages});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _sendDirectMessage(Request request, String recipientId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final content = data['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        return resp.badRequest('Meldingen kan ikke vare tom');
      }

      final message = await _directMessageService.sendDirectMessage(
        userId: userId,
        recipientId: recipientId,
        content: content.trim(),
        replyToId: data['reply_to_id'] as String?,
      );

      return resp.ok(message);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _markDirectAsRead(Request request, String recipientId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _directMessageService.markDirectAsRead(userId, recipientId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getDirectUnreadCount(Request request, String recipientId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final count = await _directMessageService.getDirectUnreadCount(userId, recipientId);
      return resp.ok({'unread_count': count});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }
}
