import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/achievement_service.dart';
import '../services/achievement_progress_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class AchievementAwardsHandler {
  final AchievementService _achievementService;
  final AchievementProgressService _progressService;
  final TeamService _teamService;

  AchievementAwardsHandler(
    this._achievementService,
    this._progressService,
    this._teamService,
  );

  Router get router {
    final router = Router();

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

  Future<Response> _getUserAchievements(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
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
      return resp.serverError('Kunne ikke hente brukers achievements');
    }
  }

  Future<Response> _getUserProgress(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final progress = await _progressService.getUserProgress(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return resp.ok({
        'progress': progress.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente achievement-progress');
    }
  }

  Future<Response> _getUserSummary(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
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
      return resp.serverError('Kunne ikke hente achievement-sammendrag');
    }
  }

  Future<Response> _awardAchievement(Request request, String teamId) async {
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
      return resp.serverError('Kunne ikke tildele achievement');
    }
  }

  Future<Response> _checkAndAwardAchievements(
      Request request, String teamId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

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

      final awarded = await _progressService.checkAndAwardAchievements(
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
      return resp.serverError('Kunne ikke sjekke achievements');
    }
  }

  Future<Response> _getTeamRecentAchievements(
      Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
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
      return resp.serverError('Kunne ikke hente nylige achievements');
    }
  }

  Future<Response> _getTeamAchievementCounts(
      Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
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
      return resp.serverError('Kunne ikke hente achievement-statistikk');
    }
  }
}
