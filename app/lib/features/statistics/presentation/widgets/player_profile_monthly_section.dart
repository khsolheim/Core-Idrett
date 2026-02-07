import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/points_config.dart';
import '../../../points/providers/points_provider.dart';

class PlayerProfileMonthlySection extends ConsumerWidget {
  final String teamId;
  final String userId;

  const PlayerProfileMonthlySection({
    super.key,
    required this.teamId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyStatsAsync = ref.watch(
      userMonthlyStatsProvider((teamId: teamId, userId: userId, months: 6)),
    );
    final theme = Theme.of(context);

    return monthlyStatsAsync.when2(
      onRetry: () => ref.invalidate(
        userMonthlyStatsProvider((teamId: teamId, userId: userId, months: 6)),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
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
                        TrendStat(
                          label: 'Snitt oppmøte',
                          value: _avgAttendance(monthlyStats),
                          suffix: '%',
                        ),
                        TrendStat(
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

class TrendStat extends StatelessWidget {
  final String label;
  final double value;
  final String suffix;

  const TrendStat({
    super.key,
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
