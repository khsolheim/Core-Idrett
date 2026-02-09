import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/mini_activity.dart';
import '../helpers/parsing_helpers.dart';

class MiniActivityTemplateService {
  final Database _db;
  final _uuid = const Uuid();

  MiniActivityTemplateService(this._db);

  Future<List<ActivityTemplate>> getTemplatesForTeam(String teamId) async {
    final result = await _db.client.select(
      'activity_templates',
      filters: {'team_id': 'eq.$teamId'},
      order: 'name.asc',
    );
    return result.map((row) => ActivityTemplate.fromJson(row)).toList();
  }

  Future<ActivityTemplate> createTemplate({
    required String teamId,
    required String name,
    required String type,
    int defaultPoints = 1,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    int winPoints = 3,
    int drawPoints = 1,
    int lossPoints = 0,
    String? leaderboardId,
  }) async {
    final id = _uuid.v4();
    await _db.client.insert('activity_templates', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'type': type,
      'default_points': defaultPoints,
      'description': description,
      'instructions': instructions,
      'sport_type': sportType,
      'suggested_rules': suggestedRules,
      'win_points': winPoints,
      'draw_points': drawPoints,
      'loss_points': lossPoints,
    });

    return ActivityTemplate(
      id: id,
      teamId: teamId,
      name: name,
      type: type,
      defaultPoints: defaultPoints,
      createdAt: DateTime.now(),
      description: description,
      instructions: instructions,
      sportType: sportType,
      suggestedRules: suggestedRules,
      winPoints: winPoints,
      drawPoints: drawPoints,
      lossPoints: lossPoints,
      leaderboardId: leaderboardId,
    );
  }

  Future<ActivityTemplate?> updateTemplate({
    required String templateId,
    String? name,
    String? type,
    int? defaultPoints,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    bool? isFavorite,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (type != null) updates['type'] = type;
    if (defaultPoints != null) updates['default_points'] = defaultPoints;
    if (description != null) updates['description'] = description;
    if (instructions != null) updates['instructions'] = instructions;
    if (sportType != null) updates['sport_type'] = sportType;
    if (suggestedRules != null) updates['suggested_rules'] = suggestedRules;
    if (isFavorite != null) updates['is_favorite'] = isFavorite;
    if (winPoints != null) updates['win_points'] = winPoints;
    if (drawPoints != null) updates['draw_points'] = drawPoints;
    if (lossPoints != null) updates['loss_points'] = lossPoints;

    if (updates.isEmpty) return null;

    await _db.client.update(
      'activity_templates',
      updates,
      filters: {'id': 'eq.$templateId'},
    );

    final result = await _db.client.select(
      'activity_templates',
      filters: {'id': 'eq.$templateId'},
    );

    if (result.isEmpty) return null;
    return ActivityTemplate.fromJson(result.first);
  }

  Future<void> toggleTemplateFavorite(String templateId) async {
    final result = await _db.client.select(
      'activity_templates',
      select: 'is_favorite',
      filters: {'id': 'eq.$templateId'},
    );

    if (result.isEmpty) return;
    final currentFavorite = safeBool(result.first, 'is_favorite', defaultValue: false);

    await _db.client.update(
      'activity_templates',
      {'is_favorite': !currentFavorite},
      filters: {'id': 'eq.$templateId'},
    );
  }

  Future<String?> getTeamIdForTemplate(String templateId) async {
    final result = await _db.client.select(
      'activity_templates',
      select: 'team_id',
      filters: {'id': 'eq.$templateId'},
    );
    if (result.isEmpty) return null;
    return safeStringNullable(result.first, 'team_id');
  }

  Future<void> deleteTemplate(String templateId) async {
    await _db.client.delete(
      'activity_templates',
      filters: {'id': 'eq.$templateId'},
    );
  }
}
