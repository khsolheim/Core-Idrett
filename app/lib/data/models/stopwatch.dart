import 'package:equatable/equatable.dart';

// Stopwatch models for timing mini-activities
// Supports both stopwatch (count up) and countdown modes

// Session type enum
enum StopwatchSessionType {
  stopwatch,
  countdown;

  static StopwatchSessionType fromString(String value) {
    switch (value) {
      case 'stopwatch':
        return StopwatchSessionType.stopwatch;
      case 'countdown':
        return StopwatchSessionType.countdown;
      default:
        return StopwatchSessionType.stopwatch;
    }
  }

  String toJson() {
    switch (this) {
      case StopwatchSessionType.stopwatch:
        return 'stopwatch';
      case StopwatchSessionType.countdown:
        return 'countdown';
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

  String get icon {
    switch (this) {
      case StopwatchSessionType.stopwatch:
        return '⏱️';
      case StopwatchSessionType.countdown:
        return '⏳';
    }
  }
}

// Session status enum
enum StopwatchSessionStatus {
  pending,
  running,
  paused,
  completed;

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
      default:
        return StopwatchSessionStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case StopwatchSessionStatus.pending:
        return 'pending';
      case StopwatchSessionStatus.running:
        return 'running';
      case StopwatchSessionStatus.paused:
        return 'paused';
      case StopwatchSessionStatus.completed:
        return 'completed';
    }
  }

  String get displayName {
    switch (this) {
      case StopwatchSessionStatus.pending:
        return 'Klar';
      case StopwatchSessionStatus.running:
        return 'Kjører';
      case StopwatchSessionStatus.paused:
        return 'Pauset';
      case StopwatchSessionStatus.completed:
        return 'Fullført';
    }
  }

  bool get isActive => this == StopwatchSessionStatus.running;
  bool get canStart => this == StopwatchSessionStatus.pending || this == StopwatchSessionStatus.paused;
  bool get canPause => this == StopwatchSessionStatus.running;
  bool get canResume => this == StopwatchSessionStatus.paused;
  bool get canComplete => this == StopwatchSessionStatus.running || this == StopwatchSessionStatus.paused;
}

/// Main stopwatch session class
class StopwatchSession extends Equatable {
  final String id;
  final String? miniActivityId;
  final String? teamId;
  final String name;
  final StopwatchSessionType sessionType;
  final int? countdownDurationMs;
  final StopwatchSessionStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final String createdBy;

  // Nested data
  final List<StopwatchTime>? times;
  final String? creatorName;
  const StopwatchSession({
    required this.id,
    this.miniActivityId,
    this.teamId,
    required this.name,
    this.sessionType = StopwatchSessionType.stopwatch,
    this.countdownDurationMs,
    this.status = StopwatchSessionStatus.pending,
    this.startedAt,
    this.completedAt,
    required this.createdAt,
    required this.createdBy,
    this.times,
    this.creatorName,
  });

  factory StopwatchSession.fromJson(Map<String, dynamic> json) {
    return
  StopwatchSession(
      id: json['id'] as String,
      miniActivityId: json['mini_activity_id'] as String?,
      teamId: json['team_id'] as String?,
      name: json['name'] as String,
      sessionType: StopwatchSessionType.fromString(json['session_type'] as String? ?? 'stopwatch'),
      countdownDurationMs: json['countdown_duration_ms'] as int?,
      status: StopwatchSessionStatus.fromString(json['status'] as String? ?? 'pending'),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
      times: json['times'] != null
          ? (json['times'] as List).map((t) => StopwatchTime.fromJson(t as Map<String, dynamic>)).toList()
          : null,
      creatorName: json['creator_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'team_id': teamId,
      'name': name,
      'session_type': sessionType.toJson(),
      'countdown_duration_ms': countdownDurationMs,
      'status': status.toJson(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      if (times != null) 'times': times!.map((t) => t.toJson()).toList(),
      'creator_name': creatorName,
    };
  }

  StopwatchSession copyWith({
    String? id,
    String? miniActivityId,
    String? teamId,
    String? name,
    StopwatchSessionType? sessionType,
    int? countdownDurationMs,
    StopwatchSessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    String? createdBy,
    List<StopwatchTime>? times,
    String? creatorName,
  }) {
    return
  StopwatchSession(
      id: id ?? this.id,
      miniActivityId: miniActivityId ?? this.miniActivityId,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      sessionType: sessionType ?? this.sessionType,
      countdownDurationMs: countdownDurationMs ?? this.countdownDurationMs,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      times: times ?? this.times,
      creatorName: creatorName ?? this.creatorName,
    );
  }

  bool get isCountdown => sessionType == StopwatchSessionType.countdown;
  bool get isRunning => status == StopwatchSessionStatus.running;
  bool get isComplete => status == StopwatchSessionStatus.completed;
  bool get isPaused => status == StopwatchSessionStatus.paused;
  bool get isPending => status == StopwatchSessionStatus.pending;

  /// Get elapsed time in milliseconds since start
  int get elapsedMs {
    if (startedAt == null) return 0;
    final endTime = completedAt ?? DateTime.now();
    return endTime.difference(startedAt!).inMilliseconds;
  }

  /// Get formatted countdown duration
  String get formattedCountdownDuration {
    if (countdownDurationMs == null) return '--:--';
    return _formatTime(countdownDurationMs!);
  }

  /// Get formatted elapsed time
  String get formattedElapsed => _formatTime(elapsedMs);

  /// Get sorted times by fastest first
  List<StopwatchTime> get sortedTimes {
    if (times == null) return [];
    final sorted = List<StopwatchTime>.from(times!);
    sorted.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    return sorted;
  }

  /// Get times sorted by split number
  List<StopwatchTime> get timesBySplit {
    if (times == null) return [];
    final sorted = List<StopwatchTime>.from(times!);
    sorted.sort((a, b) => (a.splitNumber ?? 0).compareTo(b.splitNumber ?? 0));
    return sorted;
  }

  /// Number of recorded times
  int get recordedCount => times?.length ?? 0;

  static String _formatTime(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = ms % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}';
  }


  @override
  List<Object?> get props => [id, miniActivityId, teamId, name, sessionType, countdownDurationMs, status, startedAt, completedAt, createdAt, createdBy, times, creatorName];
}

/// Individual recorded time for a user
class StopwatchTime extends Equatable {
  final String id;
  final String sessionId;
  final String userId;
  final int timeMs;
  final bool isSplit;
  final int? splitNumber;
  final DateTime recordedAt;

  // Joined data
  final String? userName;
  final String? userProfileImageUrl;
  const StopwatchTime({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.timeMs,
    this.isSplit = false,
    this.splitNumber,
    required this.recordedAt,
    this.userName,
    this.userProfileImageUrl,
  });

  factory StopwatchTime.fromJson(Map<String, dynamic> json) {
    return
  StopwatchTime(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      userId: json['user_id'] as String,
      timeMs: json['time_ms'] as int,
      isSplit: json['is_split'] as bool? ?? false,
      splitNumber: json['split_number'] as int?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      userName: json['user_name'] as String?,
      userProfileImageUrl: json['user_profile_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'user_id': userId,
      'time_ms': timeMs,
      'is_split': isSplit,
      'split_number': splitNumber,
      'recorded_at': recordedAt.toIso8601String(),
      'user_name': userName,
      'user_profile_image_url': userProfileImageUrl,
    };
  }

  StopwatchTime copyWith({
    String? id,
    String? sessionId,
    String? userId,
    int? timeMs,
    bool? isSplit,
    int? splitNumber,
    DateTime? recordedAt,
    String? userName,
    String? userProfileImageUrl,
  }) {
    return
  StopwatchTime(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      timeMs: timeMs ?? this.timeMs,
      isSplit: isSplit ?? this.isSplit,
      splitNumber: splitNumber ?? this.splitNumber,
      recordedAt: recordedAt ?? this.recordedAt,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
    );
  }

  /// Formatted time string (MM:SS.ms)
  String get formattedTime {
    final minutes = timeMs ~/ 60000;
    final seconds = (timeMs % 60000) ~/ 1000;
    final millis = timeMs % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}';
  }

  /// Formatted time with hours if needed (HH:MM:SS.ms)
  String get formattedTimeLong {
    final hours = timeMs ~/ 3600000;
    final minutes = (timeMs % 3600000) ~/ 60000;
    final seconds = (timeMs % 60000) ~/ 1000;
    final millis = timeMs % 1000;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}';
    }
    return formattedTime;
  }

  /// Get split label (e.g., "Split 1", "Split 2")
  String get splitLabel => isSplit ? 'Split ${splitNumber ?? 1}' : 'Slutt';


  @override
  List<Object?> get props => [id, sessionId, userId, timeMs, isSplit, splitNumber, recordedAt, userName, userProfileImageUrl];
}

/// Aggregated session with times (for display)
class StopwatchSessionWithTimes extends Equatable {
  final StopwatchSession session;
  final List<StopwatchTime> times;
  final StopwatchTime? fastestTime;
  final StopwatchTime? slowestTime;
  final double? averageTimeMs;
  const StopwatchSessionWithTimes({
    required this.session,
    required this.times,
    this.fastestTime,
    this.slowestTime,
    this.averageTimeMs,
  });

  factory StopwatchSessionWithTimes.fromJson(Map<String, dynamic> json) {
    final times = (json['times'] as List?)
        ?.map((t) => StopwatchTime.fromJson(t as Map<String, dynamic>))
        .toList() ?? [];

    StopwatchTime? fastest;
    StopwatchTime? slowest;
    double? average;

    if (times.isNotEmpty) {
      final sorted = List<StopwatchTime>.from(times)
        ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
      fastest = sorted.first;
      slowest = sorted.last;
      average = times.map((t) => t.timeMs).reduce((a, b) => a + b) / times.length;
    }

    return
  StopwatchSessionWithTimes(
      session: StopwatchSession.fromJson(json['session'] as Map<String, dynamic>? ?? json),
      times: times,
      fastestTime: fastest,
      slowestTime: slowest,
      averageTimeMs: average,
    );
  }

  factory StopwatchSessionWithTimes.fromSession(StopwatchSession session) {
    final times = session.times ?? [];

    StopwatchTime? fastest;
    StopwatchTime? slowest;
    double? average;

    if (times.isNotEmpty) {
      final sorted = List<StopwatchTime>.from(times)
        ..sort((a, b) => a.timeMs.compareTo(b.timeMs));
      fastest = sorted.first;
      slowest = sorted.last;
      average = times.map((t) => t.timeMs).reduce((a, b) => a + b) / times.length;
    }

    return
  StopwatchSessionWithTimes(
      session: session,
      times: times,
      fastestTime: fastest,
      slowestTime: slowest,
      averageTimeMs: average,
    );
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

  /// Get formatted average time
  String get formattedAverage {
    if (averageTimeMs == null) return '--:--';
    final ms = averageTimeMs!.round();
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = ms % 1000;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}';
  }

  /// Number of participants who recorded times
  int get participantCount => times.map((t) => t.userId).toSet().length;

  /// Get leaderboard (unique users, sorted by best time)
  List<StopwatchTime> get leaderboard {
    final Map<String, StopwatchTime> bestTimes = {};
    for (final time in times) {
      if (!bestTimes.containsKey(time.userId) || time.timeMs < bestTimes[time.userId]!.timeMs) {
        bestTimes[time.userId] = time;
      }
    }
    return bestTimes.values.toList()..sort((a, b) => a.timeMs.compareTo(b.timeMs));
  }


  @override
  List<Object?> get props => [session, times, fastestTime, slowestTime, averageTimeMs];
}
