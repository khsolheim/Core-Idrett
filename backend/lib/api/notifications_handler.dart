import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/notification_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class NotificationsHandler {
  final NotificationService _notificationService;

  NotificationsHandler(this._notificationService);

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

  Future<Response> _registerToken(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final token = data['token'] as String?;
      final platform = data['platform'] as String?;

      if (token == null || platform == null) {
        return resp.badRequest('Mangler token eller platform');
      }

      if (!['ios', 'android', 'web'].contains(platform)) {
        return resp.badRequest('Ugyldig platform');
      }

      final deviceToken = await _notificationService.registerToken(
        userId: userId,
        token: token,
        platform: platform,
      );

      return resp.ok(deviceToken.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _removeToken(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final token = data['token'] as String?;
      if (token == null) {
        return resp.badRequest('Mangler token');
      }

      await _notificationService.removeToken(userId, token);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getPreferences(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = request.url.queryParameters['team_id'];

      final prefs = await _notificationService.getPreferences(
        userId,
        teamId: teamId,
      );

      return resp.ok(prefs.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updatePreferences(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
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

      return resp.ok(prefs.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }
}
