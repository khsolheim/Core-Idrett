import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/statistics.dart';

final testRepositoryProvider = Provider<TestRepository>((ref) {
  return TestRepository(ref.watch(apiClientProvider));
});

class TestRepository {
  final ApiClient _client;

  TestRepository(this._client);

  // ============ TEST TEMPLATES ============

  /// Get all test templates for a team
  Future<List<TestTemplate>> getTemplates(String teamId) async {
    final response = await _client.get('/tests/templates/teams/$teamId');
    final data = response.data['templates'] as List;
    return data.map((t) => TestTemplate.fromJson(t as Map<String, dynamic>)).toList();
  }

  /// Get a specific template by ID
  Future<TestTemplate> getTemplate(String templateId) async {
    final response = await _client.get('/tests/templates/$templateId');
    return TestTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  /// Create a new test template
  Future<TestTemplate> createTemplate({
    required String teamId,
    required String name,
    String? description,
    required String unit,
    bool higherIsBetter = false,
  }) async {
    final response = await _client.post('/tests/templates/teams/$teamId', data: {
      'name': name,
      'description': ?description,
      'unit': unit,
      'higher_is_better': higherIsBetter,
    });
    return TestTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update a test template
  Future<TestTemplate> updateTemplate({
    required String templateId,
    String? name,
    String? description,
    String? unit,
    bool? higherIsBetter,
    bool clearDescription = false,
  }) async {
    final response = await _client.patch('/tests/templates/$templateId', data: {
      'name': ?name,
      'description': ?description,
      'unit': ?unit,
      'higher_is_better': ?higherIsBetter,
      if (clearDescription) 'clear_description': true,
    });
    return TestTemplate.fromJson(response.data as Map<String, dynamic>);
  }

  /// Delete a test template
  Future<void> deleteTemplate(String templateId) async {
    await _client.delete('/tests/templates/$templateId');
  }

  // ============ TEST RESULTS ============

  /// Get results for a template
  Future<List<TestResult>> getResults(
    String templateId, {
    String? userId,
    int? limit,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'offset': offset.toString(),
    };
    if (userId != null) queryParams['user_id'] = userId;
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _client.get(
      '/tests/templates/$templateId/results',
      queryParameters: queryParams,
    );
    final data = response.data['results'] as List;
    return data.map((r) => TestResult.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Get ranking for a template
  Future<List<Map<String, dynamic>>> getRanking(String templateId, {int? limit}) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _client.get(
      '/tests/templates/$templateId/ranking',
      queryParameters: queryParams,
    );
    return (response.data['ranking'] as List).cast<Map<String, dynamic>>();
  }

  /// Record a single result
  Future<TestResult> recordResult({
    required String templateId,
    required String userId,
    required double value,
    String? instanceId,
    String? notes,
  }) async {
    final response = await _client.post('/tests/templates/$templateId/results', data: {
      'user_id': userId,
      'value': value,
      'instance_id': ?instanceId,
      'notes': ?notes,
    });
    return TestResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Record multiple results at once
  Future<List<TestResult>> recordBulkResults({
    required String templateId,
    required List<Map<String, dynamic>> results,
    String? instanceId,
  }) async {
    final response = await _client.post('/tests/templates/$templateId/results/bulk', data: {
      'results': results,
      'instance_id': ?instanceId,
    });
    final data = response.data['results'] as List;
    return data.map((r) => TestResult.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Delete a result
  Future<void> deleteResult(String resultId) async {
    await _client.delete('/tests/results/$resultId');
  }

  // ============ USER-SPECIFIC ============

  /// Get all results for a user in a team
  Future<List<TestResult>> getUserResults(
    String teamId,
    String userId, {
    int? limit,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'offset': offset.toString(),
    };
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _client.get(
      '/tests/teams/$teamId/users/$userId/results',
      queryParameters: queryParams,
    );
    final data = response.data['results'] as List;
    return data.map((r) => TestResult.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Get personal best for a test
  Future<TestResult?> getPersonalBest(String templateId, String userId) async {
    try {
      final response = await _client.get('/tests/templates/$templateId/users/$userId/best');
      return TestResult.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Get user progress over time for a test
  Future<List<TestResult>> getUserProgress(
    String templateId,
    String userId, {
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await _client.get(
      '/tests/templates/$templateId/users/$userId/progress',
      queryParameters: queryParams,
    );
    final data = response.data['progress'] as List;
    return data.map((r) => TestResult.fromJson(r as Map<String, dynamic>)).toList();
  }
}
