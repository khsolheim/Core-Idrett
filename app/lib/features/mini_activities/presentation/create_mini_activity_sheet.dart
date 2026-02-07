import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/mini_activity.dart';
import '../providers/mini_activity_provider.dart';

class CreateMiniActivitySheet extends ConsumerStatefulWidget {
  final String instanceId;
  final String teamId;

  const CreateMiniActivitySheet({
    super.key,
    required this.instanceId,
    required this.teamId,
  });

  @override
  ConsumerState<CreateMiniActivitySheet> createState() => _CreateMiniActivitySheetState();
}

class _CreateMiniActivitySheetState extends ConsumerState<CreateMiniActivitySheet> {
  final _nameController = TextEditingController();
  MiniActivityType _type = MiniActivityType.team;
  ActivityTemplate? _selectedTemplate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _selectedTemplate?.name ?? _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);

    final success = await ref.read(createMiniActivityProvider.notifier).createMiniActivity(
          instanceId: widget.instanceId,
          templateId: _selectedTemplate?.id,
          name: name,
          type: _selectedTemplate?.type ?? _type,
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
    final templatesAsync = ref.watch(teamTemplatesProvider(widget.teamId));

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
            'Ny mini-aktivitet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),

          // Templates
          templatesAsync.when2(
            onRetry: () => ref.invalidate(teamTemplatesProvider(widget.teamId)),
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (templates) {
              if (templates.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Velg mal',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Egendefinert'),
                        selected: _selectedTemplate == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedTemplate = null);
                          }
                        },
                      ),
                      ...templates.map((template) {
                        return ChoiceChip(
                          label: Text(template.name),
                          selected: _selectedTemplate?.id == template.id,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTemplate = selected ? template : null;
                              if (selected) {
                                _type = template.type;
                              }
                            });
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),

          // Custom name input
          if (_selectedTemplate == null) ...[
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
          ] else ...[
            Card(
              child: ListTile(
                leading: Icon(
                  _selectedTemplate!.type == MiniActivityType.team
                      ? Icons.groups
                      : Icons.person,
                ),
                title: Text(_selectedTemplate!.name),
                subtitle: Text(
                  '${_selectedTemplate!.type.displayName} • ${_selectedTemplate!.defaultPoints} poeng',
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _create,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Opprett'),
          ),
        ],
      ),
    );
  }
}
