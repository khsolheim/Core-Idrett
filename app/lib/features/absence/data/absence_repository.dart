import '../../../core/utils/api_response_parser.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/absence.dart';

class AbsenceRepository {
  final ApiClient _client;

  AbsenceRepository(this._client);

  // ============ ABSENCE CATEGORIES ============

  Future<List<AbsenceCategory>> getCategories(String teamId) async {
    final response = await _client.get('/absence/teams/$teamId/categories');
    return parseList(response.data, 'categories', AbsenceCategory.fromJson);
  }

  Future<AbsenceCategory> createCategory({
    required String teamId,
    required String name,
    bool requiresApproval = false,
    bool countsAsValid = true,
    int? sortOrder,
  }) async {
    final response = await _client.post(
      '/absence/teams/$teamId/categories',
      data: {
        'name': name,
        'requires_approval': requiresApproval,
        'counts_as_valid': countsAsValid,
        'sort_order': ?sortOrder,
      },
    );
    return AbsenceCategory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AbsenceCategory?> updateCategory({
    required String categoryId,
    String? name,
    bool? requiresApproval,
    bool? countsAsValid,
    int? sortOrder,
  }) async {
    final response = await _client.patch(
      '/absence/categories/$categoryId',
      data: {
        'name': ?name,
        'requires_approval': ?requiresApproval,
        'counts_as_valid': ?countsAsValid,
        'sort_order': ?sortOrder,
      },
    );
    return AbsenceCategory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _client.delete('/absence/categories/$categoryId');
  }

  // ============ ABSENCE RECORDS ============

  Future<AbsenceRecord> registerAbsence({
    required String teamId,
    required String userId,
    required String instanceId,
    String? categoryId,
    String? reason,
  }) async {
    final response = await _client.post(
      '/absence/register',
      data: {
        'team_id': teamId,
        'user_id': userId,
        'instance_id': instanceId,
        'category_id': ?categoryId,
        'reason': ?reason,
      },
    );
    return AbsenceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<AbsenceRecord>> getTeamAbsences(
    String teamId, {
    String? userId,
    String? status,
    String? seasonId,
    int? limit,
    int offset = 0,
  }) async {
    final params = <String, String>{};
    if (userId != null) params['user_id'] = userId;
    if (status != null) params['status'] = status;
    if (seasonId != null) params['season_id'] = seasonId;
    if (limit != null) params['limit'] = limit.toString();
    if (offset > 0) params['offset'] = offset.toString();

    final response = await _client.get(
      '/absence/teams/$teamId',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return parseList(response.data, 'absences', AbsenceRecord.fromJson);
  }

  Future<List<AbsenceRecord>> getPendingAbsences(String teamId) async {
    final response = await _client.get('/absence/teams/$teamId/pending');
    return parseList(response.data, 'absences', AbsenceRecord.fromJson);
  }

  Future<AbsenceRecord?> getAbsenceDetails(String absenceId) async {
    try {
      final response = await _client.get('/absence/$absenceId');
      return AbsenceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<AbsenceRecord?> getAbsenceForInstance(
    String userId,
    String instanceId,
  ) async {
    try {
      final response = await _client.get(
        '/absence/users/$userId/instances/$instanceId',
      );
      return AbsenceRecord.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<AbsenceRecord> approveAbsence(String absenceId) async {
    final response = await _client.patch(
      '/absence/$absenceId/approve',
      data: {},
    );
    return AbsenceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AbsenceRecord> rejectAbsence(
    String absenceId, {
    String? reason,
  }) async {
    final response = await _client.patch(
      '/absence/$absenceId/reject',
      data: {
        'reason': ?reason,
      },
    );
    return AbsenceRecord.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteAbsence(String absenceId) async {
    await _client.delete('/absence/$absenceId');
  }

  // ============ ABSENCE STATS ============

  Future<AbsenceSummary> getTeamAbsenceSummary(
    String teamId, {
    String? seasonId,
  }) async {
    final params = seasonId != null ? {'season_id': seasonId} : null;
    final response = await _client.get(
      '/absence/teams/$teamId/summary',
      queryParameters: params,
    );
    return AbsenceSummary.fromJson(response.data as Map<String, dynamic>);
  }

  Future<int> countValidAbsences(
    String userId,
    String teamId, {
    String? seasonId,
  }) async {
    final params = <String, String>{};
    if (seasonId != null) params['season_id'] = seasonId;

    final response = await _client.get(
      '/absence/teams/$teamId/users/$userId/valid-count',
      queryParameters: params.isNotEmpty ? params : null,
    );
    return response.data['count'] as int;
  }

  Future<bool> hasValidAbsence(String userId, String instanceId) async {
    try {
      final response = await _client.get(
        '/absence/users/$userId/instances/$instanceId/valid',
      );
      return response.data['has_valid_absence'] as bool;
    } catch (e) {
      return false;
    }
  }
}
