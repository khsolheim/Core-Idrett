import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class NotificationsHandler {
  final NotificationService _notificationService;
  final AuthService _authService;

  NotificationsHandler(this._notificationService, this._authService);

  Router get router {
    final router = Router();

    // Device token management
    router.post('/tokens', _registerToken);
    router.post('/tokens/remove', _removeToken);

    // Preferences
    router.get('/preferences', _getPreferences);
    router.put('/preferences', _updatePreferences);

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

  Future<Response> _registerToken(Request request) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final token = data['token'] as String?;
      final platform = data['platform'] as String?;

      if (token == null || platform == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler token eller platform'}));
      }

      if (!['ios', 'android', 'web'].contains(platform)) {
        return Response(400, body: jsonEncode({'error': 'Ugyldig platform'}));
      }

      final deviceToken = await _notificationService.registerToken(
        userId: userId,
        token: token,
        platform: platform,
      );

      return Response.ok(jsonEncode(deviceToken.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _removeToken(Request request) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final token = data['token'] as String?;
      if (token == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler token'}));
      }

      await _notificationService.removeToken(userId, token);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getPreferences(Request request) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final teamId = request.url.queryParameters['team_id'];

      final prefs = await _notificationService.getPreferences(
        userId,
        teamId: teamId,
      );

      return Response.ok(jsonEncode(prefs.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _updatePreferences(Request request) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final prefs = await _notificationService.updatePreferences(
        userId: userId,
        teamId: data['team_id'] as String?,
        newActivity: data['new_activity'] as bool?,
        activityReminder: data['activity_reminder'] as bool?,
        activityCancelled: data['activity_cancelled'] as bool?,
        newFine: data['new_fine'] as bool?,
        fineDecision: data['fine_decision'] as bool?,
        teamMessage: data['team_message'] as bool?,
      );

      return Response.ok(jsonEncode(prefs.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }
}
