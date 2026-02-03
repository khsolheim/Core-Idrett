import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/absence_service.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../models/absence.dart';

class AbsenceHandler {
  final AbsenceService _absenceService;
  final AuthService _authService;
  final TeamService _teamService;

  AbsenceHandler(
    this._absenceService,
    this._authService,
    this._teamService,
  );

  Router get router {
    final router = Router();

    // Category routes
    router.get('/teams/<teamId>/categories', _getCategories);
    router.post('/teams/<teamId>/categories', _createCategory);
    router.patch('/categories/<categoryId>', _updateCategory);
    router.delete('/categories/<categoryId>', _deleteCategory);

    // Absence record routes
    router.get('/teams/<teamId>', _getAbsences);
    router.get('/teams/<teamId>/pending', _getPendingAbsences);
    router.post('/register', _registerAbsence);
    router.get('/<absenceId>', _getAbsenceById);
    router.patch('/<absenceId>/approve', _approveAbsence);
    router.patch('/<absenceId>/reject', _rejectAbsence);
    router.delete('/<absenceId>', _deleteAbsence);

    // User absence routes
    router.get('/users/<userId>/instances/<instanceId>', _getAbsenceForInstance);
    router.get('/users/<userId>/valid-count', _getValidAbsenceCount);

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

  // ============ CATEGORIES ============

  Future<Response> _getCategories(Request request, String teamId) async {
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

      final activeOnly =
          request.url.queryParameters['active_only'] != 'false';
      final categories = await _absenceService.getCategories(
        teamId,
        activeOnly: activeOnly,
      );

      return Response.ok(
        jsonEncode({
          'categories': categories.map((c) => c.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente fraværskategorier: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createCategory(Request request, String teamId) async {
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
          jsonEncode({'error': 'Kun admin kan opprette fraværskategorier'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final name = body['name'] as String?;

      if (name == null || name.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Navn er påkrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final category = await _absenceService.createCategory(
        teamId: teamId,
        name: name,
        description: body['description'] as String?,
        requiresApproval: body['requires_approval'] as bool? ?? false,
        countsAsValid: body['counts_as_valid'] as bool? ?? true,
        sortOrder: body['sort_order'] as int? ?? 0,
      );

      return Response.ok(
        jsonEncode(category.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette fraværskategori: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _updateCategory(Request request, String categoryId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _absenceService.getTeamIdForCategory(categoryId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Kategori ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan oppdatere fraværskategorier'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

      final category = await _absenceService.updateCategory(
        categoryId: categoryId,
        name: body['name'] as String?,
        description: body['description'] as String?,
        requiresApproval: body['requires_approval'] as bool?,
        countsAsValid: body['counts_as_valid'] as bool?,
        isActive: body['is_active'] as bool?,
        sortOrder: body['sort_order'] as int?,
        clearDescription: body['clear_description'] == true,
      );

      if (category == null) {
        return Response.notFound(
          jsonEncode({'error': 'Kategori ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(category.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke oppdatere fraværskategori: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteCategory(Request request, String categoryId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _absenceService.getTeamIdForCategory(categoryId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Kategori ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan slette fraværskategorier'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _absenceService.deleteCategory(categoryId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette fraværskategori: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ============ ABSENCE RECORDS ============

  Future<Response> _getAbsences(Request request, String teamId) async {
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

      final targetUserId = request.url.queryParameters['user_id'];
      final statusStr = request.url.queryParameters['status'];
      final limitStr = request.url.queryParameters['limit'];

      AbsenceStatus? status;
      if (statusStr != null) {
        status = AbsenceStatus.fromString(statusStr);
      }

      final absences = await _absenceService.getAbsenceDetails(
        teamId: teamId,
        userId: targetUserId,
        status: status,
        limit: limitStr != null ? int.tryParse(limitStr) : null,
      );

      return Response.ok(
        jsonEncode({
          'absences': absences.map((a) => a.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getPendingAbsences(Request request, String teamId) async {
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
          jsonEncode({'error': 'Kun admin kan se ventende fravær'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final absences = await _absenceService.getPendingAbsences(teamId);

      return Response.ok(
        jsonEncode({
          'absences': absences.map((a) => a.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente ventende fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _registerAbsence(Request request) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final targetUserId = body['user_id'] as String? ?? userId;
      final instanceId = body['instance_id'] as String?;

      if (instanceId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'instance_id er påkrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final absence = await _absenceService.registerAbsence(
        userId: targetUserId,
        instanceId: instanceId,
        categoryId: body['category_id'] as String?,
        reason: body['reason'] as String?,
      );

      return Response.ok(
        jsonEncode(absence.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke registrere fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getAbsenceById(Request request, String absenceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final absence = await _absenceService.getAbsenceById(absenceId);

      if (absence == null) {
        return Response.notFound(
          jsonEncode({'error': 'Fravær ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(absence.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _approveAbsence(Request request, String absenceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _absenceService.getTeamIdForAbsence(absenceId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Fravær ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan godkjenne fravær'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final absence = await _absenceService.approveAbsence(
        absenceId: absenceId,
        approverId: userId,
      );

      if (absence == null) {
        return Response.notFound(
          jsonEncode({'error': 'Fravær ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(absence.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke godkjenne fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _rejectAbsence(Request request, String absenceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = await _absenceService.getTeamIdForAbsence(absenceId);
      if (teamId == null) {
        return Response.notFound(
          jsonEncode({'error': 'Fravær ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan avvise fravær'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

      final absence = await _absenceService.rejectAbsence(
        absenceId: absenceId,
        approverId: userId,
        rejectionReason: body['rejection_reason'] as String?,
      );

      if (absence == null) {
        return Response.notFound(
          jsonEncode({'error': 'Fravær ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(absence.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke avvise fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteAbsence(Request request, String absenceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _absenceService.deleteAbsence(absenceId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getAbsenceForInstance(
      Request request, String targetUserId, String instanceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final absence = await _absenceService.getAbsenceForInstance(
        targetUserId,
        instanceId,
      );

      if (absence == null) {
        return Response.notFound(
          jsonEncode({'error': 'Ingen fravær registrert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(absence.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getValidAbsenceCount(
      Request request, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = request.url.queryParameters['team_id'];
      if (teamId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'team_id er påkrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final count = await _absenceService.countValidAbsences(
        targetUserId,
        teamId,
        seasonId: request.url.queryParameters['season_id'],
      );

      return Response.ok(
        jsonEncode({'count': count}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke telle gyldige fravær: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
