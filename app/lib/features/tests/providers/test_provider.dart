import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/statistics.dart';
import '../data/test_repository.dart';

/// Provider for test templates by team
final testTemplatesProvider = FutureProvider.family<List<TestTemplate>, String>((ref, teamId) async {
  final repo = ref.watch(testRepositoryProvider);
  return repo.getTemplates(teamId);
});

/// Provider for a single test template
final testTemplateProvider = FutureProvider.family<TestTemplate, String>((ref, templateId) async {
  final repo = ref.watch(testRepositoryProvider);
  return repo.getTemplate(templateId);
});

/// Provider for test results
final testResultsProvider = FutureProvider.family<List<TestResult>, String>((ref, templateId) async {
  final repo = ref.watch(testRepositoryProvider);
  return repo.getResults(templateId);
});

/// Provider for test ranking
final testRankingProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, templateId) async {
  final repo = ref.watch(testRepositoryProvider);
  return repo.getRanking(templateId);
});

/// State for test operations
class TestState {
  final bool isLoading;
  final String? error;
  final List<TestTemplate> templates;
  final TestTemplate? selectedTemplate;
  final List<TestResult> results;
  final List<Map<String, dynamic>> ranking;

  const TestState({
    this.isLoading = false,
    this.error,
    this.templates = const [],
    this.selectedTemplate,
    this.results = const [],
    this.ranking = const [],
  });

  TestState copyWith({
    bool? isLoading,
    String? error,
    List<TestTemplate>? templates,
    TestTemplate? selectedTemplate,
    List<TestResult>? results,
    List<Map<String, dynamic>>? ranking,
  }) {
    return TestState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      results: results ?? this.results,
      ranking: ranking ?? this.ranking,
    );
  }
}

/// Test notifier for managing test state
class TestNotifier extends StateNotifier<TestState> {
  final TestRepository _repo;
  final String _teamId;
  final Ref _ref;

  TestNotifier(this._repo, this._teamId, this._ref) : super(const TestState()) {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final templates = await _repo.getTemplates(_teamId);
      state = state.copyWith(isLoading: false, templates: templates);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectTemplate(String templateId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final template = await _repo.getTemplate(templateId);
      final results = await _repo.getResults(templateId);
      final ranking = await _repo.getRanking(templateId);
      state = state.copyWith(
        isLoading: false,
        selectedTemplate: template,
        results: results,
        ranking: ranking,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTemplate({
    required String name,
    String? description,
    required String unit,
    bool higherIsBetter = false,
  }) async {
    try {
      final template = await _repo.createTemplate(
        teamId: _teamId,
        name: name,
        description: description,
        unit: unit,
        higherIsBetter: higherIsBetter,
      );
      state = state.copyWith(templates: [...state.templates, template]);
      _ref.invalidate(testTemplatesProvider(_teamId));
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateTemplate({
    required String templateId,
    String? name,
    String? description,
    String? unit,
    bool? higherIsBetter,
  }) async {
    try {
      final updated = await _repo.updateTemplate(
        templateId: templateId,
        name: name,
        description: description,
        unit: unit,
        higherIsBetter: higherIsBetter,
      );
      final templates = state.templates.map((t) =>
        t.id == templateId ? updated : t
      ).toList();
      state = state.copyWith(
        templates: templates,
        selectedTemplate: state.selectedTemplate?.id == templateId ? updated : state.selectedTemplate,
      );
      _ref.invalidate(testTemplatesProvider(_teamId));
      _ref.invalidate(testTemplateProvider(templateId));
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTemplate(String templateId) async {
    try {
      await _repo.deleteTemplate(templateId);
      state = state.copyWith(
        templates: state.templates.where((t) => t.id != templateId).toList(),
        selectedTemplate: state.selectedTemplate?.id == templateId ? null : state.selectedTemplate,
      );
      _ref.invalidate(testTemplatesProvider(_teamId));
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> recordResult({
    required String templateId,
    required String userId,
    required double value,
    String? instanceId,
    String? notes,
  }) async {
    try {
      final result = await _repo.recordResult(
        templateId: templateId,
        userId: userId,
        value: value,
        instanceId: instanceId,
        notes: notes,
      );
      if (state.selectedTemplate?.id == templateId) {
        state = state.copyWith(results: [result, ...state.results]);
        // Refresh ranking
        final ranking = await _repo.getRanking(templateId);
        state = state.copyWith(ranking: ranking);
      }
      _ref.invalidate(testResultsProvider(templateId));
      _ref.invalidate(testRankingProvider(templateId));
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> recordBulkResults({
    required String templateId,
    required List<Map<String, dynamic>> results,
    String? instanceId,
  }) async {
    try {
      final recorded = await _repo.recordBulkResults(
        templateId: templateId,
        results: results,
        instanceId: instanceId,
      );
      if (state.selectedTemplate?.id == templateId) {
        state = state.copyWith(results: [...recorded, ...state.results]);
        // Refresh ranking
        final ranking = await _repo.getRanking(templateId);
        state = state.copyWith(ranking: ranking);
      }
      _ref.invalidate(testResultsProvider(templateId));
      _ref.invalidate(testRankingProvider(templateId));
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteResult(String resultId) async {
    try {
      await _repo.deleteResult(resultId);
      state = state.copyWith(
        results: state.results.where((r) => r.id != resultId).toList(),
      );
      if (state.selectedTemplate != null) {
        final ranking = await _repo.getRanking(state.selectedTemplate!.id);
        state = state.copyWith(ranking: ranking);
        _ref.invalidate(testResultsProvider(state.selectedTemplate!.id));
        _ref.invalidate(testRankingProvider(state.selectedTemplate!.id));
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final testNotifierProvider = StateNotifierProvider.family<TestNotifier, TestState, String>((ref, teamId) {
  final repo = ref.watch(testRepositoryProvider);
  return TestNotifier(repo, teamId, ref);
});
