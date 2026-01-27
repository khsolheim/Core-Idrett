import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/fine.dart';
import '../providers/fines_provider.dart';
import 'user_fines_sheet.dart';

class TeamAccountingScreen extends ConsumerWidget {
  final String teamId;

  const TeamAccountingScreen({super.key, required this.teamId});

  void _showUserFinesSheet(BuildContext context, UserFinesSummary user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserFinesSheet(
        user: user,
        teamId: teamId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(teamFinesSummaryProvider(teamId));
    final userSummariesAsync = ref.watch(userFinesSummariesProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bøteregnskap'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teamFinesSummaryProvider(teamId));
          ref.invalidate(userFinesSummariesProvider(teamId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team summary
              summaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Feil: $e'),
                data: (summary) => Column(
                  children: [
                    _SummaryCard(
                      title: 'Totalt utestående',
                      amount: summary.outstandingBalance,
                      color: summary.outstandingBalance > 0 ? Colors.red : Colors.green,
                      icon: Icons.account_balance_wallet,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniCard(
                            label: 'Totalt',
                            value: '${summary.totalFines.toStringAsFixed(0)} kr',
                            subValue: '${summary.fineCount} bøter',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniCard(
                            label: 'Betalt',
                            value: '${summary.totalPaid.toStringAsFixed(0)} kr',
                            subValue: '${summary.paidCount} bøter',
                            valueColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniCard(
                            label: 'Ventende',
                            value: '${summary.totalPending.toStringAsFixed(0)} kr',
                            subValue: '${summary.pendingCount} bøter',
                            valueColor: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // User breakdown
              const Text(
                'Per spiller',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              userSummariesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Feil: $e'),
                data: (summaries) {
                  if (summaries.isEmpty) {
                    return const Center(child: Text('Ingen data'));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: summaries.length,
                    itemBuilder: (context, index) {
                      final user = summaries[index];
                      final outstanding = user.outstandingBalance;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.userAvatarUrl != null
                                ? NetworkImage(user.userAvatarUrl!)
                                : null,
                            child: user.userAvatarUrl == null
                                ? Text(user.userName.substring(0, 1).toUpperCase())
                                : null,
                          ),
                          title: Text(user.userName),
                          subtitle: Text(
                            '${user.fineCount} bøter · Betalt ${user.totalPaid.toStringAsFixed(0)} kr',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${outstanding.toStringAsFixed(0)} kr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: outstanding > 0 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  Text(
                                    outstanding > 0 ? 'skylder' : 'alt betalt',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: outstanding > 0 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              if (outstanding > 0) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ],
                          ),
                          onTap: outstanding > 0
                              ? () => _showUserFinesSheet(context, user)
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            '${amount.toStringAsFixed(0)} kr',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String subValue;
  final Color? valueColor;

  const _MiniCard({
    required this.label,
    required this.value,
    required this.subValue,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          Text(subValue, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }
}
