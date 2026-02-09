import 'package:flutter/material.dart';
import '../../../../data/models/statistics.dart';

class TestRankingTab extends StatelessWidget {
  final List<Map<String, dynamic>> ranking;
  final TestTemplate template;

  const TestRankingTab({
    super.key,
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
