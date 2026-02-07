import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../data/models/mini_activity_statistics.dart';
import '../../providers/mini_activity_statistics_provider.dart';
import 'leaderboard_widgets.dart';

/// Tab content for the leaderboard in mini-activity statistics
class LeaderboardTab extends ConsumerWidget {
  final String teamId;
  final String? currentUserId;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final Function(MiniActivityPlayerStats) onPlayerTap;

  const LeaderboardTab({
    super.key,
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
          child: leaderboardAsync.when2(
            onRetry: () => ref.invalidate(teamLeaderboardProvider(TeamLeaderboardParams(
              teamId: teamId,
              sortBy: sortBy,
            ))),
            data: (stats) {
              if (stats.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.leaderboard_outlined,
                  title: 'Ingen statistikk enn\u00e5',
                  subtitle: 'Spill mini-aktiviteter for \u00e5 bygge opp statistikk',
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
          ),
        ),
      ],
    );
  }
}
