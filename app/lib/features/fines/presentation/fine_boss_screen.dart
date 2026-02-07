import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../providers/fines_provider.dart';
import 'widgets/pending_appeal_card.dart';
import 'widgets/pending_fine_card.dart';

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
            return PendingFineCard(fine: fine, teamId: teamId);
          },
        );
      },
    );
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
            return PendingAppealCard(appeal: appeal, teamId: teamId);
          },
        );
      },
    );
  }
}
