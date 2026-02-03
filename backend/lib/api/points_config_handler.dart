import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/points_config_service.dart' show PointsConfigService, AdjustmentType;
import '../services/auth_service.dart';
import '../services/team_service.dart';

class PointsConfigHandler {
  final PointsConfigService _pointsConfigService;
  final AuthService _authService;
  final TeamService _teamService;

  PointsConfigHandler(
    this._pointsConfigService,
    this._authService,
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

    // Manual adjustment routes
    router.post('/teams/<teamId>/adjust', _createAdjustment);
    router.get('/teams/<teamId>/adjustments', _getTeamAdjustments);
    router.get('/users/<userId>/adjustments', _getUserAdjustments);

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

  Future<Response> _getConfig(Request request, String teamId) async {
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
      final config = await _pointsConfigService.getOrCreateConfig(
        teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode(config.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente poengkonfigurasjon: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _createOrUpdateConfig(Request request, String teamId) async {
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
          jsonEncode({'error': 'Kun admin kan endre poengkonfigurasjon'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

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

        return Response.ok(
          jsonEncode(config?.toJson()),
          headers: {'Content-Type': 'application/json'},
        );
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

      return Response.ok(
        jsonEncode(config.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body:
            jsonEncode({'error': 'Kunne ikke opprette/oppdatere konfigurasjon: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _updateConfig(Request request, String configId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

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
        return Response.notFound(
          jsonEncode({'error': 'Konfigurasjon ikke funnet'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return Response.ok(
        jsonEncode(config.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke oppdatere konfigurasjon: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _deleteConfig(Request request, String configId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response.forbidden(
          jsonEncode({'error': 'Ikke autorisert'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _pointsConfigService.deleteConfig(configId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke slette konfigurasjon: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getTeamAttendancePoints(
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

      final targetUserId =
          request.url.queryParameters['user_id'] ?? userId;
      final seasonId = request.url.queryParameters['season_id'];

      final stats = await _pointsConfigService.getUserAttendanceStats(
        targetUserId,
        teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode(stats),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente oppmøtepoeng: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserAttendancePoints(
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

      final points = await _pointsConfigService.getUserAttendancePoints(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode({
          'points': points.map((p) => p.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente oppmøtepoeng: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _awardAttendancePoints(
      Request request, String teamId, String instanceId) async {
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
          jsonEncode({'error': 'Kun admin kan tildele poeng'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());
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

      return Response.ok(
        jsonEncode(points.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke tildele poeng: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _setOptOut(Request request, String teamId) async {
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

      final body = jsonDecode(await request.readAsString());
      final targetUserId = body['user_id'] as String? ?? userId;
      final optOut = body['opt_out'] as bool? ?? false;

      // Only allow setting own opt-out unless admin
      if (targetUserId != userId && !await _isTeamAdmin(userId, teamId)) {
        return Response.forbidden(
          jsonEncode({'error': 'Kan kun endre egen opt-out status'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Check if opt-out is allowed
      final config = await _pointsConfigService.getConfig(teamId);
      if (config != null && !config.allowOptOut && optOut) {
        return Response.forbidden(
          jsonEncode({'error': 'Opt-out er ikke aktivert for dette laget'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      await _pointsConfigService.setOptOut(targetUserId, teamId, optOut);

      return Response.ok(
        jsonEncode({'success': true, 'opt_out': optOut}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke endre opt-out status: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getOptOut(
      Request request, String teamId, String targetUserId) async {
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

      final optOut = await _pointsConfigService.hasOptedOut(targetUserId, teamId);

      return Response.ok(
        jsonEncode({'opt_out': optOut}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente opt-out status: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  // ============ MANUAL ADJUSTMENTS ============

  Future<Response> _createAdjustment(Request request, String teamId) async {
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
          jsonEncode({'error': 'Kun admin kan justere poeng'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final body = jsonDecode(await request.readAsString());

      final targetUserId = body['user_id'] as String?;
      final points = body['points'] as int?;
      final adjustmentTypeStr = body['adjustment_type'] as String?;
      final reason = body['reason'] as String?;

      if (targetUserId == null ||
          points == null ||
          adjustmentTypeStr == null ||
          reason == null) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'user_id, points, adjustment_type og reason er påkrevd',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      if (reason.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Begrunnelse kan ikke være tom'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final adjustmentType = AdjustmentType.fromString(adjustmentTypeStr);

      final adjustment = await _pointsConfigService.createAdjustment(
        teamId: teamId,
        userId: targetUserId,
        points: points,
        adjustmentType: adjustmentType,
        reason: reason.trim(),
        createdBy: userId,
        seasonId: body['season_id'] as String?,
      );

      return Response.ok(
        jsonEncode(adjustment.toJson()),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke opprette justering: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getTeamAdjustments(Request request, String teamId) async {
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
      final limit = limitStr != null ? int.tryParse(limitStr) : null;

      final adjustments = await _pointsConfigService.getTeamAdjustments(
        teamId,
        seasonId: seasonId,
        limit: limit,
      );

      return Response.ok(
        jsonEncode({
          'adjustments': adjustments.map((a) => a.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente justeringer: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _getUserAdjustments(
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

      final adjustments = await _pointsConfigService.getUserAdjustments(
        targetUserId,
        teamId: teamId,
        seasonId: seasonId,
      );

      return Response.ok(
        jsonEncode({
          'adjustments': adjustments.map((a) => a.toJson()).toList(),
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Kunne ikke hente justeringer: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }
}
