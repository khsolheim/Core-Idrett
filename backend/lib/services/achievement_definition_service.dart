import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/achievement.dart';

/// Service for managing achievement definitions (CRUD)
class AchievementDefinitionService {
  final Database _db;
  final _uuid = const Uuid();

  AchievementDefinitionService(this._db);

  /// Get all achievement definitions for a team (including global)
  Future<List<AchievementDefinition>> getDefinitions(
    String teamId, {
    bool includeGlobal = true,
    bool activeOnly = true,
    AchievementCategory? category,
  }) async {
    // Get team-specific achievements
    final teamFilters = <String, String>{'team_id': 'eq.$teamId'};
    if (activeOnly) teamFilters['is_active'] = 'eq.true';
    if (category != null) teamFilters['category'] = 'eq.${category.value}';

    final teamResult = await _db.client.select(
      'achievement_definitions',
      filters: teamFilters,
      order: 'tier.asc,name.asc',
    );

    List<Map<String, dynamic>> globalResult = [];
    if (includeGlobal) {
      // Get global achievements
      final globalFilters = <String, String>{'team_id': 'is.null'};
      if (activeOnly) globalFilters['is_active'] = 'eq.true';
      if (category != null) globalFilters['category'] = 'eq.${category.value}';

      globalResult = await _db.client.select(
        'achievement_definitions',
        filters: globalFilters,
        order: 'tier.asc,name.asc',
      );
    }

    final combined = [...globalResult, ...teamResult];
    return combined.map((row) => AchievementDefinition.fromJson(row)).toList();
  }

  /// Get a definition by ID
  Future<AchievementDefinition?> getDefinitionById(String definitionId) async {
    final result = await _db.client.select(
      'achievement_definitions',
      filters: {'id': 'eq.$definitionId'},
    );

    if (result.isEmpty) return null;
    return AchievementDefinition.fromJson(result.first);
  }

  /// Get a definition by code
  Future<AchievementDefinition?> getDefinitionByCode(
    String code, {
    String? teamId,
  }) async {
    final filters = <String, String>{'code': 'eq.$code'};
    if (teamId != null) {
      filters['team_id'] = 'eq.$teamId';
    } else {
      filters['team_id'] = 'is.null';
    }

    final result = await _db.client.select(
      'achievement_definitions',
      filters: filters,
    );

    if (result.isEmpty) return null;
    return AchievementDefinition.fromJson(result.first);
  }

  /// Create a new achievement definition
  Future<AchievementDefinition> createDefinition({
    String? teamId,
    required String code,
    required String name,
    String? description,
    String? icon,
    String? color,
    AchievementTier tier = AchievementTier.bronze,
    required AchievementCategory category,
    required AchievementCriteria criteria,
    int bonusPoints = 0,
    bool isActive = true,
    bool isSecret = false,
    bool isRepeatable = false,
    int? repeatCooldownDays,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.client.insert('achievement_definitions', {
      'id': id,
      'team_id': teamId,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'tier': tier.value,
      'category': category.value,
      'criteria': jsonEncode(criteria.toJson()),
      'bonus_points': bonusPoints,
      'is_active': isActive,
      'is_secret': isSecret,
      'is_repeatable': isRepeatable,
      'repeat_cooldown_days': repeatCooldownDays,
    });

    return AchievementDefinition(
      id: id,
      teamId: teamId,
      code: code,
      name: name,
      description: description,
      icon: icon,
      color: color,
      tier: tier,
      category: category,
      criteria: criteria,
      bonusPoints: bonusPoints,
      isActive: isActive,
      isSecret: isSecret,
      isRepeatable: isRepeatable,
      repeatCooldownDays: repeatCooldownDays,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update an achievement definition
  Future<AchievementDefinition?> updateDefinition({
    required String definitionId,
    String? name,
    String? description,
    String? icon,
    String? color,
    AchievementTier? tier,
    AchievementCriteria? criteria,
    int? bonusPoints,
    bool? isActive,
    bool? isSecret,
    bool? isRepeatable,
    int? repeatCooldownDays,
    bool clearDescription = false,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (clearDescription) {
      updates['description'] = null;
    } else if (description != null) {
      updates['description'] = description;
    }
    if (icon != null) updates['icon'] = icon;
    if (color != null) updates['color'] = color;
    if (tier != null) updates['tier'] = tier.value;
    if (criteria != null) updates['criteria'] = jsonEncode(criteria.toJson());
    if (bonusPoints != null) updates['bonus_points'] = bonusPoints;
    if (isActive != null) updates['is_active'] = isActive;
    if (isSecret != null) updates['is_secret'] = isSecret;
    if (isRepeatable != null) updates['is_repeatable'] = isRepeatable;
    if (repeatCooldownDays != null) {
      updates['repeat_cooldown_days'] = repeatCooldownDays;
    }

    await _db.client.update(
      'achievement_definitions',
      updates,
      filters: {'id': 'eq.$definitionId'},
    );

    return getDefinitionById(definitionId);
  }

  /// Delete an achievement definition
  Future<void> deleteDefinition(String definitionId) async {
    await _db.client.delete(
      'achievement_definitions',
      filters: {'id': 'eq.$definitionId'},
    );
  }

  /// Get team ID for a definition (for authorization checks)
  Future<String?> getTeamIdForDefinition(String definitionId) async {
    final result = await _db.client.select(
      'achievement_definitions',
      select: 'team_id',
      filters: {'id': 'eq.$definitionId'},
    );

    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
  }
}
