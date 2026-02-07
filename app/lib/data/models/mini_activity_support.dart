// Supporting models for mini-activities
// Teams, participants, adjustments, handicaps, and history entries

class MiniActivityTeam {
  final String id;
  final String? name;
  final int? finalScore;
  final List<MiniActivityParticipant>? participants;

  MiniActivityTeam({
    required this.id,
    this.name,
    this.finalScore,
    this.participants,
  });

  factory MiniActivityTeam.fromJson(Map<String, dynamic> json) {
    List<MiniActivityParticipant>? participants;
    if (json['participants'] != null && json['participants'] is List) {
      final list = json['participants'] as List;
      // Filter out null entries that might come from LEFT JOIN
      participants = list
          .where((p) => p != null && p is Map && p['user_id'] != null)
          .map((p) => MiniActivityParticipant.fromJson(
              p is Map<String, dynamic> ? p : Map<String, dynamic>.from(p as Map)))
          .toList();
    }

    return MiniActivityTeam(
      id: json['id'] as String,
      name: json['name'] as String?,
      finalScore: json['final_score'] as int?,
      participants: participants,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'final_score': finalScore,
      'participants': participants?.map((p) => p.toJson()).toList(),
    };
  }

  MiniActivityTeam copyWith({
    String? id,
    String? name,
    int? finalScore,
    List<MiniActivityParticipant>? participants,
  }) {
    return MiniActivityTeam(
      id: id ?? this.id,
      name: name ?? this.name,
      finalScore: finalScore ?? this.finalScore,
      participants: participants ?? this.participants,
    );
  }
}

class MiniActivityParticipant {
  final String id;
  final String userId;
  final int points;
  final String? userName;
  final String? userAvatarUrl;

  MiniActivityParticipant({
    required this.id,
    required this.userId,
    required this.points,
    this.userName,
    this.userAvatarUrl,
  });

  factory MiniActivityParticipant.fromJson(Map<String, dynamic> json) {
    return MiniActivityParticipant(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      points: json['points'] as int? ?? 0,
      userName: json['user_name'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
    };
  }

  MiniActivityParticipant copyWith({
    String? id,
    String? userId,
    int? points,
    String? userName,
    String? userAvatarUrl,
  }) {
    return MiniActivityParticipant(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}

// Adjustment model for bonus/penalty points
class MiniActivityAdjustment {
  final String id;
  final String miniActivityId;
  final String? teamId;
  final String? userId;
  final int points;
  final String? reason;
  final String createdBy;
  final DateTime createdAt;

  MiniActivityAdjustment({
    required this.id,
    required this.miniActivityId,
    this.teamId,
    this.userId,
    required this.points,
    this.reason,
    required this.createdBy,
    required this.createdAt,
  });

  factory MiniActivityAdjustment.fromJson(Map<String, dynamic> json) {
    return MiniActivityAdjustment(
      id: json['id'] as String,
      miniActivityId: json['mini_activity_id'] as String,
      teamId: json['team_id'] as String?,
      userId: json['user_id'] as String?,
      points: json['points'] as int,
      reason: json['reason'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'team_id': teamId,
      'user_id': userId,
      'points': points,
      'reason': reason,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isTeamAdjustment => teamId != null;
  bool get isUserAdjustment => userId != null;
  bool get isBonus => points > 0;
  bool get isPenalty => points < 0;

  String get displayDescription => reason ?? (isBonus ? 'Bonus' : 'Straff');

  String get targetDisplay {
    if (isTeamAdjustment) {
      return 'Lag';
    } else if (isUserAdjustment) {
      return 'Spiller';
    }
    return 'Ukjent';
  }

  String get formattedPoints {
    if (points >= 0) {
      return '+$points';
    }
    return '$points';
  }
}

// Handicap model for player handicaps
class MiniActivityHandicap {
  final String id;
  final String miniActivityId;
  final String userId;
  final double handicapValue;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;

  MiniActivityHandicap({
    required this.id,
    required this.miniActivityId,
    required this.userId,
    required this.handicapValue,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
  });

  factory MiniActivityHandicap.fromJson(Map<String, dynamic> json) {
    return MiniActivityHandicap(
      id: json['id'] as String,
      miniActivityId: json['mini_activity_id'] as String,
      userId: json['user_id'] as String,
      handicapValue: (json['handicap_value'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mini_activity_id': miniActivityId,
      'user_id': userId,
      'handicap_value': handicapValue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_name': userName,
    };
  }

  String get formattedHandicap {
    if (handicapValue >= 0) {
      return '+${handicapValue.toStringAsFixed(1)}';
    }
    return handicapValue.toStringAsFixed(1);
  }
}

// History entry for showing previous results
class MiniActivityHistoryEntry {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? winnerTeamId;
  final List<MiniActivityHistoryTeam> teams;

  MiniActivityHistoryEntry({
    required this.id,
    required this.name,
    required this.createdAt,
    this.winnerTeamId,
    required this.teams,
  });

  factory MiniActivityHistoryEntry.fromJson(Map<String, dynamic> json) {
    List<MiniActivityHistoryTeam> teams = [];
    if (json['teams'] != null) {
      teams = (json['teams'] as List)
          .map((t) => MiniActivityHistoryTeam.fromJson(
              t is Map<String, dynamic> ? t : Map<String, dynamic>.from(t as Map)))
          .toList();
    }

    return MiniActivityHistoryEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      winnerTeamId: json['winner_team_id'] as String?,
      teams: teams,
    );
  }

  bool get hasResult => winnerTeamId != null || teams.any((t) => t.finalScore != null);

  MiniActivityHistoryTeam? get winnerTeam {
    if (winnerTeamId != null) {
      return teams.cast<MiniActivityHistoryTeam?>().firstWhere(
            (t) => t?.id == winnerTeamId,
            orElse: () => null,
          );
    }
    // Determine by score
    final teamsWithScores = teams.where((t) => t.finalScore != null).toList();
    if (teamsWithScores.isNotEmpty) {
      teamsWithScores.sort((a, b) => (b.finalScore ?? 0).compareTo(a.finalScore ?? 0));
      return teamsWithScores.first;
    }
    return null;
  }
}

class MiniActivityHistoryTeam {
  final String id;
  final String? name;
  final int? finalScore;

  MiniActivityHistoryTeam({
    required this.id,
    this.name,
    this.finalScore,
  });

  factory MiniActivityHistoryTeam.fromJson(Map<String, dynamic> json) {
    return MiniActivityHistoryTeam(
      id: json['id'] as String,
      name: json['name'] as String?,
      finalScore: json['final_score'] as int?,
    );
  }
}
