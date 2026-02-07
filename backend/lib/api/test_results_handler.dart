import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/test_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class TestResultsHandler {
  final TestService _testService;
  final TeamService _teamService;

  TestResultsHandler(this._testService, this._teamService);

  Router get router {
    final router = Router();

    router.get('/templates/<templateId>/results', _getResults);
    router.get('/templates/<templateId>/ranking', _getRanking);
    router.post('/templates/<templateId>/results', _recordResult);
    router.post('/templates/<templateId>/results/bulk', _recordBulkResults);
    router.delete('/results/<resultId>', _deleteResult);

    router.get('/teams/<teamId>/users/<userId>/results', _getUserResults);
    router.get('/templates/<templateId>/users/<userId>/best', _getPersonalBest);
    router.get('/templates/<templateId>/users/<userId>/progress', _getUserProgress);

    return router;
  }

  Future<Response> _getResults(Request request, String templateId) async {
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
        return resp.forbidden('Ingen tilgang til denne testmalen');
      }

      final targetUserId = request.url.queryParameters['user_id'];
      final limitParam = request.url.queryParameters['limit'];
      final offsetParam = request.url.queryParameters['offset'];

      final results = await _testService.getResultsForTemplate(
        templateId,
        userId: targetUserId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
        offset: offsetParam != null ? int.tryParse(offsetParam) ?? 0 : 0,
      );

      return resp.ok({
        'results': results.map((r) => r.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente resultater: $e');
    }
  }

  Future<Response> _getRanking(Request request, String templateId) async {
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
        return resp.forbidden('Ingen tilgang til denne testmalen');
      }

      final limitParam = request.url.queryParameters['limit'];

      final ranking = await _testService.getTestRanking(
        templateId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
      );

      return resp.ok({
        'ranking': ranking,
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente ranking: $e');
    }
  }

  Future<Response> _recordResult(Request request, String templateId) async {
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
        return resp.forbidden('Kun admin kan registrere resultater');
      }

      final body = await parseBody(request);
      final targetUserId = body['user_id'] as String?;
      final value = body['value'];

      if (targetUserId == null) {
        return resp.badRequest('user_id er pakrevd');
      }

      if (value == null) {
        return resp.badRequest('value er pakrevd');
      }

      final result = await _testService.recordResult(
        testTemplateId: templateId,
        userId: targetUserId,
        instanceId: body['instance_id'] as String?,
        value: (value as num).toDouble(),
        notes: body['notes'] as String?,
      );

      return resp.ok(result.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke registrere resultat: $e');
    }
  }

  Future<Response> _recordBulkResults(Request request, String templateId) async {
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
        return resp.forbidden('Kun admin kan registrere resultater');
      }

      final body = await parseBody(request);
      final results = body['results'] as List?;

      if (results == null || results.isEmpty) {
        return resp.badRequest('results er pakrevd');
      }

      final recorded = await _testService.recordMultipleResults(
        testTemplateId: templateId,
        instanceId: body['instance_id'] as String?,
        results: results.cast<Map<String, dynamic>>(),
      );

      return resp.ok({
        'results': recorded.map((r) => r.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke registrere resultater: $e');
    }
  }

  Future<Response> _deleteResult(Request request, String resultId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final result = await _testService.getResultById(resultId);
      if (result == null) {
        return resp.notFound('Resultat ikke funnet');
      }

      final template = await _testService.getTemplateById(result.testTemplateId);
      if (template == null) {
        return resp.notFound('Test-mal ikke funnet');
      }

      final team = await requireTeamMember(_teamService, template.teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan slette resultater');
      }

      await _testService.deleteResult(resultId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette resultat: $e');
    }
  }

  Future<Response> _getUserResults(Request request, String teamId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final limitParam = request.url.queryParameters['limit'];
      final offsetParam = request.url.queryParameters['offset'];

      final results = await _testService.getResultsForUser(
        teamId,
        targetUserId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
        offset: offsetParam != null ? int.tryParse(offsetParam) ?? 0 : 0,
      );

      return resp.ok({
        'results': results.map((r) => r.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente brukerresultater: $e');
    }
  }

  Future<Response> _getPersonalBest(
    Request request,
    String templateId,
    String targetUserId,
  ) async {
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
        return resp.forbidden('Ingen tilgang til denne testmalen');
      }

      final result = await _testService.getPersonalBest(templateId, targetUserId);

      if (result == null) {
        return resp.notFound('Ingen resultater funnet');
      }

      return resp.ok(result.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente personlig rekord: $e');
    }
  }

  Future<Response> _getUserProgress(
    Request request,
    String templateId,
    String targetUserId,
  ) async {
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
        return resp.forbidden('Ingen tilgang til denne testmalen');
      }

      final limitParam = request.url.queryParameters['limit'];

      final results = await _testService.getUserProgress(
        templateId,
        targetUserId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
      );

      return resp.ok({
        'progress': results.map((r) => r.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente progresjon: $e');
    }
  }
}
