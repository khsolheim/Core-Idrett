import 'package:flutter/material.dart';
import '../../../../data/models/activity.dart';

class AdminActionsSection extends StatelessWidget {
  final ActivityInstance instance;
  final String teamId;
  final bool isAwardingPoints;
  final VoidCallback onAwardPoints;

  const AdminActionsSection({
    super.key,
    required this.instance,
    required this.teamId,
    required this.isAwardingPoints,
    required this.onAwardPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yesCount = instance.yesCount ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Administrator',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tildel oppm\u00F8tepoeng til alle som svarte "Ja" ($yesCount spillere)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isAwardingPoints ? null : onAwardPoints,
                icon: isAwardingPoints
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.emoji_events),
                label: Text(isAwardingPoints ? 'Tildeler poeng...' : 'Tildel oppm\u00F8tepoeng'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Poeng legges til p\u00E5 sesong-leaderboard. Allerede tildelte poeng hoppes over.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
