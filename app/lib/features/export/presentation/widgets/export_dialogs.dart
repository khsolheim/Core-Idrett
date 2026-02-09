import 'package:flutter/material.dart';
import '../../../../data/models/export_log.dart';

class ExportDialog extends StatefulWidget {
  final String teamId;
  final ExportType type;
  final Function(ExportFormat format, Map<String, String>? params) onExport;

  const ExportDialog({
    super.key,
    required this.teamId,
    required this.type,
    required this.onExport,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  ExportFormat _format = ExportFormat.csv;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Eksporter ${widget.type.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Velg format:'),
          const SizedBox(height: 8),
          RadioGroup<ExportFormat>(
            groupValue: _format,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _format = value;
                });
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: ExportFormat.values.map((format) => RadioListTile<ExportFormat>(
                title: Text(format.displayName),
                subtitle: Text(format.description),
                value: format,
              )).toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            widget.onExport(_format, null);
          },
          child: const Text('Eksporter'),
        ),
      ],
    );
  }
}

class ExportPreviewDialog extends StatelessWidget {
  final ExportData data;

  const ExportPreviewDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Eksportert data'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${data.data.length} rader eksportert',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (data.summary != null) ...[
              const SizedBox(height: 8),
              Card(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sammendrag:', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 4),
                      ...data.summary!.entries.map((e) => Text(
                        '${_formatKey(e.key)}: ${e.value}',
                        style: theme.textTheme.bodySmall,
                      )),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Forhandsvisning:'),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: data.columns.map((c) => DataColumn(
                      label: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                    )).toList(),
                    rows: data.data.take(10).map((row) => DataRow(
                      cells: row.values.map((v) => DataCell(
                        Text(_formatValue(v)),
                      )).toList(),
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Lukk'),
        ),
      ],
    );
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) =>
      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
    ).join(' ');
  }

  String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is bool) return value ? 'Ja' : 'Nei';
    return value.toString();
  }
}
