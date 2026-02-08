// Achievement definition and user achievement models

import 'achievement_enums.dart';
import 'package:equatable/equatable.dart';

/// Achievement definition (template)
class AchievementDefinition extends Equatable {
  final String id;
  final String? teamId;
  final String code;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final AchievementTier tier;
  final AchievementCategory category;
  final AchievementCriteria criteria;
  final int bonusPoints;
  final bool isActive;
  final bool isSecret;
  final bool isRepeatable;
  final int? repeatCooldownDays;
  final DateTime createdAt;
  AchievementDefinition({
    required this.id,
    this.teamId,
    required this.code,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.tier = AchievementTier.bronze,
    required this.category,
    required this.criteria,
    this.bonusPoints = 0,
    this.isActive = true,
    this.isSecret = false,
    this.isRepeatable = false,
    this.repeatCooldownDays,
    required this.createdAt,
  });

  bool get isGlobal => teamId == null;

  factory AchievementDefinition.fromJson(Map<String, dynamic> json) {
    return
  AchievementDefinition(
      id: json['id'],
      teamId: json['team_id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      tier: AchievementTier.fromString(json['tier'] ?? 'bronze'),
      category: AchievementCategory.fromString(json['category'] ?? 'milestone'),
      criteria: AchievementCriteria.fromJson(json['criteria'] ?? {}),
      bonusPoints: json['bonus_points'] ?? 0,
      isActive: json['is_active'] ?? true,
      isSecret: json['is_secret'] ?? false,
      isRepeatable: json['is_repeatable'] ?? false,
      repeatCooldownDays: json['repeat_cooldown_days'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'team_id': teamId,
        'code': code,
        'name': name,
        'description': description,
        'icon': icon,
        'color': color,
        'tier': tier.name,
        'category': category.name,
        'criteria': criteria.toJson(),
        'bonus_points': bonusPoints,
        'is_active': isActive,
        'is_secret': isSecret,
        'is_repeatable': isRepeatable,
        'repeat_cooldown_days': repeatCooldownDays,
        'created_at': createdAt.toIso8601String(),
      };

  AchievementDefinition copyWith({
    String? id,
    String? teamId,
    String? code,
    String? name,
    String? description,
    String? icon,
    String? color,
    AchievementTier? tier,
    AchievementCategory? category,
    AchievementCriteria? criteria,
    int? bonusPoints,
    bool? isActive,
    bool? isSecret,
    bool? isRepeatable,
    int? repeatCooldownDays,
    DateTime? createdAt,
  }) {
    return
  AchievementDefinition(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      tier: tier ?? this.tier,
      category: category ?? this.category,
      criteria: criteria ?? this.criteria,
      bonusPoints: bonusPoints ?? this.bonusPoints,
      isActive: isActive ?? this.isActive,
      isSecret: isSecret ?? this.isSecret,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      repeatCooldownDays: repeatCooldownDays ?? this.repeatCooldownDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }


  @override
  List<Object?> get props => [id, teamId, code, name, description, icon, color, tier, category, criteria, bonusPoints, isActive, isSecret, isRepeatable, repeatCooldownDays, createdAt];
}

/// Awarded achievement instance for a user
class UserAchievement extends Equatable {
  final String id;
  final String userId;
  final String achievementId;
  final String teamId;
  final String? seasonId;
  final int pointsAwarded;
  final int? repeatCount;
  final Map<String, dynamic>? triggerReference;
  final DateTime awardedAt;

  // Joined fields
  final AchievementDefinition? definition;
  final String? userName;
  final String? userAvatarUrl;
  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.teamId,
    this.seasonId,
    this.pointsAwarded = 0,
    this.repeatCount,
    this.triggerReference,
    required this.awardedAt,
    this.definition,
    this.userName,
    this.userAvatarUrl,
  });

  // Convenience getters
  String? get achievementName => definition?.name;
  AchievementTier? get tier => definition?.tier;
  String? get icon => definition?.icon;
  AchievementCategory? get category => definition?.category;
  String? get description => definition?.description;

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return
  UserAchievement(
      id: json['id'],
      userId: json['user_id'],
      achievementId: json['achievement_id'],
      teamId: json['team_id'],
      seasonId: json['season_id'],
      pointsAwarded: json['points_awarded'] ?? 0,
      repeatCount: json['repeat_count'],
      triggerReference: json['trigger_reference'],
      awardedAt: DateTime.parse(json['awarded_at']),
      definition: json['definition'] != null
          ? AchievementDefinition.fromJson(json['definition'])
          : null,
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'achievement_id': achievementId,
        'team_id': teamId,
        'season_id': seasonId,
        'points_awarded': pointsAwarded,
        'repeat_count': repeatCount,
        'trigger_reference': triggerReference,
        'awarded_at': awardedAt.toIso8601String(),
        if (definition != null) 'definition': definition!.toJson(),
        'user_name': userName,
        'user_avatar_url': userAvatarUrl,
      };


  @override
  List<Object?> get props => [id, userId, achievementId, teamId, seasonId, pointsAwarded, repeatCount, triggerReference, awardedAt, definition, userName, userAvatarUrl];
}

/// Progress towards an achievement
class AchievementProgress extends Equatable {
  final String id;
  final String? userId;
  final String achievementId;
  final String teamId;
  final String? seasonId;
  final int currentValue;
  final int? targetValue;
  final DateTime updatedAt;

  // Joined fields
  final AchievementDefinition? definition;
  final String? userName;
  AchievementProgress({
    required this.id,
    this.userId,
    required this.achievementId,
    required this.teamId,
    this.seasonId,
    this.currentValue = 0,
    this.targetValue,
    required this.updatedAt,
    this.definition,
    this.userName,
  });

  double get progressPercent {
    if (targetValue == null || targetValue == 0) return 0.0;
    return (currentValue / targetValue! * 100).clamp(0.0, 100.0);
  }

  // Alias for compatibility
  double get percentComplete => progressPercent;

  bool get isComplete =>
      targetValue != null && currentValue >= targetValue!;

  // Convenience getters from definition
  String? get achievementName => definition?.name;
  String? get icon => definition?.icon;
  AchievementTier? get tier => definition?.tier;
  AchievementCategory? get category => definition?.category;

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return
  AchievementProgress(
      id: json['id'],
      userId: json['user_id'],
      achievementId: json['achievement_id'],
      teamId: json['team_id'],
      seasonId: json['season_id'],
      currentValue: json['current_value'] ?? 0,
      targetValue: json['target_value'],
      updatedAt: DateTime.parse(json['updated_at']),
      definition: json['definition'] != null
          ? AchievementDefinition.fromJson(json['definition'])
          : null,
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'achievement_id': achievementId,
        'team_id': teamId,
        'season_id': seasonId,
        'current_value': currentValue,
        'target_value': targetValue,
        'updated_at': updatedAt.toIso8601String(),
        if (definition != null) 'definition': definition!.toJson(),
        'user_name': userName,
      };


  @override
  List<Object?> get props => [id, userId, achievementId, teamId, seasonId, currentValue, targetValue, updatedAt, definition, userName];
}

/// Summary of user achievements
class UserAchievementsSummary extends Equatable {
  final String userId;
  final int totalAchievements;
  final int bronzeCount;
  final int silverCount;
  final int goldCount;
  final int platinumCount;
  final int totalBonusPoints;
  final List<UserAchievement> recentAchievements;
  final List<AchievementProgress> inProgress;
  UserAchievementsSummary({
    required this.userId,
    this.totalAchievements = 0,
    this.bronzeCount = 0,
    this.silverCount = 0,
    this.goldCount = 0,
    this.platinumCount = 0,
    this.totalBonusPoints = 0,
    this.recentAchievements = const [],
    this.inProgress = const [],
  });

  factory UserAchievementsSummary.fromJson(Map<String, dynamic> json) {
    return
  UserAchievementsSummary(
      userId: json['user_id'],
      totalAchievements: json['total_achievements'] ?? 0,
      bronzeCount: json['bronze_count'] ?? 0,
      silverCount: json['silver_count'] ?? 0,
      goldCount: json['gold_count'] ?? 0,
      platinumCount: json['platinum_count'] ?? 0,
      totalBonusPoints: json['total_bonus_points'] ?? 0,
      recentAchievements: json['recent_achievements'] != null
          ? (json['recent_achievements'] as List)
              .map((e) => UserAchievement.fromJson(e))
              .toList()
          : [],
      inProgress: json['in_progress'] != null
          ? (json['in_progress'] as List)
              .map((e) => AchievementProgress.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'total_achievements': totalAchievements,
        'bronze_count': bronzeCount,
        'silver_count': silverCount,
        'gold_count': goldCount,
        'platinum_count': platinumCount,
        'total_bonus_points': totalBonusPoints,
        'recent_achievements':
            recentAchievements.map((e) => e.toJson()).toList(),
        'in_progress': inProgress.map((e) => e.toJson()).toList(),
      };


  @override
  List<Object?> get props => [userId, totalAchievements, bronzeCount, silverCount, goldCount, platinumCount, totalBonusPoints, recentAchievements, inProgress];
}
