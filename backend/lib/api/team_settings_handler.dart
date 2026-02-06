import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class TeamSettingsHandler {
  final TeamService _teamService;

  TeamSettingsHandler(this._teamService);

  Router get router {
    final router = Router();

    // Trainer types routes
    router.get('/<teamId>/trainer-types', _getTrainerTypes);
    router.post('/<teamId>/trainer-types', _createTrainerType);
    router.delete('/<teamId>/trainer-types/<trainerTypeId>', _deleteTrainerType);

    // Settings routes
    router.get('/<teamId>/settings', _getTeamSettings);
    router.patch('/<teamId>/settings', _updateTeamSettings);

    return router;
  }

  // ============ Trainer Type Handlers ============

  Future<Response> _getTrainerTypes(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify user is member of team
      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final trainerTypes = await _teamService.getTrainerTypes(teamId);
      return resp.ok(trainerTypes.map((t) => t.toJson()).toList());
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _createTrainerType(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan opprette trenertyper');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final name = data['name'] as String?;

      if (name == null || name.isEmpty) {
        return resp.badRequest('Navn er påkrevd');
      }

      final trainerType = await _teamService.createTrainerType(
        teamId: teamId,
        name: name,
      );

      return resp.ok(trainerType.toJson());
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _deleteTrainerType(Request request, String teamId, String trainerTypeId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan slette trenertyper');
      }

      await _teamService.deleteTrainerType(trainerTypeId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError();
    }
  }

  // ============ Settings Handlers ============

  Future<Response> _getTeamSettings(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final settings = await _teamService.getTeamSettings(teamId);
      return resp.ok(settings);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _updateTeamSettings(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan endre innstillinger');
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final settings = await _teamService.updateTeamSettings(
        teamId: teamId,
        attendancePoints: data['attendance_points'] as int?,
        winPoints: data['win_points'] as int?,
        drawPoints: data['draw_points'] as int?,
        lossPoints: data['loss_points'] as int?,
        appealFee: data['appeal_fee'] != null ? (data['appeal_fee'] as num).toDouble() : null,
        gameDayMultiplier: data['game_day_multiplier'] != null ? (data['game_day_multiplier'] as num).toDouble() : null,
      );

      return resp.ok(settings);
    } catch (e) {
      return resp.serverError();
    }
  }
}
