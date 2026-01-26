import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/fine.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/fines_provider.dart';

class MyFinesScreen extends ConsumerWidget {
  final String teamId;

  const MyFinesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Ikke innlogget')),
      );
    }

    final finesAsync = ref.watch(userFinesProvider((teamId: teamId, userId: user.id)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mine bøter'),
      ),
      body: finesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Feil: $e')),
        data: (fines) {
          if (fines.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Ingen bøter!'),
                  Text('Hold det slik 👍', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Calculate summary
          double totalOwed = 0;
          double totalPaid = 0;
          for (final fine in fines) {
            if (fine.status != 'rejected') {
              totalOwed += fine.amount;
              totalPaid += fine.paidAmount ?? 0;
            }
          }
          final outstanding = totalOwed - totalPaid;

          return Column(
            children: [
              // Summary card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: outstanding > 0
                        ? [Colors.orange[400]!, Colors.red[400]!]
                        : [Colors.green[400]!, Colors.teal[400]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      outstanding > 0 ? 'Du skylder' : 'Alt betalt!',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '${outstanding.toStringAsFixed(0)} kr',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (outstanding > 0)
                      Text(
                        'Betalt ${totalPaid.toStringAsFixed(0)} av ${totalOwed.toStringAsFixed(0)} kr',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Fine list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: fines.length,
                  itemBuilder: (context, index) {
                    final fine = fines[index];
                    return _MyFineCard(
                      fine: fine,
                      teamId: teamId,
                      onAppeal: () => _showAppealSheet(context, ref, fine),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAppealSheet(BuildContext context, WidgetRef ref, Fine fine) {
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Klag på bøte',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Bøte: ${fine.ruleName ?? fine.description ?? 'Ukjent'} - ${fine.amount.toStringAsFixed(0)} kr',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Hvorfor klager du?',
                hintText: 'Forklar hvorfor du mener bøten er urettferdig...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            Text(
              'OBS: Hvis klagen avslås kan du få ekstragebyr',
              style: TextStyle(color: Colors.orange[700], fontSize: 12),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Du må skrive en begrunnelse')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await ref.read(appealNotifierProvider.notifier).createAppeal(
                        fineId: fine.id,
                        reason: reason,
                        teamId: teamId,
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Klage sendt')),
                    );
                  }
                },
                child: const Text('Send klage'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MyFineCard extends StatelessWidget {
  final Fine fine;
  final String teamId;
  final VoidCallback onAppeal;

  const _MyFineCard({
    required this.fine,
    required this.teamId,
    required this.onAppeal,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final remaining = fine.remainingAmount;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (fine.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Venter på godkjenning';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = remaining > 0 ? Colors.red : Colors.green;
        statusText = remaining > 0 ? 'Ubetalt' : 'Betalt';
        statusIcon = remaining > 0 ? Icons.payment : Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.grey;
        statusText = 'Avvist';
        statusIcon = Icons.cancel;
        break;
      case 'appealed':
        statusColor = Colors.purple;
        statusText = 'Klage under behandling';
        statusIcon = Icons.gavel;
        break;
      case 'paid':
        statusColor = Colors.green;
        statusText = 'Betalt';
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = fine.status;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fine.ruleName ?? fine.description ?? 'Bøte',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${fine.amount.toStringAsFixed(0)} kr',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: fine.status == 'rejected' ? Colors.grey : null,
                    decoration: fine.status == 'rejected' ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormat.format(fine.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            if (fine.description != null &&
                fine.description!.isNotEmpty &&
                fine.ruleName != null) ...[
              const SizedBox(height: 8),
              Text(
                fine.description!,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
            if (fine.appeal != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Din klage:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      fine.appeal!.reason,
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (fine.appeal!.extraFee != null)
                      Text(
                        'Ekstragebyr: ${fine.appeal!.extraFee!.toStringAsFixed(0)} kr',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
            // Show appeal button only for approved fines without existing appeal
            if (fine.status == 'approved' && fine.appeal == null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAppeal,
                  icon: const Icon(Icons.gavel, size: 16),
                  label: const Text('Klag'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
