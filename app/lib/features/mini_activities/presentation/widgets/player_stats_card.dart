import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/mini_activity_statistics.dart';
import 'stats_helpers.dart';

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
                        ? CachedNetworkImageProvider(stats.userProfileImageUrl!)
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
                    ? CachedNetworkImageProvider(stats.userProfileImageUrl!)
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
