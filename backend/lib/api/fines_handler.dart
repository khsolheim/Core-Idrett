import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/fine_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class FinesHandler {
  final FineService _fineService;
  final TeamService _teamService;

  FinesHandler(this._fineService, this._teamService);

  Router get router {
    final router = Router();

    // Fine rules
    router.get('/teams/<teamId>/fine-rules', _getFineRules);
    router.post('/teams/<teamId>/fine-rules', _createFineRule);
    router.patch('/fine-rules/<ruleId>', _updateFineRule);
    router.delete('/fine-rules/<ruleId>', _deleteFineRule);

    // Fines
    router.get('/teams/<teamId>/fines', _getFines);
    router.post('/teams/<teamId>/fines', _createFine);
    router.get('/fines/<fineId>', _getFine);
    router.patch('/fines/<fineId>/approve', _approveFine);
    router.patch('/fines/<fineId>/reject', _rejectFine);

    // Appeals
    router.post('/fines/<fineId>/appeal', _createAppeal);
    router.patch('/appeals/<appealId>/resolve', _resolveAppeal);
    router.get('/teams/<teamId>/pending-appeals', _getPendingAppeals);

    // Payments
    router.post('/fines/<fineId>/pay', _recordPayment);

    // Summary
    router.get('/teams/<teamId>/fines-summary', _getTeamSummary);
    router.get('/teams/<teamId>/user-fines-summary', _getUserSummaries);

    return router;
  }

  // Fine Rules
  Future<Response> _getFineRules(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final activeOnly = request.url.queryParameters['active'] == 'true';
      final rules = await _fineService.getFineRules(teamId, activeOnly: activeOnly ? true : null);

      return resp.ok({'rules': rules.map((r) => r.toJson()).toList()});
    } catch (e) {
      return resp.serverError('Kunne ikke hente bøteregler');
    }
  }

  Future<Response> _createFineRule(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan opprette bøteregler');
      }

      final body = await parseBody(request);

      final name = safeStringNullable(body, 'name');
      if (name == null || name.isEmpty) {
        return resp.badRequest('name er påkrevd');
      }

      final amountRaw = safeNumNullable(body, 'amount');
      if (amountRaw == null) {
        return resp.badRequest('amount er påkrevd');
      }

      final rule = await _fineService.createFineRule(
        teamId: teamId,
        name: name,
        amount: amountRaw.toDouble(),
        description: body['description'],
      );

      return resp.ok(rule.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette bøteregel');
    }
  }

  Future<Response> _updateFineRule(Request request, String ruleId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final body = await parseBody(request);

      final rule = await _fineService.updateFineRule(
        ruleId: ruleId,
        name: body['name'],
        amount: body['amount'] != null ? safeDouble(body, 'amount') : null,
        description: body['description'],
        active: body['active'],
      );

      if (rule == null) {
        return resp.notFound('Bøteregel ikke funnet');
      }

      return resp.ok(rule.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere bøteregel');
    }
  }

  Future<Response> _deleteFineRule(Request request, String ruleId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final success = await _fineService.deleteFineRule(ruleId);

      if (!success) {
        return resp.notFound('Bøteregel ikke funnet');
      }

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette bøteregel');
    }
  }

  // Fines
  Future<Response> _getFines(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final status = request.url.queryParameters['status'];
      final offenderId = request.url.queryParameters['offender_id'];
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '') ?? 50;
      final offset = int.tryParse(request.url.queryParameters['offset'] ?? '') ?? 0;

      final fines = await _fineService.getFines(
        teamId,
        status: status,
        offenderId: offenderId,
        limit: limit,
        offset: offset,
      );

      return resp.ok({'fines': fines.map((f) => f.toJson()).toList()});
    } catch (e) {
      return resp.serverError('Kunne ikke hente bøter');
    }
  }

  Future<Response> _createFine(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final body = await parseBody(request);

      final offenderId = safeStringNullable(body, 'offender_id');
      if (offenderId == null) {
        return resp.badRequest('offender_id er påkrevd');
      }

      final amountRaw = safeNumNullable(body, 'amount');
      if (amountRaw == null) {
        return resp.badRequest('amount er påkrevd');
      }

      final fine = await _fineService.createFine(
        teamId: teamId,
        offenderId: offenderId,
        reporterId: userId,
        ruleId: body['rule_id'],
        amount: amountRaw.toDouble(),
        description: body['description'],
        evidenceUrl: body['evidence_url'],
        isGameDay: body['is_game_day'] == true,
      );

      return resp.ok(fine.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette bøte');
    }
  }

  Future<Response> _getFine(Request request, String fineId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final fine = await _fineService.getFine(fineId);

      if (fine == null) {
        return resp.notFound('Bøte ikke funnet');
      }

      return resp.ok(fine.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente bøte');
    }
  }

  Future<Response> _approveFine(Request request, String fineId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final fine = await _fineService.approveFine(fineId, userId);

      if (fine == null) {
        return resp.badRequest('Kunne ikke godkjenne bøte (kanskje allerede behandlet)');
      }

      return resp.ok(fine.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke godkjenne bøte');
    }
  }

  Future<Response> _rejectFine(Request request, String fineId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final fine = await _fineService.rejectFine(fineId, userId);

      if (fine == null) {
        return resp.badRequest('Kunne ikke avvise bøte (kanskje allerede behandlet)');
      }

      return resp.ok(fine.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke avvise bøte');
    }
  }

  // Appeals
  Future<Response> _createAppeal(Request request, String fineId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final body = await parseBody(request);

      final appeal = await _fineService.createAppeal(
        fineId: fineId,
        reason: body['reason'],
      );

      if (appeal == null) {
        return resp.badRequest('Kan ikke klage på denne bøten');
      }

      return resp.ok(appeal.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette klage');
    }
  }

  Future<Response> _resolveAppeal(Request request, String appealId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final body = await parseBody(request);

      final appeal = await _fineService.resolveAppeal(
        appealId: appealId,
        decidedBy: userId,
        accepted: body['accepted'] == true,
        extraFee: body['extra_fee'] != null ? safeDouble(body, 'extra_fee') : null,
      );

      if (appeal == null) {
        return resp.badRequest('Kunne ikke behandle klage');
      }

      return resp.ok(appeal.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke behandle klage');
    }
  }

  Future<Response> _getPendingAppeals(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final appeals = await _fineService.getPendingAppeals(teamId);

      return resp.ok({'appeals': appeals.map((a) => a.toJson()).toList()});
    } catch (e) {
      return resp.serverError('Kunne ikke hente klager');
    }
  }

  // Payments
  Future<Response> _recordPayment(Request request, String fineId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final body = await parseBody(request);

      final amountRaw = safeNumNullable(body, 'amount');
      if (amountRaw == null) {
        return resp.badRequest('amount er påkrevd');
      }

      final payment = await _fineService.recordPayment(
        fineId: fineId,
        amount: amountRaw.toDouble(),
        registeredBy: userId,
      );

      return resp.ok(payment.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke registrere betaling');
    }
  }

  // Summary
  Future<Response> _getTeamSummary(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final summary = await _fineService.getTeamSummary(teamId);

      return resp.ok(summary.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente sammendrag');
    }
  }

  Future<Response> _getUserSummaries(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til dette laget');

      final summaries = await _fineService.getUserSummaries(teamId);

      return resp.ok({'summaries': summaries.map((s) => s.toJson()).toList()});
    } catch (e) {
      return resp.serverError('Kunne ikke hente brukersammendrag');
    }
  }
}
