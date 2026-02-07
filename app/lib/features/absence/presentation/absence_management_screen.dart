import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../teams/providers/team_provider.dart';
import 'widgets/categories_tab.dart';
import 'widgets/pending_absences_tab.dart';

class AbsenceManagementScreen extends ConsumerStatefulWidget {
  final String teamId;

  const AbsenceManagementScreen({super.key, required this.teamId});

  @override
  ConsumerState<AbsenceManagementScreen> createState() =>
      _AbsenceManagementScreenState();
}

class _AbsenceManagementScreenState
    extends ConsumerState<AbsenceManagementScreen>
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
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final isAdmin = teamAsync.value?.userIsAdmin ?? false;
    final theme = Theme.of(context);

    // Admin guard
    if (teamAsync.hasValue && !isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fraværsadministrasjon')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('Du har ikke tilgang til denne siden', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Kun administratorer kan administrere fravær',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fraværsadministrasjon'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pending_actions), text: 'Ventende'),
            Tab(icon: Icon(Icons.category), text: 'Kategorier'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PendingAbsencesTab(teamId: widget.teamId),
          CategoriesTab(teamId: widget.teamId),
        ],
      ),
    );
  }
}
