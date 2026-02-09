import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/absence_service.dart';
import '../services/team_service.dart';
import '../models/absence.dart';
import 'absence_categories_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class AbsenceHandler {
  final AbsenceService _absenceService;
  final TeamService _teamService;

  AbsenceHandler(
    this._absenceService,
    this._teamService,
  );

  Router get router {
    final router = Router();

    // Absence record routes
    router.get('/teams/<teamId>', _getAbsences);
    router.get('/teams/<teamId>/pending', _getPendingAbsences);
    router.get('/teams/<teamId>/summary', _getAbsenceSummary);
    router.get('/teams/<teamId>/users/<userId>/valid-count', _getValidAbsenceCountForTeam);
    router.post('/register', _registerAbsence);
    router.get('/<absenceId>', _getAbsenceById);
    router.patch('/<absenceId>/approve', _approveAbsence);
    router.patch('/<absenceId>/reject', _rejectAbsence);
    router.delete('/<absenceId>', _deleteAbsence);

    // User absence routes
    router.get('/users/<userId>/instances/<instanceId>', _getAbsenceForInstance);
    router.get('/users/<userId>/instances/<instanceId>/valid', _hasValidAbsence);
    router.get('/users/<userId>/valid-count', _getValidAbsenceCount);

    // Mount category routes
    final categoriesHandler = AbsenceCategoriesHandler(
      _absenceService,
      _teamService,
    );
    router.mount('/', categoriesHandler.router.call);

    return router;
  }

  // ============ ABSENCE RECORDS ============

  Future<Response> _getAbsences(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
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

      return resp.ok({
        'absences': absences.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente fravær');
    }
  }

  Future<Response> _getPendingAbsences(Request request, String teamId) async {
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
        return resp.forbidden('Kun admin kan se ventende fravær');
      }

      final absences = await _absenceService.getPendingAbsences(teamId);

      return resp.ok({
        'absences': absences.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente ventende fravær');
    }
  }

  Future<Response> _registerAbsence(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await parseBody(request);
      final targetUserId = safeStringNullable(body, 'user_id') ?? userId;
      final instanceId = safeStringNullable(body, 'instance_id');

      if (instanceId == null) {
        return resp.badRequest('instance_id er påkrevd');
      }

      final absence = await _absenceService.registerAbsence(
        userId: targetUserId,
        instanceId: instanceId,
        categoryId: safeStringNullable(body, 'category_id'),
        reason: safeStringNullable(body, 'reason'),
      );

      return resp.ok(absence.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke registrere fravær');
    }
  }

  Future<Response> _getAbsenceById(Request request, String absenceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final absence = await _absenceService.getAbsenceById(absenceId);

      if (absence == null) {
        return resp.notFound('Fravær ikke funnet');
      }

      return resp.ok(absence.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente fravær');
    }
  }

  Future<Response> _approveAbsence(Request request, String absenceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _absenceService.getTeamIdForAbsence(absenceId);
      if (teamId == null) {
        return resp.notFound('Fravær ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan godkjenne fravær');
      }

      final absence = await _absenceService.approveAbsence(
        absenceId: absenceId,
        approverId: userId,
      );

      if (absence == null) {
        return resp.notFound('Fravær ikke funnet');
      }

      return resp.ok(absence.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke godkjenne fravær');
    }
  }

  Future<Response> _rejectAbsence(Request request, String absenceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = await _absenceService.getTeamIdForAbsence(absenceId);
      if (teamId == null) {
        return resp.notFound('Fravær ikke funnet');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan avvise fravær');
      }

      final body = await parseBody(request);

      final absence = await _absenceService.rejectAbsence(
        absenceId: absenceId,
        approverId: userId,
        rejectionReason: safeStringNullable(body, 'rejection_reason'),
      );

      if (absence == null) {
        return resp.notFound('Fravær ikke funnet');
      }

      return resp.ok(absence.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke avvise fravær');
    }
  }

  Future<Response> _deleteAbsence(Request request, String absenceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final absence = await _absenceService.getAbsenceById(absenceId);
      if (absence == null) {
        return resp.notFound('Fravær ikke funnet');
      }

      final isOwner = absence.userId == userId;
      var userIsAdmin = false;
      if (absence.teamId != null) {
        final team = await requireTeamMember(_teamService, absence.teamId!, userId);
        if (team != null) {
          userIsAdmin = isAdmin(team);
        }
      }
      if (!isOwner && !userIsAdmin) {
        return resp.forbidden('Kun eier eller admin kan slette fravær');
      }

      await _absenceService.deleteAbsence(absenceId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette fravær');
    }
  }

  Future<Response> _getAbsenceForInstance(
      Request request, String targetUserId, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final absence = await _absenceService.getAbsenceForInstance(
        targetUserId,
        instanceId,
      );

      if (absence == null) {
        return resp.notFound('Ingen fravær registrert');
      }

      return resp.ok(absence.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente fravær');
    }
  }

  Future<Response> _getValidAbsenceCount(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = request.url.queryParameters['team_id'];
      if (teamId == null) {
        return resp.badRequest('team_id er påkrevd');
      }

      final count = await _absenceService.countValidAbsences(
        targetUserId,
        teamId,
        seasonId: request.url.queryParameters['season_id'],
      );

      return resp.ok({'count': count});
    } catch (e) {
      return resp.serverError('Kunne ikke telle gyldige fravær');
    }
  }

  Future<Response> _getValidAbsenceCountForTeam(
      Request request, String teamId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final count = await _absenceService.countValidAbsences(
        targetUserId,
        teamId,
        seasonId: request.url.queryParameters['season_id'],
      );

      return resp.ok({'count': count});
    } catch (e) {
      return resp.serverError('Kunne ikke telle gyldige fravær');
    }
  }

  Future<Response> _hasValidAbsence(
      Request request, String targetUserId, String instanceId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final hasValid = await _absenceService.hasValidAbsence(
        targetUserId,
        instanceId,
      );

      return resp.ok({'has_valid_absence': hasValid});
    } catch (e) {
      return resp.serverError('Kunne ikke sjekke gyldig fravær');
    }
  }

  Future<Response> _getAbsenceSummary(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasonId = request.url.queryParameters['season_id'];
      final summary = await _absenceService.getAbsenceSummary(
        teamId,
        seasonId: seasonId,
      );

      return resp.ok(summary);
    } catch (e) {
      return resp.serverError('Kunne ikke hente fraværssammendrag');
    }
  }
}
