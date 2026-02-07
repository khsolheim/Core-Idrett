import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/activity_service.dart';
import '../services/activity_instance_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class ActivitiesHandler {
  final ActivityService _activityService;
  final ActivityInstanceService _activityInstanceService;
  final TeamService _teamService;

  ActivitiesHandler(this._activityService, this._activityInstanceService, this._teamService);

  Router get router {
    final router = Router();

    // Team-scoped routes
    router.get('/team/<teamId>', _getTeamActivities);
    router.post('/team/<teamId>', _createActivity);
    router.get('/team/<teamId>/upcoming', _getUpcomingInstances);
    router.get('/team/<teamId>/instances', _getInstancesByDateRange);

    // Instance routes
    router.get('/instances/<instanceId>', _getInstance);
    router.post('/instances/<instanceId>/respond', _respond);
    router.patch('/instances/<instanceId>/status', _updateInstanceStatus);
    router.patch('/instances/<instanceId>', _editInstance);
    router.delete('/instances/<instanceId>', _deleteInstance);
    router.post('/instances/<instanceId>/award-attendance', _awardAttendancePoints);

    // Activity routes
    router.patch('/<activityId>', _updateActivity);
    router.delete('/<activityId>', _deleteActivity);

    return router;
  }

  Future<Response> _getTeamActivities(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      if (await requireTeamMember(_teamService, teamId, userId) == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final activities = await _activityService.getActivitiesForTeam(teamId);
      return resp.ok(activities);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _createActivity(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      // Only admins can create activities
      if (!isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan opprette aktiviteter');
      }

      final data = await parseBody(request);

      final title = data['title'] as String?;
      final type = data['type'] as String?;
      final firstDate = data['first_date'] as String?;

      if (title == null || type == null || firstDate == null) {
        return resp.badRequest('Mangler påkrevde felt (title, type, first_date)');
      }

      final activity = await _activityService.createActivity(
        teamId: teamId,
        title: title,
        type: type,
        location: data['location'] as String?,
        description: data['description'] as String?,
        recurrenceType: data['recurrence_type'] as String? ?? 'once',
        recurrenceEndDate: data['recurrence_end_date'] != null
            ? DateTime.parse(data['recurrence_end_date'] as String)
            : null,
        responseType: data['response_type'] as String? ?? 'yes_no',
        responseDeadlineHours: data['response_deadline_hours'] as int?,
        createdBy: userId,
        firstDate: DateTime.parse(firstDate),
        startTime: data['start_time'] as String?,
        endTime: data['end_time'] as String?,
      );

      return resp.ok(activity.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getUpcomingInstances(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      if (await requireTeamMember(_teamService, teamId, userId) == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final limitParam = request.url.queryParameters['limit'];
      final limit = limitParam != null ? int.tryParse(limitParam) ?? 20 : 20;

      final instances = await _activityService.getUpcomingInstances(teamId, limit: limit);
      return resp.ok(instances);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getInstancesByDateRange(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      if (await requireTeamMember(_teamService, teamId, userId) == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final fromParam = request.url.queryParameters['from'];
      final toParam = request.url.queryParameters['to'];

      if (fromParam == null || toParam == null) {
        return resp.badRequest('Mangler from og to parametere');
      }

      final from = DateTime.parse(fromParam);
      final to = DateTime.parse(toParam);

      final instances = await _activityService.getInstancesByDateRange(
        teamId,
        from: from,
        to: to,
        userId: userId,
      );
      return resp.ok(instances);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _getInstance(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instance = await _activityService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      // Verify user is member of team
      if (await requireTeamMember(_teamService, instance['team_id'] as String, userId) == null) {
        return resp.forbidden('Ingen tilgang til denne aktiviteten');
      }

      return resp.ok(instance);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _respond(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instance = await _activityService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      if (await requireTeamMember(_teamService, instance['team_id'] as String, userId) == null) {
        return resp.forbidden('Ingen tilgang til denne aktiviteten');
      }

      final data = await parseBody(request);

      final response = data['response'] as String?;
      final comment = data['comment'] as String?;

      if (response != null && !['yes', 'no', 'maybe'].contains(response)) {
        return resp.badRequest('Ugyldig svar');
      }

      await _activityInstanceService.respond(
        instanceId: instanceId,
        userId: userId,
        response: response,
        comment: comment,
      );

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateInstanceStatus(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final instance = await _activityService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final team = await _teamService.getTeamById(instance['team_id'] as String, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan endre status');
      }

      final data = await parseBody(request);

      final status = data['status'] as String?;
      if (status == null || !['scheduled', 'completed', 'cancelled'].contains(status)) {
        return resp.badRequest('Ugyldig status');
      }

      await _activityInstanceService.updateInstanceStatus(
        instanceId,
        status,
        reason: data['reason'] as String?,
      );

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _deleteActivity(Request request, String activityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _activityService.getTeamIdForActivity(activityId);
      if (teamId == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan slette aktiviteter');
      }

      await _activityService.deleteActivity(activityId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateActivity(Request request, String activityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _activityService.getTeamIdForActivity(activityId);
      if (teamId == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan oppdatere aktiviteter');
      }

      final data = await parseBody(request);

      final title = data['title'] as String?;
      final type = data['type'] as String?;

      if (title == null || type == null) {
        return resp.badRequest('Mangler påkrevde felt (title, type)');
      }

      final activity = await _activityService.updateActivity(
        activityId: activityId,
        title: title,
        type: type,
        location: data['location'] as String?,
        description: data['description'] as String?,
      );

      return resp.ok(activity.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  /// Check if user can edit/delete an instance (admin OR activity creator)
  Future<bool> _canManageInstance(String userId, String teamId, String? createdBy) async {
    final team = await _teamService.getTeamById(teamId, userId);
    if (team == null) return false;

    // Admin can always manage
    if (isAdmin(team)) return true;

    // Creator can manage their own activities
    return createdBy != null && createdBy == userId;
  }

  Future<Response> _editInstance(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Get instance info for authorization
      final instanceInfo = await _activityInstanceService.getInstanceInfo(instanceId);
      if (instanceInfo == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final teamId = instanceInfo['team_id'] as String;
      final createdBy = instanceInfo['created_by'] as String?;

      // Check authorization
      if (!await _canManageInstance(userId, teamId, createdBy)) {
        return resp.forbidden('Du har ikke tilgang til å redigere denne aktiviteten');
      }

      final data = await parseBody(request);

      final editScope = data['edit_scope'] as String?;
      if (editScope == null || !['single', 'this_and_future'].contains(editScope)) {
        return resp.badRequest('Mangler eller ugyldig edit_scope (single | this_and_future)');
      }

      Map<String, dynamic> result;

      if (editScope == 'single') {
        result = await _activityInstanceService.editSingleInstance(
          instanceId: instanceId,
          userId: userId,
          title: data['title'] as String?,
          location: data['location'] as String?,
          description: data['description'] as String?,
          startTime: data['start_time'] as String?,
          endTime: data['end_time'] as String?,
          date: data['date'] != null ? DateTime.parse(data['date'] as String) : null,
        );
      } else {
        result = await _activityInstanceService.editFutureInstances(
          instanceId: instanceId,
          userId: userId,
          title: data['title'] as String?,
          location: data['location'] as String?,
          description: data['description'] as String?,
          startTime: data['start_time'] as String?,
          endTime: data['end_time'] as String?,
        );
      }

      return resp.ok(result);
    } catch (e) {
      if (e.toString().contains('Cannot')) {
        return resp.badRequest(e.toString());
      }
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _deleteInstance(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Get instance info for authorization
      final instanceInfo = await _activityInstanceService.getInstanceInfo(instanceId);
      if (instanceInfo == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final teamId = instanceInfo['team_id'] as String;
      final createdBy = instanceInfo['created_by'] as String?;

      // Check authorization
      if (!await _canManageInstance(userId, teamId, createdBy)) {
        return resp.forbidden('Du har ikke tilgang til å slette denne aktiviteten');
      }

      final data = await parseBody(request);

      final deleteScope = data['delete_scope'] as String?;
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
      return resp.serverError('En feil oppstod: $e');
    }
  }

  /// Award attendance points to all users who responded 'yes' to a completed activity
  Future<Response> _awardAttendancePoints(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Get instance info for authorization
      final instanceInfo = await _activityInstanceService.getInstanceInfo(instanceId);
      if (instanceInfo == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final teamId = instanceInfo['team_id'] as String;

      // Only admins can award attendance points
      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan tildele oppmøtepoeng');
      }

      final pointsAwarded = await _activityInstanceService.awardAttendancePoints(instanceId);

      return resp.ok({
        'success': true,
        'points_awarded_to': pointsAwarded,
        'message': 'Oppmøtepoeng tildelt til $pointsAwarded spillere',
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
      return resp.serverError('En feil oppstod: $e');
    }
  }
}
