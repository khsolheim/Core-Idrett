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
    final theme = Theme.of(context);

    if (isCompact) {
      return _CompactStatsCard(stats: stats, onTap: onTap);
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (stats.seasonName != null)
                          Text(
                            stats.seasonName!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
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
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'poeng',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
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
                    child: _StatItem(
                      label: 'Kamper',
                      value: '${stats.totalParticipations}',
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: 'Rekord',
                      value: stats.record,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
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
                    _PodiumBadge(
                      position: 1,
                      count: stats.firstPlaceCount,
                    ),
                    _PodiumBadge(
                      position: 2,
                      count: stats.secondPlaceCount,
                    ),
                    _PodiumBadge(
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

class _CompactStatsCard extends StatelessWidget {
  final MiniActivityPlayerStats stats;
  final VoidCallback? onTap;

  const _CompactStatsCard({
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
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

class _PodiumBadge extends StatelessWidget {
  final int position;
  final int count;

  const _PodiumBadge({
    required this.position,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final emoji = switch (position) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
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
              _HeadToHeadScore(
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

class _HeadToHeadScore extends StatelessWidget {
  final int myWins;
  final int draws;
  final int theirWins;

  const _HeadToHeadScore({
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

/// Leaderboard list widget
class MiniActivityLeaderboard extends StatelessWidget {
  final List<MiniActivityPlayerStats> stats;
  final String? currentUserId;
  final Function(MiniActivityPlayerStats)? onPlayerTap;

  const MiniActivityLeaderboard({
    super.key,
    required this.stats,
    this.currentUserId,
    this.onPlayerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.leaderboard_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Ingen statistikk ennå',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        final isCurrentUser = stat.userId == currentUserId;

        return LeaderboardRow(
          stats: stat,
          position: index + 1,
          isCurrentUser: isCurrentUser,
          onTap: onPlayerTap != null ? () => onPlayerTap!(stat) : null,
        );
      },
    );
  }
}

/// Single row in leaderboard
class LeaderboardRow extends StatelessWidget {
  final MiniActivityPlayerStats stats;
  final int position;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const LeaderboardRow({
    super.key,
    required this.stats,
    required this.position,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser ? theme.colorScheme.primaryContainer.withAlpha(77) : null,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: _PositionDisplay(position: position),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
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
                        fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      stats.record,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${stats.totalPoints}',
                style: theme.textTheme.titleLarge?.copyWith(
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

class _PositionDisplay extends StatelessWidget {
  final int position;

  const _PositionDisplay({required this.position});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (position <= 3) {
      final emoji = switch (position) {
        1 => '🥇',
        2 => '🥈',
        3 => '🥉',
        _ => '',
      };
      return Text(emoji, style: const TextStyle(fontSize: 20));
    }

    return Text(
      '$position',
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.outline,
      ),
      textAlign: TextAlign.center,
    );
  }
}
