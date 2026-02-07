import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/absence.dart';
import '../providers/absence_provider.dart';

/// Dialog for players to register absence from an activity
class AbsenceRegistrationDialog extends ConsumerStatefulWidget {
  final String teamId;
  final String instanceId;
  final String userId;
  final String activityTitle;
  final bool requireReason;

  const AbsenceRegistrationDialog({
    super.key,
    required this.teamId,
    required this.instanceId,
    required this.userId,
    required this.activityTitle,
    this.requireReason = false,
  });

  @override
  ConsumerState<AbsenceRegistrationDialog> createState() =>
      _AbsenceRegistrationDialogState();
}

class _AbsenceRegistrationDialogState
    extends ConsumerState<AbsenceRegistrationDialog> {
  final _reasonController = TextEditingController();
  AbsenceCategory? _selectedCategory;
  bool _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(absenceCategoriesProvider(widget.teamId));

    return AlertDialog(
      title: const Text('Meld fravær'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Du melder fravær fra:',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.activityTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Category selection
            Text(
              'Årsak (valgfritt)',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            categoriesAsync.when2(
              onRetry: () => ref.invalidate(absenceCategoriesProvider(widget.teamId)),
              loading: () => const LinearProgressIndicator(),
              data: (categories) {
                if (categories.isEmpty) {
                  return Text(
                    'Ingen kategorier definert',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  );
                }
                return DropdownButtonFormField<AbsenceCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Velg kategori',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<AbsenceCategory>(
                      value: null,
                      child: Text('Ingen kategori'),
                    ),
                    ...categories.map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Row(
                            children: [
                              Expanded(child: Text(cat.name)),
                              if (cat.requiresApproval)
                                Icon(
                                  Icons.hourglass_empty,
                                  size: 16,
                                  color: theme.colorScheme.outline,
                                ),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedCategory = value),
                );
              },
            ),
            const SizedBox(height: 16),

            // Reason text field
            Text(
              widget.requireReason ? 'Begrunnelse (påkrevd)' : 'Begrunnelse',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Skriv en kort begrunnelse...',
                helperText: widget.requireReason
                    ? 'Obligatorisk'
                    : 'Valgfritt, men anbefalt',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Info about approval
            if (_selectedCategory?.requiresApproval ?? false) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Denne kategorien krever godkjenning fra admin',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Meld fravær'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();

    if (widget.requireReason && reason.isEmpty) {
      ErrorDisplayService.showWarning('Du må oppgi en begrunnelse');
      return;
    }

    setState(() => _loading = true);

    final result = await ref
        .read(absenceRecordNotifierProvider.notifier)
        .registerAbsence(
          teamId: widget.teamId,
          userId: widget.userId,
          instanceId: widget.instanceId,
          categoryId: _selectedCategory?.id,
          reason: reason.isNotEmpty ? reason : null,
        );

    if (mounted) {
      setState(() => _loading = false);
      if (result != null) {
        Navigator.pop(context, true);
        final statusMsg = result.status == AbsenceStatus.pending
            ? 'Fravær meldt - venter på godkjenning'
            : 'Fravær registrert';
        ErrorDisplayService.showSuccess(statusMsg);
      } else {
        ErrorDisplayService.showWarning('Kunne ikke registrere fravær');
      }
    }
  }
}

/// Show the absence registration dialog
Future<bool> showAbsenceRegistrationDialog(
  BuildContext context, {
  required String teamId,
  required String instanceId,
  required String userId,
  required String activityTitle,
  bool requireReason = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AbsenceRegistrationDialog(
      teamId: teamId,
      instanceId: instanceId,
      userId: userId,
      activityTitle: activityTitle,
      requireReason: requireReason,
    ),
  );
  return result ?? false;
}
