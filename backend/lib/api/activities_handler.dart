import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/activity_service.dart';
import '../services/activity_instance_service.dart';
import '../services/team_service.dart';
import 'activity_instances_handler.dart';
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

    // Activity routes
    router.patch('/<activityId>', _updateActivity);
    router.delete('/<activityId>', _deleteActivity);

    // Mount instance routes
    final instancesHandler = ActivityInstancesHandler(
      _activityService,
      _activityInstanceService,
      _teamService,
    );
    router.mount('/', instancesHandler.router.call);

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
}
