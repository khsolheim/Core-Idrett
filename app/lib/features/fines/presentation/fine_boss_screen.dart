import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/fine.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/fines_provider.dart';

class FineBossScreen extends ConsumerStatefulWidget {
  final String teamId;

  const FineBossScreen({super.key, required this.teamId});

  @override
  ConsumerState<FineBossScreen> createState() => _FineBossScreenState();
}

class _FineBossScreenState extends ConsumerState<FineBossScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bøtesjef'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ventende'),
            Tab(text: 'Klager'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingFinesTab(teamId: widget.teamId),
          _PendingAppealsTab(teamId: widget.teamId),
        ],
      ),
    );
  }
}

class _PendingFinesTab extends ConsumerWidget {
  final String teamId;

  const _PendingFinesTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finesAsync = ref.watch(pendingFinesProvider(teamId));

    return finesAsync.when2(
      onRetry: () => ref.invalidate(pendingFinesProvider(teamId)),
      data: (fines) {
        if (fines.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.check_circle,
            title: 'Ingen ventende bøter',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fines.length,
          itemBuilder: (context, index) {
            final fine = fines[index];
            return _PendingFineCard(fine: fine, teamId: teamId);
          },
        );
      },
    );
  }
}

class _PendingFineCard extends ConsumerWidget {
  final Fine fine;
  final String teamId;

  const _PendingFineCard({required this.fine, required this.teamId});

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

class _PendingAppealsTab extends ConsumerWidget {
  final String teamId;

  const _PendingAppealsTab({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appealsAsync = ref.watch(pendingAppealsProvider(teamId));

    return appealsAsync.when2(
      onRetry: () => ref.invalidate(pendingAppealsProvider(teamId)),
      data: (appeals) {
        if (appeals.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.check_circle,
            title: 'Ingen ventende klager',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: appeals.length,
          itemBuilder: (context, index) {
            final appeal = appeals[index];
            return _PendingAppealCard(appeal: appeal, teamId: teamId);
          },
        );
      },
    );
  }
}

class _PendingAppealCard extends ConsumerWidget {
  final FineAppeal appeal;
  final String teamId;

  const _PendingAppealCard({required this.appeal, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final fine = appeal.fine;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with offender info
            Row(
              children: [
                if (fine != null) ...[
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
                ] else ...[
                  const Icon(Icons.gavel, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Klage på bøte',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Fine details
            if (fine != null) ...[
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
                Text(fine.description!, style: TextStyle(color: Colors.grey[700])),
              ],
              const SizedBox(height: 12),
            ],
            // Appeal reason
            _ExpandableAppealReason(reason: appeal.reason),
            const SizedBox(height: 8),
            Text(
              dateFormat.format(appeal.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _showRejectAppealDialog(context, ref),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Avslå klage'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _acceptAppeal(context, ref),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Godta klage'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _acceptAppeal(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(appealNotifierProvider.notifier).resolveAppeal(
          appealId: appeal.id,
          accepted: true,
          teamId: teamId,
        );
    if (result != null) {
      ErrorDisplayService.showSuccess('Klage godtatt - bøte fjernet');
    } else {
      ErrorDisplayService.showWarning('Kunne ikke godta klage. Prøv igjen.');
    }
  }

  void _showRejectAppealDialog(BuildContext context, WidgetRef ref) async {
    // Fetch team settings to get the default appeal fee
    final settingsAsync = ref.read(teamSettingsProvider(teamId));
    final defaultAppealFee = settingsAsync.whenOrNull(
      data: (settings) => settings.appealFee > 0 ? settings.appealFee.toStringAsFixed(0) : '',
    ) ?? '';

    final extraFeeController = TextEditingController(text: defaultAppealFee);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Avsla klage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vil du legge til ekstragebyr for a klage uten grunn?'),
            const SizedBox(height: 16),
            TextField(
              controller: extraFeeController,
              decoration: InputDecoration(
                labelText: 'Ekstragebyr (valgfritt)',
                hintText: 'F.eks. 50',
                suffixText: 'kr',
                helperText: defaultAppealFee.isNotEmpty
                    ? 'Forhandsfylt med klagegebyr fra laginnstillinger'
                    : null,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final extraFee = double.tryParse(extraFeeController.text.trim());
              final result = await ref.read(appealNotifierProvider.notifier).resolveAppeal(
                    appealId: appeal.id,
                    accepted: false,
                    teamId: teamId,
                    extraFee: extraFee,
                  );
              if (result != null) {
                ErrorDisplayService.showSuccess(extraFee != null
                    ? 'Klage avslatt med ${extraFee.toStringAsFixed(0)} kr ekstragebyr'
                    : 'Klage avslatt');
              } else {
                ErrorDisplayService.showWarning('Kunne ikke avsla klage. Prov igjen.');
              }
            },
            child: const Text('Avsla', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ExpandableAppealReason extends StatefulWidget {
  final String reason;
  const _ExpandableAppealReason({required this.reason});

  @override
  State<_ExpandableAppealReason> createState() => _ExpandableAppealReasonState();
}

class _ExpandableAppealReasonState extends State<_ExpandableAppealReason> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: Colors.orange[800], size: 20),
              const SizedBox(width: 8),
              Text(
                'Klagegrunn',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.orange[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            firstChild: Text(
              widget.reason,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            secondChild: Text(
              widget.reason,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          if (widget.reason.length > 150) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Vis mindre' : 'Vis mer',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
