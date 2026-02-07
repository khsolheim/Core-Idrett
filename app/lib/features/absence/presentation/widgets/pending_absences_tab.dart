import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/absence.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../providers/absence_provider.dart';
import 'pending_absence_card.dart';
import 'reject_reason_dialog.dart';

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
        SnackBar(content: Text('$successCount fravaer godkjent')),
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
        SnackBar(content: Text('$successCount fravaer avvist')),
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
            title: 'Ingen ventende fravaer',
            subtitle: 'Alle fravaersmeldinger er behandlet',
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
