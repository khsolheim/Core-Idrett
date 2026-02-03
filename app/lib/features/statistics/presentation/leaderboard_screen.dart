import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/points_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../points/providers/points_provider.dart';
import '../../points/presentation/manual_points_sheet.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/statistics_provider.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String teamId;

  const LeaderboardScreen({super.key, required this.teamId});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _categories = [
    (LeaderboardCategory.total, 'Total', Icons.emoji_events),
    (LeaderboardCategory.attendance, 'Oppmote', Icons.check_circle),
    (LeaderboardCategory.training, 'Trening', Icons.fitness_center),
    (LeaderboardCategory.match, 'Kamp', Icons.sports_soccer),
    (LeaderboardCategory.social, 'Sosialt', Icons.celebration),
    (LeaderboardCategory.competition, 'Konkurranse', Icons.star),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(selectedLeaderboardCategoryProvider.notifier).state =
            _categories[_tabController.index].$1;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final isAdmin = teamAsync.valueOrNull?.userIsAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poengtavle'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Poenginnstillinger',
              onPressed: () => context.push('/teams/${widget.teamId}/points-config'),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'Flere valg',
              onSelected: (value) async {
                if (value == 'adjust') {
                  final membersAsync = ref.read(teamMembersProvider(widget.teamId));
                  if (membersAsync.hasValue && membersAsync.value!.isNotEmpty) {
                    showManualPointsSheet(
                      context,
                      teamId: widget.teamId,
                      members: membersAsync.value!,
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'adjust',
                  child: ListTile(
                    leading: Icon(Icons.edit_note),
                    title: Text('Juster poeng'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories
              .map((c) => Tab(
                    icon: Icon(c.$3, size: 20),
                    text: c.$2,
                  ))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories
            .map((c) => _CategoryLeaderboard(
                  teamId: widget.teamId,
                  category: c.$1,
                ))
            .toList(),
      ),
    );
  }
}

class _CategoryLeaderboard extends ConsumerWidget {
  final String teamId;
  final LeaderboardCategory category;

  const _CategoryLeaderboard({
    required this.teamId,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSeasonAsync = ref.watch(activeSeasonProvider(teamId));
    final seasonId = activeSeasonAsync.valueOrNull?.id;
    final entriesAsync = ref.watch(rankedLeaderboardProvider(
      (teamId: teamId, category: category, seasonId: seasonId),
    ));
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final theme = Theme.of(context);

    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.leaderboard_outlined,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingen poeng ennå',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Delta i aktiviteter for å tjene poeng',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activeSeasonProvider(teamId));
            ref.invalidate(rankedLeaderboardProvider(
              (teamId: teamId, category: category, seasonId: seasonId),
            ));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isCurrentUser = currentUser?.id == entry.userId;
              return _RankedLeaderboardCard(
                entry: entry,
                isCurrentUser: isCurrentUser,
                teamId: teamId,
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Kunne ikke laste poengtavle: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                ref.invalidate(activeSeasonProvider(teamId));
                ref.invalidate(rankedLeaderboardProvider(
                  (teamId: teamId, category: category, seasonId: seasonId),
                ));
              },
              child: const Text('Prøv igjen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedLeaderboardCard extends StatelessWidget {
  final RankedLeaderboardEntry entry;
  final bool isCurrentUser;
  final String teamId;

  const _RankedLeaderboardCard({
    required this.entry,
    required this.isCurrentUser,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentUser ? 4 : 1,
      color: isCurrentUser
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      shape: isCurrentUser
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            )
          : null,
      child: InkWell(
        onTap: () => context.push('/teams/$teamId/player/${entry.userId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Rank with trend indicator
              SizedBox(
                width: 50,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getRankColor(entry.rank, theme),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.rank}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: entry.rank <= 3
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (entry.trend != null && entry.rankChange != null)
                      _TrendIndicator(
                        trend: entry.trend!,
                        change: entry.rankChange!,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Avatar
              CircleAvatar(
                backgroundImage: entry.userAvatarUrl != null
                    ? NetworkImage(entry.userAvatarUrl!)
                    : null,
                child: entry.userAvatarUrl == null && entry.userName != null
                    ? Text(entry.userName!.substring(0, 1).toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),

              // Name and stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.userName ?? 'Ukjent',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isCurrentUser ? FontWeight.bold : null,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Du',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        if (entry.optedOut)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.visibility_off,
                              size: 14,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                    if (entry.attendanceRate != null || entry.currentStreak != null)
                      Text(
                        [
                          if (entry.attendanceRate != null)
                            '${entry.attendanceRate!.toStringAsFixed(0)}% oppmøte',
                          if (entry.currentStreak != null && entry.currentStreak! > 0)
                            '${entry.currentStreak} på rad',
                        ].join(' • '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),

              // Points
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${entry.points}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRankColor(int rank, ThemeData theme) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }
}

class _TrendIndicator extends StatelessWidget {
  final String trend;
  final int change;

  const _TrendIndicator({required this.trend, required this.change});

  @override
  Widget build(BuildContext context) {
    if (change == 0 || trend == 'stable') {
      return const SizedBox.shrink();
    }

    final isUp = trend == 'up';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUp ? Icons.arrow_upward : Icons.arrow_downward,
          size: 12,
          color: isUp ? Colors.green : Colors.red,
        ),
        Text(
          '${change.abs()}',
          style: TextStyle(
            fontSize: 10,
            color: isUp ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

