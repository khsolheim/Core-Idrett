import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/achievement_definition_service.dart';
import '../services/achievement_service.dart';
import '../services/achievement_progress_service.dart';
import '../services/team_service.dart';
import '../models/achievement.dart';
import 'achievement_awards_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class AchievementsHandler {
  final AchievementDefinitionService _definitionService;
  final AchievementService _achievementService;
  final AchievementProgressService _progressService;
  final TeamService _teamService;

  AchievementsHandler(
    this._definitionService,
    this._achievementService,
    this._progressService,
    this._teamService,
  );

  Router get router {
    final router = Router();

    // Definition routes
    router.get('/teams/<teamId>/definitions', _getDefinitions);
    router.post('/teams/<teamId>/definitions', _createDefinition);
    router.get('/definitions/<definitionId>', _getDefinitionById);
    router.patch('/definitions/<definitionId>', _updateDefinition);
    router.delete('/definitions/<definitionId>', _deleteDefinition);

    // Mount user & team achievement routes
    final awardsHandler = AchievementAwardsHandler(
      _achievementService,
      _progressService,
      _teamService,
    );
    router.mount('/', awardsHandler.router.call);

    return router;
  }

  // ============ DEFINITIONS ============

  Future<Response> _getDefinitions(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final includeGlobal =
          request.url.queryParameters['include_global'] != 'false';
      final activeOnly = request.url.queryParameters['active_only'] != 'false';

      AchievementCategory? category;
      final categoryStr = request.url.queryParameters['category'];
      if (categoryStr != null) {
        category = AchievementCategory.fromString(categoryStr);
      }

      final definitions = await _definitionService.getDefinitions(
        teamId,
        includeGlobal: includeGlobal,
        activeOnly: activeOnly,
        category: category,
      );

      return resp.ok({
        'definitions': definitions.map((d) => d.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente achievements');
    }
  }

  Future<Response> _createDefinition(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan opprette achievements');
      }

      final body = await parseBody(request);

      final code = safeStringNullable(body, 'code');
      final name = safeStringNullable(body, 'name');
      final categoryStr = safeStringNullable(body, 'category');
      final criteriaJson = safeMapNullable(body, 'criteria');

      if (code == null || name == null || categoryStr == null || criteriaJson == null) {
        return resp.badRequest('code, name, category og criteria er påkrevd');
      }

      final category = AchievementCategory.fromString(categoryStr);
      final criteria = AchievementCriteria.fromJson(criteriaJson);

      AchievementTier tier = AchievementTier.bronze;
      if (body['tier'] != null) {
        tier = AchievementTier.fromString(body['tier'] as String);
      }

      final definition = await _definitionService.createDefinition(
        teamId: teamId,
        code: code,
        name: name,
        description: safeStringNullable(body, 'description'),
        icon: safeStringNullable(body, 'icon'),
        color: safeStringNullable(body, 'color'),
        tier: tier,
        category: category,
        criteria: criteria,
        bonusPoints: safeIntNullable(body, 'bonus_points') ?? 0,
        isActive: safeBool(body, 'is_active', defaultValue: true),
        isSecret: safeBool(body, 'is_secret', defaultValue: false),
        isRepeatable: safeBool(body, 'is_repeatable', defaultValue: false),
        repeatCooldownDays: safeIntNullable(body, 'repeat_cooldown_days'),
      );

      return resp.ok(definition.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette achievement');
    }
  }

  Future<Response> _getDefinitionById(
      Request request, String definitionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final definition =
          await _definitionService.getDefinitionById(definitionId);

      if (definition == null) {
        return resp.notFound('Achievement ikke funnet');
      }

      return resp.ok(definition.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente achievement');
    }
  }

  Future<Response> _updateDefinition(
      Request request, String definitionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId =
          await _definitionService.getTeamIdForDefinition(definitionId);

      if (teamId == null) {
        return resp.forbidden('Kan ikke endre globale achievements');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan oppdatere achievements');
      }

      final body = await parseBody(request);

      AchievementTier? tier;
      if (body['tier'] != null) {
        tier = AchievementTier.fromString(body['tier'] as String);
      }

      AchievementCriteria? criteria;
      if (body['criteria'] != null) {
        criteria = AchievementCriteria.fromJson(
            safeMap(body, 'criteria'));
      }

      final definition = await _definitionService.updateDefinition(
        definitionId: definitionId,
        name: safeStringNullable(body, 'name'),
        description: safeStringNullable(body, 'description'),
        icon: safeStringNullable(body, 'icon'),
        color: safeStringNullable(body, 'color'),
        tier: tier,
        criteria: criteria,
        bonusPoints: safeIntNullable(body, 'bonus_points'),
        isActive: safeBoolNullable(body, 'is_active'),
        isSecret: safeBoolNullable(body, 'is_secret'),
        isRepeatable: safeBoolNullable(body, 'is_repeatable'),
        repeatCooldownDays: safeIntNullable(body, 'repeat_cooldown_days'),
        clearDescription: body['clear_description'] == true,
      );

      if (definition == null) {
        return resp.notFound('Achievement ikke funnet');
      }

      return resp.ok(definition.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere achievement');
    }
  }

  Future<Response> _deleteDefinition(
      Request request, String definitionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId =
          await _definitionService.getTeamIdForDefinition(definitionId);

      if (teamId == null) {
        return resp.forbidden('Kan ikke slette globale achievements');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan slette achievements');
      }

      await _definitionService.deleteDefinition(definitionId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette achievement');
    }
  }
}
