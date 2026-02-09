import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/export_log.dart';
import '../providers/export_provider.dart';
import 'widgets/widgets.dart';

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

            return ExportOptionCard(
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

          historyAsync.when2(
            onRetry: () => ref.invalidate(exportHistoryProvider(widget.teamId)),
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
                    return ExportHistoryTile(log: log);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showExportDialog(ExportType type) {
    showDialog(
      context: context,
      builder: (context) => ExportDialog(
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
      ErrorDisplayService.showWarning('Eksport feilet. Prøv igjen.');
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
        ErrorDisplayService.showInfo('Data kopiert til utklippstavlen');
      }
    }
  }

  void _showExportPreview(ExportData data) {
    showDialog(
      context: context,
      builder: (context) => ExportPreviewDialog(data: data),
    );
  }
}
