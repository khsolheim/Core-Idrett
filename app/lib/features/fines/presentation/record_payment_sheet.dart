import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/fine.dart';
import '../providers/fines_provider.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  final Fine fine;
  final String teamId;

  const RecordPaymentSheet({
    super.key,
    required this.fine,
    required this.teamId,
  });

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _amountController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with remaining amount
    _amountController.text = widget.fine.remainingAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.fine.remainingAmount;

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
                    'Registrer betaling',
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

            // Fine info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.fine.ruleName ?? widget.fine.description ?? 'Bøte',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: ${widget.fine.amount.toStringAsFixed(0)} kr',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      Text(
                        'Betalt: ${(widget.fine.paidAmount ?? 0).toStringAsFixed(0)} kr',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gjenstående: ${remaining.toStringAsFixed(0)} kr',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Amount input
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
              autofocus: true,
            ),
            const SizedBox(height: 12),

            // Quick actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text = remaining.toStringAsFixed(0);
                    },
                    child: const Text('Betal alt'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text = (remaining / 2).toStringAsFixed(0);
                    },
                    child: const Text('Halvparten'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitPayment,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrer betaling'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submitPayment() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ErrorDisplayService.showWarning('Du må skrive et gyldig beløp');
      return;
    }

    final remaining = widget.fine.remainingAmount;
    if (amount > remaining) {
      ErrorDisplayService.showWarning('Beløpet kan ikke overstige gjenstående (${remaining.toStringAsFixed(0)} kr)');
      return;
    }

    setState(() => _loading = true);

    final result = await ref.read(paymentNotifierProvider.notifier).recordPayment(
          fineId: widget.fine.id,
          amount: amount,
          teamId: widget.teamId,
        );

    if (mounted) {
      setState(() => _loading = false);
      if (result != null) {
        Navigator.pop(context, true); // Return true to indicate success
        ErrorDisplayService.showSuccess('Betaling på ${amount.toStringAsFixed(0)} kr registrert');
      } else {
        ErrorDisplayService.showWarning('Kunne ikke registrere betaling. Prøv igjen.');
      }
    }
  }
}
