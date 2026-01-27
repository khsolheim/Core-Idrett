import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/statistics.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/test_provider.dart';

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
          _RankingTab(
            ranking: testState.ranking,
            template: template,
          ),
          // Results tab
          _ResultsTab(
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
      builder: (context) => _RecordResultSheet(
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Resultat registrert')),
            );
          }
        },
      ),
    );
  }
}

class _RankingTab extends StatelessWidget {
  final List<Map<String, dynamic>> ranking;
  final TestTemplate template;

  const _RankingTab({
    required this.ranking,
    required this.template,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (ranking.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen resultater enna',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Registrer resultater for a se rangering',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranking.length,
      itemBuilder: (context, index) {
        final entry = ranking[index];
        final rank = entry['rank'] as int;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: rank <= 3 ? _getRankColor(rank, theme) : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: rank <= 3
                  ? _getRankBadgeColor(rank)
                  : theme.colorScheme.surfaceContainerHighest,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rank <= 3 ? Colors.white : null,
                ),
              ),
            ),
            title: Text(entry['user_name'] ?? 'Ukjent'),
            trailing: Text(
              _formatValue(entry['value'] as num),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank, ThemeData theme) {
    switch (rank) {
      case 1:
        return Colors.amber.withValues(alpha: 0.1);
      case 2:
        return Colors.grey.shade300.withValues(alpha: 0.3);
      case 3:
        return Colors.brown.withValues(alpha: 0.1);
      default:
        return theme.colorScheme.surface;
    }
  }

  Color _getRankBadgeColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.transparent;
    }
  }

  String _formatValue(num value) {
    if (value == value.toInt()) {
      return '${value.toInt()} ${template.unit}';
    }
    return '${value.toStringAsFixed(2)} ${template.unit}';
  }
}

class _ResultsTab extends StatelessWidget {
  final List<TestResult> results;
  final TestTemplate template;
  final bool isAdmin;
  final Function(String) onDelete;

  const _ResultsTab({
    required this.results,
    required this.template,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d. MMM yyyy HH:mm', 'nb_NO');

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen resultater enna',
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(result.userName ?? 'Ukjent'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFormat.format(result.recordedAt)),
                if (result.notes != null && result.notes!.isNotEmpty)
                  Text(
                    result.notes!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatValue(result.value),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, result),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatValue(double value) {
    if (value == value.toInt()) {
      return '${value.toInt()} ${template.unit}';
    }
    return '${value.toStringAsFixed(2)} ${template.unit}';
  }

  void _confirmDelete(BuildContext context, TestResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett resultat'),
        content: Text('Er du sikker pa at du vil slette dette resultatet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete(result.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}

class _RecordResultSheet extends ConsumerStatefulWidget {
  final String teamId;
  final TestTemplate template;
  final Function(String userId, double value, String? notes) onSave;

  const _RecordResultSheet({
    required this.teamId,
    required this.template,
    required this.onSave,
  });

  @override
  ConsumerState<_RecordResultSheet> createState() => _RecordResultSheetState();
}

class _RecordResultSheetState extends ConsumerState<_RecordResultSheet> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedUserId;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Registrer resultat',
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member selector
          membersAsync.when(
            data: (members) => DropdownButtonFormField<String>(
              initialValue: _selectedUserId,
              decoration: const InputDecoration(
                labelText: 'Velg spiller *',
                border: OutlineInputBorder(),
              ),
              items: members.map((m) => DropdownMenuItem(
                value: m.userId,
                child: Text(m.userName),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUserId = value;
                });
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Kunne ikke laste medlemmer: $e'),
          ),
          const SizedBox(height: 16),

          // Value input
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: 'Resultat (${widget.template.unit}) *',
              border: const OutlineInputBorder(),
              hintText: widget.template.higherIsBetter ? 'Hoyere er bedre' : 'Lavere er bedre',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),

          // Notes input
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notater (valgfritt)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Lagre'),
          ),
        ],
      ),
    );
  }

  bool get _canSave {
    return _selectedUserId != null &&
        _valueController.text.isNotEmpty &&
        double.tryParse(_valueController.text.replaceAll(',', '.')) != null;
  }

  void _save() {
    final value = double.parse(_valueController.text.replaceAll(',', '.'));
    widget.onSave(
      _selectedUserId!,
      value,
      _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
  }
}
