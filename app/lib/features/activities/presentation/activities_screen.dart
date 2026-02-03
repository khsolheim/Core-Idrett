import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/activity.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/activity_provider.dart';
import 'widgets/series_action_dialog.dart';

class ActivitiesScreen extends ConsumerWidget {
  final String teamId;

  const ActivitiesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingInstancesProvider(teamId));

    // Enable realtime updates for activity responses
    ref.watch(activityResponsesRealtimeProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktiviteter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => context.pushNamed('calendar', pathParameters: {'teamId': teamId}),
            tooltip: 'Kalender',
          ),
        ],
      ),
      body: upcomingAsync.when(
        data: (instances) {
          if (instances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ingen kommende aktiviteter',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opprett en ny aktivitet for å komme i gang',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(upcomingInstancesProvider(teamId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: instances.length,
              itemBuilder: (context, index) {
                final instance = instances[index];
                return _ActivityInstanceCard(
                  instance: instance,
                  teamId: teamId,
                );
              },
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
              Text('Kunne ikke laste aktiviteter: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(upcomingInstancesProvider(teamId)),
                child: const Text('Prøv igjen'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('create-activity', pathParameters: {'teamId': teamId}),
        icon: const Icon(Icons.add),
        label: const Text('Ny aktivitet'),
      ),
    );
  }
}

class _ActivityInstanceCard extends ConsumerWidget {
  final ActivityInstance instance;
  final String teamId;

  const _ActivityInstanceCard({
    required this.instance,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEEE d. MMMM', 'nb_NO');
    final theme = Theme.of(context);
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final userAsync = ref.watch(authStateProvider);

    // Check if user can manage this activity
    final isAdmin = teamAsync.value?.userIsAdmin ?? false;
    final userId = userAsync.value?.id;
    final isCreator = userId != null && instance.createdBy == userId;
    final canManage = isAdmin || isCreator;

    // Don't show menu for cancelled or past activities
    final isPast = instance.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    final showMenu = canManage && instance.status != InstanceStatus.cancelled && !isPast;

    IconData typeIcon;
    switch (instance.type) {
      case ActivityType.training:
        typeIcon = Icons.fitness_center;
        break;
      case ActivityType.match:
        typeIcon = Icons.sports_soccer;
        break;
      case ActivityType.social:
        typeIcon = Icons.celebration;
        break;
      default:
        typeIcon = Icons.event;
    }

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      typeIcon,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instance.title ?? 'Aktivitet',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          dateFormat.format(instance.date),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (responseIcon != null)
                    Padding(
                      padding: EdgeInsets.only(right: showMenu ? 0 : 0),
                      child: Icon(responseIcon, color: responseColor, size: 28),
                    ),
                  if (showMenu)
                    _buildMenuButton(context, ref),
                ],
              ),
              if (instance.startTime != null || instance.location != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (instance.startTime != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        instance.formattedTime,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (instance.startTime != null && instance.location != null)
                      const SizedBox(width: 16),
                    if (instance.location != null) ...[
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          instance.location!,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _ResponseCount(
                    icon: Icons.check_circle_outline,
                    count: instance.yesCount ?? 0,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _ResponseCount(
                    icon: Icons.cancel_outlined,
                    count: instance.noCount ?? 0,
                    color: Colors.red,
                  ),
                  if (instance.responseType == ResponseType.yesNoMaybe) ...[
                    const SizedBox(width: 16),
                    _ResponseCount(
                      icon: Icons.help_outline,
                      count: instance.maybeCount ?? 0,
                      color: Colors.orange,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handleMenuAction(context, ref, action),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rediger'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('Slett'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final isPartOfSeries = instance.isPartOfSeries;

    if (action == 'edit') {
      EditScope scope = EditScope.single;

      // If part of a series, ask which scope
      if (isPartOfSeries) {
        final selectedScope = await SeriesActionDialog.show(
          context: context,
          isDelete: false,
          seriesInfo: instance.seriesInfo,
        );
        if (selectedScope == null) return; // Cancelled
        scope = selectedScope;
      }

      // Navigate to edit screen
      if (context.mounted) {
        context.push(
          '/teams/$teamId/activities/${instance.id}/edit',
          extra: {'scope': scope},
        );
      }
    } else if (action == 'delete') {
      EditScope scope = EditScope.single;

      // If part of a series, ask which scope
      if (isPartOfSeries) {
        final selectedScope = await SeriesActionDialog.show(
          context: context,
          isDelete: true,
          seriesInfo: instance.seriesInfo,
        );
        if (selectedScope == null) return; // Cancelled
        scope = selectedScope;
      }

      // Show confirmation dialog
      if (context.mounted) {
        final confirmed = await DeleteConfirmationDialog.show(
          context: context,
          scope: scope,
        );
        if (!confirmed) return;

        // Perform delete
        final result = await ref.read(deleteInstanceProvider.notifier).deleteInstance(
              instanceId: instance.id,
              teamId: teamId,
              scope: scope,
            );

        if (context.mounted) {
          if (result != null) {
            final message = scope == EditScope.single
                ? 'Aktivitet slettet'
                : '${result.affectedCount} aktiviteter slettet';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            // Refresh the list
            ref.invalidate(upcomingInstancesProvider(teamId));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kunne ikke slette aktivitet')),
            );
          }
        }
      }
    }
  }
}

class _ResponseCount extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _ResponseCount({
    required this.icon,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
