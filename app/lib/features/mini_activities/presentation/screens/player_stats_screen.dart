import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../data/models/mini_activity_statistics.dart';
import '../../providers/mini_activity_statistics_provider.dart';
import '../widgets/stats_widgets.dart';

/// Screen for viewing individual player mini-activity statistics
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
      body: statsAsync.when2(
        onRetry: () => ref.invalidate(playerStatsAggregateProvider(PlayerStatsParams(
          teamId: teamId,
          userId: userId,
        ))),
        data: (aggregate) {
          final stats = aggregate.currentStats;
          if (stats == null) {
            return const EmptyStateWidget(
              icon: Icons.bar_chart_outlined,
              title: 'Ingen statistikk funnet',
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
                      child: HistoryCard(history: history),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Card displaying a single mini-activity history entry
class HistoryCard extends StatelessWidget {
  final MiniActivityTeamHistory history;

  const HistoryCard({super.key, required this.history});

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
