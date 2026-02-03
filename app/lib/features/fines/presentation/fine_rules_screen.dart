import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/fine.dart';
import '../providers/fines_provider.dart';

class FineRulesScreen extends ConsumerWidget {
  final String teamId;

  const FineRulesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(allFineRulesProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bøteregler'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRuleDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Feil: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(
              child: Text('Ingen bøteregler enda.\nTrykk + for å legge til.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return _RuleCard(
                rule: rule,
                teamId: teamId,
                onEdit: () => _showEditRuleDialog(context, ref, rule),
                onDelete: () => _confirmDeleteRule(context, ref, rule),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateRuleDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _RuleDialog(
        teamId: teamId,
        onSave: (name, amount, description) async {
          final result = await ref.read(fineRuleNotifierProvider.notifier).createRule(
                teamId: teamId,
                name: name,
                amount: amount,
                description: description,
              );
          if (result != null) {
            ErrorDisplayService.showSuccess('Bøteregel opprettet');
          } else {
            ErrorDisplayService.showWarning('Kunne ikke opprette bøteregel. Prøv igjen.');
          }
        },
      ),
    );
  }

  void _showEditRuleDialog(BuildContext context, WidgetRef ref, FineRule rule) {
    showDialog(
      context: context,
      builder: (context) => _RuleDialog(
        teamId: teamId,
        rule: rule,
        onSave: (name, amount, description) async {
          final result = await ref.read(fineRuleNotifierProvider.notifier).updateRule(
                ruleId: rule.id,
                teamId: teamId,
                name: name,
                amount: amount,
                description: description,
              );
          if (result != null) {
            ErrorDisplayService.showSuccess('Bøteregel oppdatert');
          } else {
            ErrorDisplayService.showWarning('Kunne ikke oppdatere bøteregel. Prøv igjen.');
          }
        },
      ),
    );
  }

  void _confirmDeleteRule(BuildContext context, WidgetRef ref, FineRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett bøteregel'),
        content: Text('Er du sikker på at du vil slette "${rule.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ref.read(fineRuleNotifierProvider.notifier).deleteRule(rule.id, teamId);
              if (result) {
                ErrorDisplayService.showSuccess('Bøteregel slettet');
              } else {
                ErrorDisplayService.showWarning('Kunne ikke slette bøteregel. Prøv igjen.');
              }
            },
            child: const Text('Slett', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  final FineRule rule;
  final String teamId;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleCard({
    required this.rule,
    required this.teamId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          rule.name,
          style: TextStyle(
            decoration: rule.active ? null : TextDecoration.lineThrough,
            color: rule.active ? null : Colors.grey,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${rule.amount.toStringAsFixed(0)} kr'),
            if (rule.description != null && rule.description!.isNotEmpty)
              Text(
                rule.description!,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Rediger')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Slett', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleDialog extends StatefulWidget {
  final String teamId;
  final FineRule? rule;
  final Future<void> Function(String name, double amount, String? description) onSave;

  const _RuleDialog({
    required this.teamId,
    this.rule,
    required this.onSave,
  });

  @override
  State<_RuleDialog> createState() => _RuleDialogState();
}

class _RuleDialogState extends State<_RuleDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rule?.name);
    _amountController = TextEditingController(
      text: widget.rule?.amount.toStringAsFixed(0) ?? '',
    );
    _descriptionController = TextEditingController(text: widget.rule?.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.rule != null;

    return AlertDialog(
      title: Text(isEditing ? 'Rediger regel' : 'Ny bøteregel'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Navn',
                hintText: 'F.eks. "For sent på trening"',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Beløp (kr)',
                hintText: 'F.eks. 50',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beskrivelse (valgfritt)',
                hintText: 'Mer info om regelen...',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        TextButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lagre'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      ErrorDisplayService.showWarning('Du må skrive et navn');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ErrorDisplayService.showWarning('Du må skrive et gyldig beløp');
      return;
    }

    setState(() => _loading = true);
    await widget.onSave(name, amount, description.isEmpty ? null : description);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
