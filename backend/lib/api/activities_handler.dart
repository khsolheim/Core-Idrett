import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/activity_service.dart';
import '../services/activity_instance_service.dart';
import '../services/team_service.dart';
import 'activity_instances_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class ActivitiesHandler {
  final ActivityCrudService _crudService;
  final ActivityQueryService _queryService;
  final ActivityInstanceService _activityInstanceService;
  final TeamService _teamService;

  ActivitiesHandler(
    this._crudService,
    this._queryService,
    this._activityInstanceService,
    this._teamService,
  );

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
      _queryService,
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

      final activities = await _queryService.getActivitiesForTeam(teamId);
      return resp.ok(activities);
    } catch (e) {
      return resp.serverError('En feil oppstod');
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

      final title = safeStringNullable(data, 'title');
      final type = safeStringNullable(data, 'type');
      final firstDate = safeStringNullable(data, 'first_date');

      if (title == null || type == null || firstDate == null) {
        return resp.badRequest('Mangler påkrevde felt (title, type, first_date)');
      }

      final firstDateParsed = DateTime.tryParse(firstDate);
      if (firstDateParsed == null) {
        return resp.badRequest('Ugyldig datoformat for first_date');
      }

      DateTime? recurrenceEndDate;
      if (data['recurrence_end_date'] != null) {
        recurrenceEndDate = DateTime.tryParse(data['recurrence_end_date'] as String);
        if (recurrenceEndDate == null) {
          return resp.badRequest('Ugyldig datoformat for recurrence_end_date');
        }
      }

      final activity = await _crudService.createActivity(
        teamId: teamId,
        title: title,
        type: type,
        location: safeStringNullable(data, 'location'),
        description: safeStringNullable(data, 'description'),
        recurrenceType: safeStringNullable(data, 'recurrence_type') ?? 'once',
        recurrenceEndDate: recurrenceEndDate,
        responseType: safeStringNullable(data, 'response_type') ?? 'yes_no',
        responseDeadlineHours: safeIntNullable(data, 'response_deadline_hours'),
        createdBy: userId,
        firstDate: firstDateParsed,
        startTime: safeStringNullable(data, 'start_time'),
        endTime: safeStringNullable(data, 'end_time'),
      );

      return resp.ok(activity.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
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

      final instances = await _queryService.getUpcomingInstances(teamId, limit: limit);
      return resp.ok(instances);
    } catch (e) {
      return resp.serverError('En feil oppstod');
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

      final from = DateTime.tryParse(fromParam);
      if (from == null) {
        return resp.badRequest('Ugyldig datoformat for from');
      }

      final to = DateTime.tryParse(toParam);
      if (to == null) {
        return resp.badRequest('Ugyldig datoformat for to');
      }

      final instances = await _queryService.getInstancesByDateRange(
        teamId,
        from: from,
        to: to,
        userId: userId,
      );
      return resp.ok(instances);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _deleteActivity(Request request, String activityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _crudService.getTeamIdForActivity(activityId);
      if (teamId == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan slette aktiviteter');
      }

      await _crudService.deleteActivity(activityId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateActivity(Request request, String activityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _crudService.getTeamIdForActivity(activityId);
      if (teamId == null) {
        return resp.notFound('Aktivitet ikke funnet');
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan oppdatere aktiviteter');
      }

      final data = await parseBody(request);

      final title = safeStringNullable(data, 'title');
      final type = safeStringNullable(data, 'type');

      if (title == null || type == null) {
        return resp.badRequest('Mangler påkrevde felt (title, type)');
      }

      final activity = await _crudService.updateActivity(
        activityId: activityId,
        title: title,
        type: type,
        location: safeStringNullable(data, 'location'),
        description: safeStringNullable(data, 'description'),
      );

      return resp.ok(activity.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
