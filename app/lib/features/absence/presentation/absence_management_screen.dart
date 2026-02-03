import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/absence.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fravaersadministrasjon'),
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

class _PendingAbsencesTab extends ConsumerWidget {
  final String teamId;

  const _PendingAbsencesTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingAbsencesProvider(teamId));
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
                  'Ingen ventende fravaer',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Alle fravaersmeldinger er behandlet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(pendingAbsencesProvider(teamId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: absences.length,
            itemBuilder: (context, index) {
              return _PendingAbsenceCard(
                teamId: teamId,
                absence: absences[index],
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Kunne ikke laste fravaer: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(pendingAbsencesProvider(teamId)),
              child: const Text('Prov igjen'),
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

  const _PendingAbsenceCard({
    required this.teamId,
    required this.absence,
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
          const SnackBar(content: Text('Fravaer godkjent')),
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
          const SnackBar(content: Text('Fravaer avvist')),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
      title: const Text('Avvis fravaer'),
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
                            'Legg til kategorier for fravaerstyper',
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
              child: const Text('Prov igjen'),
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
                label: const Text('Gyldig fravaer'),
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
        content: Text('Er du sikker pa at du vil slette "${category.name}"?'),
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
        const SnackBar(content: Text('Navn er pakrevd')),
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
            subtitle: const Text('Admin ma godkjenne dette fravaeret'),
            value: _requiresApproval,
            onChanged: (value) => setState(() => _requiresApproval = value),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            title: const Text('Teller som gyldig'),
            subtitle: const Text('Fjernes fra oppmoteberegning'),
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
