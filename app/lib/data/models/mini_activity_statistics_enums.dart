// Enums for mini-activity statistics tracking

/// Point source type enum
enum PointSourceType {
  miniActivityWin,
  miniActivityDraw,
  miniActivityLoss,
  tournamentPlacement,
  bonusPoints,
  penaltyPoints,
  attendance,
  manual;

  static PointSourceType fromString(String value) {
    switch (value) {
      case 'mini_activity_win':
        return PointSourceType.miniActivityWin;
      case 'mini_activity_draw':
        return PointSourceType.miniActivityDraw;
      case 'mini_activity_loss':
        return PointSourceType.miniActivityLoss;
      case 'tournament_placement':
        return PointSourceType.tournamentPlacement;
      case 'bonus_points':
        return PointSourceType.bonusPoints;
      case 'penalty_points':
        return PointSourceType.penaltyPoints;
      case 'attendance':
        return PointSourceType.attendance;
      case 'manual':
        return PointSourceType.manual;
      default:
        return PointSourceType.manual;
    }
  }

  String toJson() {
    switch (this) {
      case PointSourceType.miniActivityWin:
        return 'mini_activity_win';
      case PointSourceType.miniActivityDraw:
        return 'mini_activity_draw';
      case PointSourceType.miniActivityLoss:
        return 'mini_activity_loss';
      case PointSourceType.tournamentPlacement:
        return 'tournament_placement';
      case PointSourceType.bonusPoints:
        return 'bonus_points';
      case PointSourceType.penaltyPoints:
        return 'penalty_points';
      case PointSourceType.attendance:
        return 'attendance';
      case PointSourceType.manual:
        return 'manual';
    }
  }

  String get displayName {
    switch (this) {
      case PointSourceType.miniActivityWin:
        return 'Seier';
      case PointSourceType.miniActivityDraw:
        return 'Uavgjort';
      case PointSourceType.miniActivityLoss:
        return 'Tap';
      case PointSourceType.tournamentPlacement:
        return 'Turneringsplassering';
      case PointSourceType.bonusPoints:
        return 'Bonuspoeng';
      case PointSourceType.penaltyPoints:
        return 'Straffepoeng';
      case PointSourceType.attendance:
        return 'Oppmøte';
      case PointSourceType.manual:
        return 'Manuell';
    }
  }

  bool get isPositive =>
      this == PointSourceType.miniActivityWin ||
      this == PointSourceType.tournamentPlacement ||
      this == PointSourceType.bonusPoints ||
      this == PointSourceType.attendance;
}
