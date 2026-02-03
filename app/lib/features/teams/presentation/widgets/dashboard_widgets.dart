import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/activity.dart';
import '../../providers/dashboard_provider.dart';

/// Widget showing the next upcoming activity
class NextActivityWidget extends StatelessWidget {
  final ActivityInstance? activity;
  final String teamId;

  const NextActivityWidget({
    super.key,
    required this.activity,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activity == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Neste aktivitet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ingen kommende aktiviteter',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('EEEE d. MMMM', 'nb_NO');
    final now = DateTime.now();
    final activityDate = activity!.date;
    final isToday = activityDate.day == now.day &&
        activityDate.month == now.month &&
        activityDate.year == now.year;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = activityDate.day == tomorrow.day &&
        activityDate.month == tomorrow.month &&
        activityDate.year == tomorrow.year;

    String dateText;
    if (isToday) {
      dateText = 'I dag';
    } else if (isTomorrow) {
      dateText = 'I morgen';
    } else {
      dateText = dateFormat.format(activityDate);
    }

    final activityType = activity!.type ?? ActivityType.other;
    final activityTitle = activity!.title ?? 'Aktivitet';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/teams/$teamId/activities/${activity!.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _getActivityColor(activityType).withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(
                    _getActivityIcon(activityType),
                    size: 16,
                    color: _getActivityColor(activityType),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Neste aktivitet',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _getActivityColor(activityType),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isToday || isTomorrow ? FontWeight.bold : null,
                          color: isToday ? theme.colorScheme.primary : null,
                        ),
                      ),
                      if (activity!.startTime != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity!.startTime!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                  if (activity!.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity!.location!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.training:
        return Icons.fitness_center;
      case ActivityType.match:
        return Icons.sports;
      case ActivityType.social:
        return Icons.celebration;
      case ActivityType.other:
        return Icons.event;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.training:
        return Colors.blue;
      case ActivityType.match:
        return Colors.red;
      case ActivityType.social:
        return Colors.orange;
      case ActivityType.other:
        return Colors.grey;
    }
  }
}

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
                  onPressed: () => context.push('/teams/$teamId/leaderboard'),
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
              ...entries.take(3).map((entry) => _LeaderboardRow(entry: entry)),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: _RankBadge(rank: entry.rank),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundImage: entry.avatarUrl != null
                ? NetworkImage(entry.avatarUrl!)
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

class _RankBadge extends StatelessWidget {
  final int rank;

  const _RankBadge({required this.rank});

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
        onTap: () => context.push('/teams/$teamId/chat'),
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
        onTap: () => context.push('/teams/$teamId/fines'),
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
        _QuickLinkChip(
          icon: Icons.calendar_month,
          label: 'Kalender',
          onTap: () => context.push('/teams/$teamId/calendar'),
        ),
        _QuickLinkChip(
          icon: Icons.folder,
          label: 'Dokumenter',
          onTap: () => context.push('/teams/$teamId/documents'),
        ),
        _QuickLinkChip(
          icon: Icons.emoji_events,
          label: 'Achievements',
          onTap: () => context.push('/teams/$teamId/achievements'),
        ),
        _QuickLinkChip(
          icon: Icons.speed,
          label: 'Tester',
          onTap: () => context.push('/teams/$teamId/tests${isAdmin ? "?admin=true" : ""}'),
        ),
        if (isAdmin)
          _QuickLinkChip(
            icon: Icons.download,
            label: 'Eksport',
            onTap: () => context.push('/teams/$teamId/export?admin=true'),
          ),
      ],
    );
  }
}

class _QuickLinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLinkChip({
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
