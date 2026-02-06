import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mini_activity.dart';
import '../data/mini_activity_repository.dart';
import 'mini_activity_providers.dart';

// Notifier for creating templates
class CreateTemplateNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<bool> createTemplate({
    required String teamId,
    required String name,
    required MiniActivityType type,
    int defaultPoints = 1,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createTemplate(
        teamId: teamId,
        name: name,
        type: type,
        defaultPoints: defaultPoints,
      );
      ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteTemplate(String templateId, String teamId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteTemplate(templateId);
      ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final createTemplateProvider = NotifierProvider<CreateTemplateNotifier, AsyncValue<void>>(CreateTemplateNotifier.new);

// Notifier for template operations
class TemplateOperationsNotifier extends Notifier<AsyncValue<void>> {
  late final MiniActivityRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(miniActivityRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<ActivityTemplate?> updateTemplate({
    required String templateId,
    required String teamId,
    String? name,
    String? description,
    String? instructions,
    String? sportType,
    Map<String, dynamic>? suggestedRules,
    bool? isFavorite,
    int? winPoints,
    int? drawPoints,
    int? lossPoints,
    String? leaderboardId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.updateTemplate(
        templateId: templateId,
        name: name,
        description: description,
        instructions: instructions,
        sportType: sportType,
        suggestedRules: suggestedRules,
        isFavorite: isFavorite,
        winPoints: winPoints,
        drawPoints: drawPoints,
        lossPoints: lossPoints,
        leaderboardId: leaderboardId,
      );
      ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<ActivityTemplate?> toggleFavorite({
    required String templateId,
    required String teamId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.toggleTemplateFavorite(templateId);
      ref.invalidate(teamTemplatesProvider(teamId));
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final templateOperationsProvider = NotifierProvider<TemplateOperationsNotifier, AsyncValue<void>>(TemplateOperationsNotifier.new);
