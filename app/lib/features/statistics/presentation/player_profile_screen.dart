import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../points/presentation/manual_points_sheet.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/statistics_provider.dart';
import 'widgets/player_profile_achievements_section.dart';
import 'widgets/player_profile_monthly_section.dart';
import 'widgets/player_profile_points_section.dart';

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
    final isAdmin = ref.watch(
      teamDetailProvider(teamId).select((t) => t.value?.userIsAdmin ?? false),
    );
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spillerprofil'),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () {
                final members = membersAsync.value ?? [];
                if (members.isNotEmpty) {
                  showManualPointsSheet(
                    context,
                    teamId: teamId,
                    members: members,
                    preselectedUserId: userId,
                  );
                }
              },
              icon: const Icon(Icons.edit_note),
              tooltip: 'Juster poeng',
            ),
        ],
      ),
      body: statsAsync.when2(
        onRetry: () => ref.invalidate(playerStatisticsProvider((teamId: teamId, userId: userId))),
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
                              child: StatColumn(
                                value: '${stats.rating!.wins}',
                                label: 'Seire',
                                color: Colors.green,
                              ),
                            ),
                            Expanded(
                              child: StatColumn(
                                value: '${stats.rating!.draws}',
                                label: 'Uavgjort',
                                color: Colors.orange,
                              ),
                            ),
                            Expanded(
                              child: StatColumn(
                                value: '${stats.rating!.losses}',
                                label: 'Tap',
                                color: Colors.red,
                              ),
                            ),
                            Expanded(
                              child: StatColumn(
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
                                  child: StatColumn(
                                    value: '${stats.currentSeason!.totalPoints}',
                                    label: 'Poeng',
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                Expanded(
                                  child: StatColumn(
                                    value: '${stats.currentSeason!.totalGoals}',
                                    label: 'Mål',
                                    color: Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: StatColumn(
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
                                  child: StatColumn(
                                    value: '${stats.currentSeason!.totalWins}',
                                    label: 'Seire',
                                    color: Colors.green,
                                  ),
                                ),
                                Expanded(
                                  child: StatColumn(
                                    value: '${stats.currentSeason!.totalDraws}',
                                    label: 'Uavgjort',
                                    color: Colors.orange,
                                  ),
                                ),
                                Expanded(
                                  child: StatColumn(
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

                  const SizedBox(height: 16),

                  // Points breakdown
                  PlayerProfilePointsSection(teamId: teamId, userId: userId),

                  const SizedBox(height: 16),

                  // Monthly stats
                  PlayerProfileMonthlySection(teamId: teamId, userId: userId),

                  const SizedBox(height: 16),

                  // Achievements
                  PlayerProfileAchievementsSection(teamId: teamId, userId: userId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const StatColumn({
    super.key,
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
