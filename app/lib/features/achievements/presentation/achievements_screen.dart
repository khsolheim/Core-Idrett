import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/achievement.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/achievement_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  final String teamId;

  const AchievementsScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final isAdmin = teamAsync.value?.userIsAdmin ?? false;

    if (user == null) {
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
            _MyAchievementsTab(teamId: teamId, userId: user.id),
            _AvailableAchievementsTab(teamId: teamId, userId: user.id),
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
              _AchievementSummaryCard(
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
                ...inProgress.map((p) => _ProgressCard(progress: p)),
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
                ...achievements.map((a) => _AchievementCard(achievement: a)),
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
                      ...notEarned.map((d) => _DefinitionCard(
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
                      ...earned.map((d) => _DefinitionCard(
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
              return _TeamAchievementCard(achievement: achievements[index]);
            },
          ),
        );
      },
    );
  }
}

class _AchievementSummaryCard extends StatelessWidget {
  final List<UserAchievement> achievements;
  final List<AchievementProgress> inProgress;

  const _AchievementSummaryCard({
    required this.achievements,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bronze =
        achievements.where((a) => a.definition?.tier == AchievementTier.bronze).length;
    final silver =
        achievements.where((a) => a.definition?.tier == AchievementTier.silver).length;
    final gold =
        achievements.where((a) => a.definition?.tier == AchievementTier.gold).length;
    final platinum =
        achievements.where((a) => a.definition?.tier == AchievementTier.platinum).length;
    final totalPoints =
        achievements.fold<int>(0, (sum, a) => sum + a.pointsAwarded);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TierCount(tier: AchievementTier.bronze, count: bronze),
                _TierCount(tier: AchievementTier.silver, count: silver),
                _TierCount(tier: AchievementTier.gold, count: gold),
                _TierCount(tier: AchievementTier.platinum, count: platinum),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Totalt oppnadd: ${achievements.length}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '+$totalPoints poeng',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (inProgress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${inProgress.length} i gang',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TierCount extends StatelessWidget {
  final AchievementTier tier;
  final int count;

  const _TierCount({required this.tier, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(tier.emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final AchievementProgress progress;

  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = progress.definition;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  def?.icon ?? '🎯',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        def?.name ?? 'Achievement',
                        style: theme.textTheme.titleSmall,
                      ),
                      if (def?.description != null)
                        Text(
                          def!.description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${progress.currentValue}/${progress.targetValue ?? "?"}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.progressPercent / 100,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final UserAchievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = achievement.definition;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getTierColor(def?.tier),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              def?.icon ?? def?.tier.emoji ?? '🏆',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(def?.name ?? 'Achievement'),
        subtitle: Text(
          'Oppnadd ${_formatDate(achievement.awardedAt)}',
          style: theme.textTheme.bodySmall,
        ),
        trailing: achievement.pointsAwarded > 0
            ? Chip(
                label: Text('+${achievement.pointsAwarded}'),
                backgroundColor: theme.colorScheme.primaryContainer,
              )
            : null,
      ),
    );
  }

  Color _getTierColor(AchievementTier? tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown.shade200;
      case AchievementTier.silver:
        return Colors.grey.shade300;
      case AchievementTier.gold:
        return Colors.amber.shade200;
      case AchievementTier.platinum:
        return Colors.blue.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _DefinitionCard extends StatelessWidget {
  final AchievementDefinition definition;
  final bool isEarned;

  const _DefinitionCard({
    required this.definition,
    required this.isEarned,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isEarned
          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : null,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isEarned ? Colors.grey.shade300 : _getTierColor(definition.tier),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              definition.isSecret && !isEarned ? '?' : (definition.icon ?? definition.tier.emoji),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          definition.isSecret && !isEarned ? 'Hemmelig achievement' : definition.name,
          style: TextStyle(
            color: isEarned ? theme.colorScheme.outline : null,
          ),
        ),
        subtitle: definition.isSecret && !isEarned
            ? null
            : Text(
                definition.description ?? definition.category.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: isEarned
            ? Icon(Icons.check_circle, color: Colors.green.shade400)
            : definition.bonusPoints > 0
                ? Chip(label: Text('+${definition.bonusPoints}'))
                : null,
      ),
    );
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown.shade200;
      case AchievementTier.silver:
        return Colors.grey.shade300;
      case AchievementTier.gold:
        return Colors.amber.shade200;
      case AchievementTier.platinum:
        return Colors.blue.shade100;
    }
  }
}

class _TeamAchievementCard extends StatelessWidget {
  final UserAchievement achievement;

  const _TeamAchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = achievement.definition;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: achievement.userAvatarUrl != null
              ? NetworkImage(achievement.userAvatarUrl!)
              : null,
          child: achievement.userAvatarUrl == null && achievement.userName != null
              ? Text(achievement.userName!.substring(0, 1).toUpperCase())
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                achievement.userName ?? 'Bruker',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              def?.icon ?? '🏆',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        subtitle: Text(
          '${def?.name ?? "Achievement"} • ${_formatDate(achievement.awardedAt)}',
        ),
        trailing: achievement.pointsAwarded > 0
            ? Text(
                '+${achievement.pointsAwarded}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'I dag';
    } else if (diff.inDays == 1) {
      return 'I gar';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} dager siden';
    } else {
      return '${date.day}.${date.month}';
    }
  }
}
