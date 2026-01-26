import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/mini_activity.dart';
import '../providers/mini_activity_provider.dart';
import 'create_mini_activity_sheet.dart';

class MiniActivitiesList extends ConsumerWidget {
  final String instanceId;
  final String teamId;

  const MiniActivitiesList({
    super.key,
    required this.instanceId,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miniActivitiesAsync = ref.watch(instanceMiniActivitiesProvider(instanceId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mini-aktiviteter',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _showCreateSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Legg til'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        miniActivitiesAsync.when(
          data: (miniActivities) {
            if (miniActivities.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.sports_esports,
                          size: 48,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingen mini-aktiviteter',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: miniActivities.map((mini) {
                return _MiniActivityCard(
                  miniActivity: mini,
                  instanceId: instanceId,
                  teamId: teamId,
                );
              }).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 8),
                    Text('Feil: $error'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(instanceMiniActivitiesProvider(instanceId)),
                      child: const Text('Prøv igjen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

class _MiniActivityCard extends StatelessWidget {
  final MiniActivity miniActivity;
  final String instanceId;
  final String teamId;

  const _MiniActivityCard({
    required this.miniActivity,
    required this.instanceId,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => context.pushNamed(
          'mini-activity-detail',
          pathParameters: {
            'teamId': teamId,
            'instanceId': instanceId,
            'miniActivityId': miniActivity.id,
          },
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                Chip(
                  label: Text('${miniActivity.teamCount} lag'),
                  visualDensity: VisualDensity.compact,
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
