import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/statistics.dart';

class TestResultsTab extends StatelessWidget {
  final List<TestResult> results;
  final TestTemplate template;
  final bool isAdmin;
  final Function(String) onDelete;

  const TestResultsTab({
    super.key,
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
