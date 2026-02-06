import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/mini_activity_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class MiniActivityTeamsHandler {
  final MiniActivityService _miniActivityService;

  MiniActivityTeamsHandler(this._miniActivityService);

  Router get router {
    final router = Router();

    // Team division
    router.post('/<miniActivityId>/divide-teams', _divideTeams);
    router.delete('/<miniActivityId>/reset-teams', _resetTeamDivision);
    router.post('/<miniActivityId>/add-participant', _addLateParticipant);
    router.put('/<miniActivityId>/teams/<miniTeamId>/name', _updateTeamName);
    router.post('/<miniActivityId>/teams', _createTeam);
    router.delete('/<miniActivityId>/teams/<miniTeamId>', _deleteTeam);
    router.put('/<miniActivityId>/participants/<participantId>/move', _moveParticipant);

    // Handicaps
    router.get('/<miniActivityId>/handicaps', _getHandicaps);
    router.post('/<miniActivityId>/handicaps', _setHandicap);
    router.delete('/<miniActivityId>/handicaps/<userId>', _removeHandicap);

    return router;
  }

  // ============ TEAM DIVISION ============

  Future<Response> _divideTeams(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final method = data['method'] as String?;
      final numberOfTeams = data['number_of_teams'] as int?;
      final participantUserIds = (data['participant_user_ids'] as List?)?.cast<String>();
      final teamId = data['team_id'] as String? ?? '';

      if (method == null || numberOfTeams == null || participantUserIds == null) {
        return resp.badRequest(
          'Mangler påkrevde felt (method, number_of_teams, participant_user_ids)',
        );
      }

      if (!['random', 'ranked', 'age', 'gmo', 'cup', 'manual'].contains(method)) {
        return resp.badRequest('Ugyldig metode');
      }

      if (numberOfTeams < 2) {
        return resp.badRequest('Må ha minst 2 lag');
      }

      if (participantUserIds.length < numberOfTeams) {
        return resp.badRequest('For få deltakere for antall lag');
      }

      await _miniActivityService.divideTeams(
        miniActivityId: miniActivityId,
        method: method,
        numberOfTeams: numberOfTeams,
        participantUserIds: participantUserIds,
        teamId: teamId,
      );

      // Return the updated mini-activity detail
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } on ArgumentError catch (e) {
      return resp.badRequest(e.message);
    } catch (e) {
      print('Divide teams error: $e');
      return resp.serverError('En feil oppstod ved lagdeling: $e');
    }
  }

  Future<Response> _resetTeamDivision(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _miniActivityService.resetTeamDivision(miniActivityId);
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _addLateParticipant(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final participantUserId = data['user_id'] as String?;
      final miniTeamId = data['mini_team_id'] as String?;

      if (participantUserId == null || miniTeamId == null) {
        return resp.badRequest('Mangler påkrevde felt (user_id, mini_team_id)');
      }

      await _miniActivityService.addLateParticipant(
        miniActivityId: miniActivityId,
        userId: participantUserId,
        teamId: miniTeamId,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateTeamName(Request request, String miniActivityId, String miniTeamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final newName = data['name'] as String?;
      if (newName == null) {
        return resp.badRequest('Mangler påkrevd felt (name)');
      }

      await _miniActivityService.updateTeamName(teamId: miniTeamId, newName: newName);
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _createTeam(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      if (name == null || name.isEmpty) {
        return resp.badRequest('Mangler påkrevd felt (name)');
      }

      await _miniActivityService.createTeam(
        miniActivityId: miniActivityId,
        name: name,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _deleteTeam(Request request, String miniActivityId, String miniTeamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      Map<String, dynamic>? data;
      if (body.isNotEmpty) {
        data = jsonDecode(body) as Map<String, dynamic>?;
      }

      await _miniActivityService.deleteTeam(
        miniActivityId: miniActivityId,
        teamId: miniTeamId,
        moveParticipantsToTeamId: data?['move_participants_to_team_id'] as String?,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _moveParticipant(Request request, String miniActivityId, String participantId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final targetTeamId = data['target_team_id'] as String?;
      if (targetTeamId == null) {
        return resp.badRequest('Mangler påkrevd felt (target_team_id)');
      }

      await _miniActivityService.moveParticipantToTeam(
        participantId: participantId,
        newTeamId: targetTeamId,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  // ============ HANDICAPS ============

  Future<Response> _getHandicaps(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final handicaps = await _miniActivityService.getHandicaps(miniActivityId);
      return resp.ok(handicaps.map((h) => h.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _setHandicap(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final targetUserId = data['user_id'] as String?;
      final handicapValue = (data['handicap_value'] as num?)?.toDouble();

      if (targetUserId == null || handicapValue == null) {
        return resp.badRequest('Mangler påkrevde felt (user_id, handicap_value)');
      }

      final handicap = await _miniActivityService.setHandicap(
        miniActivityId: miniActivityId,
        userId: targetUserId,
        handicapValue: handicapValue,
      );

      return resp.ok(handicap.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _removeHandicap(Request request, String miniActivityId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _miniActivityService.removeHandicap(miniActivityId: miniActivityId, userId: targetUserId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }
}
