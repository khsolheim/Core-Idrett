import 'package:flutter/material.dart';
import '../../../../data/models/activity.dart';

/// Card showing the edit scope (single instance vs. this-and-future).
class EditScopeIndicator extends StatelessWidget {
  final EditScope scope;

  const EditScopeIndicator({super.key, required this.scope});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scopeDescription = scope == EditScope.single
        ? 'Kun denne aktiviteten endres'
        : 'Denne og alle fremtidige aktiviteter i serien endres';

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              scope == EditScope.single ? Icons.event : Icons.repeat,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scope.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    scopeDescription,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Warning card shown when an instance is already detached from its series.
class DetachedWarningCard extends StatelessWidget {
  const DetachedWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.link_off,
              color: theme.colorScheme.onTertiaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Denne aktiviteten er allerede løsrevet fra serien',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Warning card shown when editing "this and future" scope,
/// informing that responses will be reset.
class FutureEditWarningCard extends StatelessWidget {
  const FutureEditWarningCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Svar på berørte aktiviteter vil bli nullstilt',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
