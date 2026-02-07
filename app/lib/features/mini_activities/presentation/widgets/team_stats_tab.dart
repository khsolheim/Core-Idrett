import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/mini_activity_statistics.dart';
import 'stats_widgets.dart';

/// Tab content for team statistics overview in mini-activity statistics
class TeamStatsTab extends StatelessWidget {
  final String teamId;
  final AsyncValue<TeamMiniActivityStats> teamStats;

  const TeamStatsTab({
    super.key,
    required this.teamId,
    required this.teamStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return teamStats.when2(
      data: (stats) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oversikt',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Mini-aktiviteter',
                            value: '${stats.totalMiniActivities}',
                            icon: Icons.sports_esports_outlined,
                          ),
                        ),
                        Expanded(
                          child: _StatTile(
                            label: 'Deltakelser',
                            value: '${stats.totalParticipations}',
                            icon: Icons.people_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            label: 'Fullf\u00f8rt',
                            value: '${stats.completedMiniActivities}',
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                        Expanded(
                          child: _StatTile(
                            label: 'Aktive',
                            value: '${stats.activeMiniActivities}',
                            icon: Icons.play_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Completion rate card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fullf\u00f8ringsrate',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: stats.completionRate / 100,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stats.formattedCompletionRate,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top players
            if (stats.topPlayers.isNotEmpty) ...[
              Text(
                'Toppspillere',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...stats.topPlayers.take(5).map((player) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PlayerStatsCard(
                      stats: player,
                      isCompact: true,
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
