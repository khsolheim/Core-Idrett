// Tournament Models
// Tasks: BM-024 to BM-035

// BM-025: Tournament type enum
enum TournamentType {
  singleElimination,
  doubleElimination,
  groupPlay,
  groupKnockout;

  String get value {
    switch (this) {
      case TournamentType.singleElimination:
        return 'single_elimination';
      case TournamentType.doubleElimination:
        return 'double_elimination';
      case TournamentType.groupPlay:
        return 'group_play';
      case TournamentType.groupKnockout:
        return 'group_knockout';
    }
  }

  static TournamentType fromString(String value) {
    switch (value) {
      case 'single_elimination':
        return TournamentType.singleElimination;
      case 'double_elimination':
        return TournamentType.doubleElimination;
      case 'group_play':
        return TournamentType.groupPlay;
      case 'group_knockout':
        return TournamentType.groupKnockout;
      default:
        throw ArgumentError('Unknown tournament type: $value');
    }
  }

  String get displayName {
    switch (this) {
      case TournamentType.singleElimination:
        return 'Utslagsturnering';
      case TournamentType.doubleElimination:
        return 'Dobbel utslagsturnering';
      case TournamentType.groupPlay:
        return 'Gruppespill';
      case TournamentType.groupKnockout:
        return 'Gruppespill + Sluttspill';
    }
  }
}

enum TournamentStatus {
  setup,
  inProgress,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case TournamentStatus.setup:
        return 'setup';
      case TournamentStatus.inProgress:
        return 'in_progress';
      case TournamentStatus.completed:
        return 'completed';
      case TournamentStatus.cancelled:
        return 'cancelled';
    }
  }

  static TournamentStatus fromString(String value) {
    switch (value) {
      case 'setup':
        return TournamentStatus.setup;
      case 'in_progress':
        return TournamentStatus.inProgress;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      default:
        throw ArgumentError('Unknown tournament status: $value');
    }
  }
}

enum SeedingMethod {
  random,
  ranked,
  manual;

  String get value => name;

  static SeedingMethod fromString(String value) {
    switch (value) {
      case 'random':
        return SeedingMethod.random;
      case 'ranked':
        return SeedingMethod.ranked;
      case 'manual':
        return SeedingMethod.manual;
      default:
        throw ArgumentError('Unknown seeding method: $value');
    }
  }
}

// BM-024: Tournament model
class Tournament {
  final String id;
  final String miniActivityId;
  final TournamentType tournamentType;
  final int bestOf;
  final bool bronzeFinal;
  final SeedingMethod seedingMethod;
  final int? maxParticipants;
  final TournamentStatus status;
  final DateTime createdAt;

  Tournament({
    required this.id,
    required this.miniActivityId,
    required this.tournamentType,
    this.bestOf = 1,
    this.bronzeFinal = false,
    this.seedingMethod = SeedingMethod.random,
    this.maxParticipants,
    this.status = TournamentStatus.setup,
    required this.createdAt,
  });

  factory Tournament.fromJson(Map<String, dynamic> row) {
    return Tournament(
      id: row['id'] as String,
      miniActivityId: row['mini_activity_id'] as String,
      tournamentType: TournamentType.fromString(row['tournament_type'] as String),
      bestOf: row['best_of'] as int? ?? 1,
      bronzeFinal: row['bronze_final'] as bool? ?? false,
      seedingMethod: SeedingMethod.fromString(row['seeding_method'] as String? ?? 'random'),
      maxParticipants: row['max_participants'] as int?,
      status: TournamentStatus.fromString(row['status'] as String? ?? 'setup'),
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'tournament_type': tournamentType.value,
      'best_of': bestOf,
      'bronze_final': bronzeFinal,
      'seeding_method': seedingMethod.value,
      'max_participants': maxParticipants,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
