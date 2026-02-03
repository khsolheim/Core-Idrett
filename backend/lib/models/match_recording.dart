// Match Recording Models
// Tasks: BM-036 to BM-039

// BM-038: Event type enum
enum EventType {
  goal,
  ownGoal,
  penaltyScored,
  penaltyMissed,
  yellowCard,
  redCard,
  substitution,
  injury,
  timeout,
  periodStart,
  periodEnd,
  custom;

  String get value {
    switch (this) {
      case EventType.goal:
        return 'goal';
      case EventType.ownGoal:
        return 'own_goal';
      case EventType.penaltyScored:
        return 'penalty_scored';
      case EventType.penaltyMissed:
        return 'penalty_missed';
      case EventType.yellowCard:
        return 'yellow_card';
      case EventType.redCard:
        return 'red_card';
      case EventType.substitution:
        return 'substitution';
      case EventType.injury:
        return 'injury';
      case EventType.timeout:
        return 'timeout';
      case EventType.periodStart:
        return 'period_start';
      case EventType.periodEnd:
        return 'period_end';
      case EventType.custom:
        return 'custom';
    }
  }

  static EventType fromString(String value) {
    switch (value) {
      case 'goal':
        return EventType.goal;
      case 'own_goal':
        return EventType.ownGoal;
      case 'penalty_scored':
        return EventType.penaltyScored;
      case 'penalty_missed':
        return EventType.penaltyMissed;
      case 'yellow_card':
        return EventType.yellowCard;
      case 'red_card':
        return EventType.redCard;
      case 'substitution':
        return EventType.substitution;
      case 'injury':
        return EventType.injury;
      case 'timeout':
        return EventType.timeout;
      case 'period_start':
        return EventType.periodStart;
      case 'period_end':
        return EventType.periodEnd;
      case 'custom':
        return EventType.custom;
      default:
        throw ArgumentError('Unknown event type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case EventType.goal:
        return 'Mål';
      case EventType.ownGoal:
        return 'Selvmål';
      case EventType.penaltyScored:
        return 'Straffe (mål)';
      case EventType.penaltyMissed:
        return 'Straffe (bom)';
      case EventType.yellowCard:
        return 'Gult kort';
      case EventType.redCard:
        return 'Rødt kort';
      case EventType.substitution:
        return 'Bytte';
      case EventType.injury:
        return 'Skade';
      case EventType.timeout:
        return 'Timeout';
      case EventType.periodStart:
        return 'Periode start';
      case EventType.periodEnd:
        return 'Periode slutt';
      case EventType.custom:
        return 'Annet';
    }
  }

  bool get isScoring => this == goal || this == ownGoal || this == penaltyScored;
}

// BM-036: Match period model
class MatchPeriod {
  final String id;
  final String? tournamentMatchId;
  final String? groupMatchId;
  final String? miniActivityId;
  final int periodNumber;
  final String? periodName;
  final int teamAScore;
  final int teamBScore;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  MatchPeriod({
    required this.id,
    this.tournamentMatchId,
    this.groupMatchId,
    this.miniActivityId,
    this.periodNumber = 1,
    this.periodName,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  factory MatchPeriod.fromRow(Map<String, dynamic> row) {
    return MatchPeriod(
      id: row['id'] as String,
      tournamentMatchId: row['tournament_match_id'] as String?,
      groupMatchId: row['group_match_id'] as String?,
      miniActivityId: row['mini_activity_id'] as String?,
      periodNumber: row['period_number'] as int? ?? 1,
      periodName: row['period_name'] as String?,
      teamAScore: row['team_a_score'] as int? ?? 0,
      teamBScore: row['team_b_score'] as int? ?? 0,
      startedAt: row['started_at'] as DateTime?,
      endedAt: row['ended_at'] as DateTime?,
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_match_id': tournamentMatchId,
      'group_match_id': groupMatchId,
      'mini_activity_id': miniActivityId,
      'period_number': periodNumber,
      'period_name': periodName,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isActive => startedAt != null && endedAt == null;
  bool get isCompleted => endedAt != null;

  String get displayName => periodName ?? '${periodNumber}. omgang';
}

// BM-037: Match event model
class MatchEvent {
  final String id;
  final String matchPeriodId;
  final EventType eventType;
  final String? teamId;
  final String? userId;
  final int? minute;
  final int? second;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  MatchEvent({
    required this.id,
    required this.matchPeriodId,
    required this.eventType,
    this.teamId,
    this.userId,
    this.minute,
    this.second,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  factory MatchEvent.fromRow(Map<String, dynamic> row) {
    return MatchEvent(
      id: row['id'] as String,
      matchPeriodId: row['match_period_id'] as String,
      eventType: EventType.fromString(row['event_type'] as String),
      teamId: row['team_id'] as String?,
      userId: row['user_id'] as String?,
      minute: row['minute'] as int?,
      second: row['second'] as int?,
      description: row['description'] as String?,
      metadata: row['metadata'] as Map<String, dynamic>?,
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_period_id': matchPeriodId,
      'event_type': eventType.value,
      'team_id': teamId,
      'user_id': userId,
      'minute': minute,
      'second': second,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get timeDisplay {
    if (minute == null) return '';
    if (second != null) {
      return "$minute'${second.toString().padLeft(2, '0')}\"";
    }
    return "$minute'";
  }
}

// Helper class for recording a complete match with events
class MatchRecording {
  final List<MatchPeriod> periods;
  final List<MatchEvent> events;

  MatchRecording({
    required this.periods,
    required this.events,
  });

  int get totalTeamAScore => periods.fold(0, (sum, p) => sum + p.teamAScore);
  int get totalTeamBScore => periods.fold(0, (sum, p) => sum + p.teamBScore);

  List<MatchEvent> get goals => events.where((e) => e.eventType.isScoring).toList();
  List<MatchEvent> get cards => events.where((e) =>
    e.eventType == EventType.yellowCard || e.eventType == EventType.redCard
  ).toList();

  Map<String, dynamic> toJson() {
    return {
      'periods': periods.map((p) => p.toJson()).toList(),
      'events': events.map((e) => e.toJson()).toList(),
      'total_team_a_score': totalTeamAScore,
      'total_team_b_score': totalTeamBScore,
    };
  }
}
