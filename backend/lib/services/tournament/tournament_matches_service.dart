import 'package:uuid/uuid.dart';
import '../../db/database.dart';
import '../../models/tournament.dart';
import '../../helpers/parsing_helpers.dart';

class TournamentMatchesService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentMatchesService(this._db);

  // ============ MATCHES ============

  Future<TournamentMatch> updateMatch({
    required String matchId,
    int? teamAScore,
    int? teamBScore,
    MatchStatus? status,
    DateTime? scheduledTime,
  }) async {
    final updates = <String, dynamic>{};
    if (teamAScore != null) updates['team_a_score'] = teamAScore;
    if (teamBScore != null) updates['team_b_score'] = teamBScore;
    if (status != null) updates['status'] = status.value;
    if (scheduledTime != null) updates['scheduled_time'] = scheduledTime.toIso8601String();

    if (updates.isNotEmpty) {
      await _db.client.update(
        'tournament_matches',
        updates,
        filters: {'id': 'eq.$matchId'},
      );
    }

    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return TournamentMatch.fromJson(result.first);
  }

  Future<TournamentMatch> startMatch(String matchId) async {
    await _db.client.update(
      'tournament_matches',
      {'status': 'in_progress'},
      filters: {'id': 'eq.$matchId'},
    );
    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return TournamentMatch.fromJson(result.first);
  }

  Future<TournamentMatch> completeMatch(String matchId, String winnerId) async {
    // Get current match to get scores
    final matchResult = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    if (matchResult.isEmpty) {
      throw Exception('Match not found');
    }
    final match = matchResult.first;

    await recordMatchResult(
      matchId: matchId,
      teamAScore: safeInt(match, 'team_a_score', defaultValue: 0),
      teamBScore: safeInt(match, 'team_b_score', defaultValue: 0),
      winnerId: winnerId,
    );

    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return TournamentMatch.fromJson(result.first);
  }

  Future<TournamentMatch> declareWalkover({
    required String matchId,
    required String winnerId,
    String? reason,
  }) async {
    await setWalkover(
      matchId: matchId,
      winnerId: winnerId,
      reason: reason,
    );

    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    return TournamentMatch.fromJson(result.first);
  }

  Future<TournamentMatch> createMatch({
    required String tournamentId,
    required String roundId,
    required int bracketPosition,
    String? teamAId,
    String? teamBId,
    DateTime? scheduledTime,
    int matchOrder = 0,
    String? winnerGoesToMatchId,
    String? loserGoesToMatchId,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('tournament_matches', {
      'id': id,
      'tournament_id': tournamentId,
      'round_id': roundId,
      'bracket_position': bracketPosition,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'status': 'pending',
      'scheduled_time': scheduledTime?.toIso8601String(),
      'match_order': matchOrder,
      'winner_goes_to_match_id': winnerGoesToMatchId,
      'loser_goes_to_match_id': loserGoesToMatchId,
    });

    return TournamentMatch(
      id: id,
      tournamentId: tournamentId,
      roundId: roundId,
      bracketPosition: bracketPosition,
      teamAId: teamAId,
      teamBId: teamBId,
      status: MatchStatus.pending,
      scheduledTime: scheduledTime,
      matchOrder: matchOrder,
      winnerGoesToMatchId: winnerGoesToMatchId,
      loserGoesToMatchId: loserGoesToMatchId,
      createdAt: DateTime.now(),
    );
  }

  Future<List<TournamentMatch>> getMatchesForRound(String roundId) async {
    final result = await _db.client.select(
      'tournament_matches',
      filters: {'round_id': 'eq.$roundId'},
      order: 'match_order.asc',
    );
    return result.map((row) => TournamentMatch.fromJson(row)).toList();
  }

  Future<List<TournamentMatch>> getMatchesForTournament(String tournamentId, {String? roundId}) async {
    final filters = <String, String>{'tournament_id': 'eq.$tournamentId'};
    if (roundId != null) {
      filters['round_id'] = 'eq.$roundId';
    }
    final result = await _db.client.select(
      'tournament_matches',
      filters: filters,
      order: 'match_order.asc',
    );
    return result.map((row) => TournamentMatch.fromJson(row)).toList();
  }

  Future<TournamentMatch?> getMatchById(String matchId) async {
    final result = await _db.client.select(
      'tournament_matches',
      filters: {'id': 'eq.$matchId'},
    );
    if (result.isEmpty) return null;
    return TournamentMatch.fromJson(result.first);
  }

  Future<void> recordMatchResult({
    required String matchId,
    required int teamAScore,
    required int teamBScore,
    required String winnerId,
  }) async {
    await _db.client.update(
      'tournament_matches',
      {
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        'winner_id': winnerId,
        'status': 'completed',
      },
      filters: {'id': 'eq.$matchId'},
    );

    // Advance winner to next match
    final match = await getMatchById(matchId);
    if (match != null && match.winnerGoesToMatchId != null) {
      await _advanceTeamToMatch(winnerId, match.winnerGoesToMatchId!);
    }

    // Handle loser bracket
    final loserId = winnerId == match?.teamAId ? match?.teamBId : match?.teamAId;
    if (match != null && match.loserGoesToMatchId != null && loserId != null) {
      await _advanceTeamToMatch(loserId, match.loserGoesToMatchId!);
    }
  }

  Future<void> _advanceTeamToMatch(String teamId, String matchId) async {
    final nextMatch = await getMatchById(matchId);
    if (nextMatch == null) return;

    // Place in first available slot
    if (nextMatch.teamAId == null) {
      await _db.client.update(
        'tournament_matches',
        {'team_a_id': teamId},
        filters: {'id': 'eq.$matchId'},
      );
    } else if (nextMatch.teamBId == null) {
      await _db.client.update(
        'tournament_matches',
        {'team_b_id': teamId},
        filters: {'id': 'eq.$matchId'},
      );
    }
  }

  Future<void> setWalkover({
    required String matchId,
    required String winnerId,
    String? reason,
  }) async {
    await _db.client.update(
      'tournament_matches',
      {
        'winner_id': winnerId,
        'status': 'walkover',
        'is_walkover': true,
        'walkover_reason': reason,
      },
      filters: {'id': 'eq.$matchId'},
    );

    // Advance winner
    final match = await getMatchById(matchId);
    if (match != null && match.winnerGoesToMatchId != null) {
      await _advanceTeamToMatch(winnerId, match.winnerGoesToMatchId!);
    }
  }

  // ============ MATCH GAMES (Best-of series) ============

  Future<MatchGame> createGame({
    required String matchId,
    required int gameNumber,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('match_games', {
      'id': id,
      'match_id': matchId,
      'game_number': gameNumber,
      'team_a_score': 0,
      'team_b_score': 0,
      'status': 'pending',
    });

    return MatchGame(
      id: id,
      matchId: matchId,
      gameNumber: gameNumber,
      createdAt: DateTime.now(),
    );
  }

  Future<List<MatchGame>> getGamesForMatch(String matchId) async {
    final result = await _db.client.select(
      'match_games',
      filters: {'match_id': 'eq.$matchId'},
      order: 'game_number.asc',
    );
    return result.map((row) => MatchGame.fromJson(row)).toList();
  }

  Future<void> recordGameResult({
    required String gameId,
    required int teamAScore,
    required int teamBScore,
    String? winnerId,
  }) async {
    await _db.client.update(
      'match_games',
      {
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        'winner_id': winnerId,
        'status': 'completed',
      },
      filters: {'id': 'eq.$gameId'},
    );
  }

  Future<MatchGame> recordGame({
    required String matchId,
    required int gameNumber,
    required int teamAScore,
    required int teamBScore,
    required String winnerId,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('match_games', {
      'id': id,
      'match_id': matchId,
      'game_number': gameNumber,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'winner_id': winnerId,
      'status': 'completed',
    });

    return MatchGame(
      id: id,
      matchId: matchId,
      gameNumber: gameNumber,
      teamAScore: teamAScore,
      teamBScore: teamBScore,
      winnerId: winnerId,
      status: MatchStatus.completed,
      createdAt: DateTime.now(),
    );
  }

  Future<MatchGame> updateGame({
    required String gameId,
    int? teamAScore,
    int? teamBScore,
    String? winnerId,
    MatchStatus? status,
  }) async {
    final updates = <String, dynamic>{};
    if (teamAScore != null) updates['team_a_score'] = teamAScore;
    if (teamBScore != null) updates['team_b_score'] = teamBScore;
    if (winnerId != null) updates['winner_id'] = winnerId;
    if (status != null) updates['status'] = status.value;

    if (updates.isNotEmpty) {
      await _db.client.update(
        'match_games',
        updates,
        filters: {'id': 'eq.$gameId'},
      );
    }

    final result = await _db.client.select(
      'match_games',
      filters: {'id': 'eq.$gameId'},
    );
    return MatchGame.fromJson(result.first);
  }
}
