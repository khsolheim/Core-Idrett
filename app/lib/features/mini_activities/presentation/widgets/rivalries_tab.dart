import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../data/models/mini_activity_statistics.dart';
import '../../providers/mini_activity_statistics_provider.dart';

/// Tab content for rivalries in mini-activity statistics
class RivalriesTab extends ConsumerWidget {
  final String teamId;
  final String? currentUserId;

  const RivalriesTab({
    super.key,
    required this.teamId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rivalriesAsync = ref.watch(topRivalriesProvider(teamId));

    return rivalriesAsync.when2(
      onRetry: () => ref.invalidate(topRivalriesProvider(teamId)),
      data: (rivalries) {
        if (rivalries.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.people_outline,
            title: 'Ingen rivaler enn\u00e5',
            subtitle: 'Spill mot hverandre for \u00e5 bygge opp rivaliseringer',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rivalries.length,
          itemBuilder: (context, index) {
            final rivalry = rivalries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: RivalryCard(
                rivalry: rivalry,
                position: index + 1,
              ),
            );
          },
        );
      },
    );
  }
}

/// Card displaying a head-to-head rivalry between two players
class RivalryCard extends StatelessWidget {
  final HeadToHeadStats rivalry;
  final int position;

  const RivalryCard({
    super.key,
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
