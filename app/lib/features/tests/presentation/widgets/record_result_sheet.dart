import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/statistics.dart';
import '../../../teams/providers/team_provider.dart';

class RecordResultSheet extends ConsumerStatefulWidget {
  final String teamId;
  final TestTemplate template;
  final Function(String userId, double value, String? notes) onSave;

  const RecordResultSheet({
    super.key,
    required this.teamId,
    required this.template,
    required this.onSave,
  });

  @override
  ConsumerState<RecordResultSheet> createState() => RecordResultSheetState();
}

class RecordResultSheetState extends ConsumerState<RecordResultSheet> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedUserId;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));
    final theme = Theme.of(context);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registrer resultat',
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member selector
          membersAsync.when2(
            onRetry: () => ref.invalidate(teamMembersProvider(widget.teamId)),
            loading: () => const LinearProgressIndicator(),
            data: (members) => DropdownButtonFormField<String>(
              initialValue: _selectedUserId,
              decoration: const InputDecoration(
                labelText: 'Velg spiller *',
                border: OutlineInputBorder(),
              ),
              items: members.map((m) => DropdownMenuItem(
                value: m.userId,
                child: Text(m.userName),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUserId = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Value input
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: 'Resultat (${widget.template.unit}) *',
              border: const OutlineInputBorder(),
              hintText: widget.template.higherIsBetter ? 'Hoyere er bedre' : 'Lavere er bedre',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Notes input
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notater (valgfritt)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Lagre'),
          ),
        ],
      ),
    );
  }

  bool get _canSave {
    return _selectedUserId != null &&
        _valueController.text.isNotEmpty &&
        double.tryParse(_valueController.text.replaceAll(',', '.')) != null;
  }

  void _save() {
    final value = double.parse(_valueController.text.replaceAll(',', '.'));
    widget.onSave(
      _selectedUserId!,
      value,
      _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
  }
}
