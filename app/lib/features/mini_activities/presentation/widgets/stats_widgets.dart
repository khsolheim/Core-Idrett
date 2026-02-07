import 'package:flutter/material.dart';
import '../../../../data/models/mini_activity_statistics.dart';

/// Card for displaying player statistics
class PlayerStatsCard extends StatelessWidget {
  final MiniActivityPlayerStats stats;
  final VoidCallback? onTap;
  final bool isCompact;

  const PlayerStatsCard({
    super.key,
    required this.stats,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return CompactStatsCard(stats: stats, onTap: onTap);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: stats.userProfileImageUrl != null
                        ? NetworkImage(stats.userProfileImageUrl!)
                        : null,
                    child: stats.userProfileImageUrl == null
                        ? Text(
                            stats.userName?.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(fontSize: 18),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.userName ?? 'Ukjent',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (stats.seasonName != null)
                          Text(
                            stats.seasonName!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats.totalPoints}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'poeng',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: StatsItem(
                      label: 'Kamper',
                      value: '${stats.totalParticipations}',
                    ),
                  ),
                  Expanded(
                    child: StatsItem(
                      label: 'Rekord',
                      value: stats.record,
                    ),
                  ),
                  Expanded(
                    child: StatsItem(
                      label: 'Seiersprosent',
                      value: stats.formattedWinRate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Podium finishes
              if (stats.podiumCount > 0) ...[
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    PodiumBadge(
                      position: 1,
                      count: stats.firstPlaceCount,
                    ),
                    PodiumBadge(
                      position: 2,
                      count: stats.secondPlaceCount,
                    ),
                    PodiumBadge(
                      position: 3,
                      count: stats.thirdPlaceCount,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact version of the player stats card
class CompactStatsCard extends StatelessWidget {
  final MiniActivityPlayerStats stats;
  final VoidCallback? onTap;

  const CompactStatsCard({
    super.key,
    required this.stats,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: stats.userProfileImageUrl != null
                    ? NetworkImage(stats.userProfileImageUrl!)
                    : null,
                child: stats.userProfileImageUrl == null
                    ? Text(
                        stats.userName?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(fontSize: 14),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.userName ?? 'Ukjent',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stats.record} • ${stats.formattedWinRate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${stats.totalPoints}p',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single stat label/value display
class StatsItem extends StatelessWidget {
  final String label;
  final String value;

  const StatsItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Badge showing podium position and count
class PodiumBadge extends StatelessWidget {
  final int position;
  final int count;

  const PodiumBadge({
    super.key,
    required this.position,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final emoji = switch (position) {
      1 => '\u{1F947}',
      2 => '\u{1F948}',
      3 => '\u{1F949}',
      _ => '',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text(
          'x$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// Head-to-head comparison card
class HeadToHeadCard extends StatelessWidget {
  final HeadToHeadStats stats;
  final String? currentUserId;
  final VoidCallback? onTap;

  const HeadToHeadCard({
    super.key,
    required this.stats,
    this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser1 = currentUserId == stats.user1Id;
    final myWins = isUser1 ? stats.user1Wins : stats.user2Wins;
    final theirWins = isUser1 ? stats.user2Wins : stats.user1Wins;
    final opponentName = isUser1 ? stats.user2Name : stats.user1Name;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs ${opponentName ?? "Ukjent"}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalMatchups} kamper',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              HeadToHeadScore(
                myWins: myWins,
                draws: stats.draws,
                theirWins: theirWins,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Score display for head-to-head matchups
class HeadToHeadScore extends StatelessWidget {
  final int myWins;
  final int draws;
  final int theirWins;

  const HeadToHeadScore({
    super.key,
    required this.myWins,
    required this.draws,
    required this.theirWins,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: myWins > theirWins
                ? Colors.green.shade100
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$myWins',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: myWins > theirWins ? Colors.green.shade800 : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '-',
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (draws > 0) ...[
          Text(
            '$draws',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '-',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theirWins > myWins
                ? Colors.red.shade100
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$theirWins',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theirWins > myWins ? Colors.red.shade800 : null,
            ),
          ),
        ),
      ],
    );
  }
}
