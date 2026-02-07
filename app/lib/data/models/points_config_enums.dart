/// Leaderboard category types for filtering
enum LeaderboardCategory {
  total,
  attendance,
  competition,
  training,
  match,
  social;

  static LeaderboardCategory fromString(String value) {
    return LeaderboardCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LeaderboardCategory.total,
    );
  }
}

/// Points distribution mode for mini-activities
enum MiniActivityDistribution {
  winnerOnly,
  topThree,
  allParticipants;

  static MiniActivityDistribution fromString(String value) {
    switch (value) {
      case 'winner_only':
        return MiniActivityDistribution.winnerOnly;
      case 'top_three':
        return MiniActivityDistribution.topThree;
      case 'all_participants':
        return MiniActivityDistribution.allParticipants;
      default:
        return MiniActivityDistribution.topThree;
    }
  }

  String toJsonString() {
    switch (this) {
      case MiniActivityDistribution.winnerOnly:
        return 'winner_only';
      case MiniActivityDistribution.topThree:
        return 'top_three';
      case MiniActivityDistribution.allParticipants:
        return 'all_participants';
    }
  }
}

/// Visibility mode for leaderboards
enum LeaderboardVisibility {
  all,
  rankingOnly,
  ownOnly;

  static LeaderboardVisibility fromString(String value) {
    switch (value) {
      case 'all':
        return LeaderboardVisibility.all;
      case 'ranking_only':
        return LeaderboardVisibility.rankingOnly;
      case 'own_only':
        return LeaderboardVisibility.ownOnly;
      default:
        return LeaderboardVisibility.all;
    }
  }

  String toJsonString() {
    switch (this) {
      case LeaderboardVisibility.all:
        return 'all';
      case LeaderboardVisibility.rankingOnly:
        return 'ranking_only';
      case LeaderboardVisibility.ownOnly:
        return 'own_only';
    }
  }
}

/// Mode for how new players start in the points system
enum NewPlayerStartMode {
  fromJoin,
  wholeSeason,
  adminChooses;

  static NewPlayerStartMode fromString(String value) {
    switch (value) {
      case 'from_join':
        return NewPlayerStartMode.fromJoin;
      case 'full_season':
        return NewPlayerStartMode.wholeSeason;
      case 'admin_choice':
        return NewPlayerStartMode.adminChooses;
      default:
        return NewPlayerStartMode.fromJoin;
    }
  }

  String toJsonString() {
    switch (this) {
      case NewPlayerStartMode.fromJoin:
        return 'from_join';
      case NewPlayerStartMode.wholeSeason:
        return 'full_season';
      case NewPlayerStartMode.adminChooses:
        return 'admin_choice';
    }
  }
}

/// Adjustment type for manual point adjustments
enum AdjustmentType {
  bonus,
  penalty,
  correction;

  static AdjustmentType fromString(String value) {
    return AdjustmentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AdjustmentType.bonus,
    );
  }

  String toJsonString() => name;

  String get displayName {
    switch (this) {
      case AdjustmentType.bonus:
        return 'Bonus';
      case AdjustmentType.penalty:
        return 'Straff';
      case AdjustmentType.correction:
        return 'Korreksjon';
    }
  }
}
