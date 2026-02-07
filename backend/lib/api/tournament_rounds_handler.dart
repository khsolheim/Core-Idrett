import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/tournament_service.dart';
import '../services/team_service.dart';
import '../models/tournament.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class TournamentRoundsHandler {
  final TournamentService _tournamentService;
  final TeamService _teamService;

  TournamentRoundsHandler(this._tournamentService, this._teamService);

  Router get router {
    final router = Router();

    router.get('/<tournamentId>/rounds', _getRounds);
    router.post('/<tournamentId>/rounds', _createRound);
    router.put('/rounds/<roundId>', _updateRound);

    return router;
  }

  Future<Map<String, dynamic>?> _requireTeamForTournament(
      String tournamentId, String userId) async {
    final teamId =
        await _tournamentService.getTeamIdForTournament(tournamentId);
    if (teamId == null) return null;
    return requireTeamMember(_teamService, teamId, userId);
  }

  Future<Response> _getRounds(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final rounds = await _tournamentService.getRoundsForTournament(tournamentId);
      return resp.ok(rounds.map((r) => r.toJson()).toList());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _createRound(Request request, String tournamentId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final team = await _requireTeamForTournament(tournamentId, userId);
      if (team == null) return resp.forbidden('Ingen tilgang til denne turneringen');

      final data = await parseBody(request);

      final roundNumber = data['round_number'] as int?;
      final roundName = data['round_name'] as String?;

      if (roundNumber == null || roundName == null) {
        return resp.badRequest('Mangler påkrevde felt (round_number, round_name)');
      }

      final round = await _tournamentService.createRound(
        tournamentId: tournamentId,
        roundNumber: roundNumber,
        roundName: roundName,
        roundType: data['round_type'] != null
            ? RoundType.fromString(data['round_type'] as String)
            : RoundType.winners,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
      );

      return resp.ok(round.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }

  Future<Response> _updateRound(Request request, String roundId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) return resp.forbidden('Ikke autorisert');

      final data = await parseBody(request);

      final round = await _tournamentService.updateRound(
        roundId: roundId,
        roundName: data['round_name'] as String?,
        status: data['status'] != null
            ? TournamentStatus.fromString(data['status'] as String)
            : null,
        scheduledTime: data['scheduled_time'] != null
            ? DateTime.parse(data['scheduled_time'] as String)
            : null,
      );

      return resp.ok(round.toJson());
    } catch (e) {
      return resp.serverError('En feil oppstod: $e');
    }
  }
}
