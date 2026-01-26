import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/team.dart';
import '../../teams/providers/team_provider.dart' as team;
import '../providers/fines_provider.dart';
import 'report_fine_sheet.dart';

class FinesScreen extends ConsumerWidget {
  final String teamId;

  const FinesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(team.teamDetailProvider(teamId));
    final membersAsync = ref.watch(team.teamMembersProvider(teamId));
    final summaryAsync = ref.watch(teamFinesSummaryProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bøtekasse'),
        actions: [
          IconButton(
            onPressed: () => context.push('/teams/$teamId/fines/rules'),
            icon: const Icon(Icons.settings),
            tooltip: 'Regler',
          ),
        ],
      ),
      floatingActionButton: membersAsync.when(
        loading: () => null,
        error: (_, _) => null,
        data: (members) => FloatingActionButton.extended(
          onPressed: () => _showReportFineSheet(context, members),
          icon: const Icon(Icons.add),
          label: const Text('Meld bøte'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teamFinesSummaryProvider(teamId));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary card
              summaryAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Feil: $e'),
                data: (summary) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo[400]!, Colors.indigo[600]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Lagkasse',
                        style: TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '${summary.outstandingBalance.toStringAsFixed(0)} kr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'utestående av ${summary.totalFines.toStringAsFixed(0)} kr',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Quick actions
              const Text(
                'Handlinger',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // My fines
              _ActionCard(
                icon: Icons.receipt_long,
                title: 'Mine bøter',
                subtitle: 'Se dine egne bøter',
                color: Colors.blue,
                onTap: () => context.push('/teams/$teamId/fines/mine'),
              ),

              // Check if user is admin or fine_boss
              teamAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (team) {
                  final isAdmin = team?.userRole == TeamRole.admin;
                  final isFineBoss = team?.userRole == TeamRole.fineBoss;

                  if (isAdmin || isFineBoss) {
                    return Column(
                      children: [
                        _ActionCard(
                          icon: Icons.gavel,
                          title: 'Bøtesjef',
                          subtitle: 'Godkjenn bøter og behandle klager',
                          color: Colors.orange,
                          onTap: () => context.push('/teams/$teamId/fines/boss'),
                        ),
                        _ActionCard(
                          icon: Icons.account_balance,
                          title: 'Regnskap',
                          subtitle: 'Se totaloversikt',
                          color: Colors.green,
                          onTap: () => context.push('/teams/$teamId/fines/accounting'),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              _ActionCard(
                icon: Icons.list_alt,
                title: 'Bøteregler',
                subtitle: 'Se alle regler',
                color: Colors.purple,
                onTap: () => context.push('/teams/$teamId/fines/rules'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportFineSheet(BuildContext context, List<TeamMember> members) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReportFineSheet(
        teamId: teamId,
        members: members,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
