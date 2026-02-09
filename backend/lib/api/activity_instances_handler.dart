import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/activity_service.dart';
import '../services/activity_instance_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class ActivityInstancesHandler {
  final ActivityQueryService _queryService;
  final ActivityInstanceService _activityInstanceService;
  final TeamService _teamService;

  ActivityInstancesHandler(
    this._queryService,
    this._activityInstanceService,
    this._teamService,
  );

  Router get router {
    final router = Router();

    router.get('/instances/<instanceId>', _getInstance);
    router.post('/instances/<instanceId>/respond', _respond);
    router.patch('/instances/<instanceId>/status', _updateInstanceStatus);
    router.patch('/instances/<instanceId>', _editInstance);
    router.delete('/instances/<instanceId>', _deleteInstance);
    router.post('/instances/<instanceId>/award-attendance', _awardAttendancePoints);

    return router;
  }

  Future<Response> _getInstance(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instance = await _queryService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      if (await requireTeamMember(_teamService, instance['team_id'] as String, userId) == null) {
        return resp.forbidden('Ingen tilgang til denne aktiviteten');
      }

      return resp.ok(instance);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _respond(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instance = await _queryService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      if (await requireTeamMember(_teamService, instance['team_id'] as String, userId) == null) {
        return resp.forbidden('Ingen tilgang til denne aktiviteten');
      }

      final data = await parseBody(request);

      final response = safeStringNullable(data, 'response');
      final comment = safeStringNullable(data, 'comment');

      if (response != null && !['yes', 'no', 'maybe'].contains(response)) {
        return resp.badRequest('Ugyldig svar');
      }

      await _activityInstanceService.respond(
        instanceId: instanceId,
        userId: userId,
        response: response,
        comment: comment,
      );

      return resp.ok({'message': 'Registrert'});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateInstanceStatus(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instance = await _queryService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final team = await _teamService.getTeamById(instance['team_id'] as String, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan endre status');
      }

      final data = await parseBody(request);

      final status = safeStringNullable(data, 'status');
      if (status == null || !['scheduled', 'completed', 'cancelled'].contains(status)) {
        return resp.badRequest('Ugyldig status');
      }

      await _activityInstanceService.updateInstanceStatus(
        instanceId,
        status,
        reason: safeStringNullable(data, 'reason'),
      );

      return resp.ok({'message': 'Oppdatert'});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  /// Check if user can edit/delete an instance (admin OR activity creator)
  Future<bool> _canManageInstance(String userId, String teamId, String? createdBy) async {
    final team = await _teamService.getTeamById(teamId, userId);
    if (team == null) return false;

    if (isAdmin(team)) return true;

    return createdBy != null && createdBy == userId;
  }

  Future<Response> _editInstance(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instanceInfo = await _activityInstanceService.getInstanceInfo(instanceId);
      if (instanceInfo == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final teamId = instanceInfo['team_id'] as String;
      final createdBy = safeStringNullable(instanceInfo, 'created_by');

      if (!await _canManageInstance(userId, teamId, createdBy)) {
        return resp.forbidden('Du har ikke tilgang til å redigere denne aktiviteten');
      }

      final data = await parseBody(request);

      final editScope = safeStringNullable(data, 'edit_scope');
      if (editScope == null || !['single', 'this_and_future'].contains(editScope)) {
        return resp.badRequest('Mangler eller ugyldig edit_scope (single | this_and_future)');
      }

      Map<String, dynamic> result;

      if (editScope == 'single') {
        result = await _activityInstanceService.editSingleInstance(
          instanceId: instanceId,
          userId: userId,
          title: safeStringNullable(data, 'title'),
          location: safeStringNullable(data, 'location'),
          description: safeStringNullable(data, 'description'),
          startTime: safeStringNullable(data, 'start_time'),
          endTime: safeStringNullable(data, 'end_time'),
          date: data['date'] != null ? DateTime.tryParse(data['date'] as String) : null,
        );
      } else {
        result = await _activityInstanceService.editFutureInstances(
          instanceId: instanceId,
          userId: userId,
          title: safeStringNullable(data, 'title'),
          location: safeStringNullable(data, 'location'),
          description: safeStringNullable(data, 'description'),
          startTime: safeStringNullable(data, 'start_time'),
          endTime: safeStringNullable(data, 'end_time'),
        );
      }

      return resp.ok(result);
    } catch (e) {
      if (e.toString().contains('Cannot')) {
        return resp.badRequest(e.toString());
      }
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _deleteInstance(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instanceInfo = await _activityInstanceService.getInstanceInfo(instanceId);
      if (instanceInfo == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final teamId = instanceInfo['team_id'] as String;
      final createdBy = safeStringNullable(instanceInfo, 'created_by');

      if (!await _canManageInstance(userId, teamId, createdBy)) {
        return resp.forbidden('Du har ikke tilgang til å slette denne aktiviteten');
      }

      final data = await parseBody(request);

      final deleteScope = safeStringNullable(data, 'delete_scope');
      if (deleteScope == null || !['single', 'this_and_future'].contains(deleteScope)) {
        return resp.badRequest('Mangler eller ugyldig delete_scope (single | this_and_future)');
      }

      Map<String, dynamic> result;

      if (deleteScope == 'single') {
        result = await _activityInstanceService.deleteSingleInstance(
          instanceId: instanceId,
          userId: userId,
        );
      } else {
        result = await _activityInstanceService.deleteFutureInstances(
          instanceId: instanceId,
          userId: userId,
        );
      }

      return resp.ok(result);
    } catch (e) {
      if (e.toString().contains('Cannot delete past')) {
        return resp.badRequest('Kan ikke slette aktiviteter i fortiden');
      }
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _awardAttendancePoints(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instanceInfo = await _activityInstanceService.getInstanceInfo(instanceId);
      if (instanceInfo == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final teamId = instanceInfo['team_id'] as String;

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan tildele oppmøtepoeng');
      }

      final pointsAwarded = await _activityInstanceService.awardAttendancePoints(instanceId);

      return resp.ok({
        'message': 'Registrert',
        'points_awarded_to': pointsAwarded,
        'description': 'Oppmøtepoeng tildelt til $pointsAwarded spillere',
      });
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('Cannot award points for future')) {
        return resp.badRequest('Kan ikke tildele poeng for fremtidige aktiviteter');
      }
      if (errorMsg.contains('Cannot award points for cancelled')) {
        return resp.badRequest('Kan ikke tildele poeng for avlyste aktiviteter');
      }
      if (errorMsg.contains('No active season')) {
        return resp.badRequest('Ingen aktiv sesong funnet for laget');
      }
      if (errorMsg.contains('No main leaderboard')) {
        return resp.badRequest('Ingen hovedleaderboard funnet for laget');
      }
      return resp.serverError('En feil oppstod');
    }
  }
}
