import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../points/providers/points_provider.dart';

class PlayerProfilePointsSection extends ConsumerWidget {
  final String teamId;
  final String userId;

  const PlayerProfilePointsSection({
    super.key,
    required this.teamId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceStatsAsync = ref.watch(
      userAttendanceStatsProvider((teamId: teamId, userId: userId, seasonId: null)),
    );
    final theme = Theme.of(context);

    return attendanceStatsAsync.when2(
      onRetry: () => ref.invalidate(
        userAttendanceStatsProvider((teamId: teamId, userId: userId, seasonId: null)),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      data: (stats) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Poeng',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Total points
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 32,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${stats.totalPoints}',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'poeng totalt',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Breakdown by type
                    Row(
                      children: [
                        Expanded(
                          child: PointsTypeColumn(
                            icon: Icons.fitness_center,
                            value: stats.trainingPoints,
                            label: 'Trening',
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: PointsTypeColumn(
                            icon: Icons.sports_soccer,
                            value: stats.matchPoints,
                            label: 'Kamp',
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: PointsTypeColumn(
                            icon: Icons.celebration,
                            value: stats.socialPoints,
                            label: 'Sosialt',
                            color: Colors.purple,
                          ),
                        ),
                        Expanded(
                          child: PointsTypeColumn(
                            icon: Icons.star,
                            value: stats.competitionPoints,
                            label: 'Konkurranse',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    if (stats.bonusPoints != 0) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            stats.bonusPoints >= 0 ? Icons.add_circle : Icons.remove_circle,
                            color: stats.bonusPoints >= 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stats.bonusPoints >= 0 ? '+' : ''}${stats.bonusPoints} bonuspoeng',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: stats.bonusPoints >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (stats.currentStreak != null && stats.currentStreak! > 0) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            '${stats.currentStreak} aktiviteter på rad!',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class PointsTypeColumn extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const PointsTypeColumn({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}
