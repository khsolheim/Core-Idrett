import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/team_service.dart';
import '../services/team_member_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class TeamSettingsHandler {
  final TeamService _teamService;
  final TeamMemberService _memberService;

  TeamSettingsHandler(this._teamService, this._memberService);

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

      final trainerTypes = await _memberService.getTrainerTypes(teamId);
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

      final data = await parseBody(request);
      final name = safeStringNullable(data, 'name');

      if (name == null || name.isEmpty) {
        return resp.badRequest('Navn er påkrevd');
      }

      final trainerType = await _memberService.createTrainerType(
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

      await _memberService.deleteTrainerType(trainerTypeId);
      return resp.ok({'message': 'Trenertype slettet'});
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

      final data = await parseBody(request);

      final settings = await _teamService.updateTeamSettings(
        teamId: teamId,
        attendancePoints: safeIntNullable(data, 'attendance_points'),
        winPoints: safeIntNullable(data, 'win_points'),
        drawPoints: safeIntNullable(data, 'draw_points'),
        lossPoints: safeIntNullable(data, 'loss_points'),
        appealFee: safeDoubleNullable(data, 'appeal_fee'),
        gameDayMultiplier: safeDoubleNullable(data, 'game_day_multiplier'),
      );

      return resp.ok(settings);
    } catch (e) {
      return resp.serverError();
    }
  }
}
