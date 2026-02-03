import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../services/mini_activity_service.dart';
import '../services/team_service.dart';
import '../services/mini_activity_statistics_service.dart';

class MiniActivitiesHandler {
  final MiniActivityService _miniActivityService;
  final AuthService _authService;
  final TeamService _teamService;
  final MiniActivityStatisticsService? _statsService;

  MiniActivitiesHandler(
    this._miniActivityService,
    this._authService,
    this._teamService, [
    this._statsService,
  ]);

  Router get router {
    final router = Router();

    // Template routes
    router.get('/templates/team/<teamId>', _getTemplates);
    router.post('/templates/team/<teamId>', _createTemplate);
    router.put('/templates/<templateId>', _updateTemplate);
    router.delete('/templates/<templateId>', _deleteTemplate);
    router.post('/templates/<templateId>/favorite', _toggleTemplateFavorite);

    // Standalone mini-activity routes (team-based without instance)
    router.get('/standalone/team/<teamId>', _getStandaloneMiniActivities);
    router.post('/standalone/team/<teamId>', _createStandaloneMiniActivity);

    // Mini-activity routes
    router.get('/instance/<instanceId>', _getMiniActivitiesForInstance);
    router.post('/instance/<instanceId>', _createMiniActivity);
    router.get('/<miniActivityId>', _getMiniActivityDetail);
    router.put('/<miniActivityId>', _updateMiniActivity);
    router.delete('/<miniActivityId>', _deleteMiniActivity);
    router.post('/<miniActivityId>/archive', _archiveMiniActivity);
    router.post('/<miniActivityId>/duplicate', _duplicateMiniActivity);

    // Team division
    router.post('/<miniActivityId>/divide-teams', _divideTeams);
    router.delete('/<miniActivityId>/reset-teams', _resetTeamDivision);
    router.post('/<miniActivityId>/add-participant', _addLateParticipant);
    router.put('/<miniActivityId>/teams/<miniTeamId>/name', _updateTeamName);
    router.post('/<miniActivityId>/teams', _createTeam);
    router.delete('/<miniActivityId>/teams/<miniTeamId>', _deleteTeam);
    router.put('/<miniActivityId>/participants/<participantId>/move', _moveParticipant);

    // Scores and Results
    router.post('/<miniActivityId>/scores', _recordScores);
    router.post('/<miniActivityId>/result', _setWinner);
    router.delete('/<miniActivityId>/result', _clearResult);

    // History
    router.get('/history/team/<teamId>', _getHistory);

    // Adjustments (bonus/penalty)
    router.get('/<miniActivityId>/adjustments', _getAdjustments);
    router.post('/<miniActivityId>/adjustments', _createAdjustment);

    // Handicaps
    router.get('/<miniActivityId>/handicaps', _getHandicaps);
    router.post('/<miniActivityId>/handicaps', _setHandicap);
    router.delete('/<miniActivityId>/handicaps/<userId>', _removeHandicap);

    // Statistics
    router.get('/<miniActivityId>/leaderboard', _getMiniActivityLeaderboard);

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

  Future<bool> _isTeamMember(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    return team != null;
  }

  Future<bool> _isTeamAdmin(String userId, String teamId) async {
    final team = await _teamService.getTeamById(teamId, userId);
    return team != null && team['user_role'] == 'admin';
  }

  // ============ TEMPLATES ============

  Future<Response> _getTemplates(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final templates = await _miniActivityService.getTemplatesForTeam(teamId);
      return Response.ok(jsonEncode(templates.map((t) => t.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _createTemplate(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan opprette maler'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final type = data['type'] as String?;

      if (name == null || type == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (name, type)'}));
      }

      if (!['individual', 'team'].contains(type)) {
        return Response(400, body: jsonEncode({'error': 'Ugyldig type (må være individual eller team)'}));
      }

      final template = await _miniActivityService.createTemplate(
        teamId: teamId,
        name: name,
        type: type,
        defaultPoints: data['default_points'] as int? ?? 1,
      );

      return Response.ok(jsonEncode(template.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteTemplate(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final teamId = await _miniActivityService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response(404, body: jsonEncode({'error': 'Mal ikke funnet'}));
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan slette maler'}));
      }

      await _miniActivityService.deleteTemplate(templateId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ MINI-ACTIVITIES ============

  Future<Response> _getMiniActivitiesForInstance(Request request, String instanceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final miniActivities = await _miniActivityService.getMiniActivitiesForInstance(instanceId);
      return Response.ok(jsonEncode(miniActivities));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _createMiniActivity(Request request, String instanceId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final type = data['type'] as String?;

      if (name == null || type == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (name, type)'}));
      }

      final miniActivity = await _miniActivityService.createMiniActivity(
        instanceId: instanceId,
        templateId: data['template_id'] as String?,
        name: name,
        type: type,
      );

      return Response.ok(jsonEncode(miniActivity.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _getMiniActivityDetail(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      if (detail == null) {
        return Response(404, body: jsonEncode({'error': 'Mini-aktivitet ikke funnet'}));
      }

      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _miniActivityService.deleteMiniActivity(miniActivityId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ TEAM DIVISION ============

  Future<Response> _divideTeams(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final method = data['method'] as String?;
      final numberOfTeams = data['number_of_teams'] as int?;
      final participantUserIds = (data['participant_user_ids'] as List?)?.cast<String>();
      final teamId = data['team_id'] as String? ?? '';

      if (method == null || numberOfTeams == null || participantUserIds == null) {
        return Response(400, body: jsonEncode({
          'error': 'Mangler påkrevde felt (method, number_of_teams, participant_user_ids)'
        }));
      }

      if (!['random', 'ranked', 'age', 'gmo', 'cup', 'manual'].contains(method)) {
        return Response(400, body: jsonEncode({'error': 'Ugyldig metode'}));
      }

      if (numberOfTeams < 2) {
        return Response(400, body: jsonEncode({'error': 'Må ha minst 2 lag'}));
      }

      if (participantUserIds.length < numberOfTeams) {
        return Response(400, body: jsonEncode({'error': 'For få deltakere for antall lag'}));
      }

      await _miniActivityService.divideTeams(
        miniActivityId: miniActivityId,
        method: method,
        numberOfTeams: numberOfTeams,
        participantUserIds: participantUserIds,
        teamId: teamId,
      );

      // Return the updated mini-activity detail
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } on ArgumentError catch (e) {
      return Response(400, body: jsonEncode({'error': e.message}));
    } catch (e) {
      print('Divide teams error: $e');
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod ved lagdeling: $e'}));
    }
  }

  // ============ SCORES ============

  Future<Response> _recordScores(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final teamScores = (data['team_scores'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)) ?? {};
      final participantPoints = (data['participant_points'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)) ?? {};

      await _miniActivityService.recordMultipleScores(
        miniActivityId: miniActivityId,
        teamScores: teamScores,
        participantPoints: participantPoints,
      );

      // Return the updated mini-activity detail
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ UPDATE MINI-ACTIVITY ============

  Future<Response> _updateMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      await _miniActivityService.updateMiniActivity(
        miniActivityId: miniActivityId,
        name: data['name'] as String?,
        description: data['description'] as String?,
        winPoints: data['win_points'] as int?,
        drawPoints: data['draw_points'] as int?,
        lossPoints: data['loss_points'] as int?,
        enableLeaderboard: data['enable_leaderboard'] as bool?,
        maxParticipants: data['max_participants'] as int?,
        handicapEnabled: data['handicap_enabled'] as bool?,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ STANDALONE MINI-ACTIVITIES ============

  Future<Response> _getStandaloneMiniActivities(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final includeArchived = request.url.queryParameters['include_archived'] == 'true';
      final miniActivities = await _miniActivityService.getStandaloneMiniActivitiesForTeam(
        teamId,
        includeArchived: includeArchived,
      );
      return Response.ok(jsonEncode(miniActivities));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _createStandaloneMiniActivity(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan opprette mini-aktiviteter'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      final type = data['type'] as String?;

      if (name == null || type == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (name, type)'}));
      }

      final miniActivity = await _miniActivityService.createStandaloneMiniActivity(
        teamId: teamId,
        templateId: data['template_id'] as String?,
        name: name,
        type: type,
        description: data['description'] as String?,
        leaderboardId: data['leaderboard_id'] as String?,
        enableLeaderboard: data['enable_leaderboard'] as bool? ?? true,
        winPoints: data['win_points'] as int? ?? 3,
        drawPoints: data['draw_points'] as int? ?? 1,
        lossPoints: data['loss_points'] as int? ?? 0,
      );

      return Response.ok(jsonEncode(miniActivity.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ ARCHIVE & DUPLICATE ============

  Future<Response> _archiveMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _miniActivityService.archiveMiniActivity(miniActivityId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _duplicateMiniActivity(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final newMiniActivity = await _miniActivityService.duplicateMiniActivity(
        miniActivityId: miniActivityId,
        newName: data['new_name'] as String?,
      );

      return Response.ok(jsonEncode(newMiniActivity.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ TEAM MANAGEMENT ============

  Future<Response> _resetTeamDivision(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _miniActivityService.resetTeamDivision(miniActivityId);
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _addLateParticipant(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final participantUserId = data['user_id'] as String?;
      final miniTeamId = data['mini_team_id'] as String?;

      if (participantUserId == null || miniTeamId == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (user_id, mini_team_id)'}));
      }

      await _miniActivityService.addLateParticipant(
        miniActivityId: miniActivityId,
        userId: participantUserId,
        teamId: miniTeamId,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _updateTeamName(Request request, String miniActivityId, String miniTeamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final newName = data['name'] as String?;
      if (newName == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevd felt (name)'}));
      }

      await _miniActivityService.updateTeamName(teamId: miniTeamId, newName: newName);
      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ ADJUSTMENTS ============

  Future<Response> _getAdjustments(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final adjustments = await _miniActivityService.getAdjustments(miniActivityId);
      return Response.ok(jsonEncode(adjustments.map((a) => a.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _createAdjustment(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final points = data['points'] as int?;
      if (points == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevd felt (points)'}));
      }

      final adjustment = await _miniActivityService.awardAdjustment(
        miniActivityId: miniActivityId,
        teamId: data['team_id'] as String?,
        userId: data['user_id'] as String?,
        points: points,
        reason: data['reason'] as String?,
        createdBy: userId,
      );

      return Response.ok(jsonEncode(adjustment.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ HANDICAPS ============

  Future<Response> _getHandicaps(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final handicaps = await _miniActivityService.getHandicaps(miniActivityId);
      return Response.ok(jsonEncode(handicaps.map((h) => h.toJson()).toList()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _setHandicap(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final targetUserId = data['user_id'] as String?;
      final handicapValue = (data['handicap_value'] as num?)?.toDouble();

      if (targetUserId == null || handicapValue == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevde felt (user_id, handicap_value)'}));
      }

      final handicap = await _miniActivityService.setHandicap(
        miniActivityId: miniActivityId,
        userId: targetUserId,
        handicapValue: handicapValue,
      );

      return Response.ok(jsonEncode(handicap.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _removeHandicap(Request request, String miniActivityId, String targetUserId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _miniActivityService.removeHandicap(miniActivityId: miniActivityId, userId: targetUserId);
      return Response.ok(jsonEncode({'success': true}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ TEMPLATE UPDATES ============

  Future<Response> _updateTemplate(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final teamId = await _miniActivityService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response(404, body: jsonEncode({'error': 'Mal ikke funnet'}));
      }

      if (!await _isTeamAdmin(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Kun administratorer kan oppdatere maler'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final template = await _miniActivityService.updateTemplate(
        templateId: templateId,
        name: data['name'] as String?,
        description: data['description'] as String?,
        instructions: data['instructions'] as String?,
        sportType: data['sport_type'] as String?,
        suggestedRules: data['suggested_rules'] as Map<String, dynamic>?,
        winPoints: data['win_points'] as int?,
        drawPoints: data['draw_points'] as int?,
        lossPoints: data['loss_points'] as int?,
        defaultPoints: data['default_points'] as int?,
      );

      if (template == null) {
        return Response(404, body: jsonEncode({'error': 'Mal ikke funnet'}));
      }

      return Response.ok(jsonEncode(template.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _toggleTemplateFavorite(Request request, String templateId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final teamId = await _miniActivityService.getTeamIdForTemplate(templateId);
      if (teamId == null) {
        return Response(404, body: jsonEncode({'error': 'Mal ikke funnet'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang'}));
      }

      await _miniActivityService.toggleTemplateFavorite(templateId);

      // Fetch updated templates to return the updated one
      final templates = await _miniActivityService.getTemplatesForTeam(teamId);
      final updatedTemplate = templates.firstWhere((t) => t.id == templateId);
      return Response.ok(jsonEncode(updatedTemplate.toJson()));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ NEW: TEAM MANAGEMENT ============

  Future<Response> _createTeam(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final name = data['name'] as String?;
      if (name == null || name.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevd felt (name)'}));
      }

      await _miniActivityService.createTeam(
        miniActivityId: miniActivityId,
        name: name,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _deleteTeam(Request request, String miniActivityId, String miniTeamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      Map<String, dynamic>? data;
      if (body.isNotEmpty) {
        data = jsonDecode(body) as Map<String, dynamic>?;
      }

      await _miniActivityService.deleteTeam(
        miniActivityId: miniActivityId,
        teamId: miniTeamId,
        moveParticipantsToTeamId: data?['move_participants_to_team_id'] as String?,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _moveParticipant(Request request, String miniActivityId, String participantId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final targetTeamId = data['target_team_id'] as String?;
      if (targetTeamId == null) {
        return Response(400, body: jsonEncode({'error': 'Mangler påkrevd felt (target_team_id)'}));
      }

      await _miniActivityService.moveParticipantToTeam(
        participantId: participantId,
        newTeamId: targetTeamId,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ NEW: RESULT MANAGEMENT ============

  Future<Response> _setWinner(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final winnerTeamId = data['winner_team_id'] as String?;
      final addToLeaderboard = data['add_to_leaderboard'] as bool? ?? false;

      await _miniActivityService.setWinner(
        miniActivityId: miniActivityId,
        winnerTeamId: winnerTeamId,
        addToLeaderboard: addToLeaderboard,
      );

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  Future<Response> _clearResult(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      await _miniActivityService.clearResult(miniActivityId);

      final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
      return Response.ok(jsonEncode(detail));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ NEW: HISTORY ============

  Future<Response> _getHistory(Request request, String teamId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (!await _isTeamMember(userId, teamId)) {
        return Response(403, body: jsonEncode({'error': 'Ingen tilgang til dette laget'}));
      }

      final templateId = request.url.queryParameters['template_id'];
      final limitStr = request.url.queryParameters['limit'];
      final limit = limitStr != null ? int.tryParse(limitStr) ?? 20 : 20;

      final history = await _miniActivityService.getHistory(
        teamId: teamId,
        templateId: templateId,
        limit: limit,
      );

      return Response.ok(jsonEncode(history));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }

  // ============ LEADERBOARD ============

  Future<Response> _getMiniActivityLeaderboard(Request request, String miniActivityId) async {
    try {
      final userId = await _getUserId(request);
      if (userId == null) {
        return Response(401, body: jsonEncode({'error': 'Ikke autentisert'}));
      }

      if (_statsService == null) {
        return Response.internalServerError(body: jsonEncode({'error': 'Statistikktjeneste ikke tilgjengelig'}));
      }

      // Get teamId from mini activity - first check for team_id directly
      final miniActivity = await _miniActivityService.getMiniActivityById(miniActivityId);
      if (miniActivity == null) {
        return Response(404, body: jsonEncode({'error': 'Mini-aktivitet ikke funnet'}));
      }

      // Use the activity's team_id if available
      String? teamId = miniActivity.teamId;

      // If no direct teamId, try to get from instance
      if (teamId == null) {
        final detail = await _miniActivityService.getMiniActivityDetail(miniActivityId);
        teamId = detail?['team_id'] as String?;
      }

      if (teamId == null) {
        return Response(400, body: jsonEncode({'error': 'Mini-aktivitet mangler team_id'}));
      }

      final leaderboard = await _statsService.getMiniActivityLeaderboard(teamId: teamId);
      return Response.ok(jsonEncode(leaderboard));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': 'En feil oppstod: $e'}));
    }
  }
}
