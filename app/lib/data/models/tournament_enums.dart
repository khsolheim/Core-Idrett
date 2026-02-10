// Tournament enums for mini-activity tournament system

// Tournament type enum
enum TournamentType {
  singleElimination,
  doubleElimination,
  groupPlay,
  groupKnockout;

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
        return TournamentType.singleElimination;
    }
  }

  String toJson() {
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

  String get displayName {
    switch (this) {
      case TournamentType.singleElimination:
        return 'Enkel utslagning';
      case TournamentType.doubleElimination:
        return 'Dobbel utslagning';
      case TournamentType.groupPlay:
        return 'Gruppespill';
      case TournamentType.groupKnockout:
        return 'Gruppe + sluttspill';
    }
  }
}

// Tournament status enum
enum TournamentStatus {
  draft,
  registration,
  seeding,
  inProgress,
  completed,
  cancelled;

  static TournamentStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return TournamentStatus.draft;
      case 'registration':
        return TournamentStatus.registration;
      case 'seeding':
        return TournamentStatus.seeding;
      case 'in_progress':
        return TournamentStatus.inProgress;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      default:
        return TournamentStatus.draft;
    }
  }

  String toJson() {
    switch (this) {
      case TournamentStatus.draft:
        return 'draft';
      case TournamentStatus.registration:
        return 'registration';
      case TournamentStatus.seeding:
        return 'seeding';
      case TournamentStatus.inProgress:
        return 'in_progress';
      case TournamentStatus.completed:
        return 'completed';
      case TournamentStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case TournamentStatus.draft:
        return 'Utkast';
      case TournamentStatus.registration:
        return 'Påmelding';
      case TournamentStatus.seeding:
        return 'Trekning';
      case TournamentStatus.inProgress:
        return 'Pågår';
      case TournamentStatus.completed:
        return 'Fullført';
      case TournamentStatus.cancelled:
        return 'Avlyst';
    }
  }
}

// Seeding method enum
enum SeedingMethod {
  random,
  manual,
  ranked,
  snakeSeeding;

  static SeedingMethod fromString(String value) {
    switch (value) {
      case 'random':
        return SeedingMethod.random;
      case 'manual':
        return SeedingMethod.manual;
      case 'ranked':
        return SeedingMethod.ranked;
      case 'snake_seeding':
        return SeedingMethod.snakeSeeding;
      default:
        return SeedingMethod.random;
    }
  }

  String toJson() {
    switch (this) {
      case SeedingMethod.random:
        return 'random';
      case SeedingMethod.manual:
        return 'manual';
      case SeedingMethod.ranked:
        return 'ranked';
      case SeedingMethod.snakeSeeding:
        return 'snake_seeding';
    }
  }

  String get displayName {
    switch (this) {
      case SeedingMethod.random:
        return 'Tilfeldig';
      case SeedingMethod.manual:
        return 'Manuell';
      case SeedingMethod.ranked:
        return 'Rangert';
      case SeedingMethod.snakeSeeding:
        return 'Slangetrekning';
    }
  }
}

// Round type enum
enum RoundType {
  winners,
  losers,
  bronze,
  final_,
  group;

  static RoundType fromString(String value) {
    switch (value) {
      case 'winners':
        return RoundType.winners;
      case 'losers':
        return RoundType.losers;
      case 'bronze':
        return RoundType.bronze;
      case 'final':
        return RoundType.final_;
      case 'group':
        return RoundType.group;
      default:
        return RoundType.winners;
    }
  }

  String toJson() {
    switch (this) {
      case RoundType.winners:
        return 'winners';
      case RoundType.losers:
        return 'losers';
      case RoundType.bronze:
        return 'bronze';
      case RoundType.final_:
        return 'final';
      case RoundType.group:
        return 'group';
    }
  }

  String get displayName {
    switch (this) {
      case RoundType.winners:
        return 'Vinner-bracket';
      case RoundType.losers:
        return 'Taper-bracket';
      case RoundType.bronze:
        return 'Bronsefinale';
      case RoundType.final_:
        return 'Finale';
      case RoundType.group:
        return 'Gruppespill';
    }
  }
}

// Match status enum
enum MatchStatus {
  pending,
  scheduled,
  inProgress,
  completed,
  walkover,
  cancelled;

  static MatchStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return MatchStatus.pending;
      case 'scheduled':
        return MatchStatus.scheduled;
      case 'in_progress':
        return MatchStatus.inProgress;
      case 'completed':
        return MatchStatus.completed;
      case 'walkover':
        return MatchStatus.walkover;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.pending;
    }
  }

  String toJson() {
    switch (this) {
      case MatchStatus.pending:
        return 'pending';
      case MatchStatus.scheduled:
        return 'scheduled';
      case MatchStatus.inProgress:
        return 'in_progress';
      case MatchStatus.completed:
        return 'completed';
      case MatchStatus.walkover:
        return 'walkover';
      case MatchStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayName {
    switch (this) {
      case MatchStatus.pending:
        return 'Venter';
      case MatchStatus.scheduled:
        return 'Planlagt';
      case MatchStatus.inProgress:
        return 'Pågår';
      case MatchStatus.completed:
        return 'Fullført';
      case MatchStatus.walkover:
        return 'Walkover';
      case MatchStatus.cancelled:
        return 'Avlyst';
    }
  }

  bool get isPlayable =>
      this == MatchStatus.pending ||
      this == MatchStatus.scheduled ||
      this == MatchStatus.inProgress;
}
