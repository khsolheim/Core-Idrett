import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/tournament_group_service.dart';
import '../services/tournament_service.dart';
import '../services/team_service.dart';
import '../models/tournament.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class TournamentGroupsHandler {
  final TournamentGroupService _groupService;
  final TournamentService _tournamentService;
  final TeamService _teamService;

  TournamentGroupsHandler(this._groupService, this._tournamentService, this._teamService);

  Router get router {
    final router = Router();

    // Group management
    router.get('/<tournamentId>/groups', _getGroups);
    router.post('/<tournamentId>/groups', _createGroup);
    router.put('/groups/<groupId>', _updateGroup);
    router.delete('/groups/<groupId>', _deleteGroup);

    // Group standings
    router.get('/groups/<groupId>/standings', _getGroupStandings);

    // Group matches
    router.get('/groups/<groupId>/matches', _getGroupMatches);
    router.post('/groups/<groupId>/matches', _createGroupMatch);
    router.put('/group-matches/<matchId>', _updateGroupMatch);
    router.post('/group-matches/<matchId>/complete', _completeGroupMatch);

    // Qualification rounds
    router.get('/<tournamentId>/qualifications', _getQualificationRounds);
    router.post('/<tournamentId>/qualifications', _createQualificationRound);
    router.get('/qualifications/<qualificationId>/results', _getQualificationResults);
    router.post('/qualifications/<qualificationId>/results', _recordQualificationResult);
    router.post('/qualifications/<qualificationId>/finalize', _finalizeQualification);

    return router;
  }

  /// Verify team membership via tournament for routes with tournamentId.
  Future<Map<String, dynamic>?> _requireTeamForTournament(
      String tournamentId, String userId) async {
    final teamId =
        await _tournamentService.getTeamIdForTournament(tournamentId);
    if (teamId == null) return null;
    return requireTeamMember(_teamService, teamId, userId);
  }

  // ============ GROUPS ============

  Future<Response> _getGroups(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final groups = await _groupService.getGroupsForTournament(tournamentId);
      return resp.ok(groups.map((g) => g.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _createGroup(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final data = await parseBody(request);

      final name = data['name'] as String?;
      if (name == null) {
        return resp.badRequest('Mangler påkrevd felt (name)');
      }

      final group = await _groupService.createGroup(
        tournamentId: tournamentId,
        name: name,
        advanceCount: data['advance_count'] as int? ?? 2,
        sortOrder: data['sort_order'] as int? ?? 0,
      );

      return resp.ok(group.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateGroup(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

      final group = await _groupService.updateGroup(
        groupId: groupId,
        name: data['name'] as String?,
        advanceCount: data['advance_count'] as int?,
        sortOrder: data['sort_order'] as int?,
      );

      return resp.ok(group.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _deleteGroup(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      await _groupService.deleteGroup(groupId);
      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ GROUP STANDINGS ============

  Future<Response> _getGroupStandings(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final standings = await _groupService.getGroupStandings(groupId);
      return resp.ok(standings.map((s) => s.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ GROUP MATCHES ============

  Future<Response> _getGroupMatches(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final matches = await _groupService.getGroupMatches(groupId);
      return resp.ok(matches.map((m) => m.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _createGroupMatch(Request request, String groupId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

      final teamAId = data['team_a_id'] as String?;
      final teamBId = data['team_b_id'] as String?;

      if (teamAId == null || teamBId == null) {
        return resp.badRequest('Mangler påkrevde felt (team_a_id, team_b_id)');
      }

      final match = await _groupService.createGroupMatch(
        groupId: groupId,
        teamAId: teamAId,
        teamBId: teamBId,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
        matchOrder: data['match_order'] as int? ?? 0,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _updateGroupMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

      final match = await _groupService.updateGroupMatch(
        matchId: matchId,
        teamAScore: data['team_a_score'] as int?,
        teamBScore: data['team_b_score'] as int?,
        status: data['status'] != null
            ? MatchStatus.fromString(data['status'] as String)
            : null,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _completeGroupMatch(Request request, String matchId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

      final teamAScore = data['team_a_score'] as int?;
      final teamBScore = data['team_b_score'] as int?;

      if (teamAScore == null || teamBScore == null) {
        return resp.badRequest('Mangler påkrevde felt (team_a_score, team_b_score)');
      }

      final match = await _groupService.completeGroupMatch(
        matchId: matchId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
      );

      return resp.ok(match.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  // ============ QUALIFICATION ROUNDS ============

  Future<Response> _getQualificationRounds(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final rounds = await _groupService.getQualificationRounds(tournamentId);
      return resp.ok(rounds.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _createQualificationRound(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final data = await parseBody(request);

      final name = data['name'] as String?;
      if (name == null) {
        return resp.badRequest('Mangler påkrevd felt (name)');
      }

      final round = await _groupService.createQualificationRound(
        tournamentId: tournamentId,
        name: name,
        advanceCount: data['advance_count'] as int? ?? 8,
        sortDirection: data['sort_direction'] as String? ?? 'desc',
      );

      return resp.ok(round.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _getQualificationResults(Request request, String qualificationId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final results = await _groupService.getQualificationResults(qualificationId);
      return resp.ok(results.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _recordQualificationResult(Request request, String qualificationId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final data = await parseBody(request);

      final participantUserId = data['user_id'] as String?;
      final resultValue = (data['result_value'] as num?)?.toDouble();

      if (participantUserId == null || resultValue == null) {
        return resp.badRequest('Mangler påkrevde felt (user_id, result_value)');
      }

      final result = await _groupService.recordQualificationResult(
        qualificationRoundId: qualificationId,
        userId: participantUserId,
        resultValue: resultValue,
      );

      return resp.ok(result.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }

  Future<Response> _finalizeQualification(Request request, String qualificationId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.unauthorized();

      final advancedResults = await _groupService.finalizeQualification(qualificationId);
      return resp.ok(advancedResults.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod');
    }
  }
}
