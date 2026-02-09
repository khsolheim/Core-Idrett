import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/points_config_service.dart' show ManualAdjustmentService, AdjustmentType;
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class PointsAdjustmentsHandler {
  final ManualAdjustmentService _adjustmentService;
  final TeamService _teamService;

  PointsAdjustmentsHandler(this._adjustmentService, this._teamService);

  Router get router {
    final router = Router();

    router.post('/teams/<teamId>/adjust', _createAdjustment);
    router.get('/teams/<teamId>/adjustments', _getTeamAdjustments);
    router.get('/users/<userId>/adjustments', _getUserAdjustments);

    return router;
  }

  Future<Response> _createAdjustment(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan justere poeng');
      }

      final body = await parseBody(request);

      final targetUserId = safeStringNullable(body, 'user_id');
      final points = safeIntNullable(body, 'points');
      final adjustmentTypeStr = safeStringNullable(body, 'adjustment_type');
      final reason = safeStringNullable(body, 'reason');

      if (targetUserId == null ||
          points == null ||
          adjustmentTypeStr == null ||
          reason == null) {
        return resp.badRequest(
          'user_id, points, adjustment_type og reason er påkrevd',
        );
      }

      if (reason.trim().isEmpty) {
        return resp.badRequest('Begrunnelse kan ikke være tom');
      }

      final adjustmentType = AdjustmentType.fromString(adjustmentTypeStr);

      final adjustment = await _adjustmentService.createAdjustment(
        teamId: teamId,
        userId: targetUserId,
        points: points,
        adjustmentType: adjustmentType,
        reason: reason.trim(),
        createdBy: userId,
        seasonId: safeStringNullable(body, 'season_id'),
      );

      return resp.ok(adjustment.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette justering');
    }
  }

  Future<Response> _getTeamAdjustments(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasonId = request.url.queryParameters['season_id'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) : null;

      final adjustments = await _adjustmentService.getTeamAdjustments(
        teamId,
        seasonId: seasonId,
        limit: limit,
      );

      return resp.ok({
        'adjustments': adjustments.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente justeringer');
    }
  }

  Future<Response> _getUserAdjustments(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final adjustments = await _adjustmentService.getUserAdjustments(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return resp.ok({
        'adjustments': adjustments.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente justeringer');
    }
  }
}
