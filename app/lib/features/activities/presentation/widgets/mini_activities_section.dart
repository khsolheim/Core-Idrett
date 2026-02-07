import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/mini_activity.dart';
import '../../../mini_activities/providers/mini_activity_provider.dart';
import '../../../mini_activities/presentation/create_mini_activity_sheet.dart';

/// Section displaying mini-activities on the activity detail screen.
/// Shows existing mini-activities and allows creation for authorized users.
class MiniActivitiesSection extends ConsumerWidget {
  final String instanceId;
  final String teamId;
  final bool canCreate;

  const MiniActivitiesSection({
    super.key,
    required this.instanceId,
    required this.teamId,
    required this.canCreate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miniActivitiesAsync = ref.watch(instanceMiniActivitiesProvider(instanceId));
    final theme = Theme.of(context);

    return miniActivitiesAsync.when2(
      onRetry: () => ref.invalidate(instanceMiniActivitiesProvider(instanceId)),
      data: (miniActivities) {
        // Hide section if no mini-activities and user cannot create
        if (miniActivities.isEmpty && !canCreate) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.sports_esports,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mini-aktiviteter',
                      style: theme.textTheme.titleMedium,
                    ),
                    const Spacer(),
                    if (canCreate)
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showCreateSheet(context),
                        tooltip: 'Legg til mini-aktivitet',
                      ),
                  ],
                ),
                if (miniActivities.isEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_esports,
                          size: 40,
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingen mini-aktiviteter ennå',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (canCreate) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showCreateSheet(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Legg til'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  ...miniActivities.map((mini) => _MiniActivityItem(
                        miniActivity: mini,
                        instanceId: instanceId,
                        teamId: teamId,
                      )),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  'Laster mini-aktiviteter...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      error: (error, retry) {
        // Don't show error section if user can't create - just hide it
        if (!canCreate) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.error),
                const SizedBox(height: 8),
                Text(
                  'Kunne ikke laste mini-aktiviteter',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: retry,
                  child: const Text('Prøv igjen'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateMiniActivitySheet(
        instanceId: instanceId,
        teamId: teamId,
      ),
    );
  }
}

class _MiniActivityItem extends StatelessWidget {
  final MiniActivity miniActivity;
  final String instanceId;
  final String teamId;

  const _MiniActivityItem({
    required this.miniActivity,
    required this.instanceId,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.pushNamed(
        'mini-activity-detail',
        pathParameters: {
          'teamId': teamId,
          'instanceId': instanceId,
          'miniActivityId': miniActivity.id,
        },
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                miniActivity.isTeamBased ? Icons.groups : Icons.person,
                color: theme.colorScheme.onSecondaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    miniActivity.name,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    miniActivity.type.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            if (miniActivity.teamCount != null && miniActivity.teamCount! > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${miniActivity.teamCount} lag',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
