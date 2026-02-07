import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/activity.dart';
import '../providers/activity_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  final String teamId;

  const CalendarScreen({super.key, required this.teamId});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  DateTime _getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  DateTime _getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  Color _getActivityTypeColor(ActivityType type) {
    switch (type) {
      case ActivityType.training:
        return Colors.blue;
      case ActivityType.match:
        return Colors.red;
      case ActivityType.social:
        return Colors.purple;
      case ActivityType.other:
        return Colors.grey;
    }
  }

  IconData _getActivityTypeIcon(ActivityType type) {
    switch (type) {
      case ActivityType.training:
        return Icons.fitness_center;
      case ActivityType.match:
        return Icons.sports_soccer;
      case ActivityType.social:
        return Icons.celebration;
      case ActivityType.other:
        return Icons.event;
    }
  }

  List<ActivityInstance> _getEventsForDay(
      DateTime day, List<ActivityInstance> allInstances) {
    return allInstances.where((instance) {
      return isSameDay(instance.date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = _getFirstDayOfMonth(_focusedDay).subtract(const Duration(days: 7));
    final to = _getLastDayOfMonth(_focusedDay).add(const Duration(days: 7));

    final instancesAsync = ref.watch(calendarInstancesProvider((
      teamId: widget.teamId,
      from: from,
      to: to,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'I dag',
          ),
        ],
      ),
      body: instancesAsync.when2(
        onRetry: () => ref.invalidate(calendarInstancesProvider((
          teamId: widget.teamId,
          from: from,
          to: to,
        ))),
        data: (instances) {
          final selectedDayEvents = _selectedDay != null
              ? _getEventsForDay(_selectedDay!, instances)
              : <ActivityInstance>[];

          return Column(
            children: [
              TableCalendar<ActivityInstance>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                locale: 'nb_NO',
                startingDayOfWeek: StartingDayOfWeek.monday,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: (day) => _getEventsForDay(day, instances),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                  // Invalidate to fetch new month data
                  ref.invalidate(calendarInstancesProvider((
                    teamId: widget.teamId,
                    from: _getFirstDayOfMonth(focusedDay)
                        .subtract(const Duration(days: 7)),
                    to: _getLastDayOfMonth(focusedDay)
                        .add(const Duration(days: 7)),
                  )));
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: theme.colorScheme.onPrimary,
                  ),
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;

                    // Group by type to show colored dots
                    final types = events
                        .map((e) => e.type)
                        .whereType<ActivityType>()
                        .toSet()
                        .toList();
                    return Positioned(
                      bottom: 1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: types.take(3).map((type) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _getActivityTypeColor(type),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ActivityType.values.map((type) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getActivityTypeColor(type),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          type.displayName,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              // Events list for selected day
              Expanded(
                child: selectedDayEvents.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ingen aktiviteter denne dagen',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: selectedDayEvents.length,
                        itemBuilder: (context, index) {
                          final instance = selectedDayEvents[index];
                          final type = instance.type ?? ActivityType.other;
                          return _CalendarEventCard(
                            instance: instance,
                            teamId: widget.teamId,
                            typeColor: _getActivityTypeColor(type),
                            typeIcon: _getActivityTypeIcon(type),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(
          'create-activity',
          pathParameters: {'teamId': widget.teamId},
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ny aktivitet'),
      ),
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  final ActivityInstance instance;
  final String teamId;
  final Color typeColor;
  final IconData typeIcon;

  const _CalendarEventCard({
    required this.instance,
    required this.teamId,
    required this.typeColor,
    required this.typeIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? responseColor;
    IconData? responseIcon;
    switch (instance.userResponse) {
      case UserResponse.yes:
        responseColor = Colors.green;
        responseIcon = Icons.check_circle;
        break;
      case UserResponse.no:
        responseColor = Colors.red;
        responseIcon = Icons.cancel;
        break;
      case UserResponse.maybe:
        responseColor = Colors.orange;
        responseIcon = Icons.help;
        break;
      default:
        responseColor = null;
        responseIcon = null;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.pushNamed(
          'activity-detail',
          pathParameters: {'teamId': teamId, 'instanceId': instance.id},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instance.title ?? instance.type?.displayName ?? 'Aktivitet',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (instance.startTime != null) ...[
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            instance.formattedTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                        if (instance.location != null) ...[
                          if (instance.startTime != null)
                            const SizedBox(width: 12),
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              instance.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (responseIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(responseIcon, color: responseColor, size: 24),
                ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
