import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/achievement.dart';
import '../../../data/models/points_config.dart';
import '../../achievements/providers/achievement_provider.dart';
import '../../points/presentation/manual_points_sheet.dart';
import '../../points/providers/points_provider.dart';
import '../../teams/providers/team_provider.dart';
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
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final theme = Theme.of(context);

    final isAdmin = teamAsync.valueOrNull?.userIsAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spillerprofil'),
        actions: [
          if (isAdmin)
            IconButton(
              onPressed: () {
                final members = membersAsync.valueOrNull ?? [];
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

                  const SizedBox(height: 16),

                  // Points breakdown
                  _PointsSection(teamId: teamId, userId: userId),

                  const SizedBox(height: 16),

                  // Monthly stats
                  _MonthlyStatsSection(teamId: teamId, userId: userId),

                  const SizedBox(height: 16),

                  // Achievements
                  _AchievementsSection(teamId: teamId, userId: userId),
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

// ============ POINTS SECTION ============

class _PointsSection extends ConsumerWidget {
  final String teamId;
  final String userId;

  const _PointsSection({required this.teamId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceStatsAsync = ref.watch(
      userAttendanceStatsProvider((teamId: teamId, userId: userId, seasonId: null)),
    );
    final theme = Theme.of(context);

    return attendanceStatsAsync.when(
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
                          child: _PointsTypeColumn(
                            icon: Icons.fitness_center,
                            value: stats.trainingPoints,
                            label: 'Trening',
                            color: Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _PointsTypeColumn(
                            icon: Icons.sports_soccer,
                            value: stats.matchPoints,
                            label: 'Kamp',
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _PointsTypeColumn(
                            icon: Icons.celebration,
                            value: stats.socialPoints,
                            label: 'Sosialt',
                            color: Colors.purple,
                          ),
                        ),
                        Expanded(
                          child: _PointsTypeColumn(
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
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text(
                'Kunne ikke laste poeng',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointsTypeColumn extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _PointsTypeColumn({
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

// ============ MONTHLY STATS SECTION ============

class _MonthlyStatsSection extends ConsumerWidget {
  final String teamId;
  final String userId;

  const _MonthlyStatsSection({required this.teamId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyStatsAsync = ref.watch(
      userMonthlyStatsProvider((teamId: teamId, userId: userId, months: 6)),
    );
    final theme = Theme.of(context);

    return monthlyStatsAsync.when(
      data: (monthlyStats) {
        if (monthlyStats.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Utvikling',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Simple bar chart for monthly points
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: monthlyStats.map((stat) {
                          final maxPoints = monthlyStats
                              .map((s) => s.totalPoints)
                              .reduce((a, b) => a > b ? a : b);
                          final height = maxPoints > 0
                              ? (stat.totalPoints / maxPoints) * 80
                              : 0.0;

                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${stat.totalPoints}',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: height,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getMonthAbbr(stat.month),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 24),
                    // Attendance rate trend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TrendStat(
                          label: 'Snitt oppmøte',
                          value: _avgAttendance(monthlyStats),
                          suffix: '%',
                        ),
                        _TrendStat(
                          label: 'Snitt poeng/mnd',
                          value: _avgPoints(monthlyStats),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(height: 8),
              Text(
                'Kunne ikke laste utvikling',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  double _avgAttendance(List<MonthlyUserStats> stats) {
    if (stats.isEmpty) return 0;
    final rates = stats.where((s) => s.attendanceRate != null).map((s) => s.attendanceRate!);
    if (rates.isEmpty) return 0;
    return rates.reduce((a, b) => a + b) / rates.length;
  }

  double _avgPoints(List<MonthlyUserStats> stats) {
    if (stats.isEmpty) return 0;
    return stats.map((s) => s.totalPoints).reduce((a, b) => a + b) / stats.length;
  }
}

class _TrendStat extends StatelessWidget {
  final String label;
  final double value;
  final String suffix;

  const _TrendStat({
    required this.label,
    required this.value,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '${value.toStringAsFixed(1)}$suffix',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
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

// ============ ACHIEVEMENTS SECTION ============

class _AchievementsSection extends ConsumerWidget {
  final String teamId;
  final String userId;

  const _AchievementsSection({required this.teamId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(
      userAchievementsProvider((userId: userId, teamId: teamId, seasonId: null)),
    );
    final progressAsync = ref.watch(
      userProgressProvider((userId: userId, teamId: teamId, seasonId: null)),
    );
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Earned achievements
                achievementsAsync.when(
                  data: (achievements) {
                    if (achievements.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingen achievements ennå',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: achievements.take(6).map((achievement) {
                        return _AchievementBadge(achievement: achievement);
                      }).toList(),
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Kunne ikke laste achievements'),
                ),

                // In-progress achievements
                progressAsync.when(
                  data: (progress) {
                    final inProgress = progress.where((p) => p.percentComplete < 100).take(3).toList();
                    if (inProgress.isEmpty) return const SizedBox.shrink();

                    return Column(
                      children: [
                        const Divider(height: 24),
                        Text(
                          'Under arbeid',
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...inProgress.map((p) => _ProgressMini(progress: p)),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final UserAchievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: achievement.achievementName ?? '',
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: _getTierColor(achievement.tier).withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: _getTierColor(achievement.tier),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            achievement.icon ?? _getTierEmoji(achievement.tier),
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }

  Color _getTierColor(AchievementTier? tier) {
    switch (tier) {
      case AchievementTier.platinum:
        return Colors.cyan;
      case AchievementTier.gold:
        return Colors.amber;
      case AchievementTier.silver:
        return Colors.grey.shade400;
      case AchievementTier.bronze:
      default:
        return Colors.brown.shade300;
    }
  }

  String _getTierEmoji(AchievementTier? tier) {
    switch (tier) {
      case AchievementTier.platinum:
        return '\u{1F4A0}';
      case AchievementTier.gold:
        return '\u{1F3C6}';
      case AchievementTier.silver:
        return '\u{1F948}';
      case AchievementTier.bronze:
      default:
        return '\u{1F949}';
    }
  }
}

class _ProgressMini extends StatelessWidget {
  final AchievementProgress progress;

  const _ProgressMini({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              progress.icon ?? '\u{1F3AF}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.achievementName ?? '',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: progress.percentComplete / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${progress.currentValue}/${progress.targetValue}',
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
