import 'helpers/request_helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/points_config_service.dart';
import '../services/team_service.dart';
import 'points_adjustments_handler.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

import '../helpers/parsing_helpers.dart';
class PointsConfigHandler {
  final PointsConfigCrudService _crudService;
  final AttendancePointsService _attendanceService;
  final ManualAdjustmentService _adjustmentService;
  final TeamService _teamService;

  PointsConfigHandler(
    this._crudService,
    this._attendanceService,
    this._adjustmentService,
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
      _adjustmentService,
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
      final config = await _crudService.getOrCreateConfig(
        teamId,
        seasonId: seasonId,
      );

      return resp.ok(config.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke hente poengkonfigurasjon');
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
      final existing = await _crudService.getConfig(
        teamId,
        seasonId: safeStringNullable(body, 'season_id'),
      );

      if (existing != null) {
        // Update existing
        final config = await _crudService.updateConfig(
          configId: existing.id,
          trainingPoints: safeIntNullable(body, 'training_points'),
          matchPoints: safeIntNullable(body, 'match_points'),
          socialPoints: safeIntNullable(body, 'social_points'),
          trainingWeight: (safeNumNullable(body, 'training_weight'))?.toDouble(),
          matchWeight: (safeNumNullable(body, 'match_weight'))?.toDouble(),
          socialWeight: (safeNumNullable(body, 'social_weight'))?.toDouble(),
          competitionWeight: (safeNumNullable(body, 'competition_weight'))?.toDouble(),
          miniActivityDistribution: safeStringNullable(body, 'mini_activity_distribution'),
          autoAwardAttendance: safeBoolNullable(body, 'auto_award_attendance'),
          visibility: safeStringNullable(body, 'visibility'),
          allowOptOut: safeBoolNullable(body, 'allow_opt_out'),
          requireAbsenceReason: safeBoolNullable(body, 'require_absence_reason'),
          requireAbsenceApproval: safeBoolNullable(body, 'require_absence_approval'),
          excludeValidAbsenceFromPercentage:
              safeBoolNullable(body, 'exclude_valid_absence_from_percentage'),
          newPlayerStartMode: safeStringNullable(body, 'new_player_start_mode'),
        );

        return resp.ok(config?.toJson());
      }

      // Create new
      final config = await _crudService.createConfig(
        teamId: teamId,
        seasonId: safeStringNullable(body, 'season_id'),
        trainingPoints: safeIntNullable(body, 'training_points') ?? 1,
        matchPoints: safeIntNullable(body, 'match_points') ?? 2,
        socialPoints: safeIntNullable(body, 'social_points') ?? 1,
        trainingWeight: (safeNumNullable(body, 'training_weight'))?.toDouble() ?? 1.0,
        matchWeight: (safeNumNullable(body, 'match_weight'))?.toDouble() ?? 1.5,
        socialWeight: (safeNumNullable(body, 'social_weight'))?.toDouble() ?? 0.5,
        competitionWeight:
            (safeNumNullable(body, 'competition_weight'))?.toDouble() ?? 1.0,
        miniActivityDistribution:
            safeStringNullable(body, 'mini_activity_distribution') ?? 'top_three',
        autoAwardAttendance: safeBool(body, 'auto_award_attendance', defaultValue: true),
        visibility: safeStringNullable(body, 'visibility') ?? 'all',
        allowOptOut: safeBool(body, 'allow_opt_out', defaultValue: false),
        requireAbsenceReason: safeBool(body, 'require_absence_reason', defaultValue: false),
        requireAbsenceApproval:
            safeBool(body, 'require_absence_approval', defaultValue: false),
        excludeValidAbsenceFromPercentage:
            safeBool(body, 'exclude_valid_absence_from_percentage', defaultValue: true),
        newPlayerStartMode:
            safeStringNullable(body, 'new_player_start_mode') ?? 'from_join',
      );

      return resp.ok(config.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke opprette/oppdatere konfigurasjon');
    }
  }

  Future<Response> _updateConfig(Request request, String configId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final existingConfig = await _crudService.getConfigById(configId);
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

      final config = await _crudService.updateConfig(
        configId: configId,
        trainingPoints: safeIntNullable(body, 'training_points'),
        matchPoints: safeIntNullable(body, 'match_points'),
        socialPoints: safeIntNullable(body, 'social_points'),
        trainingWeight: (safeNumNullable(body, 'training_weight'))?.toDouble(),
        matchWeight: (safeNumNullable(body, 'match_weight'))?.toDouble(),
        socialWeight: (safeNumNullable(body, 'social_weight'))?.toDouble(),
        competitionWeight: (safeNumNullable(body, 'competition_weight'))?.toDouble(),
        miniActivityDistribution: safeStringNullable(body, 'mini_activity_distribution'),
        autoAwardAttendance: safeBoolNullable(body, 'auto_award_attendance'),
        visibility: safeStringNullable(body, 'visibility'),
        allowOptOut: safeBoolNullable(body, 'allow_opt_out'),
        requireAbsenceReason: safeBoolNullable(body, 'require_absence_reason'),
        requireAbsenceApproval: safeBoolNullable(body, 'require_absence_approval'),
        excludeValidAbsenceFromPercentage:
            safeBoolNullable(body, 'exclude_valid_absence_from_percentage'),
        newPlayerStartMode: safeStringNullable(body, 'new_player_start_mode'),
      );

      if (config == null) {
        return resp.notFound('Konfigurasjon ikke funnet');
      }

      return resp.ok(config.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke oppdatere konfigurasjon');
    }
  }

  Future<Response> _deleteConfig(Request request, String configId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      final existingConfig = await _crudService.getConfigById(configId);
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

      await _crudService.deleteConfig(configId);

      return resp.ok({'success': true});
    } catch (e) {
      return resp.serverError('Kunne ikke slette konfigurasjon');
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

      final stats = await _attendanceService.getUserAttendanceStats(
        targetUserId,
        teamId,
        seasonId: seasonId,
      );

      return resp.ok(stats);
    } catch (e) {
      return resp.serverError('Kunne ikke hente oppmøtepoeng');
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

      final points = await _attendanceService.getUserAttendancePoints(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return resp.ok({
        'points': points.map((p) => p.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Kunne ikke hente oppmøtepoeng');
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

      final targetUserId = safeStringNullable(body, 'user_id');
      if (targetUserId == null) {
        return resp.badRequest('user_id er påkrevd');
      }

      final activityType = safeStringNullable(body, 'activity_type');
      if (activityType == null) {
        return resp.badRequest('activity_type er påkrevd');
      }

      final basePoints = safeIntNullable(body, 'base_points');
      if (basePoints == null) {
        return resp.badRequest('base_points er påkrevd');
      }

      final weightedPointsRaw = safeNumNullable(body, 'weighted_points');
      if (weightedPointsRaw == null) {
        return resp.badRequest('weighted_points er påkrevd');
      }
      final weightedPoints = weightedPointsRaw.toDouble();

      final points = await _attendanceService.awardAttendancePoints(
        teamId: teamId,
        userId: targetUserId,
        instanceId: instanceId,
        activityType: activityType,
        seasonId: safeStringNullable(body, 'season_id'),
        basePoints: basePoints,
        weightedPoints: weightedPoints,
      );

      return resp.ok(points.toJson());
    } catch (e) {
      return resp.serverError('Kunne ikke tildele poeng');
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
      final targetUserId = safeStringNullable(body, 'user_id') ?? userId;
      final optOut = safeBool(body, 'opt_out', defaultValue: false);

      // Only allow setting own opt-out unless admin
      if (targetUserId != userId && !isAdmin(team)) {
        return resp.forbidden('Kan kun endre egen opt-out status');
      }

      // Check if opt-out is allowed
      final config = await _crudService.getConfig(teamId);
      if (config != null && !config.allowOptOut && optOut) {
        return resp.forbidden('Opt-out er ikke aktivert for dette laget');
      }

      await _crudService.setOptOut(targetUserId, teamId, optOut);

      return resp.ok({'success': true, 'opt_out': optOut});
    } catch (e) {
      return resp.serverError('Kunne ikke endre opt-out status');
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

      final optOut = await _crudService.hasOptedOut(targetUserId, teamId);

      return resp.ok({'opt_out': optOut});
    } catch (e) {
      return resp.serverError('Kunne ikke hente opt-out status');
    }
  }
}
