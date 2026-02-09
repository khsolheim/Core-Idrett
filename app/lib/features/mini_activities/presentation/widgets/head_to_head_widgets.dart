import 'package:flutter/material.dart';
import '../../../../data/models/mini_activity_statistics.dart';

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
