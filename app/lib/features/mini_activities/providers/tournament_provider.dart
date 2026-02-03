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

// ============ NOTIFIERS ============

// Notifier for tournament management
class TournamentNotifier extends Notifier<AsyncValue<void>> {
  late final TournamentRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(tournamentRepositoryProvider);
    return const AsyncValue.data(null);
  }

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
      ref.invalidate(tournamentForMiniActivityProvider(miniActivityId));
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
      ref.invalidate(tournamentProvider(tournamentId));
      ref.invalidate(tournamentForMiniActivityProvider(miniActivityId));
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
      ref.invalidate(tournamentProvider(tournamentId));
      ref.invalidate(tournamentForMiniActivityProvider(miniActivityId));
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
      ref.invalidate(tournamentProvider(tournamentId));
      ref.invalidate(tournamentRoundsProvider(tournamentId));
      ref.invalidate(tournamentMatchesProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final tournamentNotifierProvider = NotifierProvider<TournamentNotifier, AsyncValue<void>>(() {
  return TournamentNotifier();
});

// Notifier for match operations
class MatchNotifier extends Notifier<AsyncValue<void>> {
  late final TournamentRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(tournamentRepositoryProvider);
    return const AsyncValue.data(null);
  }

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
      ref.invalidate(matchDetailProvider(matchId));
      ref.invalidate(tournamentMatchesProvider(tournamentId));
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
      ref.invalidate(matchDetailProvider(matchId));
      ref.invalidate(tournamentMatchesProvider(tournamentId));
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
      ref.invalidate(matchDetailProvider(matchId));
      ref.invalidate(tournamentMatchesProvider(tournamentId));
      ref.invalidate(tournamentProvider(tournamentId));
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
      ref.invalidate(matchDetailProvider(matchId));
      ref.invalidate(tournamentMatchesProvider(tournamentId));
      ref.invalidate(tournamentProvider(tournamentId));
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
      ref.invalidate(matchGamesProvider(matchId));
      ref.invalidate(matchDetailProvider(matchId));
      ref.invalidate(tournamentMatchesProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final matchNotifierProvider = NotifierProvider<MatchNotifier, AsyncValue<void>>(() {
  return MatchNotifier();
});

// Notifier for group operations
class GroupNotifier extends Notifier<AsyncValue<void>> {
  late final TournamentRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(tournamentRepositoryProvider);
    return const AsyncValue.data(null);
  }

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
      ref.invalidate(tournamentGroupsProvider(tournamentId));
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
      ref.invalidate(tournamentGroupsProvider(tournamentId));
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
      ref.invalidate(tournamentGroupsProvider(tournamentId));
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
      ref.invalidate(tournamentGroupsProvider(tournamentId));
      ref.invalidate(groupStandingsProvider(groupId));
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
      ref.invalidate(tournamentGroupsProvider(tournamentId));
      ref.invalidate(groupStandingsProvider(groupId));
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
      ref.invalidate(tournamentGroupsProvider(tournamentId));
      ref.invalidate(groupMatchesProvider(groupId));
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
      ref.invalidate(groupMatchesProvider(groupId));
      ref.invalidate(groupStandingsProvider(groupId));
      ref.invalidate(tournamentGroupsProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final groupNotifierProvider = NotifierProvider<GroupNotifier, AsyncValue<void>>(() {
  return GroupNotifier();
});

// Notifier for qualification operations
class QualificationNotifier extends Notifier<AsyncValue<void>> {
  late final TournamentRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(tournamentRepositoryProvider);
    return const AsyncValue.data(null);
  }

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
      ref.invalidate(qualificationRoundsProvider(tournamentId));
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
      ref.invalidate(qualificationRoundsProvider(tournamentId));
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
      ref.invalidate(qualificationRoundsProvider(tournamentId));
      ref.invalidate(tournamentProvider(tournamentId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final qualificationNotifierProvider = NotifierProvider<QualificationNotifier, AsyncValue<void>>(() {
  return QualificationNotifier();
});
