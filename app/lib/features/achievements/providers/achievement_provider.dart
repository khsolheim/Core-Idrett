import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/achievement.dart';
import '../data/achievement_repository.dart';

// Repository provider
final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AchievementRepository(client);
});

// ============ ACHIEVEMENT DEFINITIONS ============

final achievementDefinitionsProvider = FutureProvider.family<
    List<AchievementDefinition>,
    ({String teamId, bool includeGlobal, bool activeOnly, AchievementCategory? category})>(
    (ref, params) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getDefinitions(
    params.teamId,
    includeGlobal: params.includeGlobal,
    activeOnly: params.activeOnly,
    category: params.category,
  );
});

final teamAchievementsProvider =
    FutureProvider.family<List<AchievementDefinition>, String>(
        (ref, teamId) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getDefinitions(teamId, includeGlobal: true, activeOnly: true);
});

final achievementDefinitionProvider =
    FutureProvider.family<AchievementDefinition?, String>(
        (ref, definitionId) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getDefinitionById(definitionId);
});

class AchievementDefinitionNotifier
    extends StateNotifier<AsyncValue<AchievementDefinition?>> {
  final AchievementRepository _repo;
  final Ref _ref;

  AchievementDefinitionNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<AchievementDefinition?> createDefinition({
    required String teamId,
    required String code,
    required String name,
    String? description,
    String? icon,
    String? color,
    AchievementTier tier = AchievementTier.bronze,
    required AchievementCategory category,
    required AchievementCriteria criteria,
    int bonusPoints = 0,
    bool isActive = true,
    bool isSecret = false,
    bool isRepeatable = false,
    int? repeatCooldownDays,
  }) async {
    state = const AsyncValue.loading();
    try {
      final definition = await _repo.createDefinition(
        teamId: teamId,
        code: code,
        name: name,
        description: description,
        icon: icon,
        color: color,
        tier: tier,
        category: category,
        criteria: criteria,
        bonusPoints: bonusPoints,
        isActive: isActive,
        isSecret: isSecret,
        isRepeatable: isRepeatable,
        repeatCooldownDays: repeatCooldownDays,
      );
      state = AsyncValue.data(definition);
      _ref.invalidate(teamAchievementsProvider(teamId));
      return definition;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<AchievementDefinition?> updateDefinition({
    required String teamId,
    required String definitionId,
    String? name,
    String? description,
    String? icon,
    String? color,
    AchievementTier? tier,
    AchievementCriteria? criteria,
    int? bonusPoints,
    bool? isActive,
    bool? isSecret,
    bool? isRepeatable,
    int? repeatCooldownDays,
    bool clearDescription = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final definition = await _repo.updateDefinition(
        definitionId: definitionId,
        name: name,
        description: description,
        icon: icon,
        color: color,
        tier: tier,
        criteria: criteria,
        bonusPoints: bonusPoints,
        isActive: isActive,
        isSecret: isSecret,
        isRepeatable: isRepeatable,
        repeatCooldownDays: repeatCooldownDays,
        clearDescription: clearDescription,
      );
      state = AsyncValue.data(definition);
      _ref.invalidate(teamAchievementsProvider(teamId));
      _ref.invalidate(achievementDefinitionProvider(definitionId));
      return definition;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> deleteDefinition(String teamId, String definitionId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteDefinition(definitionId);
      state = const AsyncValue.data(null);
      _ref.invalidate(teamAchievementsProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final achievementDefinitionNotifierProvider = StateNotifierProvider<
    AchievementDefinitionNotifier, AsyncValue<AchievementDefinition?>>((ref) {
  final repo = ref.watch(achievementRepositoryProvider);
  return AchievementDefinitionNotifier(repo, ref);
});

// ============ USER ACHIEVEMENTS ============

final userAchievementsProvider = FutureProvider.family<List<UserAchievement>,
    ({String userId, String? teamId, String? seasonId})>((ref, params) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getUserAchievements(
    params.userId,
    teamId: params.teamId,
    seasonId: params.seasonId,
  );
});

final userProgressProvider = FutureProvider.family<List<AchievementProgress>,
    ({String userId, String? teamId, String? seasonId})>((ref, params) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getUserProgress(
    params.userId,
    teamId: params.teamId,
    seasonId: params.seasonId,
  );
});

final userAchievementsSummaryProvider =
    FutureProvider.family<UserAchievementsSummary,
        ({String userId, String? teamId, String? seasonId})>(
        (ref, params) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getUserAchievementsSummary(
    params.userId,
    teamId: params.teamId,
    seasonId: params.seasonId,
  );
});

class UserAchievementNotifier extends StateNotifier<AsyncValue<UserAchievement?>> {
  final AchievementRepository _repo;
  final Ref _ref;

  UserAchievementNotifier(this._repo, this._ref)
      : super(const AsyncValue.data(null));

  Future<UserAchievement?> awardAchievement({
    required String teamId,
    required String userId,
    required String achievementId,
    String? seasonId,
    int? pointsAwarded,
    Map<String, dynamic>? triggerReference,
  }) async {
    state = const AsyncValue.loading();
    try {
      final achievement = await _repo.awardAchievement(
        teamId: teamId,
        userId: userId,
        achievementId: achievementId,
        seasonId: seasonId,
        pointsAwarded: pointsAwarded,
        triggerReference: triggerReference,
      );
      state = AsyncValue.data(achievement);
      // Invalidate related providers
      _ref.invalidate(userAchievementsProvider(
          (userId: userId, teamId: teamId, seasonId: seasonId)));
      _ref.invalidate(userAchievementsSummaryProvider(
          (userId: userId, teamId: teamId, seasonId: seasonId)));
      _ref.invalidate(teamRecentAchievementsProvider(teamId));
      return achievement;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<List<UserAchievement>> checkAndAward({
    required String teamId,
    required String userId,
    String? seasonId,
    Map<String, dynamic>? context,
  }) async {
    state = const AsyncValue.loading();
    try {
      final awarded = await _repo.checkAndAwardAchievements(
        teamId,
        userId,
        seasonId: seasonId,
        context: context,
      );
      state = const AsyncValue.data(null);
      // Invalidate related providers
      _ref.invalidate(userAchievementsProvider(
          (userId: userId, teamId: teamId, seasonId: seasonId)));
      _ref.invalidate(userProgressProvider(
          (userId: userId, teamId: teamId, seasonId: seasonId)));
      _ref.invalidate(userAchievementsSummaryProvider(
          (userId: userId, teamId: teamId, seasonId: seasonId)));
      _ref.invalidate(teamRecentAchievementsProvider(teamId));
      return awarded;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return [];
    }
  }
}

final userAchievementNotifierProvider =
    StateNotifierProvider<UserAchievementNotifier, AsyncValue<UserAchievement?>>(
        (ref) {
  final repo = ref.watch(achievementRepositoryProvider);
  return UserAchievementNotifier(repo, ref);
});

// ============ TEAM ACHIEVEMENTS OVERVIEW ============

final teamRecentAchievementsProvider =
    FutureProvider.family<List<UserAchievement>, String>((ref, teamId) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getTeamRecentAchievements(teamId, limit: 10);
});

final teamRecentAchievementsWithParamsProvider = FutureProvider.family<
    List<UserAchievement>,
    ({String teamId, int? limit, String? seasonId})>((ref, params) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getTeamRecentAchievements(
    params.teamId,
    limit: params.limit,
    seasonId: params.seasonId,
  );
});

final teamAchievementCountsProvider =
    FutureProvider.family<Map<String, int>, ({String teamId, String? seasonId})>(
        (ref, params) async {
  final repo = ref.watch(achievementRepositoryProvider);
  return repo.getTeamAchievementCounts(params.teamId, seasonId: params.seasonId);
});

// ============ SELECTED CATEGORY STATE ============

final selectedAchievementCategoryProvider =
    StateProvider<AchievementCategory?>((ref) => null);
