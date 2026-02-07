import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/statistics.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/test_provider.dart';

class TestsScreen extends ConsumerWidget {
  final String teamId;
  final bool isAdmin;

  const TestsScreen({
    super.key,
    required this.teamId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testState = ref.watch(testNotifierProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tester'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(testNotifierProvider(teamId).notifier).loadTemplates(),
          ),
        ],
      ),
      body: testState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : testState.templates.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.speed,
                  title: 'Ingen tester enna',
                  subtitle: 'Opprett tester for a spore fremgang',
                  action: isAdmin
                      ? FilledButton.icon(
                          onPressed: () => _showCreateTemplateDialog(context, ref),
                          icon: const Icon(Icons.add),
                          label: const Text('Opprett test'),
                        )
                      : null,
                )
              : RefreshIndicator(
                  onRefresh: () => ref.read(testNotifierProvider(teamId).notifier).loadTemplates(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: testState.templates.length,
                    itemBuilder: (context, index) {
                      final template = testState.templates[index];
                      return _TestTemplateCard(
                        template: template,
                        isAdmin: isAdmin,
                        onTap: () => context.pushNamed(
                          'test-detail',
                          pathParameters: {'teamId': teamId, 'templateId': template.id},
                        ),
                        onEdit: isAdmin
                            ? () => _showEditTemplateDialog(context, ref, template)
                            : null,
                        onDelete: isAdmin
                            ? () => _confirmDelete(context, ref, template)
                            : null,
                      );
                    },
                  ),
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showCreateTemplateDialog(context, ref),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showCreateTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _CreateTemplateDialog(
        onSave: (name, description, unit, higherIsBetter) async {
          final success = await ref.read(testNotifierProvider(teamId).notifier).createTemplate(
            name: name,
            description: description,
            unit: unit,
            higherIsBetter: higherIsBetter,
          );
          if (success && context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _showEditTemplateDialog(BuildContext context, WidgetRef ref, TestTemplate template) {
    showDialog(
      context: context,
      builder: (context) => _CreateTemplateDialog(
        initialTemplate: template,
        onSave: (name, description, unit, higherIsBetter) async {
          final success = await ref.read(testNotifierProvider(teamId).notifier).updateTemplate(
            templateId: template.id,
            name: name,
            description: description,
            unit: unit,
            higherIsBetter: higherIsBetter,
          );
          if (success && context.mounted) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TestTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett test'),
        content: Text('Er du sikker pa at du vil slette "${template.name}"? Alle resultater vil ogsa bli slettet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(testNotifierProvider(teamId).notifier).deleteTemplate(template.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}

class _TestTemplateCard extends StatelessWidget {
  final TestTemplate template;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _TestTemplateCard({
    required this.template,
    required this.isAdmin,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  _getIcon(),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (template.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        template.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Chip(
                          label: Text(template.unit),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          template.higherIsBetter ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        Text(
                          template.higherIsBetter ? 'Hoyere er bedre' : 'Lavere er bedre',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isAdmin)
                PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
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
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Slett', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    final unit = template.unit.toLowerCase();
    if (unit.contains('sekund') || unit.contains('minutt') || unit.contains('tid')) {
      return Icons.timer;
    }
    if (unit.contains('meter') || unit.contains('km') || unit.contains('distanse')) {
      return Icons.straighten;
    }
    if (unit.contains('kg') || unit.contains('vekt')) {
      return Icons.fitness_center;
    }
    if (unit.contains('rep') || unit.contains('ganger')) {
      return Icons.repeat;
    }
    return Icons.speed;
  }
}

class _CreateTemplateDialog extends StatefulWidget {
  final TestTemplate? initialTemplate;
  final Function(String name, String? description, String unit, bool higherIsBetter) onSave;

  const _CreateTemplateDialog({
    this.initialTemplate,
    required this.onSave,
  });

  @override
  State<_CreateTemplateDialog> createState() => _CreateTemplateDialogState();
}

class _CreateTemplateDialogState extends State<_CreateTemplateDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String _selectedUnit = 'sekunder';
  bool _higherIsBetter = false;

  final _units = [
    'sekunder',
    'minutter',
    'meter',
    'kilometer',
    'repetisjoner',
    'kg',
    'poeng',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialTemplate?.name ?? '');
    _descriptionController = TextEditingController(text: widget.initialTemplate?.description ?? '');
    if (widget.initialTemplate != null) {
      _selectedUnit = widget.initialTemplate!.unit;
      _higherIsBetter = widget.initialTemplate!.higherIsBetter;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTemplate != null;

    return AlertDialog(
      title: Text(isEditing ? 'Rediger test' : 'Opprett test'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Navn *',
                hintText: 'f.eks. 60-meter sprint',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivelse (valgfritt)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _units.contains(_selectedUnit) ? _selectedUnit : _units.first,
              decoration: const InputDecoration(
                labelText: 'Enhet',
                border: OutlineInputBorder(),
              ),
              items: _units.map((unit) => DropdownMenuItem(
                value: unit,
                child: Text(unit),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedUnit = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Hoyere er bedre'),
              subtitle: Text(
                _higherIsBetter
                    ? 'Hoyere verdier gir bedre plassering'
                    : 'Lavere verdier gir bedre plassering',
              ),
              value: _higherIsBetter,
              onChanged: (value) {
                setState(() {
                  _higherIsBetter = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            widget.onSave(
              name,
              _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              _selectedUnit,
              _higherIsBetter,
            );
          },
          child: Text(isEditing ? 'Lagre' : 'Opprett'),
        ),
      ],
    );
  }
}
