import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stopwatch.dart';
import '../data/stopwatch_repository.dart';

// ============ READ PROVIDERS ============

// Provider for a session by ID
final stopwatchSessionProvider = FutureProvider.family<StopwatchSession, String>((ref, sessionId) async {
  final repository = ref.watch(stopwatchRepositoryProvider);
  return repository.getSession(sessionId);
});

// Provider for session with times
final stopwatchSessionWithTimesProvider = FutureProvider.family<StopwatchSessionWithTimes, String>((ref, sessionId) async {
  final repository = ref.watch(stopwatchRepositoryProvider);
  return repository.getSessionWithTimes(sessionId);
});

// Provider for sessions of a mini-activity
final miniActivitySessionsProvider = FutureProvider.family<List<StopwatchSession>, String>((ref, miniActivityId) async {
  final repository = ref.watch(stopwatchRepositoryProvider);
  return repository.getSessionsForMiniActivity(miniActivityId);
});

// Provider for sessions of a team
final teamSessionsProvider = FutureProvider.family<List<StopwatchSession>, String>((ref, teamId) async {
  final repository = ref.watch(stopwatchRepositoryProvider);
  return repository.getSessionsForTeam(teamId);
});

// Provider for times of a session
final sessionTimesProvider = FutureProvider.family<List<StopwatchTime>, String>((ref, sessionId) async {
  final repository = ref.watch(stopwatchRepositoryProvider);
  return repository.getTimesForSession(sessionId);
});

// Provider for leaderboard of a session
final sessionLeaderboardProvider = FutureProvider.family<List<StopwatchTime>, String>((ref, sessionId) async {
  final repository = ref.watch(stopwatchRepositoryProvider);
  return repository.getLeaderboard(sessionId);
});

// ============ STATE NOTIFIERS ============

// StateNotifier for session management
class StopwatchSessionNotifier extends StateNotifier<AsyncValue<void>> {
  final StopwatchRepository _repository;
  final Ref _ref;

  StopwatchSessionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<StopwatchSession?> createSession({
    String? miniActivityId,
    String? teamId,
    required String name,
    StopwatchSessionType sessionType = StopwatchSessionType.stopwatch,
    int? countdownDurationMs,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createSession(
        miniActivityId: miniActivityId,
        teamId: teamId,
        name: name,
        sessionType: sessionType,
        countdownDurationMs: countdownDurationMs,
      );
      if (miniActivityId != null) {
        _ref.invalidate(miniActivitySessionsProvider(miniActivityId));
      }
      if (teamId != null) {
        _ref.invalidate(teamSessionsProvider(teamId));
      }
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<StopwatchSession?> updateSession({
    required String sessionId,
    String? miniActivityId,
    String? teamId,
    String? name,
    StopwatchSessionType? sessionType,
    int? countdownDurationMs,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateSession(
        sessionId: sessionId,
        name: name,
        sessionType: sessionType,
        countdownDurationMs: countdownDurationMs,
      );
      _ref.invalidate(stopwatchSessionProvider(sessionId));
      _ref.invalidate(stopwatchSessionWithTimesProvider(sessionId));
      if (miniActivityId != null) {
        _ref.invalidate(miniActivitySessionsProvider(miniActivityId));
      }
      if (teamId != null) {
        _ref.invalidate(teamSessionsProvider(teamId));
      }
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteSession({
    required String sessionId,
    String? miniActivityId,
    String? teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteSession(sessionId);
      _ref.invalidate(stopwatchSessionProvider(sessionId));
      _ref.invalidate(stopwatchSessionWithTimesProvider(sessionId));
      if (miniActivityId != null) {
        _ref.invalidate(miniActivitySessionsProvider(miniActivityId));
      }
      if (teamId != null) {
        _ref.invalidate(teamSessionsProvider(teamId));
      }
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final stopwatchSessionNotifierProvider = StateNotifierProvider<StopwatchSessionNotifier, AsyncValue<void>>((ref) {
  return StopwatchSessionNotifier(ref.watch(stopwatchRepositoryProvider), ref);
});

// StateNotifier for session control (start/pause/resume/complete)
class StopwatchControlNotifier extends StateNotifier<AsyncValue<StopwatchSession?>> {
  final StopwatchRepository _repository;
  final Ref _ref;

  StopwatchControlNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  void _invalidateSession(String sessionId) {
    _ref.invalidate(stopwatchSessionProvider(sessionId));
    _ref.invalidate(stopwatchSessionWithTimesProvider(sessionId));
  }

  Future<StopwatchSession?> startSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.startSession(sessionId);
      _invalidateSession(sessionId);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<StopwatchSession?> pauseSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.pauseSession(sessionId);
      _invalidateSession(sessionId);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<StopwatchSession?> resumeSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.resumeSession(sessionId);
      _invalidateSession(sessionId);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<StopwatchSession?> completeSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.completeSession(sessionId);
      _invalidateSession(sessionId);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<StopwatchSession?> resetSession(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.resetSession(sessionId);
      _invalidateSession(sessionId);
      _ref.invalidate(sessionTimesProvider(sessionId));
      _ref.invalidate(sessionLeaderboardProvider(sessionId));
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final stopwatchControlNotifierProvider = StateNotifierProvider<StopwatchControlNotifier, AsyncValue<StopwatchSession?>>((ref) {
  return StopwatchControlNotifier(ref.watch(stopwatchRepositoryProvider), ref);
});

// StateNotifier for time recording
class StopwatchTimeNotifier extends StateNotifier<AsyncValue<void>> {
  final StopwatchRepository _repository;
  final Ref _ref;

  StopwatchTimeNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<StopwatchTime?> recordTime({
    required String sessionId,
    required String userId,
    required int timeMs,
    bool isSplit = false,
    int? splitNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.recordTime(
        sessionId: sessionId,
        userId: userId,
        timeMs: timeMs,
        isSplit: isSplit,
        splitNumber: splitNumber,
      );
      _ref.invalidate(sessionTimesProvider(sessionId));
      _ref.invalidate(sessionLeaderboardProvider(sessionId));
      _ref.invalidate(stopwatchSessionWithTimesProvider(sessionId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<StopwatchTime?> updateTime({
    required String timeId,
    required String sessionId,
    int? timeMs,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateTime(
        timeId: timeId,
        timeMs: timeMs,
      );
      _ref.invalidate(sessionTimesProvider(sessionId));
      _ref.invalidate(sessionLeaderboardProvider(sessionId));
      _ref.invalidate(stopwatchSessionWithTimesProvider(sessionId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteTime({
    required String timeId,
    required String sessionId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTime(timeId);
      _ref.invalidate(sessionTimesProvider(sessionId));
      _ref.invalidate(sessionLeaderboardProvider(sessionId));
      _ref.invalidate(stopwatchSessionWithTimesProvider(sessionId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> clearTimes(String sessionId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.clearTimesForSession(sessionId);
      _ref.invalidate(sessionTimesProvider(sessionId));
      _ref.invalidate(sessionLeaderboardProvider(sessionId));
      _ref.invalidate(stopwatchSessionWithTimesProvider(sessionId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final stopwatchTimeNotifierProvider = StateNotifierProvider<StopwatchTimeNotifier, AsyncValue<void>>((ref) {
  return StopwatchTimeNotifier(ref.watch(stopwatchRepositoryProvider), ref);
});

// Live stopwatch state for UI (local state, not persisted)
class LiveStopwatchState {
  final int elapsedMs;
  final bool isRunning;
  final List<int> splitTimes;

  const LiveStopwatchState({
    this.elapsedMs = 0,
    this.isRunning = false,
    this.splitTimes = const [],
  });

  LiveStopwatchState copyWith({
    int? elapsedMs,
    bool? isRunning,
    List<int>? splitTimes,
  }) {
    return LiveStopwatchState(
      elapsedMs: elapsedMs ?? this.elapsedMs,
      isRunning: isRunning ?? this.isRunning,
      splitTimes: splitTimes ?? this.splitTimes,
    );
  }

  String get formattedTime {
    final minutes = elapsedMs ~/ 60000;
    final seconds = (elapsedMs % 60000) ~/ 1000;
    final millis = elapsedMs % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}';
  }
}

class LiveStopwatchNotifier extends StateNotifier<LiveStopwatchState> {
  LiveStopwatchNotifier() : super(const LiveStopwatchState());

  void setElapsed(int ms) {
    state = state.copyWith(elapsedMs: ms);
  }

  void setRunning(bool running) {
    state = state.copyWith(isRunning: running);
  }

  void addSplit(int ms) {
    state = state.copyWith(splitTimes: [...state.splitTimes, ms]);
  }

  void reset() {
    state = const LiveStopwatchState();
  }

  void start() {
    state = state.copyWith(isRunning: true);
  }

  void stop() {
    state = state.copyWith(isRunning: false);
  }
}

final liveStopwatchProvider = StateNotifierProvider.family<LiveStopwatchNotifier, LiveStopwatchState, String>((ref, sessionId) {
  return LiveStopwatchNotifier();
});
