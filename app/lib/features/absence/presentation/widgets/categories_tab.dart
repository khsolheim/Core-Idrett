import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/absence.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../providers/absence_provider.dart';

class CategoriesTab extends ConsumerWidget {
  final String teamId;

  const CategoriesTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(absenceCategoriesProvider(teamId));

    return categoriesAsync.when2(
      onRetry: () => ref.invalidate(absenceCategoriesProvider(teamId)),
      data: (categories) {
        return Column(
          children: [
            Expanded(
              child: categories.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.category_outlined,
                      title: 'Ingen kategorier',
                      subtitle: 'Legg til kategorier for fraværstyper',
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(absenceCategoriesProvider(teamId));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return CategoryCard(
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
    );
  }

  void _showAddCategoryDialog(
      BuildContext context, WidgetRef ref, String teamId) {
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
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

class CategoryCard extends ConsumerWidget {
  final String teamId;
  final AbsenceCategory category;

  const CategoryCard({
    super.key,
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
      builder: (context) => CategoryFormDialog(
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

class CategoryFormDialog extends StatefulWidget {
  final String teamId;
  final AbsenceCategory? existingCategory;
  final Future<void> Function(
      String name, bool requiresApproval, bool countsAsValid) onSave;

  const CategoryFormDialog({
    super.key,
    required this.teamId,
    this.existingCategory,
    required this.onSave,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
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
