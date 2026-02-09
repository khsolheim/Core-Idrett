import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/test_service.dart';
import '../services/team_service.dart';
import 'test_results_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class TestsHandler {
  final TestService _testService;
  final TeamService _teamService;

  TestsHandler(this._testService, this._teamService);

  Router get router {
    final router = Router();

    // Template routes
    router.get('/templates/teams/<teamId>', _getTemplates);
    router.post('/templates/teams/<teamId>', _createTemplate);
    router.get('/templates/<templateId>', _getTemplateById);
    router.patch('/templates/<templateId>', _updateTemplate);
    router.delete('/templates/<templateId>', _deleteTemplate);

    // Mount results routes
    final resultsHandler = TestResultsHandler(_testService, _teamService);
    router.mount('/', resultsHandler.router.call);

    return router;
  }

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

      final templates = await _testService.getTemplatesForTeam(teamId);

      return resp.ok({
        'templates': templates.map((t) => t.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente testmaler');
    }
  }

  Future<Response> _getTemplateById(Request request, String templateId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final template = await _testService.getTemplateById(templateId);
      if (template == null) {
        return resp.notFound('Testmal ikke funnet');
      }

      final team = await requireTeamMember(_teamService, template.teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til denne testmalen');
      }

      return resp.ok(template.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente testmal');
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
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan opprette testmaler');
      }

      final body = await parseBody(request);
      final name = safeStringNullable(body, 'name');
      final unit = safeStringNullable(body, 'unit');

      if (name == null || name.isEmpty) {
        return resp.badRequest('Navn er pakrevd');
      }

      if (unit == null || unit.isEmpty) {
        return resp.badRequest('Enhet er pakrevd');
      }

      final template = await _testService.createTemplate(
        teamId: teamId,
        name: name,
        description: safeStringNullable(body, 'description'),
        unit: unit,
        higherIsBetter: safeBool(body, 'higher_is_better', defaultValue: false),
      );

      return resp.ok(template.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette testmal');
    }
  }

  Future<Response> _updateTemplate(Request request, String templateId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return resp.notFound('Testmal ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan oppdatere testmaler');
      }

      final body = await parseBody(request);

      final template = await _testService.updateTemplate(
        templateId: templateId,
        name: safeStringNullable(body, 'name'),
        description: safeStringNullable(body, 'description'),
        unit: safeStringNullable(body, 'unit'),
        higherIsBetter: safeBoolNullable(body, 'higher_is_better'),
        clearDescription: body['clear_description'] == true,
      );

      if (template == null) {
        return resp.notFound('Testmal ikke funnet');
      }

      return resp.ok(template.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere testmal');
    }
  }

  Future<Response> _deleteTemplate(Request request, String templateId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return resp.notFound('Testmal ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan slette testmaler');
      }

      await _testService.deleteTemplate(templateId);

      return resp.ok({'message': 'Test slettet'});
    } catch (e) {
      return resp.serverError('Kunne ikke slette testmal');
    }
  }
}
