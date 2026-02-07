// Tournament group play models
// TournamentGroup, GroupStanding, GroupMatch, QualificationRound, QualificationResult

import 'tournament_enums.dart';

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
