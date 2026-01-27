import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/test_service.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';

class TestsHandler {
  final TestService _testService;
  final AuthService _authService;
  final TeamService _teamService;

  TestsHandler(this._testService, this._authService, this._teamService);

  Router get router {
    final router = Router();

    // Template routes
    router.get('/templates/teams/<teamId>', _getTemplates);
    router.post('/templates/teams/<teamId>', _createTemplate);
    router.get('/templates/<templateId>', _getTemplateById);
    router.patch('/templates/<templateId>', _updateTemplate);
    router.delete('/templates/<templateId>', _deleteTemplate);

    // Results routes
    router.get('/templates/<templateId>/results', _getResults);
    router.get('/templates/<templateId>/ranking', _getRanking);
    router.post('/templates/<templateId>/results', _recordResult);
    router.post('/templates/<templateId>/results/bulk', _recordBulkResults);
    router.delete('/results/<resultId>', _deleteResult);

    // User-specific routes
    router.get('/teams/<teamId>/users/<userId>/results', _getUserResults);
    router.get('/templates/<templateId>/users/<userId>/best', _getPersonalBest);
    router.get('/templates/<templateId>/users/<userId>/progress', _getUserProgress);

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

  Future<bool> _isTeamAdmin(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    if (team == null) return false;
    return team['user_is_admin'] == true || team['user_role'] == 'admin';
  }

  Future<Response> _getTemplates(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final templates = await _testService.getTemplatesForTeam(teamId);

      return Response.ok(
        jsonEncode({
          'templates': templates.map((t) => t.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente testmaler: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getTemplateById(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final template = await _testService.getTemplateById(templateId);
      if (template == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(template.teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til denne testmalen'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(template.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente testmal: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createTemplate(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan opprette testmaler'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final name = body['name'] as String?;
      final unit = body['unit'] as String?;

      if (name == null || name.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Navn er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (unit == null || unit.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Enhet er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final template = await _testService.createTemplate(
        teamId: teamId,
        name: name,
        description: body['description'] as String?,
        unit: unit,
        higherIsBetter: body['higher_is_better'] as bool? ?? false,
      );

      return Response.ok(
        jsonEncode(template.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette testmal: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _updateTemplate(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan oppdatere testmaler'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

      final template = await _testService.updateTemplate(
        templateId: templateId,
        name: body['name'] as String?,
        description: body['description'] as String?,
        unit: body['unit'] as String?,
        higherIsBetter: body['higher_is_better'] as bool?,
        clearDescription: body['clear_description'] == true,
      );

      if (template == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(template.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke oppdatere testmal: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteTemplate(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan slette testmaler'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _testService.deleteTemplate(templateId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette testmal: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getResults(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til denne testmalen'}),
          headers: {'Content-Type': 'application/json'},
        );
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

      return Response.ok(
        jsonEncode({
          'results': results.map((r) => r.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente resultater: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getRanking(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til denne testmalen'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final limitParam = request.url.queryParameters['limit'];

      final ranking = await _testService.getTestRanking(
        templateId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
      );

      return Response.ok(
        jsonEncode({
          'ranking': ranking,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente ranking: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _recordResult(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan registrere resultater'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final targetUserId = body['user_id'] as String?;
      final value = body['value'];

      if (targetUserId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (value == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'value er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await _testService.recordResult(
        testTemplateId: templateId,
        userId: targetUserId,
        instanceId: body['instance_id'] as String?,
        value: (value as num).toDouble(),
        notes: body['notes'] as String?,
      );

      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke registrere resultat: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _recordBulkResults(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan registrere resultater'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final results = body['results'] as List?;

      if (results == null || results.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'results er pakrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final recorded = await _testService.recordMultipleResults(
        testTemplateId: templateId,
        instanceId: body['instance_id'] as String?,
        results: results.cast<Map<String, dynamic>>(),
      );

      return Response.ok(
        jsonEncode({
          'results': recorded.map((r) => r.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke registrere resultater: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteResult(Request request, String resultId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Hent resultatet
      final result = await _testService.getResultById(resultId);
      if (result == null) {
        return Response.notFound(
          jsonEncode({'error': 'Resultat ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Hent template for å finne teamet
      final template = await _testService.getTemplateById(result.testTemplateId);
      if (template == null) {
        return Response.notFound(
          jsonEncode({'error': 'Test-mal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Sjekk at brukeren har admin-tilgang til teamet
      if (!await _isTeamAdmin(userId, template.teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan slette resultater'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _testService.deleteResult(resultId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette resultat: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserResults(Request request, String teamId, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final limitParam = request.url.queryParameters['limit'];
      final offsetParam = request.url.queryParameters['offset'];

      final results = await _testService.getResultsForUser(
        teamId,
        targetUserId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
        offset: offsetParam != null ? int.tryParse(offsetParam) ?? 0 : 0,
      );

      return Response.ok(
        jsonEncode({
          'results': results.map((r) => r.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente brukerresultater: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getPersonalBest(
    Request request,
    String templateId,
    String targetUserId,
  ) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til denne testmalen'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final result = await _testService.getPersonalBest(templateId, targetUserId);

      if (result == null) {
        return Response.notFound(
          jsonEncode({'error': 'Ingen resultater funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(result.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente personlig rekord: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserProgress(
    Request request,
    String templateId,
    String targetUserId,
  ) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _testService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Testmal ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til denne testmalen'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final limitParam = request.url.queryParameters['limit'];

      final results = await _testService.getUserProgress(
        templateId,
        targetUserId,
        limit: limitParam != null ? int.tryParse(limitParam) : null,
      );

      return Response.ok(
        jsonEncode({
          'progress': results.map((r) => r.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente progresjon: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
