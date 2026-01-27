import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/mini_activity.dart';
import '../providers/mini_activity_provider.dart';

class TemplatesScreen extends ConsumerWidget {
  final String teamId;

  const TemplatesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(teamTemplatesProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-aktivitet maler'),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_add,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ingen maler ennå',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opprett maler for raske mini-aktiviteter',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(teamTemplatesProvider(teamId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                return _TemplateCard(
                  template: template,
                  teamId: teamId,
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
              Text('Kunne ikke laste maler: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(teamTemplatesProvider(teamId)),
                child: const Text('Prøv igjen'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTemplateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ny mal'),
      ),
    );
  }

  void _showCreateTemplateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateTemplateSheet(teamId: teamId),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final ActivityTemplate template;
  final String teamId;

  const _TemplateCard({
    required this.template,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            template.type == MiniActivityType.team ? Icons.groups : Icons.person,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(template.name),
        subtitle: Text(
          '${template.type.displayName} • ${template.defaultPoints} poeng',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _confirmDelete(context, ref),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett mal?'),
        content: Text('Er du sikker på at du vil slette "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(createTemplateProvider.notifier).deleteTemplate(
                    template.id,
                    teamId,
                  );
            },
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}

class _CreateTemplateSheet extends ConsumerStatefulWidget {
  final String teamId;

  const _CreateTemplateSheet({required this.teamId});

  @override
  ConsumerState<_CreateTemplateSheet> createState() => _CreateTemplateSheetState();
}

class _CreateTemplateSheetState extends ConsumerState<_CreateTemplateSheet> {
  final _nameController = TextEditingController();
  MiniActivityType _type = MiniActivityType.team;
  int _defaultPoints = 1;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final success = await ref.read(createTemplateProvider.notifier).createTemplate(
          teamId: widget.teamId,
          name: _nameController.text.trim(),
          type: _type,
          defaultPoints: _defaultPoints,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ny aktivitetsmal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Navn',
              hintText: 'F.eks. "Skytekonkurranse"',
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          SegmentedButton<MiniActivityType>(
            segments: const [
              ButtonSegment(
                value: MiniActivityType.team,
                label: Text('Lag'),
                icon: Icon(Icons.groups),
              ),
              ButtonSegment(
                value: MiniActivityType.individual,
                label: Text('Individuell'),
                icon: Icon(Icons.person),
              ),
            ],
            selected: {_type},
            onSelectionChanged: (selection) {
              setState(() => _type = selection.first);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Standard poeng:'),
              const Spacer(),
              IconButton(
                onPressed: _defaultPoints > 1
                    ? () => setState(() => _defaultPoints--)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              Text(
                '$_defaultPoints',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                onPressed: () => setState(() => _defaultPoints++),
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _create,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Opprett mal'),
          ),
        ],
      ),
    );
  }
}
