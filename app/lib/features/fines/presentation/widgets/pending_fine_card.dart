import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/error_display_service.dart';
import '../../../../data/models/fine.dart';
import '../../providers/fines_provider.dart';

class PendingFineCard extends ConsumerWidget {
  final Fine fine;
  final String teamId;

  const PendingFineCard({super.key, required this.fine, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

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
                  backgroundImage: fine.offenderAvatarUrl != null
                      ? NetworkImage(fine.offenderAvatarUrl!)
                      : null,
                  child: fine.offenderAvatarUrl == null
                      ? Text(fine.offenderName?.substring(0, 1).toUpperCase() ?? '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fine.offenderName ?? 'Ukjent',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Meldt av ${fine.reporterName ?? 'ukjent'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${fine.amount.toStringAsFixed(0)} kr',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (fine.ruleName != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fine.ruleName!,
                  style: TextStyle(color: Colors.blue[900], fontSize: 12),
                ),
              ),
            if (fine.description != null && fine.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(fine.description!),
            ],
            const SizedBox(height: 8),
            Text(
              dateFormat.format(fine.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _rejectFine(context, ref),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Avvis'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _approveFine(context, ref),
                  child: const Text('Godkjenn'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _approveFine(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(fineNotifierProvider.notifier).approveFine(fine.id, teamId);
    if (result != null) {
      ErrorDisplayService.showSuccess('Bøte godkjent');
    } else {
      ErrorDisplayService.showWarning('Kunne ikke godkjenne bøte. Prøv igjen.');
    }
  }

  void _rejectFine(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(fineNotifierProvider.notifier).rejectFine(fine.id, teamId);
    if (result != null) {
      ErrorDisplayService.showSuccess('Bøte avvist');
    } else {
      ErrorDisplayService.showWarning('Kunne ikke avvise bøte. Prøv igjen.');
    }
  }
}
