import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../providers/dashboard_provider.dart';

/// Widget showing top leaderboard entries
class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String teamId;

  const LeaderboardWidget({
    super.key,
    required this.entries,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.leaderboard, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Leaderboard',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.pushNamed('leaderboard', pathParameters: {'teamId': teamId}),
                  child: const Text('Se alle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text(
                'Ingen poeng registrert enda',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            else
              ...entries.take(3).map((entry) => DashboardLeaderboardRow(entry: entry)),
          ],
        ),
      ),
    );
  }
}

/// Single row in the dashboard leaderboard preview
class DashboardLeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const DashboardLeaderboardRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: DashboardRankBadge(rank: entry.rank),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundImage: entry.avatarUrl != null
                ? CachedNetworkImageProvider(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.userName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.userName,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${entry.points} p',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge showing rank with color for top 3
class DashboardRankBadge extends StatelessWidget {
  final int rank;

  const DashboardRankBadge({super.key, required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getRankColor(rank),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return Text(
      '$rank.',
      style: TextStyle(
        color: Theme.of(context).colorScheme.outline,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.transparent;
    }
  }
}

/// Widget showing unread messages count
class MessagesWidget extends StatelessWidget {
  final int unreadCount;
  final String teamId;

  const MessagesWidget({
    super.key,
    required this.unreadCount,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => context.pushNamed('chat', pathParameters: {'teamId': teamId}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.chat_bubble,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Meldinger',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      unreadCount > 0
                          ? '$unreadCount uleste'
                          : 'Ingen nye meldinger',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: unreadCount > 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget showing fines summary
class FinesWidget extends StatelessWidget {
  final FinesSummary summary;
  final String teamId;

  const FinesWidget({
    super.key,
    required this.summary,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnpaid = summary.unpaidCount > 0;
    final hasPending = summary.pendingApproval > 0;

    return Card(
      child: InkWell(
        onTap: () => context.pushNamed('fines', pathParameters: {'teamId': teamId}),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasUnpaid
                      ? Colors.red.withValues(alpha: 0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: hasUnpaid ? Colors.red : theme.colorScheme.outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Botekasse',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasUnpaid)
                      Text(
                        '${summary.unpaidCount} ubetalte (${summary.unpaidAmount.toStringAsFixed(0)} kr)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                        ),
                      )
                    else if (hasPending)
                      Text(
                        '${summary.pendingApproval} venter godkjenning',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      )
                    else
                      Text(
                        'Ingen ubetalte boter',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick links grid for additional features
class QuickLinksWidget extends StatelessWidget {
  final String teamId;
  final bool isAdmin;

  const QuickLinksWidget({
    super.key,
    required this.teamId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        QuickLinkChip(
          icon: Icons.calendar_month,
          label: 'Kalender',
          onTap: () => context.pushNamed('calendar', pathParameters: {'teamId': teamId}),
        ),
        QuickLinkChip(
          icon: Icons.folder,
          label: 'Dokumenter',
          onTap: () => context.pushNamed('documents', pathParameters: {'teamId': teamId}),
        ),
        QuickLinkChip(
          icon: Icons.emoji_events,
          label: 'Achievements',
          onTap: () => context.pushNamed('achievements', pathParameters: {'teamId': teamId}),
        ),
        QuickLinkChip(
          icon: Icons.speed,
          label: 'Tester',
          onTap: () => context.pushNamed(
            'tests',
            pathParameters: {'teamId': teamId},
            queryParameters: isAdmin ? {'admin': 'true'} : {},
          ),
        ),
        if (isAdmin)
          QuickLinkChip(
            icon: Icons.download,
            label: 'Eksport',
            onTap: () => context.pushNamed(
              'export',
              pathParameters: {'teamId': teamId},
              queryParameters: {'admin': 'true'},
            ),
          ),
      ],
    );
  }
}

/// Individual quick link chip
class QuickLinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickLinkChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }
}
