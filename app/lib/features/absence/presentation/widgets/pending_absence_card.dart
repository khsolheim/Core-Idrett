import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/error_display_service.dart';
import '../../../../data/models/absence.dart';
import '../../providers/absence_provider.dart';
import 'reject_reason_dialog.dart';

class PendingAbsenceCard extends ConsumerStatefulWidget {
  final String teamId;
  final AbsenceRecord absence;
  final bool isSelected;
  final bool isSelectMode;
  final VoidCallback? onToggleSelect;

  const PendingAbsenceCard({
    super.key,
    required this.teamId,
    required this.absence,
    this.isSelected = false,
    this.isSelectMode = false,
    this.onToggleSelect,
  });

  @override
  ConsumerState<PendingAbsenceCard> createState() =>
      _PendingAbsenceCardState();
}

class _PendingAbsenceCardState extends ConsumerState<PendingAbsenceCard> {
  bool _isLoading = false;

  Future<void> _approve() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(absenceRecordNotifierProvider.notifier).approveAbsence(
            widget.teamId,
            widget.absence.id,
          );
      if (mounted) {
        ErrorDisplayService.showSuccess('Fravær godkjent');
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayService.showWarning('Kunne ikke godkjenne fravær. Prøv igjen.');
      }
    } finally{
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reject() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const RejectReasonDialog(),
    );

    if (reason == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(absenceRecordNotifierProvider.notifier).rejectAbsence(
            widget.teamId,
            widget.absence.id,
            reason: reason.isNotEmpty ? reason : null,
          );
      if (mounted) {
        ErrorDisplayService.showSuccess('Fravær avvist');
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayService.showWarning('Kunne ikke avvise fravær. Prøv igjen.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final absence = widget.absence;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: widget.isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onLongPress: widget.onToggleSelect,
        onTap: widget.isSelectMode ? widget.onToggleSelect : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.isSelectMode) ...[
                    Checkbox(
                      value: widget.isSelected,
                      onChanged: (_) => widget.onToggleSelect?.call(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  CircleAvatar(
                  backgroundImage: absence.userAvatarUrl != null
                      ? CachedNetworkImageProvider(absence.userAvatarUrl!)
                      : null,
                  child: absence.userAvatarUrl == null && absence.userName != null
                      ? Text(absence.userName!.substring(0, 1).toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        absence.userName ?? 'Ukjent bruker',
                        style: theme.textTheme.titleSmall,
                      ),
                      if (absence.activityName != null)
                        Text(
                          absence.activityName!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ),
                if (absence.categoryName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      absence.categoryName!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            if (absence.reason != null && absence.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Begrunnelse:',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      absence.reason!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            if (!widget.isSelectMode) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _reject,
                    icon: const Icon(Icons.close),
                    label: const Text('Avvis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _approve,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Godkjenn'),
                  ),
                ],
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
