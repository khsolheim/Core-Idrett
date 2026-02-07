import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/statistics_provider.dart';

class AttendanceScreen extends ConsumerWidget {
  final String teamId;

  const AttendanceScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(teamAttendanceProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Oppmøte'),
      ),
      body: attendanceAsync.when2(
        onRetry: () => ref.invalidate(teamAttendanceProvider(teamId)),
        data: (records) {
          if (records.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.event_available_outlined,
              title: 'Ingen oppmøtedata',
              subtitle: 'Oppmøte registreres automatisk ved aktiviteter',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teamAttendanceProvider(teamId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Card(
                  key: ValueKey(record.userId),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: record.userAvatarUrl != null
                              ? CachedNetworkImageProvider(record.userAvatarUrl!)
                              : null,
                          child: record.userAvatarUrl == null
                              ? Text(record.userName.substring(0, 1).toUpperCase())
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.userName,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _StatChip(
                                    icon: Icons.check_circle,
                                    color: Colors.green,
                                    value: '${record.attended}',
                                  ),
                                  const SizedBox(width: 8),
                                  _StatChip(
                                    icon: Icons.cancel,
                                    color: Colors.red,
                                    value: '${record.missed}',
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'av ${record.totalActivities}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Percentage
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: record.percentage / 100,
                                strokeWidth: 6,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  _getPercentageColor(record.percentage),
                                ),
                              ),
                              Text(
                                '${record.percentage.round()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getPercentageColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 2),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
