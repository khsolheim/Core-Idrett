import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity_statistics.dart';
import '../../providers/mini_activity_statistics_provider.dart';
import '../widgets/stats_widgets.dart';

/// Screen for viewing team mini-activity statistics and leaderboard
class MiniActivityStatisticsScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String? currentUserId;

  const MiniActivityStatisticsScreen({
    super.key,
    required this.teamId,
    this.currentUserId,
  });

  @override
  ConsumerState<MiniActivityStatisticsScreen> createState() =>
      _MiniActivityStatisticsScreenState();
}

class _MiniActivityStatisticsScreenState
    extends ConsumerState<MiniActivityStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'total_points';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamStatsAsync = ref.watch(teamMiniActivityStatsProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-aktiviteter'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ledertavle'),
            Tab(text: 'Rivaler'),
            Tab(text: 'Statistikk'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LeaderboardTab(
            teamId: widget.teamId,
            currentUserId: widget.currentUserId,
            sortBy: _sortBy,
            onSortChanged: (value) => setState(() => _sortBy = value),
            onPlayerTap: _showPlayerStats,
          ),
          _RivalriesTab(
            teamId: widget.teamId,
            currentUserId: widget.currentUserId,
          ),
          _TeamStatsTab(
            teamId: widget.teamId,
            teamStats: teamStatsAsync,
          ),
        ],
      ),
    );
  }

  void _refresh() {
    ref.invalidate(teamMiniActivityStatsProvider(widget.teamId));
    ref.invalidate(topRivalriesProvider(widget.teamId));
    ref.invalidate(teamLeaderboardProvider(TeamLeaderboardParams(
      teamId: widget.teamId,
      sortBy: _sortBy,
    )));
  }

  void _showPlayerStats(MiniActivityPlayerStats stats) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerStatsScreen(
          teamId: widget.teamId,
          userId: stats.userId,
          userName: stats.userName,
        ),
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final String teamId;
  final String? currentUserId;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final Function(MiniActivityPlayerStats) onPlayerTap;

  const _LeaderboardTab({
    required this.teamId,
    this.currentUserId,
    required this.sortBy,
    required this.onSortChanged,
    required this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final leaderboardAsync = ref.watch(teamLeaderboardProvider(TeamLeaderboardParams(
      teamId: teamId,
      sortBy: sortBy,
    )));

    return Column(
      children: [
        // Sort selector
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Sorter etter:',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'total_points', label: Text('Poeng')),
                    ButtonSegment(value: 'total_wins', label: Text('Seire')),
                  ],
                  selected: {sortBy},
                  onSelectionChanged: (selection) => onSortChanged(selection.first),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Leaderboard
        Expanded(
          child: leaderboardAsync.when(
            data: (stats) {
              if (stats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.leaderboard_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ingen statistikk ennå',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Spill mini-aktiviteter for å bygge opp statistikk',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final stat = stats[index];
                  final isCurrentUser = stat.userId == currentUserId;

                  return LeaderboardRow(
                    stats: stat,
                    position: index + 1,
                    isCurrentUser: isCurrentUser,
                    onTap: () => onPlayerTap(stat),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Feil: $e')),
          ),
        ),
      ],
    );
  }
}

class _RivalriesTab extends ConsumerWidget {
  final String teamId;
  final String? currentUserId;

  const _RivalriesTab({
    required this.teamId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rivalriesAsync = ref.watch(topRivalriesProvider(teamId));

    return rivalriesAsync.when(
      data: (rivalries) {
        if (rivalries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingen rivaler ennå',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Spill mot hverandre for å bygge opp rivaliseringer',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rivalries.length,
          itemBuilder: (context, index) {
            final rivalry = rivalries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _RivalryCard(
                rivalry: rivalry,
                position: index + 1,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Feil: $e')),
    );
  }
}

class _RivalryCard extends StatelessWidget {
  final HeadToHeadStats rivalry;
  final int position;

  const _RivalryCard({
    required this.rivalry,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Rivalry header
            Row(
              children: [
                if (rivalry.isRivalry)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'RIVAL',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  '${rivalry.totalMatchups} kamper',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Players vs display
            Row(
              children: [
                Expanded(
                  child: _PlayerColumn(
                    name: rivalry.user1Name ?? 'Spiller 1',
                    wins: rivalry.user1Wins,
                    isLeading: rivalry.user1Wins > rivalry.user2Wins,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      'VS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (rivalry.draws > 0)
                      Text(
                        '${rivalry.draws} uavgjort',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: _PlayerColumn(
                    name: rivalry.user2Name ?? 'Spiller 2',
                    wins: rivalry.user2Wins,
                    isLeading: rivalry.user2Wins > rivalry.user1Wins,
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerColumn extends StatelessWidget {
  final String name;
  final int wins;
  final bool isLeading;
  final bool alignRight;

  const _PlayerColumn({
    required this.name,
    required this.wins,
    this.isLeading = false,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: isLeading ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isLeading ? Colors.green.shade100 : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$wins',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isLeading ? Colors.green.shade800 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamStatsTab extends StatelessWidget {
  final String teamId;
  final AsyncValue<TeamMiniActivityStats> teamStats;

  const _TeamStatsTab({
    required this.teamId,
    required this.teamStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return teamStats.when(
      data: (stats) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oversikt',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Mini-aktiviteter',
                            value: '${stats.totalMiniActivities}',
                            icon: Icons.sports_esports_outlined,
                          ),
                        ),
                        Expanded(
                          child: _StatTile(
                            label: 'Deltakelser',
                            value: '${stats.totalParticipations}',
                            icon: Icons.people_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Fullført',
                            value: '${stats.completedMiniActivities}',
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        Expanded(
                          child: _StatTile(
                            label: 'Aktive',
                            value: '${stats.activeMiniActivities}',
                            icon: Icons.play_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Completion rate card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fullføringsrate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: stats.completionRate / 100,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stats.formattedCompletionRate,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top players
            if (stats.topPlayers.isNotEmpty) ...[
              Text(
                'Toppspillere',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...stats.topPlayers.take(5).map((player) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PlayerStatsCard(
                      stats: player,
                      isCompact: true,
                    ),
                  )),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Feil: $e')),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Player stats detail screen
class PlayerStatsScreen extends ConsumerWidget {
  final String teamId;
  final String userId;
  final String? userName;

  const PlayerStatsScreen({
    super.key,
    required this.teamId,
    required this.userId,
    this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(playerStatsAggregateProvider(PlayerStatsParams(
      teamId: teamId,
      userId: userId,
    )));

    return Scaffold(
      appBar: AppBar(
        title: Text(userName ?? 'Spillerstatistikk'),
      ),
      body: statsAsync.when(
        data: (aggregate) {
          final stats = aggregate.currentStats;
          if (stats == null) {
            return Center(
              child: Text(
                'Ingen statistikk funnet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Main stats card
              PlayerStatsCard(stats: stats),
              const SizedBox(height: 16),

              // Head-to-head records
              if (aggregate.headToHeadRecords.isNotEmpty) ...[
                Text(
                  'Head-to-Head',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...aggregate.headToHeadRecords.take(5).map((h2h) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HeadToHeadCard(
                        stats: h2h,
                        currentUserId: userId,
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Recent history
              if (aggregate.recentHistory.isNotEmpty) ...[
                Text(
                  'Siste resultater',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...aggregate.recentHistory.take(10).map((history) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _HistoryCard(history: history),
                    )),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Feil: $e')),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final MiniActivityTeamHistory history;

  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (history.medalEmoji != null)
              Text(history.medalEmoji!, style: const TextStyle(fontSize: 20))
            else
              SizedBox(
                width: 28,
                child: Text(
                  history.placementDisplay,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    history.miniActivityName ?? 'Mini-aktivitet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (history.teamName != null)
                    Text(
                      history.teamName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ),
            if (history.pointsEarned != 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: history.pointsEarned > 0
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  history.pointsEarned > 0
                      ? '+${history.pointsEarned}'
                      : '${history.pointsEarned}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: history.pointsEarned > 0
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
