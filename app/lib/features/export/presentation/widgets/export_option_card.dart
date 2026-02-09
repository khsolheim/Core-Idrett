import 'package:flutter/material.dart';
import '../../../../data/models/export_log.dart';

class ExportOptionCard extends StatelessWidget {
  final ExportType type;
  final bool isExporting;
  final VoidCallback onExport;

  const ExportOptionCard({
    super.key,
    required this.type,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(_getIcon(), color: theme.colorScheme.primary),
        ),
        title: Text(type.displayName),
        subtitle: Text(type.description),
        trailing: isExporting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.download),
                onPressed: onExport,
              ),
        onTap: isExporting ? null : onExport,
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ExportType.leaderboard:
        return Icons.leaderboard;
      case ExportType.attendance:
        return Icons.how_to_reg;
      case ExportType.fines:
        return Icons.receipt_long;
      case ExportType.activities:
        return Icons.event;
      case ExportType.members:
        return Icons.people;
    }
  }
}
