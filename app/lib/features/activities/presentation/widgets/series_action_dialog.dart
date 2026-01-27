import 'package:flutter/material.dart';
import '../../../../data/models/activity.dart';

/// Dialog for choosing whether to edit/delete a single instance or all future instances
class SeriesActionDialog extends StatelessWidget {
  final bool isDelete;
  final SeriesInfo? seriesInfo;
  final void Function(EditScope scope) onScopeSelected;

  const SeriesActionDialog({
    super.key,
    required this.isDelete,
    this.seriesInfo,
    required this.onScopeSelected,
  });

  /// Shows the dialog and returns the selected scope, or null if cancelled
  static Future<EditScope?> show({
    required BuildContext context,
    required bool isDelete,
    SeriesInfo? seriesInfo,
  }) async {
    return showDialog<EditScope>(
      context: context,
      builder: (context) => SeriesActionDialog(
        isDelete: isDelete,
        seriesInfo: seriesInfo,
        onScopeSelected: (scope) => Navigator.of(context).pop(scope),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isDelete ? 'Slett aktivitet' : 'Rediger aktivitet';

    return AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dette er en del av en gjentakende serie${seriesInfo != null ? ' (${seriesInfo!.positionText})' : ''}.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Hva vil du gjøre?',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Avbryt'),
        ),
        OutlinedButton(
          onPressed: () => onScopeSelected(EditScope.single),
          child: Text(EditScope.single.displayName),
        ),
        FilledButton(
          onPressed: () => onScopeSelected(EditScope.thisAndFuture),
          style: isDelete
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(EditScope.thisAndFuture.displayName),
        ),
      ],
    );
  }
}

/// Confirmation dialog for delete operations
class DeleteConfirmationDialog extends StatelessWidget {
  final EditScope scope;
  final int affectedCount;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.scope,
    required this.affectedCount,
    required this.onConfirm,
  });

  /// Shows the confirmation dialog and returns true if confirmed
  static Future<bool> show({
    required BuildContext context,
    required EditScope scope,
    int affectedCount = 1,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        scope: scope,
        affectedCount: affectedCount,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final message = scope == EditScope.single
        ? 'Er du sikker på at du vil slette denne aktiviteten?'
        : 'Er du sikker på at du vil slette $affectedCount aktiviteter?';

    final warning = scope == EditScope.thisAndFuture
        ? 'Alle svar på disse aktivitetene vil også bli slettet.'
        : 'Alle svar på denne aktiviteten vil også bli slettet.';

    return AlertDialog(
      title: const Text('Bekreft sletting'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 8),
          Text(
            warning,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: const Text('Slett'),
        ),
      ],
    );
  }
}
