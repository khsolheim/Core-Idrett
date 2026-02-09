import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/statistics.dart';
import '../providers/test_provider.dart';
import 'widgets/widgets.dart';

class TestDetailScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String templateId;
  final bool isAdmin;

  const TestDetailScreen({
    super.key,
    required this.teamId,
    required this.templateId,
    this.isAdmin = false,
  });

  @override
  ConsumerState<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends ConsumerState<TestDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load template data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(testNotifierProvider(widget.teamId).notifier).selectTemplate(widget.templateId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testState = ref.watch(testNotifierProvider(widget.teamId));
    final template = testState.selectedTemplate;

    if (testState.isLoading || template == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(template.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rangering'),
            Tab(text: 'Resultater'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Ranking tab
          TestRankingTab(
            ranking: testState.ranking,
            template: template,
          ),
          // Results tab
          TestResultsTab(
            results: testState.results,
            template: template,
            isAdmin: widget.isAdmin,
            onDelete: (resultId) async {
              await ref.read(testNotifierProvider(widget.teamId).notifier).deleteResult(resultId);
            },
          ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showRecordResultSheet(template),
              icon: const Icon(Icons.add),
              label: const Text('Registrer'),
            )
          : null,
    );
  }

  void _showRecordResultSheet(TestTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => RecordResultSheet(
        teamId: widget.teamId,
        template: template,
        onSave: (userId, value, notes) async {
          final success = await ref
              .read(testNotifierProvider(widget.teamId).notifier)
              .recordResult(
                templateId: template.id,
                userId: userId,
                value: value,
                notes: notes,
              );
          if (success && context.mounted) {
            Navigator.pop(context);
            ErrorDisplayService.showSuccess('Resultat registrert');
          }
        },
      ),
    );
  }
}
