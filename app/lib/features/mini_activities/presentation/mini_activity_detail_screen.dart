import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../providers/mini_activity_provider.dart';
import 'widgets/mini_activity_detail_content.dart';
import 'widgets/mini_activity_sheets.dart';

class MiniActivityDetailScreen extends ConsumerWidget {
  final String miniActivityId;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId;

  const MiniActivityDetailScreen({
    super.key,
    required this.miniActivityId,
    this.instanceId, // Optional for standalone mini-activities
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(miniActivityDetailProvider(miniActivityId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-aktivitet'),
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Vis historikk',
            onPressed: () => _showHistorySheet(context, ref),
          ),
        ],
      ),
      body: detailAsync.when2(
        onRetry: () => ref.invalidate(miniActivityDetailProvider(miniActivityId)),
        data: (miniActivity) => MiniActivityDetailContent(
          miniActivity: miniActivity,
          instanceId: instanceId,
          teamId: teamId,
        ),
      ),
    );
  }

  void _showHistorySheet(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.read(miniActivityDetailProvider(miniActivityId));
    detailAsync.whenData((miniActivity) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => MiniActivityHistorySheet(
          teamId: teamId,
          templateId: miniActivity.templateId,
        ),
      );
    });
  }
}
