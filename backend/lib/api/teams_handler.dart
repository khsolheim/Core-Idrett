import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/team_service.dart';
import '../services/team_member_service.dart';
import '../services/dashboard_service.dart';
import 'team_settings_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class TeamsHandler {
  final TeamService _teamService;
  final TeamMemberService _memberService;
  final DashboardService _dashboardService;

  TeamsHandler(this._teamService, this._memberService, this._dashboardService);

  Router get router {
    final router = Router();

    // Team routes
    router.get('/', _getTeams);
    router.post('/', _createTeam);
    router.get('/<teamId>', _getTeam);
    router.patch('/<teamId>', _updateTeam);
    router.post('/<teamId>/invite', _regenerateInviteCode);
    router.get('/<teamId>/dashboard', _getDashboard);

    // Member routes
    router.get('/<teamId>/members', _getTeamMembers);
    router.patch('/<teamId>/members/<memberId>/permissions', _updateMemberPermissions);
    router.post('/<teamId>/members/<memberId>/deactivate', _deactivateMember);
    router.post('/<teamId>/members/<memberId>/reactivate', _reactivateMember);
    router.post('/<teamId>/members/<memberId>/injured', _setMemberInjuredStatus);
    router.delete('/<teamId>/members/<memberId>', _removeMember);

    // Mount settings & trainer types routes
    final settingsHandler = TeamSettingsHandler(_teamService, _memberService);
    router.mount('/', settingsHandler.router.call);

    return router;
  }

  // ============ Team Handlers ============

  Future<Response> _getTeams(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teams = await _teamService.getTeamsForUser(userId);
      return resp.ok(teams);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _createTeam(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final name = data['name'] as String?;
      final sport = data['sport'] as String?;

      if (name == null || name.isEmpty) {
        return resp.badRequest('Lagnavn er påkrevd');
      }

      final team = await _teamService.createTeam(
        name: name,
        sport: sport,
        creatorId: userId,
      );

      return resp.ok(team.toJson());
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _getTeam(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return resp.notFound('Lag ikke funnet');
      }

      return resp.ok(team);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _updateTeam(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan redigere laget');
      }

      final data = await parseBody(request);

      final name = data['name'] as String?;
      final sport = data['sport'] as String?;

      if (name == null && sport == null) {
        return resp.badRequest('Ingen felt å oppdatere');
      }

      final updated = await _teamService.updateTeam(
        teamId: teamId,
        name: name,
        sport: sport,
      );

      if (updated == null) {
        return resp.notFound('Lag ikke funnet');
      }

      return resp.ok(updated);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _regenerateInviteCode(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan generere ny invitasjonskode');
      }

      final newCode = await _teamService.regenerateInviteCode(teamId);
      return resp.ok({'invite_code': newCode});
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _getDashboard(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final dashboard = await _dashboardService.getDashboardData(teamId, userId);
      return resp.ok(dashboard);
    } catch (e) {
      return resp.serverError();
    }
  }

  // ============ Member Handlers ============

  Future<Response> _getTeamMembers(Request request, String teamId) async {
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

      // Check for include_inactive query param (admin only)
      final includeInactive = request.url.queryParameters['include_inactive'] == 'true';
      if (includeInactive && !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan se inaktive medlemmer');
      }

      final members = await _teamService.getTeamMembers(teamId, includeInactive: includeInactive);
      return resp.ok(members);
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _updateMemberPermissions(Request request, String teamId, String memberId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan endre tilganger');
      }

      final data = await parseBody(request);

      final isAdminFlag = data['is_admin'] as bool?;
      final isFineBoss = data['is_fine_boss'] as bool?;
      final isCoach = data['is_coach'] as bool?;
      final trainerTypeId = data['trainer_type_id'] as String?;
      final clearTrainerType = data.containsKey('trainer_type_id') && trainerTypeId == null;

      await _memberService.updateMemberPermissions(
        memberId: memberId,
        isAdmin: isAdminFlag,
        isFineBoss: isFineBoss,
        isCoach: isCoach,
        trainerTypeId: trainerTypeId,
        clearTrainerType: clearTrainerType,
      );

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _deactivateMember(Request request, String teamId, String memberId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan deaktivere medlemmer');
      }

      await _memberService.deactivateMember(memberId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _reactivateMember(Request request, String teamId, String memberId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan reaktivere medlemmer');
      }

      await _memberService.reactivateMember(memberId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _removeMember(Request request, String teamId, String memberId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan fjerne medlemmer');
      }

      await _memberService.removeMember(memberId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError();
    }
  }

  Future<Response> _setMemberInjuredStatus(Request request, String teamId, String memberId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !isAdmin(team)) {
        return resp.forbidden('Kun administratorer kan endre skadet-status');
      }

      final data = await parseBody(request);
      final isInjured = data['is_injured'] as bool?;

      if (isInjured == null) {
        return resp.badRequest('is_injured er pakrevd');
      }

      await _memberService.setMemberInjuredStatus(memberId, isInjured);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError();
    }
  }
}
