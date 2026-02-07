import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/absence.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../providers/absence_provider.dart';

class PendingAbsencesTab extends ConsumerStatefulWidget {
  final String teamId;

  const PendingAbsencesTab({super.key, required this.teamId});

  @override
  ConsumerState<PendingAbsencesTab> createState() => _PendingAbsencesTabState();
}

class _PendingAbsencesTabState extends ConsumerState<PendingAbsencesTab> {
  final Set<String> _selectedIds = {};
  bool _isSelectMode = false;
  bool _isBulkProcessing = false;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectMode = false;
        }
      } else {
        _selectedIds.add(id);
        _isSelectMode = true;
      }
    });
  }

  void _selectAll(List<AbsenceRecord> absences) {
    setState(() {
      _selectedIds.addAll(absences.map((a) => a.id));
      _isSelectMode = true;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectMode = false;
    });
  }

  Future<void> _bulkApprove() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isBulkProcessing = true);

    int successCount = 0;
    for (final id in _selectedIds.toList()) {
      try {
        await ref.read(absenceRecordNotifierProvider.notifier).approveAbsence(
              widget.teamId,
              id,
            );
        successCount++;
      } catch (_) {
        // Continue with next item
      }
    }

    if (mounted) {
      setState(() {
        _isBulkProcessing = false;
        _selectedIds.clear();
        _isSelectMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount fravær godkjent')),
      );
    }
  }

  Future<void> _bulkReject() async {
    if (_selectedIds.isEmpty) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const RejectReasonDialog(),
    );

    if (reason == null) return;

    setState(() => _isBulkProcessing = true);

    int successCount = 0;
    for (final id in _selectedIds.toList()) {
      try {
        await ref.read(absenceRecordNotifierProvider.notifier).rejectAbsence(
              widget.teamId,
              id,
              reason: reason.isNotEmpty ? reason : null,
            );
        successCount++;
      } catch (_) {
        // Continue with next item
      }
    }

    if (mounted) {
      setState(() {
        _isBulkProcessing = false;
        _selectedIds.clear();
        _isSelectMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount fravær avvist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingAbsencesProvider(widget.teamId));
    final theme = Theme.of(context);

    return pendingAsync.when2(
      onRetry: () => ref.invalidate(pendingAbsencesProvider(widget.teamId)),
      data: (absences) {
        if (absences.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.check_circle_outline,
            title: 'Ingen ventende fravær',
            subtitle: 'Alle fraværsmeldinger er behandlet',
          );
        }

        return Column(
          children: [
            // Bulk actions bar
            if (_isSelectMode || absences.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Row(
                  children: [
                    if (_isSelectMode) ...[
                      Text(
                        '${_selectedIds.length} valgt',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearSelection,
                        child: const Text('Fjern valg'),
                      ),
                      const Spacer(),
                      if (_isBulkProcessing)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else ...[
                        OutlinedButton.icon(
                          onPressed: _bulkReject,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Avvis'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _bulkApprove,
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Godkjenn'),
                        ),
                      ],
                    ] else ...[
                      Text(
                        '${absences.length} ventende',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _selectAll(absences),
                        icon: const Icon(Icons.select_all, size: 18),
                        label: const Text('Velg alle'),
                      ),
                    ],
                  ],
                ),
              ),

            // List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(pendingAbsencesProvider(widget.teamId));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: absences.length,
                  itemBuilder: (context, index) {
                    final absence = absences[index];
                    return PendingAbsenceCard(
                      teamId: widget.teamId,
                      absence: absence,
                      isSelected: _selectedIds.contains(absence.id),
                      isSelectMode: _isSelectMode,
                      onToggleSelect: () => _toggleSelection(absence.id),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fravær godkjent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke godkjenne: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fravær avvist')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke avvise: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                      ? NetworkImage(absence.userAvatarUrl!)
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

class RejectReasonDialog extends StatefulWidget {
  const RejectReasonDialog({super.key});

  @override
  State<RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<RejectReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Avvis fravær'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Begrunnelse (valgfritt)',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Avvis'),
        ),
      ],
    );
  }
}
