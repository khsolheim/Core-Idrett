import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/mini_activity.dart';

/// List view for standalone activities, grouped by active/archived status
class StandaloneActivityList extends StatelessWidget {
  final List<MiniActivity> activities;
  final String teamId;

  const StandaloneActivityList({
    super.key,
    required this.activities,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen mini-aktiviteter enna',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trykk + for a opprette en ny aktivitet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group by archived status
    final active = activities.where((a) => !a.isArchived).toList();
    final archived = activities.where((a) => a.isArchived).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          _SectionHeader(
            title: 'Aktive',
            count: active.length,
          ),
          const SizedBox(height: 8),
          ...active.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StandaloneActivityCard(activity: a),
              )),
          const SizedBox(height: 16),
        ],
        if (archived.isNotEmpty) ...[
          _SectionHeader(
            title: 'Arkiverte',
            count: archived.length,
          ),
          const SizedBox(height: 8),
          ...archived.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StandaloneActivityCard(activity: a, isArchived: true),
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Card widget displaying a standalone mini-activity
class StandaloneActivityCard extends StatelessWidget {
  final MiniActivity activity;
  final bool isArchived;

  const StandaloneActivityCard({
    super.key,
    required this.activity,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openActivity(context),
        child: Opacity(
          opacity: isArchived ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ActivityTypeIcon(type: activity.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (activity.description != null)
                            Text(
                              activity.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    _TypeChip(type: activity.type, isArchived: isArchived),
                  ],
                ),
                if (activity.teams != null && activity.teams!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.teams!.length} lag',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      if (activity.enableLeaderboard)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.leaderboard_outlined,
                              size: 16,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ledertavle',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openActivity(BuildContext context) {
    final teamId = activity.teamId;
    if (teamId == null) return;
    context.pushNamed(
      'standalone-mini-activity-detail',
      pathParameters: {'teamId': teamId, 'miniActivityId': activity.id},
    );
  }
}

class _ActivityTypeIcon extends StatelessWidget {
  final MiniActivityType type;

  const _ActivityTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      MiniActivityType.team => (Icons.groups_outlined, Colors.blue),
      MiniActivityType.individual => (Icons.person_outline, Colors.green),
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final MiniActivityType type;
  final bool isArchived;

  const _TypeChip({
    required this.type,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isArchived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Arkivert',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
