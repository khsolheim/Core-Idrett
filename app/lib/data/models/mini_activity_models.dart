// Core Mini-Activity Models

import 'mini_activity_enums.dart';
import 'mini_activity_support.dart';

class ActivityTemplate {
  final String id;
  final String teamId;
  final String name;
  final MiniActivityType type;
  final int defaultPoints;
  final DateTime createdAt;
  // New fields
  final String? description;
  final String? instructions;
  final String? sportType;
  final Map<String, dynamic>? suggestedRules;
  final bool isFavorite;
  final int winPoints;
  final int drawPoints;
  final int lossPoints;
  final String? leaderboardId;

  ActivityTemplate({
    required this.id,
    required this.teamId,
    required this.name,
    required this.type,
    required this.defaultPoints,
    required this.createdAt,
    this.description,
    this.instructions,
    this.sportType,
    this.suggestedRules,
    this.isFavorite = false,
    this.winPoints = 3,
    this.drawPoints = 1,
    this.lossPoints = 0,
    this.leaderboardId,
  });

  factory ActivityTemplate.fromJson(Map<String, dynamic> json) {
    return ActivityTemplate(
      id: json['id'] as String,
      teamId: json['team_id'] as String,
      name: json['name'] as String,
      type: MiniActivityType.fromString(json['type'] as String),
      defaultPoints: json['default_points'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      instructions: json['instructions'] as String?,
      sportType: json['sport_type'] as String?,
      suggestedRules: json['suggested_rules'] as Map<String, dynamic>?,
      isFavorite: json['is_favorite'] as bool? ?? false,
      winPoints: json['win_points'] as int? ?? 3,
      drawPoints: json['draw_points'] as int? ?? 1,
      lossPoints: json['loss_points'] as int? ?? 0,
      leaderboardId: json['leaderboard_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'team_id': teamId,
      'name': name,
      'type': type.toApiString(),
      'default_points': defaultPoints,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'instructions': instructions,
      'sport_type': sportType,
      'suggested_rules': suggestedRules,
      'is_favorite': isFavorite,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      'leaderboard_id': leaderboardId,
    };
  }

  ActivityTemplate copyWith({
    String? id,
    String? teamId,
    String? name,
    MiniActivityType? type,
    int? defaultPoints,
    DateTime? createdAt,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    bool? isFavorite,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
  }) {
    return ActivityTemplate(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      type: type ?? this.type,
      defaultPoints: defaultPoints ?? this.defaultPoints,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      sportType: sportType ?? this.sportType,
      suggestedRules: suggestedRules ?? this.suggestedRules,
      isFavorite: isFavorite ?? this.isFavorite,
      winPoints: winPoints ?? this.winPoints,
      drawPoints: drawPoints ?? this.drawPoints,
      lossPoints: lossPoints ?? this.lossPoints,
      leaderboardId: leaderboardId ?? this.leaderboardId,
    );
  }
}

class MiniActivity {
  final String id;
  final String? instanceId; // Nullable for standalone activities
  final String? templateId;
  final String name;
  final MiniActivityType type;
  final DivisionMethod? divisionMethod;
  final int numTeams;
  final DateTime createdAt;
  final int? teamCount;
  final int? participantCount;
  final List<MiniActivityTeam>? teams;
  final List<MiniActivityParticipant>? participants;
  // New fields
  final String? teamId; // For standalone mini-activities
  final String? leaderboardId;
  final bool enableLeaderboard;
  final int winPoints;
  final int drawPoints;
  final int lossPoints;
  final String? description;
  final int? maxParticipants;
  final bool handicapEnabled;
  final DateTime? archivedAt;
  final String? winnerTeamId; // Manually set winner (null = draw or no result yet)

  MiniActivity({
    required this.id,
    this.instanceId,
    this.templateId,
    required this.name,
    required this.type,
    this.divisionMethod,
    this.numTeams = 2,
    required this.createdAt,
    this.teamCount,
    this.participantCount,
    this.teams,
    this.participants,
    this.teamId,
    this.leaderboardId,
    this.enableLeaderboard = true,
    this.winPoints = 3,
    this.drawPoints = 1,
    this.lossPoints = 0,
    this.description,
    this.maxParticipants,
    this.handicapEnabled = false,
    this.archivedAt,
    this.winnerTeamId,
  });

  factory MiniActivity.fromJson(Map<String, dynamic> json) {
    List<MiniActivityTeam>? teams;
    if (json['teams'] != null) {
      teams = (json['teams'] as List)
          .map((t) => MiniActivityTeam.fromJson(
              t is Map<String, dynamic> ? t : Map<String, dynamic>.from(t as Map)))
          .toList();
    }

    List<MiniActivityParticipant>? participants;
    if (json['participants'] != null) {
      participants = (json['participants'] as List)
          .map((p) => MiniActivityParticipant.fromJson(
              p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList();
    }

    return MiniActivity(
      id: json['id'] as String,
      instanceId: json['instance_id'] as String?,
      templateId: json['template_id'] as String?,
      name: json['name'] as String,
      type: MiniActivityType.fromString(json['type'] as String),
      divisionMethod: json['division_method'] != null
          ? DivisionMethod.fromString(json['division_method'] as String?)
          : null,
      numTeams: json['num_teams'] as int? ?? 2,
      createdAt: DateTime.parse(json['created_at'] as String),
      teamCount: json['team_count'] as int?,
      participantCount: json['participant_count'] as int?,
      teams: teams,
      participants: participants,
      teamId: json['team_id'] as String?,
      leaderboardId: json['leaderboard_id'] as String?,
      enableLeaderboard: json['enable_leaderboard'] as bool? ?? true,
      winPoints: json['win_points'] as int? ?? 3,
      drawPoints: json['draw_points'] as int? ?? 1,
      lossPoints: json['loss_points'] as int? ?? 0,
      description: json['description'] as String?,
      maxParticipants: json['max_participants'] as int?,
      handicapEnabled: json['handicap_enabled'] as bool? ?? false,
      archivedAt: json['archived_at'] != null
          ? DateTime.parse(json['archived_at'] as String)
          : null,
      winnerTeamId: json['winner_team_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instance_id': instanceId,
      'template_id': templateId,
      'name': name,
      'type': type.toApiString(),
      'division_method': divisionMethod?.toApiString(),
      'num_teams': numTeams,
      'created_at': createdAt.toIso8601String(),
      'team_id': teamId,
      'leaderboard_id': leaderboardId,
      'enable_leaderboard': enableLeaderboard,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
      'description': description,
      'max_participants': maxParticipants,
      'handicap_enabled': handicapEnabled,
      'archived_at': archivedAt?.toIso8601String(),
      'winner_team_id': winnerTeamId,
    };
  }

  bool get hasTeams => teams != null && teams!.isNotEmpty;
  bool get isTeamBased => type == MiniActivityType.team;
  bool get isStandalone => instanceId == null && teamId != null;
  bool get isArchived => archivedAt != null;
  bool get hasResult => winnerTeamId != null || (teams?.any((t) => t.finalScore != null) ?? false);
  bool get isDraw => hasResult && winnerTeamId == null && teams != null && _allTeamsHaveSameScore();

  bool _allTeamsHaveSameScore() {
    if (teams == null || teams!.isEmpty) return false;
    final scores = teams!.map((t) => t.finalScore).where((s) => s != null).toSet();
    return scores.length <= 1;
  }

  /// Get the winner team if there is one
  MiniActivityTeam? get winnerTeam {
    if (winnerTeamId != null && teams != null) {
      return teams!.cast<MiniActivityTeam?>().firstWhere(
            (t) => t?.id == winnerTeamId,
            orElse: () => null,
          );
    }
    // Determine winner by score if no explicit winner
    if (teams != null && teams!.isNotEmpty) {
      final teamsWithScores = teams!.where((t) => t.finalScore != null).toList();
      if (teamsWithScores.length == teams!.length && teamsWithScores.isNotEmpty) {
        teamsWithScores.sort((a, b) => (b.finalScore ?? 0).compareTo(a.finalScore ?? 0));
        final highestScore = teamsWithScores.first.finalScore;
        final winnersCount = teamsWithScores.where((t) => t.finalScore == highestScore).length;
        if (winnersCount == 1) {
          return teamsWithScores.first;
        }
      }
    }
    return null;
  }

  MiniActivity copyWith({
    String? id,
    String? instanceId,
    String? templateId,
    String? name,
    MiniActivityType? type,
    DivisionMethod? divisionMethod,
    int? numTeams,
    DateTime? createdAt,
    int? teamCount,
    int? participantCount,
    List<MiniActivityTeam>? teams,
    List<MiniActivityParticipant>? participants,
    String? teamId,
    String? leaderboardId,
    bool? enableLeaderboard,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? description,
    int? maxParticipants,
    bool? handicapEnabled,
    DateTime? archivedAt,
    String? winnerTeamId,
  }) {
    return MiniActivity(
      id: id ?? this.id,
      instanceId: instanceId ?? this.instanceId,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      type: type ?? this.type,
      divisionMethod: divisionMethod ?? this.divisionMethod,
      numTeams: numTeams ?? this.numTeams,
      createdAt: createdAt ?? this.createdAt,
      teamCount: teamCount ?? this.teamCount,
      participantCount: participantCount ?? this.participantCount,
      teams: teams ?? this.teams,
      participants: participants ?? this.participants,
      teamId: teamId ?? this.teamId,
      leaderboardId: leaderboardId ?? this.leaderboardId,
      enableLeaderboard: enableLeaderboard ?? this.enableLeaderboard,
      winPoints: winPoints ?? this.winPoints,
      drawPoints: drawPoints ?? this.drawPoints,
      lossPoints: lossPoints ?? this.lossPoints,
      description: description ?? this.description,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      handicapEnabled: handicapEnabled ?? this.handicapEnabled,
      archivedAt: archivedAt ?? this.archivedAt,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
    );
  }
}
