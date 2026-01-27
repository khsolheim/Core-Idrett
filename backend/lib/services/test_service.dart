import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/test.dart';

class TestService {
  final Database _db;
  final _uuid = const Uuid();

  TestService(this._db);

  // ============ TEST TEMPLATES ============

  /// Get all test templates for a team
  Future<List<TestTemplate>> getTemplatesForTeam(String teamId) async {
    final result = await _db.client.select(
      'test_templates',
      filters: {'team_id': 'eq.$teamId'},
      order: 'name.asc',
    );

    return result.map((row) => TestTemplate.fromRow(row)).toList();
  }

  /// Get a test template by ID
  Future<TestTemplate?> getTemplateById(String templateId) async {
    final result = await _db.client.select(
      'test_templates',
      filters: {'id': 'eq.$templateId'},
    );

    if (result.isEmpty) return null;
    return TestTemplate.fromRow(result.first);
  }

  /// Create a new test template
  Future<TestTemplate> createTemplate({
    required String teamId,
    required String name,
    String? description,
    required String unit,
    bool higherIsBetter = false,
  }) async {
    final id = _uuid.v4();

    await _db.client.insert('test_templates', {
      'id': id,
      'team_id': teamId,
      'name': name,
      'description': description,
      'unit': unit,
      'higher_is_better': higherIsBetter,
    });

    return TestTemplate(
      id: id,
      teamId: teamId,
      name: name,
      description: description,
      unit: unit,
      higherIsBetter: higherIsBetter,
      createdAt: DateTime.now(),
    );
  }

  /// Update a test template
  Future<TestTemplate?> updateTemplate({
    required String templateId,
    String? name,
    String? description,
    String? unit,
    bool? higherIsBetter,
    bool clearDescription = false,
  }) async {
    final updates = <String, dynamic>{};

    if (name != null) updates['name'] = name;
    if (clearDescription) {
      updates['description'] = null;
    } else if (description != null) {
      updates['description'] = description;
    }
    if (unit != null) updates['unit'] = unit;
    if (higherIsBetter != null) updates['higher_is_better'] = higherIsBetter;

    if (updates.isEmpty) {
      return getTemplateById(templateId);
    }

    await _db.client.update(
      'test_templates',
      updates,
      filters: {'id': 'eq.$templateId'},
    );

    return getTemplateById(templateId);
  }

  /// Delete a test template
  Future<void> deleteTemplate(String templateId) async {
    await _db.client.delete(
      'test_templates',
      filters: {'id': 'eq.$templateId'},
    );
  }

  /// Get team ID for a template (for authorization)
  Future<String?> getTeamIdForTemplate(String templateId) async {
    final result = await _db.client.select(
      'test_templates',
      select: 'team_id',
      filters: {'id': 'eq.$templateId'},
    );

    if (result.isEmpty) return null;
    return result.first['team_id'] as String?;
  }

  // ============ TEST RESULTS ============

  /// Get results for a test template (with optional user filter)
  Future<List<TestResult>> getResultsForTemplate(
    String templateId, {
    String? userId,
    int? limit,
    int offset = 0,
  }) async {
    final filters = <String, String>{'test_template_id': 'eq.$templateId'};
    if (userId != null) {
      filters['user_id'] = 'eq.$userId';
    }

    final results = await _db.client.select(
      'test_results',
      filters: filters,
      order: 'recorded_at.desc',
      limit: limit,
      offset: offset,
    );

    if (results.isEmpty) return [];

    // Get user info
    final userIds = results.map((r) => r['user_id'] as String).toSet().toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    // Get template info
    final template = await getTemplateById(templateId);

    return results.map((r) {
      final user = userMap[r['user_id']] ?? {};
      return TestResult(
        id: r['id'] as String,
        testTemplateId: r['test_template_id'] as String,
        userId: r['user_id'] as String,
        instanceId: r['instance_id'] as String?,
        value: (r['value'] as num).toDouble(),
        recordedAt: DateTime.parse(r['recorded_at'] as String),
        notes: r['notes'] as String?,
        userName: user['name'] as String?,
        userAvatarUrl: user['avatar_url'] as String?,
        testName: template?.name,
        testUnit: template?.unit,
      );
    }).toList();
  }

  /// Get all results for a user across all tests in a team
  Future<List<TestResult>> getResultsForUser(
    String teamId,
    String userId, {
    int? limit,
    int offset = 0,
  }) async {
    // Get templates for team first
    final templates = await getTemplatesForTeam(teamId);
    if (templates.isEmpty) return [];

    final templateIds = templates.map((t) => t.id).toList();
    final templateMap = <String, TestTemplate>{};
    for (final t in templates) {
      templateMap[t.id] = t;
    }

    final results = await _db.client.select(
      'test_results',
      filters: {
        'test_template_id': 'in.(${templateIds.join(',')})',
        'user_id': 'eq.$userId',
      },
      order: 'recorded_at.desc',
      limit: limit,
      offset: offset,
    );

    return results.map((r) {
      final template = templateMap[r['test_template_id']];
      return TestResult(
        id: r['id'] as String,
        testTemplateId: r['test_template_id'] as String,
        userId: r['user_id'] as String,
        instanceId: r['instance_id'] as String?,
        value: (r['value'] as num).toDouble(),
        recordedAt: DateTime.parse(r['recorded_at'] as String),
        notes: r['notes'] as String?,
        testName: template?.name,
        testUnit: template?.unit,
      );
    }).toList();
  }

  /// Get best result for each user in a test (for ranking)
  Future<List<Map<String, dynamic>>> getTestRanking(
    String templateId, {
    int? limit,
  }) async {
    final template = await getTemplateById(templateId);
    if (template == null) return [];

    // Get all results
    final results = await _db.client.select(
      'test_results',
      filters: {'test_template_id': 'eq.$templateId'},
    );

    if (results.isEmpty) return [];

    // Find best result per user
    final bestResults = <String, Map<String, dynamic>>{};
    for (final r in results) {
      final userId = r['user_id'] as String;
      final value = (r['value'] as num).toDouble();

      if (!bestResults.containsKey(userId)) {
        bestResults[userId] = r;
      } else {
        final currentBest = (bestResults[userId]!['value'] as num).toDouble();
        final isBetter = template.higherIsBetter
            ? value > currentBest
            : value < currentBest;
        if (isBetter) {
          bestResults[userId] = r;
        }
      }
    }

    // Sort by best value
    final sorted = bestResults.values.toList();
    sorted.sort((a, b) {
      final aVal = (a['value'] as num).toDouble();
      final bVal = (b['value'] as num).toDouble();
      return template.higherIsBetter
          ? bVal.compareTo(aVal)
          : aVal.compareTo(bVal);
    });

    // Get user info
    final userIds = sorted.map((r) => r['user_id'] as String).toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    // Build ranking
    final ranking = <Map<String, dynamic>>[];
    for (int i = 0; i < sorted.length; i++) {
      if (limit != null && i >= limit) break;

      final r = sorted[i];
      final user = userMap[r['user_id']] ?? {};
      ranking.add({
        'rank': i + 1,
        'user_id': r['user_id'],
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
        'value': r['value'],
        'recorded_at': r['recorded_at'],
      });
    }

    return ranking;
  }

  /// Record a test result
  Future<TestResult> recordResult({
    required String testTemplateId,
    required String userId,
    String? instanceId,
    required double value,
    String? notes,
  }) async {
    final id = _uuid.v4();

    await _db.client.insert('test_results', {
      'id': id,
      'test_template_id': testTemplateId,
      'user_id': userId,
      'instance_id': instanceId,
      'value': value,
      'notes': notes,
    });

    return TestResult(
      id: id,
      testTemplateId: testTemplateId,
      userId: userId,
      instanceId: instanceId,
      value: value,
      recordedAt: DateTime.now(),
      notes: notes,
    );
  }

  /// Record multiple results at once
  Future<List<TestResult>> recordMultipleResults({
    required String testTemplateId,
    String? instanceId,
    required List<Map<String, dynamic>> results, // [{user_id, value, notes?}]
  }) async {
    final recorded = <TestResult>[];

    for (final r in results) {
      final result = await recordResult(
        testTemplateId: testTemplateId,
        userId: r['user_id'] as String,
        instanceId: instanceId,
        value: (r['value'] as num).toDouble(),
        notes: r['notes'] as String?,
      );
      recorded.add(result);
    }

    return recorded;
  }

  /// Get a test result by ID
  Future<TestResult?> getResultById(String resultId) async {
    final results = await _db.client.select(
      'test_results',
      filters: {'id': 'eq.$resultId'},
    );

    if (results.isEmpty) return null;
    return TestResult.fromRow(results.first);
  }

  /// Delete a test result
  Future<void> deleteResult(String resultId) async {
    await _db.client.delete(
      'test_results',
      filters: {'id': 'eq.$resultId'},
    );
  }

  /// Get user's personal best for a test
  Future<TestResult?> getPersonalBest(
    String templateId,
    String userId,
  ) async {
    final template = await getTemplateById(templateId);
    if (template == null) return null;

    final order = template.higherIsBetter ? 'value.desc' : 'value.asc';

    final results = await _db.client.select(
      'test_results',
      filters: {
        'test_template_id': 'eq.$templateId',
        'user_id': 'eq.$userId',
      },
      order: order,
      limit: 1,
    );

    if (results.isEmpty) return null;

    return TestResult(
      id: results.first['id'] as String,
      testTemplateId: results.first['test_template_id'] as String,
      userId: results.first['user_id'] as String,
      instanceId: results.first['instance_id'] as String?,
      value: (results.first['value'] as num).toDouble(),
      recordedAt: DateTime.parse(results.first['recorded_at'] as String),
      notes: results.first['notes'] as String?,
      testName: template.name,
      testUnit: template.unit,
    );
  }

  /// Get user's progress over time for a test
  Future<List<TestResult>> getUserProgress(
    String templateId,
    String userId, {
    int? limit,
  }) async {
    final template = await getTemplateById(templateId);

    final results = await _db.client.select(
      'test_results',
      filters: {
        'test_template_id': 'eq.$templateId',
        'user_id': 'eq.$userId',
      },
      order: 'recorded_at.asc',
      limit: limit,
    );

    return results.map((r) => TestResult(
      id: r['id'] as String,
      testTemplateId: r['test_template_id'] as String,
      userId: r['user_id'] as String,
      instanceId: r['instance_id'] as String?,
      value: (r['value'] as num).toDouble(),
      recordedAt: DateTime.parse(r['recorded_at'] as String),
      notes: r['notes'] as String?,
      testName: template?.name,
      testUnit: template?.unit,
    )).toList();
  }
}
