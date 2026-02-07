import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/mini_activity_service.dart';
import '../services/mini_activity_template_service.dart';
import '../services/mini_activity_division_service.dart';
import '../services/mini_activity_result_service.dart';
import '../services/team_service.dart';
import '../services/mini_activity_statistics_service.dart';
import 'mini_activity_teams_handler.dart';
import 'mini_activity_scoring_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class MiniActivitiesHandler {
  final MiniActivityService _miniActivityService;
  final MiniActivityTemplateService _templateService;
  final MiniActivityDivisionService _divisionService;
  final MiniActivityResultService _resultService;
  final TeamService _teamService;
  final MiniActivityStatisticsService? _statsService;

  MiniActivitiesHandler(
    this._miniActivityService,
    this._templateService,
    this._divisionService,
    this._resultService,
    this._teamService, [
    this._statsService,
  ]);

  Router get router {
    final router = Router();

    // Template routes
    router.get('/templates/team/<teamId>', _getTemplates);
    router.post('/templates/team/<teamId>', _createTemplate);
    router.put('/templates/<templateId>', _updateTemplate);
    router.delete('/templates/<templateId>', _deleteTemplate);
    router.post('/templates/<templateId>/favorite', _toggleTemplateFavorite);

    // Standalone mini-activity routes (team-based without instance)
    router.get('/standalone/team/<teamId>', _getStandaloneMiniActivities);
    router.post('/standalone/team/<teamId>', _createStandaloneMiniActivity);

    // Mini-activity routes
    router.get('/instance/<instanceId>', _getMiniActivitiesForInstance);
    router.post('/instance/<instanceId>', _createMiniActivity);
    router.get('/<miniActivityId>', _getMiniActivityDetail);
    router.put('/<miniActivityId>', _updateMiniActivity);
    router.delete('/<miniActivityId>', _deleteMiniActivity);
    router.post('/<miniActivityId>/archive', _archiveMiniActivity);
    router.post('/<miniActivityId>/duplicate', _duplicateMiniActivity);

    // History
    router.get('/history/team/<teamId>', _getHistory);

    // Mount team division & handicap routes
    final teamsHandler = MiniActivityTeamsHandler(
      _miniActivityService,
      _divisionService,
    );
    router.mount('/', teamsHandler.router.call);

    // Mount scoring, results & adjustments routes
    final scoringHandler = MiniActivityScoringHandler(
      _miniActivityService,
      _resultService,
      _statsService,
    );
    router.mount('/', scoringHandler.router.call);

    return router;
  }

  // ============ TEMPLATES ============

  Future<Response> _getTemplates(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final templates = await _templateService.getTemplatesForTeam(teamId);
      return resp.ok(templates.map((t) => t.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _createTemplate(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Kun administratorer kan opprette maler');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan opprette maler');
      }

      final data = await parseBody(request);

      final name = data['name'] as String?;
      final type = data['type'] as String?;

      if (name == null || type == null) {
        return resp.badRequest('Mangler påkrevde felt (name, type)');
      }

      if (!['individual', 'team'].contains(type)) {
        return resp.badRequest('Ugyldig type (må være individual eller team)');
      }

      final template = await _templateService.createTemplate(
        teamId: teamId,
        name: name,
        type: type,
        defaultPoints: data['default_points'] as int? ?? 1,
      );

      return resp.ok(template.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _deleteTemplate(Request request, String templateId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _templateService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return resp.notFound('Mal ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan slette maler');
      }

      await _templateService.deleteTemplate(templateId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateTemplate(Request request, String templateId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _templateService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return resp.notFound('Mal ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan oppdatere maler');
      }

      final data = await parseBody(request);

      final template = await _templateService.updateTemplate(
        templateId: templateId,
        name: data['name'] as String?,
        description: data['description'] as String?,
        instructions: data['instructions'] as String?,
        sportType: data['sport_type'] as String?,
        suggestedRules: data['suggested_rules'] as Map<String, dynamic>?,
        winPoints: data['win_points'] as int?,
        drawPoints: data['draw_points'] as int?,
        lossPoints: data['loss_points'] as int?,
        defaultPoints: data['default_points'] as int?,
      );

      if (template == null) {
        return resp.notFound('Mal ikke funnet');
      }

      return resp.ok(template.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _toggleTemplateFavorite(Request request, String templateId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _templateService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return resp.notFound('Mal ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang');
      }

      await _templateService.toggleTemplateFavorite(templateId);

      // Fetch updated templates to return the updated one
      final templates = await _templateService.getTemplatesForTeam(teamId);
      final updatedTemplate = templates.firstWhere((t) => t.id == templateId);
      return resp.ok(updatedTemplate.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ MINI-ACTIVITIES ============

  Future<Response> _getMiniActivitiesForInstance(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final miniActivities = await _miniActivityService.getMiniActivitiesForInstance(instanceId);
      return resp.ok(miniActivities);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _createMiniActivity(Request request, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final name = data['name'] as String?;
      final type = data['type'] as String?;

      if (name == null || type == null) {
        return resp.badRequest('Mangler påkrevde felt (name, type)');
      }

      final miniActivity = await _miniActivityService.createMiniActivity(
        instanceId: instanceId,
        templateId: data['template_id'] as String?,
        name: name,
        type: type,
      );

      return resp.ok(miniActivity.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getMiniActivityDetail(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      if (detail == null) {
        return resp.notFound('Mini-aktivitet ikke funnet');
      }

      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      await _miniActivityService.updateMiniActivity(
        miniActivityId: miniActivityId,
        name: data['name'] as String?,
        description: data['description'] as String?,
        winPoints: data['win_points'] as int?,
        drawPoints: data['draw_points'] as int?,
        lossPoints: data['loss_points'] as int?,
        enableLeaderboard: data['enable_leaderboard'] as bool?,
        maxParticipants: data['max_participants'] as int?,
        handicapEnabled: data['handicap_enabled'] as bool?,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _deleteMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _miniActivityService.deleteMiniActivity(miniActivityId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ STANDALONE MINI-ACTIVITIES ============

  Future<Response> _getStandaloneMiniActivities(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final includeArchived = request.url.queryParameters['include_archived'] == 'true';
      final miniActivities = await _miniActivityService.getStandaloneMiniActivitiesForTeam(
        teamId,
        includeArchived: includeArchived,
      );
      return resp.ok(miniActivities);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _createStandaloneMiniActivity(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Kun administratorer kan opprette mini-aktiviteter');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan opprette mini-aktiviteter');
      }

      final data = await parseBody(request);

      final name = data['name'] as String?;
      final type = data['type'] as String?;

      if (name == null || type == null) {
        return resp.badRequest('Mangler påkrevde felt (name, type)');
      }

      final miniActivity = await _miniActivityService.createStandaloneMiniActivity(
        teamId: teamId,
        templateId: data['template_id'] as String?,
        name: name,
        type: type,
        description: data['description'] as String?,
        leaderboardId: data['leaderboard_id'] as String?,
        enableLeaderboard: data['enable_leaderboard'] as bool? ?? true,
        winPoints: data['win_points'] as int? ?? 3,
        drawPoints: data['draw_points'] as int? ?? 1,
        lossPoints: data['loss_points'] as int? ?? 0,
      );

      return resp.ok(miniActivity.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ ARCHIVE & DUPLICATE ============

  Future<Response> _archiveMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _miniActivityService.archiveMiniActivity(miniActivityId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _duplicateMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final newMiniActivity = await _miniActivityService.duplicateMiniActivity(
        miniActivityId: miniActivityId,
        newName: data['new_name'] as String?,
      );

      return resp.ok(newMiniActivity.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ HISTORY ============

  Future<Response> _getHistory(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final templateId = request.url.queryParameters['template_id'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 20 : 20;

      final history = await _miniActivityService.getHistory(
        teamId: teamId,
        templateId: templateId,
        limit: limit,
      );

      return resp.ok(history);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
