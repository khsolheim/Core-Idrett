import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/tournament.dart';
import '../data/tournament_repository.dart';

export 'tournament_notifiers.dart';

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

