import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/achievement.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/achievement_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import 'widgets/achievement_cards.dart';

class AchievementsScreen extends ConsumerWidget {
  final String teamId;

  const AchievementsScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(
      authStateProvider.select((a) => a.value?.id),
    );
    final isAdmin = ref.watch(
      teamDetailProvider(teamId).select((t) => t.value?.userIsAdmin ?? false),
    );

    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Achievements'),
          actions: [
            if (isAdmin)
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Administrer achievements',
                onPressed: () => context.pushNamed(
                  'achievements-admin',
                  pathParameters: {'teamId': teamId},
                ),
              ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Mine', icon: Icon(Icons.person, size: 20)),
              Tab(text: 'Tilgjengelige', icon: Icon(Icons.stars, size: 20)),
              Tab(text: 'Team', icon: Icon(Icons.group, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyAchievementsTab(teamId: teamId, userId: userId),
            _AvailableAchievementsTab(teamId: teamId, userId: userId),
            _TeamAchievementsTab(teamId: teamId),
          ],
        ),
      ),
    );
  }
}

class _MyAchievementsTab extends ConsumerWidget {
  final String teamId;
  final String userId;

  const _MyAchievementsTab({required this.teamId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(userAchievementsProvider(
      (userId: userId, teamId: teamId, seasonId: null),
    ));
    final progressAsync = ref.watch(userProgressProvider(
      (userId: userId, teamId: teamId, seasonId: null),
    ));
    final theme = Theme.of(context);

    return achievementsAsync.when2(
      onRetry: () => ref.invalidate(userAchievementsProvider(
        (userId: userId, teamId: teamId, seasonId: null),
      )),
      data: (achievements) {
        final inProgress = progressAsync.value ?? [];

        if (achievements.isEmpty && inProgress.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.emoji_events_outlined,
            title: 'Ingen achievements enna',
            subtitle: 'Delta i aktiviteter for a tjene achievements',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(userAchievementsProvider(
              (userId: userId, teamId: teamId, seasonId: null),
            ));
            ref.invalidate(userProgressProvider(
              (userId: userId, teamId: teamId, seasonId: null),
            ));
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              AchievementSummaryCard(
                achievements: achievements,
                inProgress: inProgress,
              ),
              const SizedBox(height: 24),

              // In Progress section
              if (inProgress.isNotEmpty) ...[
                Text(
                  'I gang',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...inProgress.map((p) => AchievementProgressCard(progress: p)),
                const SizedBox(height: 24),
              ],

              // Earned section
              if (achievements.isNotEmpty) ...[
                Text(
                  'Oppnadd',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...achievements.map((a) => EarnedAchievementCard(achievement: a)),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AvailableAchievementsTab extends ConsumerWidget {
  final String teamId;
  final String userId;

  const _AvailableAchievementsTab({
    required this.teamId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final definitionsAsync = ref.watch(teamAchievementsProvider(teamId));
    final earnedAsync = ref.watch(userAchievementsProvider(
      (userId: userId, teamId: teamId, seasonId: null),
    ));
    final selectedCategory = ref.watch(selectedAchievementCategoryProvider);
    final theme = Theme.of(context);

    return definitionsAsync.when2(
      onRetry: () => ref.invalidate(teamAchievementsProvider(teamId)),
      data: (definitions) {
        final earnedIds =
            earnedAsync.value?.map((a) => a.achievementId).toSet() ?? {};

        // Filter by category
        final filtered = selectedCategory == null
            ? definitions
            : definitions.where((d) => d.category == selectedCategory).toList();

        // Split into earned and not earned
        final notEarned = filtered.where((d) => !earnedIds.contains(d.id)).toList();
        final earned = filtered.where((d) => earnedIds.contains(d.id)).toList();

        return Column(
          children: [
            // Category filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('Alle'),
                    selected: selectedCategory == null,
                    onSelected: (_) {
                      ref.read(selectedAchievementCategoryProvider.notifier).select(null);
                    },
                  ),
                  const SizedBox(width: 8),
                  ...AchievementCategory.values.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat.displayName),
                          selected: selectedCategory == cat,
                          onSelected: (_) {
                            ref.read(selectedAchievementCategoryProvider.notifier).select(cat);
                          },
                        ),
                      )),
                ],
              ),
            ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(teamAchievementsProvider(teamId));
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (notEarned.isNotEmpty) ...[
                      Text(
                        'Ikke oppnadd',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...notEarned.map((d) => AchievementDefinitionCard(
                            definition: d,
                            isEarned: false,
                          )),
                      const SizedBox(height: 24),
                    ],
                    if (earned.isNotEmpty) ...[
                      Text(
                        'Oppnadd',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...earned.map((d) => AchievementDefinitionCard(
                            definition: d,
                            isEarned: true,
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TeamAchievementsTab extends ConsumerWidget {
  final String teamId;

  const _TeamAchievementsTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(teamRecentAchievementsProvider(teamId));

    return recentAsync.when2(
      onRetry: () => ref.invalidate(teamRecentAchievementsProvider(teamId)),
      data: (achievements) {
        if (achievements.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.group_outlined,
            title: 'Ingen achievements pa laget enna',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teamRecentAchievementsProvider(teamId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              return TeamAchievementCard(achievement: achievements[index]);
            },
          ),
        );
      },
    );
  }
}
