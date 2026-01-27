import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';

class TeamsHandler {
  final TeamService _teamService;
  final AuthService _authService;

  TeamsHandler(this._teamService, this._authService);

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
    router.patch('/<teamId>/members/<memberId>/role', _updateMemberRole);
    router.patch('/<teamId>/members/<memberId>/permissions', _updateMemberPermissions);
    router.post('/<teamId>/members/<memberId>/deactivate', _deactivateMember);
    router.post('/<teamId>/members/<memberId>/reactivate', _reactivateMember);
    router.delete('/<teamId>/members/<memberId>', _removeMember);

    // Trainer types routes
    router.get('/<teamId>/trainer-types', _getTrainerTypes);
    router.post('/<teamId>/trainer-types', _createTrainerType);
    router.delete('/<teamId>/trainer-types/<trainerTypeId>', _deleteTrainerType);

    // Settings routes
    router.get('/<teamId>/settings', _getTeamSettings);
    router.patch('/<teamId>/settings', _updateTeamSettings);

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

  /// Check if user is admin using new flag system (with backwards compatibility)
  bool _isAdmin(Map<String, dynamic> team) {
    return team['user_is_admin'] == true || team['user_role'] == 'admin';
  }

  // ============ Team Handlers ============

  Future<Response> _getTeams(Request request) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final teams = await _teamService.getTeamsForUser(userId);
      return Response.ok(jsonEncode(teams));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _createTeam(Request request) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final sport = data['sport'] as String?;

      if (name == null || name.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Lagnavn er påkrevd'}));
      }

      final team = await _teamService.createTeam(
        name: name,
        sport: sport,
        creatorId: userId,
      );

      return Response.ok(jsonEncode(team.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _getTeam(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response(404, body: jsonEncode({'error': 'Lag ikke funnet'}));
      }

      return Response.ok(jsonEncode(team));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _updateTeam(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan redigere laget'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final sport = data['sport'] as String?;

      if (name == null && sport == null) {
        return Response(400, body: jsonEncode({'error': 'Ingen felt å oppdatere'}));
      }

      final updated = await _teamService.updateTeam(
        teamId: teamId,
        name: name,
        sport: sport,
      );

      if (updated == null) {
        return Response(404, body: jsonEncode({'error': 'Lag ikke funnet'}));
      }

      return Response.ok(jsonEncode(updated));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _regenerateInviteCode(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      if (!_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan generere ny invitasjonskode'}));
      }

      final newCode = await _teamService.regenerateInviteCode(teamId);
      return Response.ok(jsonEncode({'invite_code': newCode}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _getDashboard(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final dashboard = await _teamService.getDashboardData(teamId, userId);
      return Response.ok(jsonEncode(dashboard));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ Member Handlers ============

  Future<Response> _getTeamMembers(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      // Verify user is member of team
      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      // Check for include_inactive query param (admin only)
      final includeInactive = request.url.queryParameters['include_inactive'] == 'true';
      if (includeInactive && !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan se inaktive medlemmer'}));
      }

      final members = await _teamService.getTeamMembers(teamId, includeInactive: includeInactive);
      return Response.ok(jsonEncode(members));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  /// @deprecated Use _updateMemberPermissions instead
  Future<Response> _updateMemberRole(Request request, String teamId, String memberId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan endre roller'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final role = data['role'] as String?;

      if (role == null || !['admin', 'fine_boss', 'player'].contains(role)) {
        return Response(400, body: jsonEncode({'error': 'Ugyldig rolle'}));
      }

      await _teamService.updateMemberRole(memberId, role);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _updateMemberPermissions(Request request, String teamId, String memberId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan endre tilganger'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final isAdmin = data['is_admin'] as bool?;
      final isFineBoss = data['is_fine_boss'] as bool?;
      final isCoach = data['is_coach'] as bool?;
      final trainerTypeId = data['trainer_type_id'] as String?;
      final clearTrainerType = data.containsKey('trainer_type_id') && trainerTypeId == null;

      await _teamService.updateMemberPermissions(
        memberId: memberId,
        isAdmin: isAdmin,
        isFineBoss: isFineBoss,
        isCoach: isCoach,
        trainerTypeId: trainerTypeId,
        clearTrainerType: clearTrainerType,
      );

      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _deactivateMember(Request request, String teamId, String memberId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan deaktivere medlemmer'}));
      }

      await _teamService.deactivateMember(memberId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _reactivateMember(Request request, String teamId, String memberId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan reaktivere medlemmer'}));
      }

      await _teamService.reactivateMember(memberId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _removeMember(Request request, String teamId, String memberId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan fjerne medlemmer'}));
      }

      await _teamService.removeMember(memberId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  // ============ Trainer Type Handlers ============

  Future<Response> _getTrainerTypes(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      // Verify user is member of team
      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final trainerTypes = await _teamService.getTrainerTypes(teamId);
      return Response.ok(jsonEncode(trainerTypes.map((t) => t.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _createTrainerType(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan opprette trenertyper'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final name = data['name'] as String?;

      if (name == null || name.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Navn er påkrevd'}));
      }

      final trainerType = await _teamService.createTrainerType(
        teamId: teamId,
        name: name,
      );

      return Response.ok(jsonEncode(trainerType.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _deleteTrainerType(Request request, String teamId, String trainerTypeId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan slette trenertyper'}));
      }

      await _teamService.deleteTrainerType(trainerTypeId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  // ============ Settings Handlers ============

  Future<Response> _getTeamSettings(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final settings = await _teamService.getTeamSettings(teamId);
      return Response.ok(jsonEncode(settings));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _updateTeamSettings(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || !_isAdmin(team)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan endre innstillinger'}));
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

      return Response.ok(jsonEncode(settings));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }
}
