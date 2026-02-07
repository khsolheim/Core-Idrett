import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/points_config_service.dart' show PointsConfigService;
import '../services/team_service.dart';
import 'points_adjustments_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class PointsConfigHandler {
  final PointsConfigService _pointsConfigService;
  final TeamService _teamService;

  PointsConfigHandler(
    this._pointsConfigService,
    this._teamService,
  );

  Router get router {
    final router = Router();

    // Points config routes
    router.get('/teams/<teamId>/config', _getConfig);
    router.post('/teams/<teamId>/config', _createOrUpdateConfig);
    router.patch('/config/<configId>', _updateConfig);
    router.delete('/config/<configId>', _deleteConfig);

    // Attendance points routes
    router.get('/teams/<teamId>/attendance', _getTeamAttendancePoints);
    router.get('/users/<userId>/attendance', _getUserAttendancePoints);
    router.post('/teams/<teamId>/award/<instanceId>', _awardAttendancePoints);

    // Opt-out routes
    router.post('/teams/<teamId>/opt-out', _setOptOut);
    router.get('/teams/<teamId>/opt-out/<userId>', _getOptOut);

    // Mount manual adjustment routes
    final adjustmentsHandler = PointsAdjustmentsHandler(
      _pointsConfigService,
      _teamService,
    );
    router.mount('/', adjustmentsHandler.router.call);

    return router;
  }

  Future<Response> _getConfig(Request request, String teamId) async {
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
      final config = await _pointsConfigService.getOrCreateConfig(
        teamId,
        seasonId: seasonId,
      );

      return resp.ok(config.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente poengkonfigurasjon: $e');
    }
  }

  Future<Response> _createOrUpdateConfig(Request request, String teamId) async {
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
        return resp.forbidden('Kun admin kan endre poengkonfigurasjon');
      }

      final body = await parseBody(request);

      // Check if config exists
      final existing = await _pointsConfigService.getConfig(
        teamId,
        seasonId: body['season_id'] as String?,
      );

      if (existing != null) {
        // Update existing
        final config = await _pointsConfigService.updateConfig(
          configId: existing.id,
          trainingPoints: body['training_points'] as int?,
          matchPoints: body['match_points'] as int?,
          socialPoints: body['social_points'] as int?,
          trainingWeight: (body['training_weight'] as num?)?.toDouble(),
          matchWeight: (body['match_weight'] as num?)?.toDouble(),
          socialWeight: (body['social_weight'] as num?)?.toDouble(),
          competitionWeight: (body['competition_weight'] as num?)?.toDouble(),
          miniActivityDistribution: body['mini_activity_distribution'] as String?,
          autoAwardAttendance: body['auto_award_attendance'] as bool?,
          visibility: body['visibility'] as String?,
          allowOptOut: body['allow_opt_out'] as bool?,
          requireAbsenceReason: body['require_absence_reason'] as bool?,
          requireAbsenceApproval: body['require_absence_approval'] as bool?,
          excludeValidAbsenceFromPercentage:
              body['exclude_valid_absence_from_percentage'] as bool?,
          newPlayerStartMode: body['new_player_start_mode'] as String?,
        );

        return resp.ok(config?.toJson());
      }

      // Create new
      final config = await _pointsConfigService.createConfig(
        teamId: teamId,
        seasonId: body['season_id'] as String?,
        trainingPoints: body['training_points'] as int? ?? 1,
        matchPoints: body['match_points'] as int? ?? 2,
        socialPoints: body['social_points'] as int? ?? 1,
        trainingWeight: (body['training_weight'] as num?)?.toDouble() ?? 1.0,
        matchWeight: (body['match_weight'] as num?)?.toDouble() ?? 1.5,
        socialWeight: (body['social_weight'] as num?)?.toDouble() ?? 0.5,
        competitionWeight:
            (body['competition_weight'] as num?)?.toDouble() ?? 1.0,
        miniActivityDistribution:
            body['mini_activity_distribution'] as String? ?? 'top_three',
        autoAwardAttendance: body['auto_award_attendance'] as bool? ?? true,
        visibility: body['visibility'] as String? ?? 'all',
        allowOptOut: body['allow_opt_out'] as bool? ?? false,
        requireAbsenceReason: body['require_absence_reason'] as bool? ?? false,
        requireAbsenceApproval:
            body['require_absence_approval'] as bool? ?? false,
        excludeValidAbsenceFromPercentage:
            body['exclude_valid_absence_from_percentage'] as bool? ?? true,
        newPlayerStartMode:
            body['new_player_start_mode'] as String? ?? 'from_join',
      );

      return resp.ok(config.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette/oppdatere konfigurasjon: $e');
    }
  }

  Future<Response> _updateConfig(Request request, String configId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final existingConfig = await _pointsConfigService.getConfigById(configId);
      if (existingConfig == null) {
        return resp.notFound('Konfigurasjon ikke funnet');
      }

      final team = await requireTeamMember(_teamService, existingConfig.teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan endre poengkonfigurasjon');
      }

      final body = await parseBody(request);

      final config = await _pointsConfigService.updateConfig(
        configId: configId,
        trainingPoints: body['training_points'] as int?,
        matchPoints: body['match_points'] as int?,
        socialPoints: body['social_points'] as int?,
        trainingWeight: (body['training_weight'] as num?)?.toDouble(),
        matchWeight: (body['match_weight'] as num?)?.toDouble(),
        socialWeight: (body['social_weight'] as num?)?.toDouble(),
        competitionWeight: (body['competition_weight'] as num?)?.toDouble(),
        miniActivityDistribution: body['mini_activity_distribution'] as String?,
        autoAwardAttendance: body['auto_award_attendance'] as bool?,
        visibility: body['visibility'] as String?,
        allowOptOut: body['allow_opt_out'] as bool?,
        requireAbsenceReason: body['require_absence_reason'] as bool?,
        requireAbsenceApproval: body['require_absence_approval'] as bool?,
        excludeValidAbsenceFromPercentage:
            body['exclude_valid_absence_from_percentage'] as bool?,
        newPlayerStartMode: body['new_player_start_mode'] as String?,
      );

      if (config == null) {
        return resp.notFound('Konfigurasjon ikke funnet');
      }

      return resp.ok(config.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere konfigurasjon: $e');
    }
  }

  Future<Response> _deleteConfig(Request request, String configId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final existingConfig = await _pointsConfigService.getConfigById(configId);
      if (existingConfig == null) {
        return resp.notFound('Konfigurasjon ikke funnet');
      }

      final team = await requireTeamMember(_teamService, existingConfig.teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      if (!isAdmin(team)) {
        return resp.forbidden('Kun admin kan slette poengkonfigurasjon');
      }

      await _pointsConfigService.deleteConfig(configId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette konfigurasjon: $e');
    }
  }

  Future<Response> _getTeamAttendancePoints(
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

      final targetUserId =
          request.url.queryParameters['user_id'] ?? userId;
      final seasonId = request.url.queryParameters['season_id'];

      final stats = await _pointsConfigService.getUserAttendanceStats(
        targetUserId,
        teamId,
        seasonId: seasonId,
      );

      return resp.ok(stats);
    } catch (e) {
      return resp.serverError('Kunne ikke hente oppmøtepoeng: $e');
    }
  }

  Future<Response> _getUserAttendancePoints(
      Request request, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final teamId = request.url.queryParameters['team_id'];
      final seasonId = request.url.queryParameters['season_id'];

      final points = await _pointsConfigService.getUserAttendancePoints(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return resp.ok({
        'points': points.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente oppmøtepoeng: $e');
    }
  }

  Future<Response> _awardAttendancePoints(
      Request request, String teamId, String instanceId) async {
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
        return resp.forbidden('Kun admin kan tildele poeng');
      }

      final body = await parseBody(request);
      final targetUserId = body['user_id'] as String;
      final activityType = body['activity_type'] as String;
      final basePoints = body['base_points'] as int;
      final weightedPoints = (body['weighted_points'] as num).toDouble();

      final points = await _pointsConfigService.awardAttendancePoints(
        teamId: teamId,
        userId: targetUserId,
        instanceId: instanceId,
        activityType: activityType,
        seasonId: body['season_id'] as String?,
        basePoints: basePoints,
        weightedPoints: weightedPoints,
      );

      return resp.ok(points.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke tildele poeng: $e');
    }
  }

  Future<Response> _setOptOut(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final body = await parseBody(request);
      final targetUserId = body['user_id'] as String? ?? userId;
      final optOut = body['opt_out'] as bool? ?? false;

      // Only allow setting own opt-out unless admin
      if (targetUserId != userId && !isAdmin(team)) {
        return resp.forbidden('Kan kun endre egen opt-out status');
      }

      // Check if opt-out is allowed
      final config = await _pointsConfigService.getConfig(teamId);
      if (config != null && !config.allowOptOut && optOut) {
        return resp.forbidden('Opt-out er ikke aktivert for dette laget');
      }

      await _pointsConfigService.setOptOut(targetUserId, teamId, optOut);

      return resp.ok({'success': true, 'opt_out': optOut});
    } catch (e) {
      return resp.serverError('Kunne ikke endre opt-out status: $e');
    }
  }

  Future<Response> _getOptOut(
      Request request, String teamId, String targetUserId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Ingen tilgang til dette laget');
      }

      final optOut = await _pointsConfigService.hasOptedOut(targetUserId, teamId);

      return resp.ok({'opt_out': optOut});
    } catch (e) {
      return resp.serverError('Kunne ikke hente opt-out status: $e');
    }
  }
}
