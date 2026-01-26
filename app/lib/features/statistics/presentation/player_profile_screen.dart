import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/statistics_provider.dart';

class PlayerProfileScreen extends ConsumerWidget {
  final String teamId;
  final String userId;

  const PlayerProfileScreen({
    super.key,
    required this.teamId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(playerStatisticsProvider((teamId: teamId, userId: userId)));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spillerprofil'),
      ),
      body: statsAsync.when(
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(playerStatisticsProvider((teamId: teamId, userId: userId)));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage: stats.userAvatarUrl != null
                                ? NetworkImage(stats.userAvatarUrl!)
                                : null,
                            child: stats.userAvatarUrl == null
                                ? Text(
                                    stats.userName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 32),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stats.userName,
                                  style: theme.textTheme.headlineSmall,
                                ),
                                if (stats.rating != null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rating: ${stats.rating!.rating.round()}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.primary,
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
                  ),
                  const SizedBox(height: 16),

                  // Attendance
                  Text(
                    'Oppmøte',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${stats.attendedActivities}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'Deltatt',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${stats.totalActivities - stats.attendedActivities}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: Colors.red,
                                  ),
                                ),
                                Text(
                                  'Fraværende',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${stats.attendancePercentage.round()}%',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  'Oppmøte',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating stats
                  if (stats.rating != null) ...[
                    Text(
                      'Kamper',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                value: '${stats.rating!.wins}',
                                label: 'Seire',
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                value: '${stats.rating!.draws}',
                                label: 'Uavgjort',
                                color: Colors.orange,
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                value: '${stats.rating!.losses}',
                                label: 'Tap',
                                color: Colors.red,
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                value: '${stats.rating!.winRate.round()}%',
                                label: 'Seierrate',
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Season stats
                  if (stats.currentSeason != null) ...[
                    Text(
                      'Sesong ${stats.currentSeason!.seasonYear}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _StatColumn(
                                    value: '${stats.currentSeason!.totalPoints}',
                                    label: 'Poeng',
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Expanded(
                                  child: _StatColumn(
                                    value: '${stats.currentSeason!.totalGoals}',
                                    label: 'Mål',
                                    color: Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: _StatColumn(
                                    value: '${stats.currentSeason!.totalAssists}',
                                    label: 'Assists',
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: _StatColumn(
                                    value: '${stats.currentSeason!.totalWins}',
                                    label: 'Seire',
                                    color: Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: _StatColumn(
                                    value: '${stats.currentSeason!.totalDraws}',
                                    label: 'Uavgjort',
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: _StatColumn(
                                    value: '${stats.currentSeason!.totalLosses}',
                                    label: 'Tap',
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Kunne ikke laste statistikk: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(
                  playerStatisticsProvider((teamId: teamId, userId: userId)),
                ),
                child: const Text('Prøv igjen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
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
    );
  }
}
