import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/fine.dart';
import '../providers/fines_provider.dart';
import 'record_payment_sheet.dart';

class UserFinesSheet extends ConsumerWidget {
  final UserFinesSummary user;
  final String teamId;

  const UserFinesSheet({
    super.key,
    required this.user,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finesAsync = ref.watch(unpaidUserFinesProvider((teamId: teamId, userId: user.userId)));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: user.userAvatarUrl != null
                            ? NetworkImage(user.userAvatarUrl!)
                            : null,
                        child: user.userAvatarUrl == null
                            ? Text(
                                user.userName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontSize: 20),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.userName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Utestående: ${user.outstandingBalance.toStringAsFixed(0)} kr',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Fines list
            Expanded(
              child: finesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Feil: $e')),
                data: (fines) {
                  if (fines.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: Colors.green),
                          SizedBox(height: 16),
                          Text('Ingen ubetalte bøter'),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: fines.length,
                    itemBuilder: (context, index) {
                      final fine = fines[index];
                      return _UnpaidFineCard(
                        fine: fine,
                        teamId: teamId,
                        onPaymentRecorded: () {
                          // Refresh the fines list after payment
                          ref.invalidate(unpaidUserFinesProvider((teamId: teamId, userId: user.userId)));
                          ref.invalidate(userFinesSummariesProvider(teamId));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UnpaidFineCard extends StatelessWidget {
  final Fine fine;
  final String teamId;
  final VoidCallback onPaymentRecorded;

  const _UnpaidFineCard({
    required this.fine,
    required this.teamId,
    required this.onPaymentRecorded,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final remaining = fine.remainingAmount;
    final hasPaidSome = (fine.paidAmount ?? 0) > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showPaymentSheet(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      fine.ruleName ?? fine.description ?? 'Bøte',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${fine.amount.toStringAsFixed(0)} kr',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (hasPaidSome) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Gjenstår: ${remaining.toStringAsFixed(0)} kr',
                        style: TextStyle(color: Colors.orange[700], fontSize: 12),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Ubetalt',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ],
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
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showPaymentSheet(context),
                    icon: const Icon(Icons.payment, size: 18),
                    label: const Text('Registrer betaling'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecordPaymentSheet(
        fine: fine,
        teamId: teamId,
      ),
    ).then((result) {
      if (result == true) {
        onPaymentRecorded();
      }
    });
  }
}
