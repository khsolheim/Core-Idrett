import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/absence.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/absence_provider.dart';

class AbsenceManagementScreen extends ConsumerStatefulWidget {
  final String teamId;

  const AbsenceManagementScreen({super.key, required this.teamId});

  @override
  ConsumerState<AbsenceManagementScreen> createState() =>
      _AbsenceManagementScreenState();
}

class _AbsenceManagementScreenState
    extends ConsumerState<AbsenceManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final isAdmin = teamAsync.valueOrNull?.userIsAdmin ?? false;
    final theme = Theme.of(context);

    // Admin guard
    if (teamAsync.hasValue && !isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fraværsadministrasjon')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('Du har ikke tilgang til denne siden', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Kun administratorer kan administrere fravær',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraværsadministrasjon'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Ventende'),
            Tab(icon: Icon(Icons.category), text: 'Kategorier'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingAbsencesTab(teamId: widget.teamId),
          _CategoriesTab(teamId: widget.teamId),
        ],
      ),
    );
  }
}

// ============ PENDING ABSENCES TAB ============

class _PendingAbsencesTab extends ConsumerStatefulWidget {
  final String teamId;

  const _PendingAbsencesTab({required this.teamId});

  @override
  ConsumerState<_PendingAbsencesTab> createState() => _PendingAbsencesTabState();
}

class _PendingAbsencesTabState extends ConsumerState<_PendingAbsencesTab> {
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
      builder: (context) => _RejectReasonDialog(),
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

    return pendingAsync.when(
      data: (absences) {
        if (absences.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ingen ventende fravær',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Alle fraværsmeldinger er behandlet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
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
                    return _PendingAbsenceCard(
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Kunne ikke laste fravær: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(pendingAbsencesProvider(widget.teamId)),
              child: const Text('Prøv igjen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingAbsenceCard extends ConsumerStatefulWidget {
  final String teamId;
  final AbsenceRecord absence;
  final bool isSelected;
  final bool isSelectMode;
  final VoidCallback? onToggleSelect;

  const _PendingAbsenceCard({
    required this.teamId,
    required this.absence,
    this.isSelected = false,
    this.isSelectMode = false,
    this.onToggleSelect,
  });

  @override
  ConsumerState<_PendingAbsenceCard> createState() =>
      _PendingAbsenceCardState();
}

class _PendingAbsenceCardState extends ConsumerState<_PendingAbsenceCard> {
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
      builder: (context) => _RejectReasonDialog(),
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

class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
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

// ============ CATEGORIES TAB ============

class _CategoriesTab extends ConsumerWidget {
  final String teamId;

  const _CategoriesTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(absenceCategoriesProvider(teamId));
    final theme = Theme.of(context);

    return categoriesAsync.when(
      data: (categories) {
        return Column(
          children: [
            Expanded(
              child: categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ingen kategorier',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Legg til kategorier for fraværstyper',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(absenceCategoriesProvider(teamId));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return _CategoryCard(
                            teamId: teamId,
                            category: categories[index],
                          );
                        },
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showAddCategoryDialog(context, ref, teamId),
                icon: const Icon(Icons.add),
                label: const Text('Legg til kategori'),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Kunne ikke laste kategorier: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(absenceCategoriesProvider(teamId)),
              child: const Text('Prøv igjen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(
      BuildContext context, WidgetRef ref, String teamId) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        teamId: teamId,
        onSave: (name, requiresApproval, countsAsValid) async {
          await ref.read(absenceCategoryNotifierProvider.notifier).createCategory(
                teamId: teamId,
                name: name,
                requiresApproval: requiresApproval,
                countsAsValid: countsAsValid,
              );
        },
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  final String teamId;
  final AbsenceCategory category;

  const _CategoryCard({
    required this.teamId,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(category.name),
        subtitle: Row(
          children: [
            if (category.requiresApproval)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: const Text('Krever godkjenning'),
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (category.countsAsValid)
              Chip(
                label: const Text('Gyldig fravær'),
                labelStyle: theme.textTheme.labelSmall,
                backgroundColor: theme.colorScheme.primaryContainer,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(context, ref);
            } else if (value == 'delete') {
              _showDeleteConfirmation(context, ref);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Rediger'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text(
                  'Slett',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        teamId: teamId,
        existingCategory: category,
        onSave: (name, requiresApproval, countsAsValid) async {
          await ref.read(absenceCategoryNotifierProvider.notifier).updateCategory(
                teamId: teamId,
                categoryId: category.id,
                name: name,
                requiresApproval: requiresApproval,
                countsAsValid: countsAsValid,
              );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett kategori'),
        content: Text('Er du sikker på at du vil slette "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref
                  .read(absenceCategoryNotifierProvider.notifier)
                  .deleteCategory(teamId, category.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final String teamId;
  final AbsenceCategory? existingCategory;
  final Future<void> Function(
      String name, bool requiresApproval, bool countsAsValid) onSave;

  const _CategoryFormDialog({
    required this.teamId,
    this.existingCategory,
    required this.onSave,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  late TextEditingController _nameController;
  late bool _requiresApproval;
  late bool _countsAsValid;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingCategory?.name ?? '',
    );
    _requiresApproval = widget.existingCategory?.requiresApproval ?? false;
    _countsAsValid = widget.existingCategory?.countsAsValid ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navn er påkrevd')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onSave(
        _nameController.text.trim(),
        _requiresApproval,
        _countsAsValid,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingCategory != null
                ? 'Kategori oppdatert'
                : 'Kategori opprettet'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kunne ikke lagre: $e'),
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
    final isEditing = widget.existingCategory != null;

    return AlertDialog(
      title: Text(isEditing ? 'Rediger kategori' : 'Ny kategori'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Navn',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Krever godkjenning'),
            subtitle: const Text('Admin må godkjenne dette fraværet'),
            value: _requiresApproval,
            onChanged: (value) => setState(() => _requiresApproval = value),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Teller som gyldig'),
            subtitle: const Text('Fjernes fra oppmøteberegning'),
            value: _countsAsValid,
            onChanged: (value) => setState(() => _countsAsValid = value),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Lagre' : 'Opprett'),
        ),
      ],
    );
  }
}
