import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/absence_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class AbsenceCategoriesHandler {
  final AbsenceService _absenceService;
  final TeamService _teamService;

  AbsenceCategoriesHandler(this._absenceService, this._teamService);

  Router get router {
    final router = Router();

    router.get('/teams/<teamId>/categories', _getCategories);
    router.post('/teams/<teamId>/categories', _createCategory);
    router.patch('/categories/<categoryId>', _updateCategory);
    router.delete('/categories/<categoryId>', _deleteCategory);

    return router;
  }

  Future<Response> _getCategories(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final activeOnly =
          request.url.queryParameters['active_only'] != 'false';
      final categories = await _absenceService.getCategories(
        teamId,
        activeOnly: activeOnly,
      );

      return resp.ok({
        'categories': categories.map((c) => c.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente fraværskategorier');
    }
  }

  Future<Response> _createCategory(Request request, String teamId) async {
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
        return resp.forbidden('Kun admin kan opprette fraværskategorier');
      }

      final body = await parseBody(request);
      final name = safeStringNullable(body, 'name');

      if (name == null || name.isEmpty) {
        return resp.badRequest('Navn er påkrevd');
      }

      final category = await _absenceService.createCategory(
        teamId: teamId,
        name: name,
        description: safeStringNullable(body, 'description'),
        requiresApproval: safeBoolNullable(body, 'requires_approval') ?? false,
        countsAsValid: safeBoolNullable(body, 'counts_as_valid') ?? true,
        sortOrder: safeIntNullable(body, 'sort_order') ?? 0,
      );

      return resp.ok(category.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette fraværskategori');
    }
  }

  Future<Response> _updateCategory(Request request, String categoryId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _absenceService.getTeamIdForCategory(categoryId);
      if (teamId == null) {
        return resp.notFound('Kategori ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan oppdatere fraværskategorier');
      }

      final body = await parseBody(request);

      final category = await _absenceService.updateCategory(
        categoryId: categoryId,
        name: safeStringNullable(body, 'name'),
        description: safeStringNullable(body, 'description'),
        requiresApproval: safeBoolNullable(body, 'requires_approval'),
        countsAsValid: safeBoolNullable(body, 'counts_as_valid'),
        isActive: safeBoolNullable(body, 'is_active'),
        sortOrder: safeIntNullable(body, 'sort_order'),
        clearDescription: body['clear_description'] == true,
      );

      if (category == null) {
        return resp.notFound('Kategori ikke funnet');
      }

      return resp.ok(category.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere fraværskategori');
    }
  }

  Future<Response> _deleteCategory(Request request, String categoryId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _absenceService.getTeamIdForCategory(categoryId);
      if (teamId == null) {
        return resp.notFound('Kategori ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan slette fraværskategorier');
      }

      await _absenceService.deleteCategory(categoryId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette fraværskategori');
    }
  }
}
