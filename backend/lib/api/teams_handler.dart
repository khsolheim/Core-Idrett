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

    router.get('/', _getTeams);
    router.post('/', _createTeam);
    router.get('/<teamId>', _getTeam);
    router.patch('/<teamId>', _updateTeam);
    router.get('/<teamId>/members', _getTeamMembers);
    router.post('/<teamId>/invite', _regenerateInviteCode);
    router.patch('/<teamId>/members/<memberId>/role', _updateMemberRole);
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

      final members = await _teamService.getTeamMembers(teamId);
      return Response.ok(jsonEncode(members));
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

      if (team['user_role'] != 'admin') {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan generere ny invitasjonskode'}));
      }

      final newCode = await _teamService.regenerateInviteCode(teamId);
      return Response.ok(jsonEncode({'invite_code': newCode}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }

  Future<Response> _updateMemberRole(Request request, String teamId, String memberId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || team['user_role'] != 'admin') {
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

  Future<Response> _updateTeam(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null || team['user_role'] != 'admin') {
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
      if (team == null || team['user_role'] != 'admin') {
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
      );

      return Response.ok(jsonEncode(settings));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod'}));
    }
  }
}
