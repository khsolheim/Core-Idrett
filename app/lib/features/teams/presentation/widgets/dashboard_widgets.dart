import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/activity.dart';

/// Widget showing the next upcoming activity
class NextActivityWidget extends StatelessWidget {
  final ActivityInstance? activity;
  final String teamId;

  const NextActivityWidget({
    super.key,
    required this.activity,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activity == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Neste aktivitet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Ingen kommende aktiviteter',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('EEEE d. MMMM', 'nb_NO');
    final now = DateTime.now();
    final activityDate = activity!.date;
    final isToday = activityDate.day == now.day &&
        activityDate.month == now.month &&
        activityDate.year == now.year;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = activityDate.day == tomorrow.day &&
        activityDate.month == tomorrow.month &&
        activityDate.year == tomorrow.year;

    String dateText;
    if (isToday) {
      dateText = 'I dag';
    } else if (isTomorrow) {
      dateText = 'I morgen';
    } else {
      dateText = dateFormat.format(activityDate);
    }

    final activityType = activity!.type ?? ActivityType.other;
    final activityTitle = activity!.title ?? 'Aktivitet';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.pushNamed(
          'activity-detail',
          pathParameters: {'teamId': teamId, 'instanceId': activity!.id},
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _getActivityColor(activityType).withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(
                    _getActivityIcon(activityType),
                    size: 16,
                    color: _getActivityColor(activityType),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Neste aktivitet',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _getActivityColor(activityType),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activityTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isToday || isTomorrow ? FontWeight.bold : null,
                          color: isToday ? theme.colorScheme.primary : null,
                        ),
                      ),
                      if (activity!.startTime != null) ...[
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          activity!.startTime!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                  if (activity!.location != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity!.location!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.training:
        return Icons.fitness_center;
      case ActivityType.match:
        return Icons.sports;
      case ActivityType.social:
        return Icons.celebration;
      case ActivityType.other:
        return Icons.event;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.training:
        return Colors.blue;
      case ActivityType.match:
        return Colors.red;
      case ActivityType.social:
        return Colors.orange;
      case ActivityType.other:
        return Colors.grey;
    }
  }
}
