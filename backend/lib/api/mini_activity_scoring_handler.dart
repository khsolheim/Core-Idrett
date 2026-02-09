import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/mini_activity_service.dart';
import '../services/mini_activity_result_service.dart';
import '../services/mini_activity_statistics_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class MiniActivityScoringHandler {
  final MiniActivityService _miniActivityService;
  final MiniActivityResultService _resultService;
  final MiniActivityStatsAggregationService? _aggregationService;

  MiniActivityScoringHandler(this._miniActivityService, this._resultService, [this._aggregationService]);

  Router get router {
    final router = Router();

    // Scores and Results
    router.post('/<miniActivityId>/scores', _recordScores);
    router.post('/<miniActivityId>/result', _setWinner);
    router.delete('/<miniActivityId>/result', _clearResult);

    // Adjustments (bonus/penalty)
    router.get('/<miniActivityId>/adjustments', _getAdjustments);
    router.post('/<miniActivityId>/adjustments', _createAdjustment);

    // Leaderboard
    router.get('/<miniActivityId>/leaderboard', _getMiniActivityLeaderboard);

    return router;
  }

  // ============ SCORES ============

  Future<Response> _recordScores(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final teamScores = (safeMapNullable(data, 'team_scores'))
          ?.map((k, v) => MapEntry(k, v as int)) ?? {};
      final participantPoints = (safeMapNullable(data, 'participant_points'))
          ?.map((k, v) => MapEntry(k, v as int)) ?? {};

      await _resultService.recordMultipleScores(
        miniActivityId: miniActivityId,
        teamScores: teamScores,
        participantPoints: participantPoints,
      );

      // Return the updated mini-activity detail
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ RESULT MANAGEMENT ============

  Future<Response> _setWinner(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final winnerTeamId = safeStringNullable(data, 'winner_team_id');
      final addToLeaderboard = safeBool(data, 'add_to_leaderboard', defaultValue: false);

      await _resultService.setWinner(
        miniActivityId: miniActivityId,
        winnerTeamId: winnerTeamId,
        addToLeaderboard: addToLeaderboard,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _clearResult(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _resultService.clearResult(miniActivityId);

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ ADJUSTMENTS ============

  Future<Response> _getAdjustments(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final adjustments = await _resultService.getAdjustments(miniActivityId);
      return resp.ok(adjustments.map((a) => a.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _createAdjustment(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final points = safeIntNullable(data, 'points');
      if (points == null) {
        return resp.badRequest('Mangler påkrevd felt (points)');
      }

      final adjustment = await _resultService.awardAdjustment(
        miniActivityId: miniActivityId,
        teamId: safeStringNullable(data, 'team_id'),
        userId: safeStringNullable(data, 'user_id'),
        points: points,
        reason: safeStringNullable(data, 'reason'),
        createdBy: userId,
      );

      return resp.ok(adjustment.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ LEADERBOARD ============

  Future<Response> _getMiniActivityLeaderboard(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final aggregationService = _aggregationService;
      if (aggregationService == null) {
        return resp.serverError('Statistikktjeneste ikke tilgjengelig');
      }

      // Get teamId from mini activity - first check for team_id directly
      final miniActivity = await _miniActivityService.getMiniActivityById(miniActivityId);
      if (miniActivity == null) {
        return resp.notFound('Mini-aktivitet ikke funnet');
      }

      // Use the activity's team_id if available
      String? teamId = miniActivity.teamId;

      // If no direct teamId, try to get from instance
      if (teamId == null) {
        final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
        teamId = detail?['team_id'] as String?;
      }

      if (teamId == null) {
        return resp.badRequest('Mini-aktivitet mangler team_id');
      }

      final leaderboard = await aggregationService.getMiniActivityLeaderboard(teamId: teamId);
      return resp.ok(leaderboard);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
