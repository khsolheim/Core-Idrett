import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/mini_activity_statistics.dart';

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
                'Ingen statistikk enn\u00e5',
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
                child: PositionDisplay(position: position),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
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

/// Display for leaderboard position (medal emoji for top 3, number otherwise)
class PositionDisplay extends StatelessWidget {
  final int position;

  const PositionDisplay({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (position <= 3) {
      final emoji = switch (position) {
        1 => '\u{1F947}',
        2 => '\u{1F948}',
        3 => '\u{1F949}',
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
