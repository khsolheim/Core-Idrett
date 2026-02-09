import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/notification_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
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

      final data = await parseBody(request);

      final token = safeStringNullable(data, 'token');
      final platform = safeStringNullable(data, 'platform');

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
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _removeToken(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final token = safeStringNullable(data, 'token');
      if (token == null) {
        return resp.badRequest('Mangler token');
      }

      await _notificationService.removeToken(userId, token);
      return resp.ok({'message': 'Token fjernet'});
    } catch (e) {
      return resp.serverError('En feil oppstod');
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
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updatePreferences(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final prefs = await _notificationService.updatePreferences(
        userId: userId,
        teamId: safeStringNullable(data, 'team_id'),
        newActivity: safeBoolNullable(data, 'new_activity'),
        activityReminder: safeBoolNullable(data, 'activity_reminder'),
        activityCancelled: safeBoolNullable(data, 'activity_cancelled'),
        newFine: safeBoolNullable(data, 'new_fine'),
        fineDecision: safeBoolNullable(data, 'fine_decision'),
        teamMessage: safeBoolNullable(data, 'team_message'),
      );

      return resp.ok(prefs.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
