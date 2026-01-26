import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/fine.dart';
import '../../../data/models/team.dart';
import '../providers/fines_provider.dart';

class ReportFineSheet extends ConsumerStatefulWidget {
  final String teamId;
  final List<TeamMember> members;

  const ReportFineSheet({
    super.key,
    required this.teamId,
    required this.members,
  });

  @override
  ConsumerState<ReportFineSheet> createState() => _ReportFineSheetState();
}

class _ReportFineSheetState extends ConsumerState<ReportFineSheet> {
  TeamMember? _selectedMember;
  FineRule? _selectedRule;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(fineRulesProvider(widget.teamId));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Meld bøte',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Select offender
            const Text('Hvem skal ha bøte?', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<TeamMember>(
              initialValue: _selectedMember,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Velg spiller',
              ),
              items: widget.members.map((member) {
                return DropdownMenuItem(
                  value: member,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: member.userAvatarUrl != null
                            ? NetworkImage(member.userAvatarUrl!)
                            : null,
                        child: member.userAvatarUrl == null
                            ? Text(member.userName.substring(0, 1).toUpperCase())
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(member.userName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedMember = value),
            ),
            const SizedBox(height: 16),

            // Select rule or custom amount
            const Text('Type bøte', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            rulesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Kunne ikke laste regler: $e'),
              data: (rules) {
                return Column(
                  children: [
                    DropdownButtonFormField<FineRule?>(
                      initialValue: _selectedRule,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Velg bøteregel (valgfritt)',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Egendefinert bøte'),
                        ),
                        ...rules.map((rule) {
                          return DropdownMenuItem(
                            value: rule,
                            child: Text('${rule.name} (${rule.amount.toStringAsFixed(0)} kr)'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRule = value;
                          if (value != null) {
                            _amountController.text = value.amount.toStringAsFixed(0);
                          }
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Amount (editable even with rule selected)
            const Text('Beløp', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Beløp i kr',
                suffixText: 'kr',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Beskrivelse (valgfritt)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Hva skjedde?',
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitFine,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Meld bøte'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFine() async {
    if (_selectedMember == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du må velge en spiller')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Du må skrive et gyldig beløp')),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await ref.read(fineNotifierProvider.notifier).createFine(
          teamId: widget.teamId,
          offenderId: _selectedMember!.userId,
          ruleId: _selectedRule?.id,
          amount: amount,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );

    if (mounted) {
      setState(() => _loading = false);
      if (result != null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bøte meldt til ${_selectedMember!.userName}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke melde bøte')),
        );
      }
    }
  }
}
