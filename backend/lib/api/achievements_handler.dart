import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/team_service.dart';
import '../models/achievement.dart';

class AchievementsHandler {
  final AchievementService _achievementService;
  final AuthService _authService;
  final TeamService _teamService;

  AchievementsHandler(
    this._achievementService,
    this._authService,
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

  Future<String?> _getUserId(Request request) async {
    final authHeader = request.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    final token = authHeader.substring(7);
    final user = await _authService.getUserFromToken(token);
    return user?.id;
  }

  Future<bool> _isTeamAdmin(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    if (team == null) return false;
    return team['user_is_admin'] == true || team['user_role'] == 'admin';
  }

  // ============ DEFINITIONS ============

  Future<Response> _getDefinitions(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
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

      return Response.ok(
        jsonEncode({
          'definitions': definitions.map((d) => d.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente achievements: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createDefinition(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan opprette achievements'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

      final code = body['code'] as String?;
      final name = body['name'] as String?;
      final categoryStr = body['category'] as String?;
      final criteriaJson = body['criteria'] as Map<String, dynamic>?;

      if (code == null || name == null || categoryStr == null || criteriaJson == null) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'code, name, category og criteria er påkrevd',
          }),
          headers: {'Content-Type': 'application/json'},
        );
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

      return Response.ok(
        jsonEncode(definition.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette achievement: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getDefinitionById(
      Request request, String definitionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final definition =
          await _achievementService.getDefinitionById(definitionId);

      if (definition == null) {
        return Response.notFound(
          jsonEncode({'error': 'Achievement ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(definition.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente achievement: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _updateDefinition(
      Request request, String definitionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId =
          await _achievementService.getTeamIdForDefinition(definitionId);

      // Global achievements can't be modified by team admins
      if (teamId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Kan ikke endre globale achievements'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan oppdatere achievements'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

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
        return Response.notFound(
          jsonEncode({'error': 'Achievement ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(definition.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke oppdatere achievement: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteDefinition(
      Request request, String definitionId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId =
          await _achievementService.getTeamIdForDefinition(definitionId);

      if (teamId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Kan ikke slette globale achievements'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan slette achievements'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _achievementService.deleteDefinition(definitionId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette achievement: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ============ USER ACHIEVEMENTS ============

  Future<Response> _getUserAchievements(
      Request request, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final achievements = await _achievementService.getUserAchievements(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode({
          'achievements': achievements.map((a) => a.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente brukers achievements: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserProgress(
      Request request, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final progress = await _achievementService.getUserProgress(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode({
          'progress': progress.map((p) => p.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body:
            jsonEncode({'error': 'Kunne ikke hente achievement-progress: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserSummary(
      Request request, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final summary = await _achievementService.getUserAchievementsSummary(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode(summary),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente achievement-sammendrag: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _awardAchievement(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kun admin kan tildele achievements'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
      final targetUserId = body['user_id'] as String?;
      final achievementId = body['achievement_id'] as String?;

      if (targetUserId == null || achievementId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id og achievement_id er påkrevd'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final achievement = await _achievementService.awardAchievement(
        userId: targetUserId,
        achievementId: achievementId,
        teamId: teamId,
        seasonId: body['season_id'] as String?,
        pointsAwarded: body['points_awarded'] as int?,
        triggerReference: body['trigger_reference'] as Map<String, dynamic>?,
      );

      return Response.ok(
        jsonEncode(achievement.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke tildele achievement: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _checkAndAwardAchievements(
      Request request, String teamId, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Only admin can trigger check for other users
      if (targetUserId != userId && !await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode(
              {'error': 'Kun admin kan sjekke achievements for andre'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = await request.readAsString();
      Map<String, dynamic>? context;
      if (body.isNotEmpty) {
        final parsed = jsonDecode(body);
        context = parsed['context'] as Map<String, dynamic>?;
      }

      final seasonId = request.url.queryParameters['season_id'];

      final awarded = await _achievementService.checkAndAwardAchievements(
        targetUserId,
        teamId,
        seasonId: seasonId,
        context: context,
      );

      return Response.ok(
        jsonEncode({
          'awarded': awarded.map((a) => a.toJson()).toList(),
          'count': awarded.length,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke sjekke achievements: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ============ TEAM ACHIEVEMENTS ============

  Future<Response> _getTeamRecentAchievements(
      Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final seasonId = request.url.queryParameters['season_id'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 10 : 10;

      final achievements = await _achievementService.getTeamRecentAchievements(
        teamId,
        seasonId: seasonId,
        limit: limit,
      );

      return Response.ok(
        jsonEncode({
          'achievements': achievements.map((a) => a.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente nylige achievements: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getTeamAchievementCounts(
      Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final team = await _teamService.getTeamById(teamId, userId);
      if (team == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ingen tilgang til dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final seasonId = request.url.queryParameters['season_id'];

      final counts = await _achievementService.getTeamAchievementCounts(
        teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode(counts),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente achievement-statistikk: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
