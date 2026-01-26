import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/mini_activity_service.dart';
import '../services/team_service.dart';

class MiniActivitiesHandler {
  final MiniActivityService _miniActivityService;
  final AuthService _authService;
  final TeamService _teamService;

  MiniActivitiesHandler(this._miniActivityService, this._authService, this._teamService);

  Router get router {
    final router = Router();

    // Template routes
    router.get('/templates/team/<teamId>', _getTemplates);
    router.post('/templates/team/<teamId>', _createTemplate);
    router.delete('/templates/<templateId>', _deleteTemplate);

    // Mini-activity routes
    router.get('/instance/<instanceId>', _getMiniActivitiesForInstance);
    router.post('/instance/<instanceId>', _createMiniActivity);
    router.get('/<miniActivityId>', _getMiniActivityDetail);
    router.delete('/<miniActivityId>', _deleteMiniActivity);

    // Team division
    router.post('/<miniActivityId>/divide-teams', _divideTeams);

    // Scores
    router.post('/<miniActivityId>/scores', _recordScores);

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

  Future<bool> _isTeamAdmin(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    return team != null && team['user_role'] == 'admin';
  }

  // ============ TEMPLATES ============

  Future<Response> _getTemplates(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final templates = await _miniActivityService.getTemplatesForTeam(teamId);
      return Response.ok(jsonEncode(templates.map((t) => t.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _createTemplate(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan opprette maler'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final type = data['type'] as String?;

      if (name == null || type == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (name, type)'}));
      }

      if (!['individual', 'team'].contains(type)) {
        return Response(400, body: jsonEncode({'error': 'Ugyldig type (må være individual eller team)'}));
      }

      final template = await _miniActivityService.createTemplate(
        teamId: teamId,
        name: name,
        type: type,
        defaultPoints: data['default_points'] as int? ?? 1,
      );

      return Response.ok(jsonEncode(template.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteTemplate(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final teamId = await _miniActivityService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response(404, body: jsonEncode({'error': 'Mal ikke funnet'}));
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan slette maler'}));
      }

      await _miniActivityService.deleteTemplate(templateId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ MINI-ACTIVITIES ============

  Future<Response> _getMiniActivitiesForInstance(Request request, String instanceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final miniActivities = await _miniActivityService.getMiniActivitiesForInstance(instanceId);
      return Response.ok(jsonEncode(miniActivities));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _createMiniActivity(Request request, String instanceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final type = data['type'] as String?;

      if (name == null || type == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (name, type)'}));
      }

      final miniActivity = await _miniActivityService.createMiniActivity(
        instanceId: instanceId,
        templateId: data['template_id'] as String?,
        name: name,
        type: type,
      );

      return Response.ok(jsonEncode(miniActivity.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getMiniActivityDetail(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      if (detail == null) {
        return Response(404, body: jsonEncode({'error': 'Mini-aktivitet ikke funnet'}));
      }

      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _miniActivityService.deleteMiniActivity(miniActivityId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ TEAM DIVISION ============

  Future<Response> _divideTeams(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final method = data['method'] as String?;
      final numberOfTeams = data['number_of_teams'] as int?;
      final participantUserIds = (data['participant_user_ids'] as List?)?.cast<String>();
      final teamId = data['team_id'] as String? ?? '';

      if (method == null || numberOfTeams == null || participantUserIds == null) {
        return Response(400, body: jsonEncode({
          'error': 'Mangler påkrevde felt (method, number_of_teams, participant_user_ids)'
        }));
      }

      if (!['random', 'ranked', 'age'].contains(method)) {
        return Response(400, body: jsonEncode({'error': 'Ugyldig metode (random, ranked, age)'}));
      }

      if (numberOfTeams < 2) {
        return Response(400, body: jsonEncode({'error': 'Må ha minst 2 lag'}));
      }

      if (participantUserIds.length < numberOfTeams) {
        return Response(400, body: jsonEncode({'error': 'For få deltakere for antall lag'}));
      }

      await _miniActivityService.divideTeams(
        miniActivityId: miniActivityId,
        method: method,
        numberOfTeams: numberOfTeams,
        participantUserIds: participantUserIds,
        teamId: teamId,
      );

      // Return the updated mini-activity detail
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ SCORES ============

  Future<Response> _recordScores(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final teamScores = (data['team_scores'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)) ?? {};
      final participantPoints = (data['participant_points'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)) ?? {};

      await _miniActivityService.recordMultipleScores(
        miniActivityId: miniActivityId,
        teamScores: teamScores,
        participantPoints: participantPoints,
      );

      // Return the updated mini-activity detail
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }
}
