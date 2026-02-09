// Stopwatch and Timer Models
// Tasks: BM-040 to BM-045

import 'package:equatable/equatable.dart';

import '../helpers/parsing_helpers.dart';

// BM-041: Session type enum
enum StopwatchSessionType {
  stopwatch,
  countdown;

  String get value => name;

  static StopwatchSessionType fromString(String value) {
    switch (value) {
      case 'stopwatch':
        return StopwatchSessionType.stopwatch;
      case 'countdown':
        return StopwatchSessionType.countdown;
      default:
        throw ArgumentError('Unknown session type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case StopwatchSessionType.stopwatch:
        return 'Stoppeklokke';
      case StopwatchSessionType.countdown:
        return 'Nedtelling';
    }
  }
}

// BM-042: Session status enum
enum StopwatchSessionStatus {
  pending,
  running,
  paused,
  completed,
  cancelled;

  String get value => name;

  static StopwatchSessionStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return StopwatchSessionStatus.pending;
      case 'running':
        return StopwatchSessionStatus.running;
      case 'paused':
        return StopwatchSessionStatus.paused;
      case 'completed':
        return StopwatchSessionStatus.completed;
      case 'cancelled':
        return StopwatchSessionStatus.cancelled;
      default:
        throw ArgumentError('Unknown session status: $value');
    }
  }
}

// BM-040: Stopwatch session model
class StopwatchSession extends Equatable {
  final String id;
  final String? miniActivityId;
  final String? teamId;
  final String? name;
  final StopwatchSessionType sessionType;
  final int? countdownDurationMs;
  final StopwatchSessionStatus status;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? completedAt;
  final int elapsedMsAtPause;
  final DateTime createdAt;
  final String createdBy;

  const StopwatchSession({
    required this.id,
    this.miniActivityId,
    this.teamId,
    this.name,
    required this.sessionType,
    this.countdownDurationMs,
    this.status = StopwatchSessionStatus.pending,
    this.startedAt,
    this.pausedAt,
    this.completedAt,
    this.elapsedMsAtPause = 0,
    required this.createdAt,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [
        id,
        miniActivityId,
        teamId,
        name,
        sessionType,
        countdownDurationMs,
        status,
        startedAt,
        pausedAt,
        completedAt,
        elapsedMsAtPause,
        createdAt,
        createdBy,
      ];

  factory StopwatchSession.fromJson(Map<String, dynamic> row) {
    return StopwatchSession(
      id: safeString(row, 'id'),
      miniActivityId: safeStringNullable(row, 'mini_activity_id'),
      teamId: safeStringNullable(row, 'team_id'),
      name: safeStringNullable(row, 'name'),
      sessionType: StopwatchSessionType.fromString(safeString(row, 'session_type')),
      countdownDurationMs: safeIntNullable(row, 'countdown_duration_ms'),
      status: StopwatchSessionStatus.fromString(safeString(row, 'status', defaultValue: 'pending')),
      startedAt: safeDateTimeNullable(row, 'started_at'),
      pausedAt: safeDateTimeNullable(row, 'paused_at'),
      completedAt: safeDateTimeNullable(row, 'completed_at'),
      elapsedMsAtPause: safeInt(row, 'elapsed_ms_at_pause', defaultValue: 0),
      createdAt: requireDateTime(row, 'created_at'),
      createdBy: safeString(row, 'created_by'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'team_id': teamId,
      'name': name,
      'session_type': sessionType.value,
      'countdown_duration_ms': countdownDurationMs,
      'status': status.value,
      'started_at': startedAt?.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'elapsed_ms_at_pause': elapsedMsAtPause,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  bool get isRunning => status == StopwatchSessionStatus.running;
  bool get isPaused => status == StopwatchSessionStatus.paused;
  bool get isCompleted => status == StopwatchSessionStatus.completed;
  bool get canStart => status == StopwatchSessionStatus.pending;
  bool get canResume => status == StopwatchSessionStatus.paused;

  /// Calculate current elapsed time in milliseconds
  int getCurrentElapsedMs() {
    if (status == StopwatchSessionStatus.pending) return 0;
    if (status == StopwatchSessionStatus.paused) return elapsedMsAtPause;
    if (status == StopwatchSessionStatus.completed) {
      if (completedAt != null && startedAt != null) {
        return completedAt!.difference(startedAt!).inMilliseconds + elapsedMsAtPause;
      }
      return elapsedMsAtPause;
    }
    // Running
    if (startedAt != null) {
      return DateTime.now().difference(startedAt!).inMilliseconds + elapsedMsAtPause;
    }
    return 0;
  }

  /// For countdown: get remaining time
  int? getRemainingMs() {
    if (sessionType != StopwatchSessionType.countdown || countdownDurationMs == null) {
      return null;
    }
    final elapsed = getCurrentElapsedMs();
    final remaining = countdownDurationMs! - elapsed;
    return remaining < 0 ? 0 : remaining;
  }
}

// BM-043: Stopwatch time model
class StopwatchTime extends Equatable {
  final String id;
  final String sessionId;
  final String userId;
  final int timeMs;
  final bool isSplit;
  final int? splitNumber;
  final int? lapNumber;
  final String? notes;
  final DateTime recordedAt;

  const StopwatchTime({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.timeMs,
    this.isSplit = false,
    this.splitNumber,
    this.lapNumber,
    this.notes,
    required this.recordedAt,
  });

  @override
  List<Object?> get props => [
        id,
        sessionId,
        userId,
        timeMs,
        isSplit,
        splitNumber,
        lapNumber,
        notes,
        recordedAt,
      ];

  factory StopwatchTime.fromJson(Map<String, dynamic> row) {
    return StopwatchTime(
      id: safeString(row, 'id'),
      sessionId: safeString(row, 'session_id'),
      userId: safeString(row, 'user_id'),
      timeMs: safeInt(row, 'time_ms'),
      isSplit: safeBool(row, 'is_split', defaultValue: false),
      splitNumber: safeIntNullable(row, 'split_number'),
      lapNumber: safeIntNullable(row, 'lap_number'),
      notes: safeStringNullable(row, 'notes'),
      recordedAt: requireDateTime(row, 'recorded_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'time_ms': timeMs,
      'formatted_time': formattedTime,
      'is_split': isSplit,
      'split_number': splitNumber,
      'lap_number': lapNumber,
      'notes': notes,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  // BM-044: Formatted time getter
  String get formattedTime {
    final hours = timeMs ~/ 3600000;
    final minutes = (timeMs % 3600000) ~/ 60000;
    final seconds = (timeMs % 60000) ~/ 1000;
    final milliseconds = timeMs % 1000;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
             '${minutes.toString().padLeft(2, '0')}:'
             '${seconds.toString().padLeft(2, '0')}.'
             '${milliseconds.toString().padLeft(3, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
           '${seconds.toString().padLeft(2, '0')}.'
           '${milliseconds.toString().padLeft(3, '0')}';
  }

  /// Format as MM:SS (no milliseconds)
  String get formattedTimeShort {
    final minutes = timeMs ~/ 60000;
    final seconds = (timeMs % 60000) ~/ 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get time in seconds with decimal
  double get timeInSeconds => timeMs / 1000.0;
}

// Helper class for session with times
class StopwatchSessionWithTimes extends Equatable {
  final StopwatchSession session;
  final List<StopwatchTime> times;

  const StopwatchSessionWithTimes({
    required this.session,
    required this.times,
  });

  @override
  List<Object?> get props => [session, times];

  List<StopwatchTime> get sortedByTime => List.from(times)..sort((a, b) => a.timeMs.compareTo(b.timeMs));
  List<StopwatchTime> get sortedByRecordedAt => List.from(times)..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  StopwatchTime? get fastestTime => times.isEmpty ? null : sortedByTime.first;
  StopwatchTime? get slowestTime => times.isEmpty ? null : sortedByTime.last;

  int? get averageTimeMs {
    if (times.isEmpty) return null;
    return times.map((t) => t.timeMs).reduce((a, b) => a + b) ~/ times.length;
  }

  Map<String, dynamic> toJson() {
    return {
      'session': session.toJson(),
      'times': times.map((t) => t.toJson()).toList(),
      'fastest_time': fastestTime?.toJson(),
      'slowest_time': slowestTime?.toJson(),
      'average_time_ms': averageTimeMs,
    };
  }
}
