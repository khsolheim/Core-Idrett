import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/tournament.dart';
import '../data/tournament_repository.dart';

// ============ READ PROVIDERS ============

// Provider for a tournament by ID
final tournamentProvider = FutureProvider.family<Tournament, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getTournament(tournamentId);
});

// Provider for tournament by mini-activity ID
final tournamentForMiniActivityProvider = FutureProvider.family<Tournament?, String>((ref, miniActivityId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getTournamentForMiniActivity(miniActivityId);
});

// Provider for tournament rounds
final tournamentRoundsProvider = FutureProvider.family<List<TournamentRound>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getRounds(tournamentId);
});

// Provider for tournament matches
final tournamentMatchesProvider = FutureProvider.family<List<TournamentMatch>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getMatches(tournamentId);
});

// Provider for a specific match
final matchDetailProvider = FutureProvider.family<TournamentMatch, String>((ref, matchId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getMatch(matchId);
});

// Provider for match games (best-of series)
final matchGamesProvider = FutureProvider.family<List<MatchGame>, String>((ref, matchId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getGames(matchId);
});

// Provider for tournament groups
final tournamentGroupsProvider = FutureProvider.family<List<TournamentGroup>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getGroups(tournamentId);
});

// Provider for group standings
final groupStandingsProvider = FutureProvider.family<List<GroupStanding>, String>((ref, groupId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getGroupStandings(groupId);
});

// Provider for group matches
final groupMatchesProvider = FutureProvider.family<List<GroupMatch>, String>((ref, groupId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getGroupMatches(groupId);
});

// Provider for qualification rounds
final qualificationRoundsProvider = FutureProvider.family<List<QualificationRound>, String>((ref, tournamentId) async {
  final repository = ref.watch(tournamentRepositoryProvider);
  return repository.getQualificationRounds(tournamentId);
});

// ============ STATE NOTIFIERS ============

// StateNotifier for tournament management
class TournamentNotifier extends StateNotifier<AsyncValue<void>> {
  final TournamentRepository _repository;
  final Ref _ref;

  TournamentNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<Tournament?> createTournament({
    required String miniActivityId,
    required TournamentType tournamentType,
    int bestOf = 1,
    bool bronzeFinal = false,
    SeedingMethod seedingMethod = SeedingMethod.random,
    int? maxParticipants,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createTournament(
        miniActivityId: miniActivityId,
        tournamentType: tournamentType,
        bestOf: bestOf,
        bronzeFinal: bronzeFinal,
        seedingMethod: seedingMethod,
        maxParticipants: maxParticipants,
      );
      _ref.invalidate(tournamentForMiniActivityProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<Tournament?> updateTournament({
    required String tournamentId,
    required String miniActivityId,
    TournamentType? tournamentType,
    TournamentStatus? status,
    int? bestOf,
    bool? bronzeFinal,
    SeedingMethod? seedingMethod,
    int? maxParticipants,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateTournament(
        tournamentId: tournamentId,
        tournamentType: tournamentType,
        status: status,
        bestOf: bestOf,
        bronzeFinal: bronzeFinal,
        seedingMethod: seedingMethod,
        maxParticipants: maxParticipants,
      );
      _ref.invalidate(tournamentProvider(tournamentId));
      _ref.invalidate(tournamentForMiniActivityProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteTournament({
    required String tournamentId,
    required String miniActivityId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTournament(tournamentId);
      _ref.invalidate(tournamentProvider(tournamentId));
      _ref.invalidate(tournamentForMiniActivityProvider(miniActivityId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<List<TournamentMatch>?> generateBracket({
    required String tournamentId,
    required List<String> participantIds,
    List<int>? seeds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.generateBracket(
        tournamentId: tournamentId,
        participantIds: participantIds,
        seeds: seeds,
      );
      _ref.invalidate(tournamentProvider(tournamentId));
      _ref.invalidate(tournamentRoundsProvider(tournamentId));
      _ref.invalidate(tournamentMatchesProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final tournamentNotifierProvider = StateNotifierProvider<TournamentNotifier, AsyncValue<void>>((ref) {
  return TournamentNotifier(ref.watch(tournamentRepositoryProvider), ref);
});

// StateNotifier for match operations
class MatchNotifier extends StateNotifier<AsyncValue<void>> {
  final TournamentRepository _repository;
  final Ref _ref;

  MatchNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<TournamentMatch?> updateMatch({
    required String matchId,
    required String tournamentId,
    int? teamAScore,
    int? teamBScore,
    MatchStatus? status,
    DateTime? scheduledTime,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateMatch(
        matchId: matchId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        status: status,
        scheduledTime: scheduledTime,
      );
      _ref.invalidate(matchDetailProvider(matchId));
      _ref.invalidate(tournamentMatchesProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<TournamentMatch?> startMatch({
    required String matchId,
    required String tournamentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.startMatch(matchId);
      _ref.invalidate(matchDetailProvider(matchId));
      _ref.invalidate(tournamentMatchesProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<TournamentMatch?> completeMatch({
    required String matchId,
    required String tournamentId,
    required String winnerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.completeMatch(
        matchId: matchId,
        winnerId: winnerId,
      );
      _ref.invalidate(matchDetailProvider(matchId));
      _ref.invalidate(tournamentMatchesProvider(tournamentId));
      _ref.invalidate(tournamentProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<TournamentMatch?> declareWalkover({
    required String matchId,
    required String tournamentId,
    required String winnerId,
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.declareWalkover(
        matchId: matchId,
        winnerId: winnerId,
        reason: reason,
      );
      _ref.invalidate(matchDetailProvider(matchId));
      _ref.invalidate(tournamentMatchesProvider(tournamentId));
      _ref.invalidate(tournamentProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<MatchGame?> recordGame({
    required String matchId,
    required String tournamentId,
    required int gameNumber,
    required int teamAScore,
    required int teamBScore,
    String? winnerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.recordGame(
        matchId: matchId,
        gameNumber: gameNumber,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        winnerId: winnerId,
      );
      _ref.invalidate(matchGamesProvider(matchId));
      _ref.invalidate(matchDetailProvider(matchId));
      _ref.invalidate(tournamentMatchesProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final matchNotifierProvider = StateNotifierProvider<MatchNotifier, AsyncValue<void>>((ref) {
  return MatchNotifier(ref.watch(tournamentRepositoryProvider), ref);
});

// StateNotifier for group operations
class GroupNotifier extends StateNotifier<AsyncValue<void>> {
  final TournamentRepository _repository;
  final Ref _ref;

  GroupNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<TournamentGroup?> createGroup({
    required String tournamentId,
    required String name,
    int advanceCount = 2,
    int sortOrder = 0,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createGroup(
        tournamentId: tournamentId,
        name: name,
        advanceCount: advanceCount,
        sortOrder: sortOrder,
      );
      _ref.invalidate(tournamentGroupsProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<TournamentGroup?> updateGroup({
    required String groupId,
    required String tournamentId,
    String? name,
    int? advanceCount,
    int? sortOrder,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateGroup(
        groupId: groupId,
        name: name,
        advanceCount: advanceCount,
        sortOrder: sortOrder,
      );
      _ref.invalidate(tournamentGroupsProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteGroup({
    required String groupId,
    required String tournamentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteGroup(groupId);
      _ref.invalidate(tournamentGroupsProvider(tournamentId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<TournamentGroup?> addTeamToGroup({
    required String groupId,
    required String tournamentId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.addTeamToGroup(
        groupId: groupId,
        teamId: teamId,
      );
      _ref.invalidate(tournamentGroupsProvider(tournamentId));
      _ref.invalidate(groupStandingsProvider(groupId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> removeTeamFromGroup({
    required String groupId,
    required String tournamentId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeTeamFromGroup(
        groupId: groupId,
        teamId: teamId,
      );
      _ref.invalidate(tournamentGroupsProvider(tournamentId));
      _ref.invalidate(groupStandingsProvider(groupId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<TournamentGroup?> generateGroupFixtures({
    required String groupId,
    required String tournamentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.generateGroupFixtures(groupId);
      _ref.invalidate(tournamentGroupsProvider(tournamentId));
      _ref.invalidate(groupMatchesProvider(groupId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<GroupMatch?> completeGroupMatch({
    required String matchId,
    required String groupId,
    required String tournamentId,
    required int teamAScore,
    required int teamBScore,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.completeGroupMatch(
        matchId: matchId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
      );
      _ref.invalidate(groupMatchesProvider(groupId));
      _ref.invalidate(groupStandingsProvider(groupId));
      _ref.invalidate(tournamentGroupsProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final groupNotifierProvider = StateNotifierProvider<GroupNotifier, AsyncValue<void>>((ref) {
  return GroupNotifier(ref.watch(tournamentRepositoryProvider), ref);
});

// StateNotifier for qualification operations
class QualificationNotifier extends StateNotifier<AsyncValue<void>> {
  final TournamentRepository _repository;
  final Ref _ref;

  QualificationNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<QualificationRound?> createQualificationRound({
    required String tournamentId,
    required String name,
    int advanceCount = 8,
    String sortDirection = 'asc',
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createQualificationRound(
        tournamentId: tournamentId,
        name: name,
        advanceCount: advanceCount,
        sortDirection: sortDirection,
      );
      _ref.invalidate(qualificationRoundsProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<QualificationResult?> recordResult({
    required String qualificationRoundId,
    required String tournamentId,
    required String userId,
    required double resultValue,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.recordQualificationResult(
        qualificationRoundId: qualificationRoundId,
        userId: userId,
        resultValue: resultValue,
      );
      _ref.invalidate(qualificationRoundsProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<List<QualificationResult>?> finalizeQualification({
    required String qualificationRoundId,
    required String tournamentId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.finalizeQualification(qualificationRoundId);
      _ref.invalidate(qualificationRoundsProvider(tournamentId));
      _ref.invalidate(tournamentProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final qualificationNotifierProvider = StateNotifierProvider<QualificationNotifier, AsyncValue<void>>((ref) {
  return QualificationNotifier(ref.watch(tournamentRepositoryProvider), ref);
});
