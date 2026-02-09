import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/export_log.dart';

class ExportHistoryTile extends StatelessWidget {
  final ExportLog log;

  const ExportHistoryTile({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d. MMM yyyy HH:mm', 'nb_NO');
    final type = ExportType.fromString(log.exportType);

    return ListTile(
      leading: Icon(
        _getFormatIcon(log.fileFormat),
        color: theme.colorScheme.outline,
      ),
      title: Text(type?.displayName ?? log.exportType),
      subtitle: Text(
        '${log.userName ?? 'Ukjent'} - ${dateFormat.format(log.createdAt)}',
      ),
      trailing: Chip(
        label: Text(log.fileFormat.toUpperCase()),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'csv':
        return Icons.table_chart;
      case 'xlsx':
        return Icons.description;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.code;
    }
  }
}
