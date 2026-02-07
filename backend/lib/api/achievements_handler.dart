import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/achievement_service.dart';
import '../services/team_service.dart';
import '../models/achievement.dart';
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

    // User achievement routes
    router.get('/users/<userId>', _getUserAchievements);
    router.get('/users/<userId>/progress', _getUserProgress);
    router.get('/users/<userId>/summary', _getUserSummary);
    router.post('/teams/<teamId>/award', _awardAchievement);
    router.post('/teams/<teamId>/check/<userId>', _checkAndAwardAchievements);

    // Team achievement routes
    router.get('/teams/<teamId>/recent', _getTeamRecentAchievements);
    router.get('/teams/<teamId>/counts', _getTeamAchievementCounts);

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

      // Global achievements can't be modified by team admins
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

  // ============ USER ACHIEVEMENTS ============

  Future<Response> _getUserAchievements(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final achievements = await _achievementService.getUserAchievements(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return resp.ok({
        'achievements': achievements.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente brukers achievements: $e');
    }
  }

  Future<Response> _getUserProgress(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final progress = await _achievementService.getUserProgress(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return resp.ok({
        'progress': progress.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente achievement-progress: $e');
    }
  }

  Future<Response> _getUserSummary(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final summary = await _achievementService.getUserAchievementsSummary(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return resp.ok(summary);
    } catch (e) {
      return resp.serverError('Kunne ikke hente achievement-sammendrag: $e');
    }
  }

  Future<Response> _awardAchievement(Request request, String teamId) async {
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
        return resp.forbidden('Kun admin kan tildele achievements');
      }

      final body = await parseBody(request);
      final targetUserId = body['user_id'] as String?;
      final achievementId = body['achievement_id'] as String?;

      if (targetUserId == null || achievementId == null) {
        return resp.badRequest('user_id og achievement_id er påkrevd');
      }

      final achievement = await _achievementService.awardAchievement(
        userId: targetUserId,
        achievementId: achievementId,
        teamId: teamId,
        seasonId: body['season_id'] as String?,
        pointsAwarded: body['points_awarded'] as int?,
        triggerReference: body['trigger_reference'] as Map<String, dynamic>?,
      );

      return resp.ok(achievement.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke tildele achievement: $e');
    }
  }

  Future<Response> _checkAndAwardAchievements(
      Request request, String teamId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      // Only admin can trigger check for other users
      if (targetUserId != userId) {
        final team = await requireTeamMember(_teamService, teamId, userId);
        if (team == null || !isAdmin(team)) {
          return resp.forbidden('Kun admin kan sjekke achievements for andre');
        }
      }

      Map<String, dynamic>? context;
      try {
        final parsed = await parseBody(request);
        context = parsed['context'] as Map<String, dynamic>?;
      } catch (_) {
        // Body is optional
      }

      final seasonId = request.url.queryParameters['season_id'];

      final awarded = await _achievementService.checkAndAwardAchievements(
        targetUserId,
        teamId,
        seasonId: seasonId,
        context: context,
      );

      return resp.ok({
        'awarded': awarded.map((a) => a.toJson()).toList(),
        'count': awarded.length,
      });
    } catch (e) {
      return resp.serverError('Kunne ikke sjekke achievements: $e');
    }
  }

  // ============ TEAM ACHIEVEMENTS ============

  Future<Response> _getTeamRecentAchievements(
      Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasonId = request.url.queryParameters['season_id'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 10 : 10;

      final achievements = await _achievementService.getTeamRecentAchievements(
        teamId,
        seasonId: seasonId,
        limit: limit,
      );

      return resp.ok({
        'achievements': achievements.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente nylige achievements: $e');
    }
  }

  Future<Response> _getTeamAchievementCounts(
      Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.forbidden('Ikke autorisert');
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final seasonId = request.url.queryParameters['season_id'];

      final counts = await _achievementService.getTeamAchievementCounts(
        teamId,
        seasonId: seasonId,
      );

      return resp.ok(counts);
    } catch (e) {
      return resp.serverError('Kunne ikke hente achievement-statistikk: $e');
    }
  }
}
