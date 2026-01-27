import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/export_log.dart';
import '../providers/export_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final String teamId;
  final bool isAdmin;

  const ExportScreen({
    super.key,
    required this.teamId,
    this.isAdmin = false,
  });

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportNotifierProvider(widget.teamId));
    final historyAsync = ref.watch(exportHistoryProvider(widget.teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eksporter data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Export options
          Text(
            'Velg hva du vil eksportere',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          ...ExportType.values.map((type) {
            // Hide members export for non-admins
            if (type == ExportType.members && !widget.isAdmin) {
              return const SizedBox.shrink();
            }

            return _ExportOptionCard(
              type: type,
              isExporting: exportState.isExporting && exportState.currentType == type.value,
              onExport: () => _showExportDialog(type),
            );
          }),

          const SizedBox(height: 32),

          // Export history
          Text(
            'Eksporthistorikk',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          historyAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Ingen eksporter enna',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.take(10).length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = history[index];
                    return _ExportHistoryTile(log: log);
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Kunne ikke laste historikk: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(ExportType type) {
    showDialog(
      context: context,
      builder: (context) => _ExportDialog(
        teamId: widget.teamId,
        type: type,
        onExport: (format, params) => _performExport(type, format, params),
      ),
    );
  }

  Future<void> _performExport(
    ExportType type,
    ExportFormat format,
    Map<String, String>? params,
  ) async {
    final notifier = ref.read(exportNotifierProvider(widget.teamId).notifier);

    if (format == ExportFormat.csv) {
      final csv = await notifier.exportToCsv(type, extraParams: params);
      if (csv != null && mounted) {
        await _shareCsv(csv, '${type.value}_export.csv');
      }
    } else {
      ExportData? data;
      switch (type) {
        case ExportType.leaderboard:
          data = await notifier.exportLeaderboard(
            seasonId: params?['season_id'],
            leaderboardId: params?['leaderboard_id'],
          );
          break;
        case ExportType.attendance:
          data = await notifier.exportAttendance(
            seasonId: params?['season_id'],
            fromDate: params?['from_date'] != null
                ? DateTime.tryParse(params!['from_date']!)
                : null,
            toDate: params?['to_date'] != null
                ? DateTime.tryParse(params!['to_date']!)
                : null,
          );
          break;
        case ExportType.fines:
          data = await notifier.exportFines(
            paidOnly: params?['paid_only'] == 'true',
            fromDate: params?['from_date'] != null
                ? DateTime.tryParse(params!['from_date']!)
                : null,
            toDate: params?['to_date'] != null
                ? DateTime.tryParse(params!['to_date']!)
                : null,
          );
          break;
        case ExportType.activities:
          data = await notifier.exportActivities(
            fromDate: params?['from_date'] != null
                ? DateTime.tryParse(params!['from_date']!)
                : null,
            toDate: params?['to_date'] != null
                ? DateTime.tryParse(params!['to_date']!)
                : null,
          );
          break;
        case ExportType.members:
          data = await notifier.exportMembers();
          break;
      }

      if (data != null && mounted) {
        _showExportPreview(data);
      }
    }

    final error = ref.read(exportNotifierProvider(widget.teamId)).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Feil: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareCsv(String content, String filename) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$filename');
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Eksport fra Core Idrett',
      );
    } catch (e) {
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: content));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data kopiert til utklippstavlen')),
        );
      }
    }
  }

  void _showExportPreview(ExportData data) {
    showDialog(
      context: context,
      builder: (context) => _ExportPreviewDialog(data: data),
    );
  }
}

class _ExportOptionCard extends StatelessWidget {
  final ExportType type;
  final bool isExporting;
  final VoidCallback onExport;

  const _ExportOptionCard({
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

class _ExportHistoryTile extends StatelessWidget {
  final ExportLog log;

  const _ExportHistoryTile({required this.log});

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

class _ExportDialog extends StatefulWidget {
  final String teamId;
  final ExportType type;
  final Function(ExportFormat format, Map<String, String>? params) onExport;

  const _ExportDialog({
    required this.teamId,
    required this.type,
    required this.onExport,
  });

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
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

class _ExportPreviewDialog extends StatelessWidget {
  final ExportData data;

  const _ExportPreviewDialog({required this.data});

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
