import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/mini_activity_service.dart';
import '../services/mini_activity_division_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class MiniActivityTeamsHandler {
  final MiniActivityService _miniActivityService;
  final MiniActivityDivisionAlgorithmService _algorithmService;
  final MiniActivityDivisionManagementService _managementService;

  MiniActivityTeamsHandler(
    this._miniActivityService,
    this._algorithmService,
    this._managementService,
  );

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

      final data = await parseBody(request);

      final method = safeStringNullable(data, 'method');
      final numberOfTeams = safeIntNullable(data, 'number_of_teams');
      final participantUserIds = (safeListNullable(data, 'participant_user_ids'))?.cast<String>();
      final teamId = safeStringNullable(data, 'team_id') ?? '';

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

      await _algorithmService.divideTeams(
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
      return resp.serverError('En feil oppstod ved lagdeling');
    }
  }

  Future<Response> _resetTeamDivision(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _managementService.resetTeamDivision(miniActivityId);
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _addLateParticipant(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final participantUserId = safeStringNullable(data, 'user_id');
      final miniTeamId = safeStringNullable(data, 'mini_team_id');

      if (participantUserId == null || miniTeamId == null) {
        return resp.badRequest('Mangler påkrevde felt (user_id, mini_team_id)');
      }

      await _managementService.addLateParticipant(
        miniActivityId: miniActivityId,
        userId: participantUserId,
        teamId: miniTeamId,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateTeamName(Request request, String miniActivityId, String miniTeamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final newName = safeStringNullable(data, 'name');
      if (newName == null) {
        return resp.badRequest('Mangler påkrevd felt (name)');
      }

      await _managementService.updateTeamName(teamId: miniTeamId, newName: newName);
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _createTeam(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final name = safeStringNullable(data, 'name');
      if (name == null || name.isEmpty) {
        return resp.badRequest('Mangler påkrevd felt (name)');
      }

      await _managementService.createTeam(
        miniActivityId: miniActivityId,
        name: name,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _deleteTeam(Request request, String miniActivityId, String miniTeamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      Map<String, dynamic> data = {};
      try {
        data = await parseBody(request);
      } catch (_) {
        // Body is optional for delete
      }

      await _managementService.deleteTeam(
        miniActivityId: miniActivityId,
        teamId: miniTeamId,
        moveParticipantsToTeamId: safeStringNullable(data, 'move_participants_to_team_id'),
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _moveParticipant(Request request, String miniActivityId, String participantId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final targetTeamId = safeStringNullable(data, 'target_team_id');
      if (targetTeamId == null) {
        return resp.badRequest('Mangler påkrevd felt (target_team_id)');
      }

      await _managementService.moveParticipantToTeam(
        participantId: participantId,
        newTeamId: targetTeamId,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return resp.ok(detail);
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ HANDICAPS ============

  Future<Response> _getHandicaps(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final handicaps = await _managementService.getHandicaps(miniActivityId);
      return resp.ok(handicaps.map((h) => h.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _setHandicap(Request request, String miniActivityId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final data = await parseBody(request);

      final targetUserId = safeStringNullable(data, 'user_id');
      final handicapValue = (safeNumNullable(data, 'handicap_value'))?.toDouble();

      if (targetUserId == null || handicapValue == null) {
        return resp.badRequest('Mangler påkrevde felt (user_id, handicap_value)');
      }

      final handicap = await _managementService.setHandicap(
        miniActivityId: miniActivityId,
        userId: targetUserId,
        handicapValue: handicapValue,
      );

      return resp.ok(handicap.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _removeHandicap(Request request, String miniActivityId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      await _managementService.removeHandicap(miniActivityId: miniActivityId, userId: targetUserId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
