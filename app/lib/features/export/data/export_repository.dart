import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/export_log.dart';

final exportRepositoryProvider = Provider<ExportRepository>((ref) {
  return ExportRepository(ref.watch(apiClientProvider));
});

class ExportRepository {
  final ApiClient _client;

  ExportRepository(this._client);

  /// Export leaderboard data
  Future<ExportData> exportLeaderboard(
    String teamId, {
    String format = 'json',
    String? seasonId,
    String? leaderboardId,
  }) async {
    final queryParams = <String, String>{
      'format': format,
    };
    if (seasonId != null) queryParams['season_id'] = seasonId;
    if (leaderboardId != null) queryParams['leaderboard_id'] = leaderboardId;

    final response = await _client.get(
      '/exports/teams/$teamId/leaderboard',
      queryParameters: queryParams,
    );
    return ExportData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Export attendance data
  Future<ExportData> exportAttendance(
    String teamId, {
    String format = 'json',
    String? seasonId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, String>{
      'format': format,
    };
    if (seasonId != null) queryParams['season_id'] = seasonId;
    if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

    final response = await _client.get(
      '/exports/teams/$teamId/attendance',
      queryParameters: queryParams,
    );
    return ExportData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Export fines data
  Future<ExportData> exportFines(
    String teamId, {
    String format = 'json',
    bool? paidOnly,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, String>{
      'format': format,
    };
    if (paidOnly != null) queryParams['paid_only'] = paidOnly.toString();
    if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

    final response = await _client.get(
      '/exports/teams/$teamId/fines',
      queryParameters: queryParams,
    );
    return ExportData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Export members data (admin only)
  Future<ExportData> exportMembers(
    String teamId, {
    String format = 'json',
  }) async {
    final response = await _client.get(
      '/exports/teams/$teamId/members',
      queryParameters: {'format': format},
    );
    return ExportData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Export activities data
  Future<ExportData> exportActivities(
    String teamId, {
    String format = 'json',
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, String>{
      'format': format,
    };
    if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();

    final response = await _client.get(
      '/exports/teams/$teamId/activities',
      queryParameters: queryParams,
    );
    return ExportData.fromJson(response.data as Map<String, dynamic>);
  }

  /// Get CSV content directly
  Future<String> exportToCsv(
    String teamId,
    ExportType type, {
    Map<String, String>? extraParams,
  }) async {
    final queryParams = <String, String>{
      'format': 'csv',
      ...?extraParams,
    };

    final endpoint = switch (type) {
      ExportType.leaderboard => '/exports/teams/$teamId/leaderboard',
      ExportType.attendance => '/exports/teams/$teamId/attendance',
      ExportType.fines => '/exports/teams/$teamId/fines',
      ExportType.activities => '/exports/teams/$teamId/activities',
      ExportType.members => '/exports/teams/$teamId/members',
    };

    final response = await _client.get(endpoint, queryParameters: queryParams);
    return response.data as String;
  }

  /// Get export history
  Future<List<ExportLog>> getExportHistory(String teamId, {int limit = 50}) async {
    final response = await _client.get(
      '/exports/teams/$teamId/history',
      queryParameters: {'limit': limit.toString()},
    );
    final data = response.data['exports'] as List;
    return data.map((e) => ExportLog.fromJson(e as Map<String, dynamic>)).toList();
  }
}
