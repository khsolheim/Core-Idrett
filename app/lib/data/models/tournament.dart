// Tournament models for mini-activity tournament system
// Supports single/double elimination, group play, and qualification rounds

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
        return 'Seeding';
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

/// Main Tournament class
class Tournament {
  final String id;
  final String miniActivityId;
  final TournamentType tournamentType;
  final TournamentStatus status;
  final int bestOf;
  final bool bronzeFinal;
  final SeedingMethod seedingMethod;
  final int? maxParticipants;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Nested data (loaded separately)
  final List<TournamentRound>? rounds;
  final List<TournamentGroup>? groups;

  Tournament({
    required this.id,
    required this.miniActivityId,
    required this.tournamentType,
    this.status = TournamentStatus.draft,
    this.bestOf = 1,
    this.bronzeFinal = false,
    this.seedingMethod = SeedingMethod.random,
    this.maxParticipants,
    required this.createdAt,
    this.updatedAt,
    this.rounds,
    this.groups,
  });

  factory Tournament.fromJson(Map<String, dynamic> json) {
    return Tournament(
      id: json['id'] as String,
      miniActivityId: json['mini_activity_id'] as String,
      tournamentType: TournamentType.fromString(json['tournament_type'] as String? ?? 'single_elimination'),
      status: TournamentStatus.fromString(json['status'] as String? ?? 'draft'),
      bestOf: json['best_of'] as int? ?? 1,
      bronzeFinal: json['bronze_final'] as bool? ?? false,
      seedingMethod: SeedingMethod.fromString(json['seeding_method'] as String? ?? 'random'),
      maxParticipants: json['max_participants'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      rounds: json['rounds'] != null
          ? (json['rounds'] as List).map((r) => TournamentRound.fromJson(r as Map<String, dynamic>)).toList()
          : null,
      groups: json['groups'] != null
          ? (json['groups'] as List).map((g) => TournamentGroup.fromJson(g as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'tournament_type': tournamentType.toJson(),
      'status': status.toJson(),
      'best_of': bestOf,
      'bronze_final': bronzeFinal,
      'seeding_method': seedingMethod.toJson(),
      'max_participants': maxParticipants,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      if (rounds != null) 'rounds': rounds!.map((r) => r.toJson()).toList(),
      if (groups != null) 'groups': groups!.map((g) => g.toJson()).toList(),
    };
  }

  Tournament copyWith({
    String? id,
    String? miniActivityId,
    TournamentType? tournamentType,
    TournamentStatus? status,
    int? bestOf,
    bool? bronzeFinal,
    SeedingMethod? seedingMethod,
    int? maxParticipants,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TournamentRound>? rounds,
    List<TournamentGroup>? groups,
  }) {
    return Tournament(
      id: id ?? this.id,
      miniActivityId: miniActivityId ?? this.miniActivityId,
      tournamentType: tournamentType ?? this.tournamentType,
      status: status ?? this.status,
      bestOf: bestOf ?? this.bestOf,
      bronzeFinal: bronzeFinal ?? this.bronzeFinal,
      seedingMethod: seedingMethod ?? this.seedingMethod,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rounds: rounds ?? this.rounds,
      groups: groups ?? this.groups,
    );
  }

  bool get isElimination =>
      tournamentType == TournamentType.singleElimination ||
      tournamentType == TournamentType.doubleElimination;

  bool get hasGroups =>
      tournamentType == TournamentType.groupPlay ||
      tournamentType == TournamentType.groupKnockout;
}

/// Tournament round within a bracket
class TournamentRound {
  final String id;
  final String tournamentId;
  final int roundNumber;
  final String roundName;
  final RoundType roundType;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final DateTime createdAt;

  // Nested data
  final List<TournamentMatch>? matches;

  TournamentRound({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    required this.roundName,
    this.roundType = RoundType.winners,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    required this.createdAt,
    this.matches,
  });

  factory TournamentRound.fromJson(Map<String, dynamic> json) {
    return TournamentRound(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      roundNumber: json['round_number'] as int,
      roundName: json['round_name'] as String,
      roundType: RoundType.fromString(json['round_type'] as String? ?? 'winners'),
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      scheduledTime: json['scheduled_time'] != null ? DateTime.parse(json['scheduled_time'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      matches: json['matches'] != null
          ? (json['matches'] as List).map((m) => TournamentMatch.fromJson(m as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'round_number': roundNumber,
      'round_name': roundName,
      'round_type': roundType.toJson(),
      'status': status.toJson(),
      'scheduled_time': scheduledTime?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (matches != null) 'matches': matches!.map((m) => m.toJson()).toList(),
    };
  }

  TournamentRound copyWith({
    String? id,
    String? tournamentId,
    int? roundNumber,
    String? roundName,
    RoundType? roundType,
    MatchStatus? status,
    DateTime? scheduledTime,
    DateTime? createdAt,
    List<TournamentMatch>? matches,
  }) {
    return TournamentRound(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      roundNumber: roundNumber ?? this.roundNumber,
      roundName: roundName ?? this.roundName,
      roundType: roundType ?? this.roundType,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
      matches: matches ?? this.matches,
    );
  }
}

/// A single match in a tournament
class TournamentMatch {
  final String id;
  final String tournamentId;
  final String? roundId;
  final int bracketPosition;
  final String? teamAId;
  final String? teamBId;
  final String? winnerId;
  final int teamAScore;
  final int teamBScore;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final int matchOrder;
  final String? winnerGoesToMatchId;
  final String? loserGoesToMatchId;
  final bool isWalkover;
  final String? walkoverReason;
  final DateTime createdAt;

  // Nested data
  final List<MatchGame>? games;
  final String? teamAName;
  final String? teamBName;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    this.roundId,
    this.bracketPosition = 0,
    this.teamAId,
    this.teamBId,
    this.winnerId,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    this.matchOrder = 0,
    this.winnerGoesToMatchId,
    this.loserGoesToMatchId,
    this.isWalkover = false,
    this.walkoverReason,
    required this.createdAt,
    this.games,
    this.teamAName,
    this.teamBName,
  });

  factory TournamentMatch.fromJson(Map<String, dynamic> json) {
    return TournamentMatch(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      roundId: json['round_id'] as String?,
      bracketPosition: json['bracket_position'] as int? ?? 0,
      teamAId: json['team_a_id'] as String?,
      teamBId: json['team_b_id'] as String?,
      winnerId: json['winner_id'] as String?,
      teamAScore: json['team_a_score'] as int? ?? 0,
      teamBScore: json['team_b_score'] as int? ?? 0,
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      scheduledTime: json['scheduled_time'] != null ? DateTime.parse(json['scheduled_time'] as String) : null,
      matchOrder: json['match_order'] as int? ?? 0,
      winnerGoesToMatchId: json['winner_goes_to_match_id'] as String?,
      loserGoesToMatchId: json['loser_goes_to_match_id'] as String?,
      isWalkover: json['is_walkover'] as bool? ?? false,
      walkoverReason: json['walkover_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      games: json['games'] != null
          ? (json['games'] as List).map((g) => MatchGame.fromJson(g as Map<String, dynamic>)).toList()
          : null,
      teamAName: json['team_a_name'] as String?,
      teamBName: json['team_b_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'round_id': roundId,
      'bracket_position': bracketPosition,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'winner_id': winnerId,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'status': status.toJson(),
      'scheduled_time': scheduledTime?.toIso8601String(),
      'match_order': matchOrder,
      'winner_goes_to_match_id': winnerGoesToMatchId,
      'loser_goes_to_match_id': loserGoesToMatchId,
      'is_walkover': isWalkover,
      'walkover_reason': walkoverReason,
      'created_at': createdAt.toIso8601String(),
      if (games != null) 'games': games!.map((g) => g.toJson()).toList(),
      'team_a_name': teamAName,
      'team_b_name': teamBName,
    };
  }

  TournamentMatch copyWith({
    String? id,
    String? tournamentId,
    String? roundId,
    int? bracketPosition,
    String? teamAId,
    String? teamBId,
    String? winnerId,
    int? teamAScore,
    int? teamBScore,
    MatchStatus? status,
    DateTime? scheduledTime,
    int? matchOrder,
    String? winnerGoesToMatchId,
    String? loserGoesToMatchId,
    bool? isWalkover,
    String? walkoverReason,
    DateTime? createdAt,
    List<MatchGame>? games,
    String? teamAName,
    String? teamBName,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      roundId: roundId ?? this.roundId,
      bracketPosition: bracketPosition ?? this.bracketPosition,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      winnerId: winnerId ?? this.winnerId,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      matchOrder: matchOrder ?? this.matchOrder,
      winnerGoesToMatchId: winnerGoesToMatchId ?? this.winnerGoesToMatchId,
      loserGoesToMatchId: loserGoesToMatchId ?? this.loserGoesToMatchId,
      isWalkover: isWalkover ?? this.isWalkover,
      walkoverReason: walkoverReason ?? this.walkoverReason,
      createdAt: createdAt ?? this.createdAt,
      games: games ?? this.games,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
    );
  }

  bool get hasTeams => teamAId != null && teamBId != null;
  bool get isComplete => status == MatchStatus.completed || status == MatchStatus.walkover;
  String get scoreDisplay => '$teamAScore - $teamBScore';
}

/// Individual game within a best-of series match
class MatchGame {
  final String id;
  final String matchId;
  final int gameNumber;
  final int teamAScore;
  final int teamBScore;
  final String? winnerId;
  final MatchStatus status;
  final DateTime createdAt;

  MatchGame({
    required this.id,
    required this.matchId,
    required this.gameNumber,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.winnerId,
    this.status = MatchStatus.pending,
    required this.createdAt,
  });

  factory MatchGame.fromJson(Map<String, dynamic> json) {
    return MatchGame(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      gameNumber: json['game_number'] as int,
      teamAScore: json['team_a_score'] as int? ?? 0,
      teamBScore: json['team_b_score'] as int? ?? 0,
      winnerId: json['winner_id'] as String?,
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'game_number': gameNumber,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'winner_id': winnerId,
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  MatchGame copyWith({
    String? id,
    String? matchId,
    int? gameNumber,
    int? teamAScore,
    int? teamBScore,
    String? winnerId,
    MatchStatus? status,
    DateTime? createdAt,
  }) {
    return MatchGame(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      gameNumber: gameNumber ?? this.gameNumber,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      winnerId: winnerId ?? this.winnerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isComplete => status == MatchStatus.completed;
  String get scoreDisplay => '$teamAScore - $teamBScore';
}

/// Group within a group-stage tournament
class TournamentGroup {
  final String id;
  final String tournamentId;
  final String name;
  final int advanceCount;
  final int sortOrder;
  final DateTime createdAt;

  // Nested data
  final List<GroupStanding>? standings;
  final List<GroupMatch>? matches;

  TournamentGroup({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.advanceCount = 2,
    this.sortOrder = 0,
    required this.createdAt,
    this.standings,
    this.matches,
  });

  factory TournamentGroup.fromJson(Map<String, dynamic> json) {
    return TournamentGroup(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      name: json['name'] as String,
      advanceCount: json['advance_count'] as int? ?? 2,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      standings: json['standings'] != null
          ? (json['standings'] as List).map((s) => GroupStanding.fromJson(s as Map<String, dynamic>)).toList()
          : null,
      matches: json['matches'] != null
          ? (json['matches'] as List).map((m) => GroupMatch.fromJson(m as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'name': name,
      'advance_count': advanceCount,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      if (standings != null) 'standings': standings!.map((s) => s.toJson()).toList(),
      if (matches != null) 'matches': matches!.map((m) => m.toJson()).toList(),
    };
  }

  TournamentGroup copyWith({
    String? id,
    String? tournamentId,
    String? name,
    int? advanceCount,
    int? sortOrder,
    DateTime? createdAt,
    List<GroupStanding>? standings,
    List<GroupMatch>? matches,
  }) {
    return TournamentGroup(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      advanceCount: advanceCount ?? this.advanceCount,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      standings: standings ?? this.standings,
      matches: matches ?? this.matches,
    );
  }

  /// Get sorted standings by position
  List<GroupStanding> get sortedStandings {
    if (standings == null) return [];
    final sorted = List<GroupStanding>.from(standings!);
    sorted.sort((a, b) => a.position.compareTo(b.position));
    return sorted;
  }
}

/// Team standing within a group
class GroupStanding {
  final String id;
  final String groupId;
  final String teamId;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;
  final int position;
  final DateTime updatedAt;

  // Joined data
  final String? teamName;

  GroupStanding({
    required this.id,
    required this.groupId,
    required this.teamId,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
    this.position = 0,
    required this.updatedAt,
    this.teamName,
  });

  factory GroupStanding.fromJson(Map<String, dynamic> json) {
    return GroupStanding(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      teamId: json['team_id'] as String,
      played: json['played'] as int? ?? 0,
      won: json['won'] as int? ?? 0,
      drawn: json['drawn'] as int? ?? 0,
      lost: json['lost'] as int? ?? 0,
      goalsFor: json['goals_for'] as int? ?? 0,
      goalsAgainst: json['goals_against'] as int? ?? 0,
      points: json['points'] as int? ?? 0,
      position: json['position'] as int? ?? 0,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      teamName: json['team_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'team_id': teamId,
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goals_for': goalsFor,
      'goals_against': goalsAgainst,
      'points': points,
      'position': position,
      'updated_at': updatedAt.toIso8601String(),
      'team_name': teamName,
    };
  }

  GroupStanding copyWith({
    String? id,
    String? groupId,
    String? teamId,
    int? played,
    int? won,
    int? drawn,
    int? lost,
    int? goalsFor,
    int? goalsAgainst,
    int? points,
    int? position,
    DateTime? updatedAt,
    String? teamName,
  }) {
    return GroupStanding(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      teamId: teamId ?? this.teamId,
      played: played ?? this.played,
      won: won ?? this.won,
      drawn: drawn ?? this.drawn,
      lost: lost ?? this.lost,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      points: points ?? this.points,
      position: position ?? this.position,
      updatedAt: updatedAt ?? this.updatedAt,
      teamName: teamName ?? this.teamName,
    );
  }

  int get goalDifference => goalsFor - goalsAgainst;
  String get goalDifferenceDisplay => goalDifference >= 0 ? '+$goalDifference' : '$goalDifference';
  String get record => '$won-$drawn-$lost';
}

/// Match within a group stage
class GroupMatch {
  final String id;
  final String groupId;
  final String? teamAId;
  final String? teamBId;
  final int teamAScore;
  final int teamBScore;
  final MatchStatus status;
  final DateTime? scheduledTime;
  final int matchOrder;
  final DateTime createdAt;

  // Joined data
  final String? teamAName;
  final String? teamBName;

  GroupMatch({
    required this.id,
    required this.groupId,
    this.teamAId,
    this.teamBId,
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.status = MatchStatus.pending,
    this.scheduledTime,
    this.matchOrder = 0,
    required this.createdAt,
    this.teamAName,
    this.teamBName,
  });

  factory GroupMatch.fromJson(Map<String, dynamic> json) {
    return GroupMatch(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      teamAId: json['team_a_id'] as String?,
      teamBId: json['team_b_id'] as String?,
      teamAScore: json['team_a_score'] as int? ?? 0,
      teamBScore: json['team_b_score'] as int? ?? 0,
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      scheduledTime: json['scheduled_time'] != null ? DateTime.parse(json['scheduled_time'] as String) : null,
      matchOrder: json['match_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      teamAName: json['team_a_name'] as String?,
      teamBName: json['team_b_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      'status': status.toJson(),
      'scheduled_time': scheduledTime?.toIso8601String(),
      'match_order': matchOrder,
      'created_at': createdAt.toIso8601String(),
      'team_a_name': teamAName,
      'team_b_name': teamBName,
    };
  }

  GroupMatch copyWith({
    String? id,
    String? groupId,
    String? teamAId,
    String? teamBId,
    int? teamAScore,
    int? teamBScore,
    MatchStatus? status,
    DateTime? scheduledTime,
    int? matchOrder,
    DateTime? createdAt,
    String? teamAName,
    String? teamBName,
  }) {
    return GroupMatch(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      teamAId: teamAId ?? this.teamAId,
      teamBId: teamBId ?? this.teamBId,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      matchOrder: matchOrder ?? this.matchOrder,
      createdAt: createdAt ?? this.createdAt,
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
    );
  }

  bool get hasTeams => teamAId != null && teamBId != null;
  bool get isComplete => status == MatchStatus.completed;
  String get scoreDisplay => '$teamAScore - $teamBScore';
}

/// Qualification round for time/score-based tournaments
class QualificationRound {
  final String id;
  final String tournamentId;
  final String name;
  final int advanceCount;
  final String sortDirection; // 'asc' or 'desc'
  final MatchStatus status;
  final DateTime createdAt;

  // Nested data
  final List<QualificationResult>? results;

  QualificationRound({
    required this.id,
    required this.tournamentId,
    required this.name,
    this.advanceCount = 8,
    this.sortDirection = 'asc',
    this.status = MatchStatus.pending,
    required this.createdAt,
    this.results,
  });

  factory QualificationRound.fromJson(Map<String, dynamic> json) {
    return QualificationRound(
      id: json['id'] as String,
      tournamentId: json['tournament_id'] as String,
      name: json['name'] as String,
      advanceCount: json['advance_count'] as int? ?? 8,
      sortDirection: json['sort_direction'] as String? ?? 'asc',
      status: MatchStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: DateTime.parse(json['created_at'] as String),
      results: json['results'] != null
          ? (json['results'] as List).map((r) => QualificationResult.fromJson(r as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'name': name,
      'advance_count': advanceCount,
      'sort_direction': sortDirection,
      'status': status.toJson(),
      'created_at': createdAt.toIso8601String(),
      if (results != null) 'results': results!.map((r) => r.toJson()).toList(),
    };
  }

  QualificationRound copyWith({
    String? id,
    String? tournamentId,
    String? name,
    int? advanceCount,
    String? sortDirection,
    MatchStatus? status,
    DateTime? createdAt,
    List<QualificationResult>? results,
  }) {
    return QualificationRound(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      name: name ?? this.name,
      advanceCount: advanceCount ?? this.advanceCount,
      sortDirection: sortDirection ?? this.sortDirection,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      results: results ?? this.results,
    );
  }

  bool get isAscending => sortDirection == 'asc';
  bool get isComplete => status == MatchStatus.completed;

  /// Get sorted results by rank
  List<QualificationResult> get sortedResults {
    if (results == null) return [];
    final sorted = List<QualificationResult>.from(results!);
    sorted.sort((a, b) => a.rank.compareTo(b.rank));
    return sorted;
  }
}

/// Individual result in a qualification round
class QualificationResult {
  final String id;
  final String qualificationRoundId;
  final String userId;
  final double resultValue;
  final bool advanced;
  final int rank;
  final DateTime createdAt;

  // Joined data
  final String? userName;

  QualificationResult({
    required this.id,
    required this.qualificationRoundId,
    required this.userId,
    required this.resultValue,
    this.advanced = false,
    this.rank = 0,
    required this.createdAt,
    this.userName,
  });

  factory QualificationResult.fromJson(Map<String, dynamic> json) {
    return QualificationResult(
      id: json['id'] as String,
      qualificationRoundId: json['qualification_round_id'] as String,
      userId: json['user_id'] as String,
      resultValue: (json['result_value'] as num).toDouble(),
      advanced: json['advanced'] as bool? ?? false,
      rank: json['rank'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: json['user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'qualification_round_id': qualificationRoundId,
      'user_id': userId,
      'result_value': resultValue,
      'advanced': advanced,
      'rank': rank,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
    };
  }

  QualificationResult copyWith({
    String? id,
    String? qualificationRoundId,
    String? userId,
    double? resultValue,
    bool? advanced,
    int? rank,
    DateTime? createdAt,
    String? userName,
  }) {
    return QualificationResult(
      id: id ?? this.id,
      qualificationRoundId: qualificationRoundId ?? this.qualificationRoundId,
      userId: userId ?? this.userId,
      resultValue: resultValue ?? this.resultValue,
      advanced: advanced ?? this.advanced,
      rank: rank ?? this.rank,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
    );
  }

  /// Format result value for display (handles time vs score)
  String formatResult({bool isTime = false}) {
    if (isTime) {
      // Format as time (assuming milliseconds)
      final ms = resultValue.round();
      final minutes = ms ~/ 60000;
      final seconds = (ms % 60000) ~/ 1000;
      final millis = ms % 1000;
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(millis ~/ 10).toString().padLeft(2, '0')}';
    }
    // Format as score
    return resultValue.toStringAsFixed(resultValue.truncateToDouble() == resultValue ? 0 : 2);
  }
}
