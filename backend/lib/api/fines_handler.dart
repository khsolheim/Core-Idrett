import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/fine_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class FinesHandler {
  final FineService _fineService;

  FinesHandler(this._fineService);

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
      final activeOnly = request.url.queryParameters['active'] == 'true';
      final rules = await _fineService.getFineRules(teamId, activeOnly: activeOnly ? true : null);

      return resp.ok({'rules': rules.map((r) => r.toJson()).toList()});
    } catch (e) {
      return resp.serverError('Kunne ikke hente bøteregler: $e');
    }
  }

  Future<Response> _createFineRule(Request request, String teamId) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final rule = await _fineService.createFineRule(
        teamId: teamId,
        name: body['name'],
        amount: (body['amount'] as num).toDouble(),
        description: body['description'],
      );

      return resp.ok(rule.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette bøteregel: $e');
    }
  }

  Future<Response> _updateFineRule(Request request, String ruleId) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final rule = await _fineService.updateFineRule(
        ruleId: ruleId,
        name: body['name'],
        amount: body['amount'] != null ? (body['amount'] as num).toDouble() : null,
        description: body['description'],
        active: body['active'],
      );

      if (rule == null) {
        return resp.notFound('Bøteregel ikke funnet');
      }

      return resp.ok(rule.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere bøteregel: $e');
    }
  }

  Future<Response> _deleteFineRule(Request request, String ruleId) async {
    try {
      final success = await _fineService.deleteFineRule(ruleId);

      if (!success) {
        return resp.notFound('Bøteregel ikke funnet');
      }

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette bøteregel: $e');
    }
  }

  // Fines
  Future<Response> _getFines(Request request, String teamId) async {
    try {
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
      return resp.serverError('Kunne ikke hente bøter: $e');
    }
  }

  Future<Response> _createFine(Request request, String teamId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final reporterId = getUserId(request);

      if (reporterId == null) {
        return resp.unauthorized();
      }

      final fine = await _fineService.createFine(
        teamId: teamId,
        offenderId: body['offender_id'],
        reporterId: reporterId,
        ruleId: body['rule_id'],
        amount: (body['amount'] as num).toDouble(),
        description: body['description'],
        evidenceUrl: body['evidence_url'],
        isGameDay: body['is_game_day'] == true,
      );

      return resp.ok(fine.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette bøte: $e');
    }
  }

  Future<Response> _getFine(Request request, String fineId) async {
    try {
      final fine = await _fineService.getFine(fineId);

      if (fine == null) {
        return resp.notFound('Bøte ikke funnet');
      }

      return resp.ok(fine.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente bøte: $e');
    }
  }

  Future<Response> _approveFine(Request request, String fineId) async {
    try {
      final approvedBy = getUserId(request);

      if (approvedBy == null) {
        return resp.unauthorized();
      }

      final fine = await _fineService.approveFine(fineId, approvedBy);

      if (fine == null) {
        return resp.badRequest('Kunne ikke godkjenne bøte (kanskje allerede behandlet)');
      }

      return resp.ok(fine.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke godkjenne bøte: $e');
    }
  }

  Future<Response> _rejectFine(Request request, String fineId) async {
    try {
      final approvedBy = getUserId(request);

      if (approvedBy == null) {
        return resp.unauthorized();
      }

      final fine = await _fineService.rejectFine(fineId, approvedBy);

      if (fine == null) {
        return resp.badRequest('Kunne ikke avvise bøte (kanskje allerede behandlet)');
      }

      return resp.ok(fine.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke avvise bøte: $e');
    }
  }

  // Appeals
  Future<Response> _createAppeal(Request request, String fineId) async {
    try {
      final body = jsonDecode(await request.readAsString());

      final appeal = await _fineService.createAppeal(
        fineId: fineId,
        reason: body['reason'],
      );

      if (appeal == null) {
        return resp.badRequest('Kan ikke klage på denne bøten');
      }

      return resp.ok(appeal.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette klage: $e');
    }
  }

  Future<Response> _resolveAppeal(Request request, String appealId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final decidedBy = getUserId(request);

      if (decidedBy == null) {
        return resp.unauthorized();
      }

      final appeal = await _fineService.resolveAppeal(
        appealId: appealId,
        decidedBy: decidedBy,
        accepted: body['accepted'] == true,
        extraFee: body['extra_fee'] != null ? (body['extra_fee'] as num).toDouble() : null,
      );

      if (appeal == null) {
        return resp.badRequest('Kunne ikke behandle klage');
      }

      return resp.ok(appeal.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke behandle klage: $e');
    }
  }

  Future<Response> _getPendingAppeals(Request request, String teamId) async {
    try {
      final appeals = await _fineService.getPendingAppeals(teamId);

      return resp.ok({'appeals': appeals.map((a) => a.toJson()).toList()});
    } catch (e) {
      return resp.serverError('Kunne ikke hente klager: $e');
    }
  }

  // Payments
  Future<Response> _recordPayment(Request request, String fineId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final registeredBy = getUserId(request);

      if (registeredBy == null) {
        return resp.unauthorized();
      }

      final payment = await _fineService.recordPayment(
        fineId: fineId,
        amount: (body['amount'] as num).toDouble(),
        registeredBy: registeredBy,
      );

      return resp.ok(payment.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke registrere betaling: $e');
    }
  }

  // Summary
  Future<Response> _getTeamSummary(Request request, String teamId) async {
    try {
      final summary = await _fineService.getTeamSummary(teamId);

      return resp.ok(summary.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente sammendrag: $e');
    }
  }

  Future<Response> _getUserSummaries(Request request, String teamId) async {
    try {
      final summaries = await _fineService.getUserSummaries(teamId);

      return resp.ok({'summaries': summaries.map((s) => s.toJson()).toList()});
    } catch (e) {
      return resp.serverError('Kunne ikke hente brukersammendrag: $e');
    }
  }
}
