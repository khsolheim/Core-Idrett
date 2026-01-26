import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/fine_service.dart';

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

      return Response.ok(
        jsonEncode({'rules': rules.map((r) => r.toJson()).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente bøteregler: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
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

      return Response.ok(
        jsonEncode(rule.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette bøteregel: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
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
        return Response.notFound(
          jsonEncode({'error': 'Bøteregel ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(rule.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke oppdatere bøteregel: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteFineRule(Request request, String ruleId) async {
    try {
      final success = await _fineService.deleteFineRule(ruleId);

      if (!success) {
        return Response.notFound(
          jsonEncode({'error': 'Bøteregel ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette bøteregel: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
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

      return Response.ok(
        jsonEncode({'fines': fines.map((f) => f.toJson()).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente bøter: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createFine(Request request, String teamId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final reporterId = request.context['userId'] as String?;

      if (reporterId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fine = await _fineService.createFine(
        teamId: teamId,
        offenderId: body['offender_id'],
        reporterId: reporterId,
        ruleId: body['rule_id'],
        amount: (body['amount'] as num).toDouble(),
        description: body['description'],
        evidenceUrl: body['evidence_url'],
      );

      return Response.ok(
        jsonEncode(fine.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette bøte: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getFine(Request request, String fineId) async {
    try {
      final fine = await _fineService.getFine(fineId);

      if (fine == null) {
        return Response.notFound(
          jsonEncode({'error': 'Bøte ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(fine.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente bøte: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _approveFine(Request request, String fineId) async {
    try {
      final approvedBy = request.context['userId'] as String?;

      if (approvedBy == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fine = await _fineService.approveFine(fineId, approvedBy);

      if (fine == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Kunne ikke godkjenne bøte (kanskje allerede behandlet)'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(fine.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke godkjenne bøte: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _rejectFine(Request request, String fineId) async {
    try {
      final approvedBy = request.context['userId'] as String?;

      if (approvedBy == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final fine = await _fineService.rejectFine(fineId, approvedBy);

      if (fine == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Kunne ikke avvise bøte (kanskje allerede behandlet)'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(fine.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke avvise bøte: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
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
        return Response.badRequest(
          body: jsonEncode({'error': 'Kan ikke klage på denne bøten'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(appeal.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette klage: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _resolveAppeal(Request request, String appealId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final decidedBy = request.context['userId'] as String?;

      if (decidedBy == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final appeal = await _fineService.resolveAppeal(
        appealId: appealId,
        decidedBy: decidedBy,
        accepted: body['accepted'] == true,
        extraFee: body['extra_fee'] != null ? (body['extra_fee'] as num).toDouble() : null,
      );

      if (appeal == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Kunne ikke behandle klage'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(appeal.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke behandle klage: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getPendingAppeals(Request request, String teamId) async {
    try {
      final appeals = await _fineService.getPendingAppeals(teamId);

      return Response.ok(
        jsonEncode({'appeals': appeals.map((a) => a.toJson()).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente klager: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Payments
  Future<Response> _recordPayment(Request request, String fineId) async {
    try {
      final body = jsonDecode(await request.readAsString());
      final registeredBy = request.context['userId'] as String?;

      if (registeredBy == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final payment = await _fineService.recordPayment(
        fineId: fineId,
        amount: (body['amount'] as num).toDouble(),
        registeredBy: registeredBy,
      );

      return Response.ok(
        jsonEncode(payment.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke registrere betaling: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // Summary
  Future<Response> _getTeamSummary(Request request, String teamId) async {
    try {
      final summary = await _fineService.getTeamSummary(teamId);

      return Response.ok(
        jsonEncode(summary.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente sammendrag: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserSummaries(Request request, String teamId) async {
    try {
      final summaries = await _fineService.getUserSummaries(teamId);

      return Response.ok(
        jsonEncode({'summaries': summaries.map((s) => s.toJson()).toList()}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente brukersammendrag: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
