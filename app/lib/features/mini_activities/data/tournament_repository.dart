import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/tournament.dart';

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository(ref.watch(apiClientProvider));
});

class TournamentRepository {
  final ApiClient _apiClient;

  TournamentRepository(this._apiClient);

  // ============ TOURNAMENTS ============

  Future<Tournament> createTournament({
    required String miniActivityId,
    required TournamentType tournamentType,
    int bestOf = 1,
    bool bronzeFinal = false,
    SeedingMethod seedingMethod = SeedingMethod.random,
    int? maxParticipants,
  }) async {
    final response = await _apiClient.post('/tournaments/mini-activity/$miniActivityId', data: {
      'tournament_type': tournamentType.toJson(),
      'best_of': bestOf,
      'bronze_final': bronzeFinal,
      'seeding_method': seedingMethod.toJson(),
      if (maxParticipants != null) 'max_participants': maxParticipants,
    });
    return Tournament.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Tournament> getTournament(String tournamentId) async {
    final response = await _apiClient.get('/tournaments/$tournamentId');
    return Tournament.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Tournament?> getTournamentForMiniActivity(String miniActivityId) async {
    final response = await _apiClient.get('/tournaments/mini-activity/$miniActivityId');
    if (response.data == null) return null;
    return Tournament.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Tournament> updateTournament({
    required String tournamentId,
    TournamentType? tournamentType,
    TournamentStatus? status,
    int? bestOf,
    bool? bronzeFinal,
    SeedingMethod? seedingMethod,
    int? maxParticipants,
  }) async {
    final response = await _apiClient.patch('/tournaments/$tournamentId', data: {
      if (tournamentType != null) 'tournament_type': tournamentType.toJson(),
      if (status != null) 'status': status.toJson(),
      if (bestOf != null) 'best_of': bestOf,
      if (bronzeFinal != null) 'bronze_final': bronzeFinal,
      if (seedingMethod != null) 'seeding_method': seedingMethod.toJson(),
      if (maxParticipants != null) 'max_participants': maxParticipants,
    });
    return Tournament.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteTournament(String tournamentId) async {
    await _apiClient.delete('/tournaments/$tournamentId');
  }

  // ============ BRACKET GENERATION ============

  Future<List<TournamentMatch>> generateBracket({
    required String tournamentId,
    required List<String> participantIds,
    List<int>? seeds,
  }) async {
    final response = await _apiClient.post('/tournaments/$tournamentId/generate-bracket', data: {
      'participant_ids': participantIds,
      if (seeds != null) 'seeds': seeds,
    });
    final data = response.data as List;
    return data.map((json) => TournamentMatch.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ============ ROUNDS ============

  Future<List<TournamentRound>> getRounds(String tournamentId) async {
    final response = await _apiClient.get('/tournaments/$tournamentId/rounds');
    final data = response.data as List;
    return data.map((json) => TournamentRound.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<TournamentRound> createRound({
    required String tournamentId,
    required int roundNumber,
    required String roundName,
    RoundType roundType = RoundType.winners,
    DateTime? scheduledTime,
  }) async {
    final response = await _apiClient.post('/tournaments/$tournamentId/rounds', data: {
      'round_number': roundNumber,
      'round_name': roundName,
      'round_type': roundType.toJson(),
      if (scheduledTime != null) 'scheduled_time': scheduledTime.toIso8601String(),
    });
    return TournamentRound.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TournamentRound> updateRound({
    required String roundId,
    String? roundName,
    MatchStatus? status,
    DateTime? scheduledTime,
  }) async {
    final response = await _apiClient.patch('/tournaments/rounds/$roundId', data: {
      if (roundName != null) 'round_name': roundName,
      if (status != null) 'status': status.toJson(),
      if (scheduledTime != null) 'scheduled_time': scheduledTime.toIso8601String(),
    });
    return TournamentRound.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ MATCHES ============

  Future<List<TournamentMatch>> getMatches(String tournamentId, {String? roundId}) async {
    final queryParams = <String, String>{};
    if (roundId != null) queryParams['round_id'] = roundId;

    final response = await _apiClient.get(
      '/tournaments/$tournamentId/matches',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data as List;
    return data.map((json) => TournamentMatch.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<TournamentMatch> getMatch(String matchId) async {
    final response = await _apiClient.get('/tournaments/matches/$matchId');
    return TournamentMatch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TournamentMatch> updateMatch({
    required String matchId,
    int? teamAScore,
    int? teamBScore,
    MatchStatus? status,
    DateTime? scheduledTime,
  }) async {
    final response = await _apiClient.patch('/tournaments/matches/$matchId', data: {
      if (teamAScore != null) 'team_a_score': teamAScore,
      if (teamBScore != null) 'team_b_score': teamBScore,
      if (status != null) 'status': status.toJson(),
      if (scheduledTime != null) 'scheduled_time': scheduledTime.toIso8601String(),
    });
    return TournamentMatch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TournamentMatch> startMatch(String matchId) async {
    final response = await _apiClient.post('/tournaments/matches/$matchId/start');
    return TournamentMatch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TournamentMatch> completeMatch({
    required String matchId,
    required String winnerId,
  }) async {
    final response = await _apiClient.post('/tournaments/matches/$matchId/complete', data: {
      'winner_id': winnerId,
    });
    return TournamentMatch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TournamentMatch> declareWalkover({
    required String matchId,
    required String winnerId,
    String? reason,
  }) async {
    final response = await _apiClient.post('/tournaments/matches/$matchId/walkover', data: {
      'winner_id': winnerId,
      if (reason != null) 'reason': reason,
    });
    return TournamentMatch.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ BEST-OF GAMES ============

  Future<List<MatchGame>> getGames(String matchId) async {
    final response = await _apiClient.get('/tournaments/matches/$matchId/games');
    final data = response.data as List;
    return data.map((json) => MatchGame.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<MatchGame> recordGame({
    required String matchId,
    required int gameNumber,
    required int teamAScore,
    required int teamBScore,
    String? winnerId,
  }) async {
    final response = await _apiClient.post('/tournaments/matches/$matchId/games', data: {
      'game_number': gameNumber,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      if (winnerId != null) 'winner_id': winnerId,
    });
    return MatchGame.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MatchGame> updateGame({
    required String gameId,
    int? teamAScore,
    int? teamBScore,
    String? winnerId,
    MatchStatus? status,
  }) async {
    final response = await _apiClient.patch('/tournaments/games/$gameId', data: {
      if (teamAScore != null) 'team_a_score': teamAScore,
      if (teamBScore != null) 'team_b_score': teamBScore,
      if (winnerId != null) 'winner_id': winnerId,
      if (status != null) 'status': status.toJson(),
    });
    return MatchGame.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ GROUPS ============

  Future<List<TournamentGroup>> getGroups(String tournamentId) async {
    final response = await _apiClient.get('/tournaments/$tournamentId/groups');
    final data = response.data as List;
    return data.map((json) => TournamentGroup.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<TournamentGroup> createGroup({
    required String tournamentId,
    required String name,
    int advanceCount = 2,
    int sortOrder = 0,
  }) async {
    final response = await _apiClient.post('/tournaments/$tournamentId/groups', data: {
      'name': name,
      'advance_count': advanceCount,
      'sort_order': sortOrder,
    });
    return TournamentGroup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TournamentGroup> updateGroup({
    required String groupId,
    String? name,
    int? advanceCount,
    int? sortOrder,
  }) async {
    final response = await _apiClient.patch('/tournaments/groups/$groupId', data: {
      if (name != null) 'name': name,
      if (advanceCount != null) 'advance_count': advanceCount,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
    return TournamentGroup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteGroup(String groupId) async {
    await _apiClient.delete('/tournaments/groups/$groupId');
  }

  Future<TournamentGroup> addTeamToGroup({
    required String groupId,
    required String teamId,
  }) async {
    final response = await _apiClient.post('/tournaments/groups/$groupId/teams', data: {
      'team_id': teamId,
    });
    return TournamentGroup.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> removeTeamFromGroup({
    required String groupId,
    required String teamId,
  }) async {
    await _apiClient.delete('/tournaments/groups/$groupId/teams/$teamId');
  }

  // ============ GROUP STANDINGS ============

  Future<List<GroupStanding>> getGroupStandings(String groupId) async {
    final response = await _apiClient.get('/tournaments/groups/$groupId/standings');
    final data = response.data as List;
    return data.map((json) => GroupStanding.fromJson(json as Map<String, dynamic>)).toList();
  }

  // ============ GROUP MATCHES ============

  Future<List<GroupMatch>> getGroupMatches(String groupId) async {
    final response = await _apiClient.get('/tournaments/groups/$groupId/matches');
    final data = response.data as List;
    return data.map((json) => GroupMatch.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<GroupMatch> updateGroupMatch({
    required String matchId,
    int? teamAScore,
    int? teamBScore,
    MatchStatus? status,
    DateTime? scheduledTime,
  }) async {
    final response = await _apiClient.patch('/tournaments/group-matches/$matchId', data: {
      if (teamAScore != null) 'team_a_score': teamAScore,
      if (teamBScore != null) 'team_b_score': teamBScore,
      if (status != null) 'status': status.toJson(),
      if (scheduledTime != null) 'scheduled_time': scheduledTime.toIso8601String(),
    });
    return GroupMatch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GroupMatch> completeGroupMatch({
    required String matchId,
    required int teamAScore,
    required int teamBScore,
  }) async {
    final response = await _apiClient.post('/tournaments/group-matches/$matchId/complete', data: {
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
    });
    return GroupMatch.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TournamentGroup> generateGroupFixtures(String groupId) async {
    final response = await _apiClient.post('/tournaments/groups/$groupId/generate-fixtures');
    return TournamentGroup.fromJson(response.data as Map<String, dynamic>);
  }

  // ============ QUALIFICATION ROUNDS ============

  Future<List<QualificationRound>> getQualificationRounds(String tournamentId) async {
    final response = await _apiClient.get('/tournaments/$tournamentId/qualifications');
    final data = response.data as List;
    return data.map((json) => QualificationRound.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<QualificationRound> createQualificationRound({
    required String tournamentId,
    required String name,
    int advanceCount = 8,
    String sortDirection = 'asc',
  }) async {
    final response = await _apiClient.post('/tournaments/$tournamentId/qualifications', data: {
      'name': name,
      'advance_count': advanceCount,
      'sort_direction': sortDirection,
    });
    return QualificationRound.fromJson(response.data as Map<String, dynamic>);
  }

  Future<QualificationResult> recordQualificationResult({
    required String qualificationRoundId,
    required String userId,
    required double resultValue,
  }) async {
    final response = await _apiClient.post('/tournaments/qualifications/$qualificationRoundId/results', data: {
      'user_id': userId,
      'result_value': resultValue,
    });
    return QualificationResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<QualificationResult>> finalizeQualification(String qualificationRoundId) async {
    final response = await _apiClient.post('/tournaments/qualifications/$qualificationRoundId/finalize');
    final data = response.data as List;
    return data.map((json) => QualificationResult.fromJson(json as Map<String, dynamic>)).toList();
  }
}
