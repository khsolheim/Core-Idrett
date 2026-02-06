import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/export_service.dart';
import '../services/team_service.dart';
import '../models/export_log.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/response_helpers.dart' as resp;

class ExportsHandler {
  final ExportService _exportService;
  final TeamService _teamService;

  ExportsHandler(this._exportService, this._teamService);

  Router get router {
    final router = Router();

    // Export data endpoints
    router.get('/teams/<teamId>/leaderboard', _exportLeaderboard);
    router.get('/teams/<teamId>/attendance', _exportAttendance);
    router.get('/teams/<teamId>/fines', _exportFines);
    router.get('/teams/<teamId>/members', _exportMembers);
    router.get('/teams/<teamId>/activities', _exportActivities);

    // Export history
    router.get('/teams/<teamId>/history', _getExportHistory);

    return router;
  }

  /// Export leaderboard data
  Future<Response> _exportLeaderboard(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Not a team member');
      }

      final params = request.url.queryParameters;
      final format = params['format'] ?? 'json';
      final seasonId = params['season_id'];
      final leaderboardId = params['leaderboard_id'];

      final data = await _exportService.exportLeaderboard(
        teamId,
        seasonId: seasonId,
        leaderboardId: leaderboardId,
      );

      // Log the export
      await _exportService.logExport(
        teamId: teamId,
        userId: userId,
        exportType: ExportType.leaderboard,
        fileFormat: format,
        parameters: {
          'season_id': seasonId,
          'leaderboard_id': leaderboardId,
        },
      );

      return _formatResponse(data, format, 'leaderboard');
    } catch (e) {
      return resp.serverError('Failed to export leaderboard: $e');
    }
  }

  /// Export attendance data
  Future<Response> _exportAttendance(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Not a team member');
      }

      final params = request.url.queryParameters;
      final format = params['format'] ?? 'json';
      final seasonId = params['season_id'];
      final fromDate = params['from_date'] != null
          ? DateTime.tryParse(params['from_date']!)
          : null;
      final toDate = params['to_date'] != null
          ? DateTime.tryParse(params['to_date']!)
          : null;

      final data = await _exportService.exportAttendance(
        teamId,
        seasonId: seasonId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Log the export
      await _exportService.logExport(
        teamId: teamId,
        userId: userId,
        exportType: ExportType.attendance,
        fileFormat: format,
        parameters: {
          'season_id': seasonId,
          'from_date': fromDate?.toIso8601String(),
          'to_date': toDate?.toIso8601String(),
        },
      );

      return _formatResponse(data, format, 'attendance');
    } catch (e) {
      return resp.serverError('Failed to export attendance: $e');
    }
  }

  /// Export fines data
  Future<Response> _exportFines(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Not a team member');
      }

      final params = request.url.queryParameters;
      final format = params['format'] ?? 'json';
      final paidOnly = params['paid_only'] == 'true'
          ? true
          : (params['paid_only'] == 'false' ? false : null);
      final fromDate = params['from_date'] != null
          ? DateTime.tryParse(params['from_date']!)
          : null;
      final toDate = params['to_date'] != null
          ? DateTime.tryParse(params['to_date']!)
          : null;

      final data = await _exportService.exportFines(
        teamId,
        paidOnly: paidOnly,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Log the export
      await _exportService.logExport(
        teamId: teamId,
        userId: userId,
        exportType: ExportType.fines,
        fileFormat: format,
        parameters: {
          'paid_only': paidOnly,
          'from_date': fromDate?.toIso8601String(),
          'to_date': toDate?.toIso8601String(),
        },
      );

      return _formatResponse(data, format, 'fines');
    } catch (e) {
      return resp.serverError('Failed to export fines: $e');
    }
  }

  /// Export members data
  Future<Response> _exportMembers(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership and admin rights
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Not a team member');
      }

      // Only admins can export member data (contains emails)
      if (!isAdmin(team)) {
        return resp.forbidden('Only admins can export member data');
      }

      final params = request.url.queryParameters;
      final format = params['format'] ?? 'json';

      final data = await _exportService.exportMembers(teamId);

      // Log the export
      await _exportService.logExport(
        teamId: teamId,
        userId: userId,
        exportType: ExportType.members,
        fileFormat: format,
      );

      return _formatResponse(data, format, 'members');
    } catch (e) {
      return resp.serverError('Failed to export members: $e');
    }
  }

  /// Export activities data
  Future<Response> _exportActivities(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Not a team member');
      }

      final params = request.url.queryParameters;
      final format = params['format'] ?? 'json';
      final fromDate = params['from_date'] != null
          ? DateTime.tryParse(params['from_date']!)
          : null;
      final toDate = params['to_date'] != null
          ? DateTime.tryParse(params['to_date']!)
          : null;

      final data = await _exportService.exportActivities(
        teamId,
        fromDate: fromDate,
        toDate: toDate,
      );

      // Log the export
      await _exportService.logExport(
        teamId: teamId,
        userId: userId,
        exportType: ExportType.activities,
        fileFormat: format,
        parameters: {
          'from_date': fromDate?.toIso8601String(),
          'to_date': toDate?.toIso8601String(),
        },
      );

      return _formatResponse(data, format, 'activities');
    } catch (e) {
      return resp.serverError('Failed to export activities: $e');
    }
  }

  /// Get export history
  Future<Response> _getExportHistory(Request request, String teamId) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Verify team membership
      final team = await requireTeamMember(_teamService, teamId, userId);
      if (team == null) {
        return resp.forbidden('Not a team member');
      }

      final params = request.url.queryParameters;
      final limit = int.tryParse(params['limit'] ?? '50') ?? 50;

      final history = await _exportService.getExportHistory(teamId, limit: limit);

      return resp.ok({
        'exports': history.map((e) => e.toJson()).toList(),
      });
    } catch (e) {
      return resp.serverError('Failed to get export history: $e');
    }
  }

  /// Format response based on requested format
  Response _formatResponse(Map<String, dynamic> data, String format, String filename) {
    switch (format.toLowerCase()) {
      case 'csv':
        final csv = _exportService.generateCsv(data);
        return Response.ok(
          csv,
          headers: {
            'content-type': 'text/csv; charset=utf-8',
            'content-disposition': 'attachment; filename="$filename.csv"',
          },
        );
      case 'json':
      default:
        return resp.ok(data);
    }
  }
}
