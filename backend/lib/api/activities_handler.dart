import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/activity_service.dart';
import '../services/team_service.dart';

class ActivitiesHandler {
  final ActivityService _activityService;
  final AuthService _authService;
  final TeamService _teamService;

  ActivitiesHandler(this._activityService, this._authService, this._teamService);

  Router get router {
    final router = Router();

    // Team-scoped routes
    router.get('/team/<teamId>', _getTeamActivities);
    router.post('/team/<teamId>', _createActivity);
    router.get('/team/<teamId>/upcoming', _getUpcomingInstances);

    // Instance routes
    router.get('/instances/<instanceId>', _getInstance);
    router.post('/instances/<instanceId>/respond', _respond);
    router.patch('/instances/<instanceId>/status', _updateInstanceStatus);

    // Activity routes
    router.patch('/<activityId>', _updateActivity);
    router.delete('/<activityId>', _deleteActivity);

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

  Future<bool> _isTeamMember(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    return team != null;
  }

  Future<Response> _getTeamActivities(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final activities = await _activityService.getActivitiesForTeam(teamId);
      return Response.ok(jsonEncode(activities));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _createActivity(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      // Only admins can create activities
      if (team['user_role'] != 'admin') {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan opprette aktiviteter'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final title = data['title'] as String?;
      final type = data['type'] as String?;
      final firstDate = data['first_date'] as String?;

      if (title == null || type == null || firstDate == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (title, type, first_date)'}));
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

      return Response.ok(jsonEncode(activity.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getUpcomingInstances(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final limitParam = request.url.queryParameters['limit'];
      final limit = limitParam != null ? int.tryParse(limitParam) ?? 20 : 20;

      final instances = await _activityService.getUpcomingInstances(teamId, limit: limit);
      return Response.ok(jsonEncode(instances));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getInstance(Request request, String instanceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final instance = await _activityService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return Response(404, body: jsonEncode({'error': 'Aktivitet ikke funnet'}));
      }

      // Verify user is member of team
      if (!await _isTeamMember(userId, instance['team_id'] as String)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til denne aktiviteten'}));
      }

      return Response.ok(jsonEncode(instance));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _respond(Request request, String instanceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final instance = await _activityService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return Response(404, body: jsonEncode({'error': 'Aktivitet ikke funnet'}));
      }

      if (!await _isTeamMember(userId, instance['team_id'] as String)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til denne aktiviteten'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final response = data['response'] as String?;
      final comment = data['comment'] as String?;

      if (response != null && !['yes', 'no', 'maybe'].contains(response)) {
        return Response(400, body: jsonEncode({'error': 'Ugyldig svar'}));
      }

      await _activityService.respond(
        instanceId: instanceId,
        userId: userId,
        response: response,
        comment: comment,
      );

      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _updateInstanceStatus(Request request, String instanceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final instance = await _activityService.getInstanceWithResponses(instanceId, userId);
      if (instance == null) {
        return Response(404, body: jsonEncode({'error': 'Aktivitet ikke funnet'}));
      }

      final team = await _teamService.getTeamById(instance['team_id'] as String, userId);
      if (team == null || team['user_role'] != 'admin') {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan endre status'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final status = data['status'] as String?;
      if (status == null || !['scheduled', 'completed', 'cancelled'].contains(status)) {
        return Response(400, body: jsonEncode({'error': 'Ugyldig status'}));
      }

      await _activityService.updateInstanceStatus(
        instanceId,
        status,
        reason: data['reason'] as String?,
      );

      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteActivity(Request request, String activityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final teamId = await _activityService.getTeamIdForActivity(activityId);
      if (teamId == null) {
        return Response(404, body: jsonEncode({'error': 'Aktivitet ikke funnet'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || team['user_role'] != 'admin') {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan slette aktiviteter'}));
      }

      await _activityService.deleteActivity(activityId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _updateActivity(Request request, String activityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final teamId = await _activityService.getTeamIdForActivity(activityId);
      if (teamId == null) {
        return Response(404, body: jsonEncode({'error': 'Aktivitet ikke funnet'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || team['user_role'] != 'admin') {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan oppdatere aktiviteter'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final title = data['title'] as String?;
      final type = data['type'] as String?;

      if (title == null || type == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (title, type)'}));
      }

      final activity = await _activityService.updateActivity(
        activityId: activityId,
        title: title,
        type: type,
        location: data['location'] as String?,
        description: data['description'] as String?,
      );

      return Response.ok(jsonEncode(activity.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }
}
