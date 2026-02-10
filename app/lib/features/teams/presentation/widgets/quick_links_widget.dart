import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Quick links grid for additional features
class QuickLinksWidget extends StatelessWidget {
  final String teamId;
  final bool isAdmin;

  const QuickLinksWidget({
    super.key,
    required this.teamId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        QuickLinkChip(
          icon: Icons.calendar_month,
          label: 'Kalender',
          onTap: () => context.pushNamed('calendar', pathParameters: {'teamId': teamId}),
        ),
        QuickLinkChip(
          icon: Icons.folder,
          label: 'Dokumenter',
          onTap: () => context.pushNamed('documents', pathParameters: {'teamId': teamId}),
        ),
        QuickLinkChip(
          icon: Icons.emoji_events,
          label: 'Prestasjoner',
          onTap: () => context.pushNamed('achievements', pathParameters: {'teamId': teamId}),
        ),
        QuickLinkChip(
          icon: Icons.speed,
          label: 'Tester',
          onTap: () => context.pushNamed(
            'tests',
            pathParameters: {'teamId': teamId},
            queryParameters: isAdmin ? {'admin': 'true'} : {},
          ),
        ),
        if (isAdmin)
          QuickLinkChip(
            icon: Icons.download,
            label: 'Eksport',
            onTap: () => context.pushNamed(
              'export',
              pathParameters: {'teamId': teamId},
              queryParameters: {'admin': 'true'},
            ),
          ),
      ],
    );
  }
}

/// Individual quick link chip
class QuickLinkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickLinkChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );
  }
}
