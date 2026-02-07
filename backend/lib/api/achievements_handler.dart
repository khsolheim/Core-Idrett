import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/achievement_service.dart';
import '../services/team_service.dart';
import '../models/achievement.dart';
import 'achievement_awards_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class AchievementsHandler {
  final AchievementService _achievementService;
  final TeamService _teamService;

  AchievementsHandler(this._achievementService, this._teamService);

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
        return resp.forbidden('Ikke autorisert');
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

      final definitions = await _achievementService.getDefinitions(
        teamId,
        includeGlobal: includeGlobal,
        activeOnly: activeOnly,
        category: category,
      );

      return resp.ok({
        'definitions': definitions.map((d) => d.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente achievements: $e');
    }
  }

  Future<Response> _createDefinition(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan opprette achievements');
      }

      final body = await parseBody(request);

      final code = body['code'] as String?;
      final name = body['name'] as String?;
      final categoryStr = body['category'] as String?;
      final criteriaJson = body['criteria'] as Map<String, dynamic>?;

      if (code == null || name == null || categoryStr == null || criteriaJson == null) {
        return resp.badRequest('code, name, category og criteria er påkrevd');
      }

      final category = AchievementCategory.fromString(categoryStr);
      final criteria = AchievementCriteria.fromJson(criteriaJson);

      AchievementTier tier = AchievementTier.bronze;
      if (body['tier'] != null) {
        tier = AchievementTier.fromString(body['tier'] as String);
      }

      final definition = await _achievementService.createDefinition(
        teamId: teamId,
        code: code,
        name: name,
        description: body['description'] as String?,
        icon: body['icon'] as String?,
        color: body['color'] as String?,
        tier: tier,
        category: category,
        criteria: criteria,
        bonusPoints: body['bonus_points'] as int? ?? 0,
        isActive: body['is_active'] as bool? ?? true,
        isSecret: body['is_secret'] as bool? ?? false,
        isRepeatable: body['is_repeatable'] as bool? ?? false,
        repeatCooldownDays: body['repeat_cooldown_days'] as int?,
      );

      return resp.ok(definition.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette achievement: $e');
    }
  }

  Future<Response> _getDefinitionById(
      Request request, String definitionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final definition =
          await _achievementService.getDefinitionById(definitionId);

      if (definition == null) {
        return resp.notFound('Achievement ikke funnet');
      }

      return resp.ok(definition.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente achievement: $e');
    }
  }

  Future<Response> _updateDefinition(
      Request request, String definitionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final teamId =
          await _achievementService.getTeamIdForDefinition(definitionId);

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
            body['criteria'] as Map<String, dynamic>);
      }

      final definition = await _achievementService.updateDefinition(
        definitionId: definitionId,
        name: body['name'] as String?,
        description: body['description'] as String?,
        icon: body['icon'] as String?,
        color: body['color'] as String?,
        tier: tier,
        criteria: criteria,
        bonusPoints: body['bonus_points'] as int?,
        isActive: body['is_active'] as bool?,
        isSecret: body['is_secret'] as bool?,
        isRepeatable: body['is_repeatable'] as bool?,
        repeatCooldownDays: body['repeat_cooldown_days'] as int?,
        clearDescription: body['clear_description'] == true,
      );

      if (definition == null) {
        return resp.notFound('Achievement ikke funnet');
      }

      return resp.ok(definition.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere achievement: $e');
    }
  }

  Future<Response> _deleteDefinition(
      Request request, String definitionId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final teamId =
          await _achievementService.getTeamIdForDefinition(definitionId);

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

      await _achievementService.deleteDefinition(definitionId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette achievement: $e');
    }
  }
}
