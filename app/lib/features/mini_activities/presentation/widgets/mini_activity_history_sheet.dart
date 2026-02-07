import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../providers/mini_activity_provider.dart';

// History Sheet
class MiniActivityHistorySheet extends ConsumerWidget {
  final String teamId;
  final String? templateId;

  const MiniActivityHistorySheet({
    super.key,
    required this.teamId,
    this.templateId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(miniActivityHistoryProvider(
      MiniActivityHistoryParams(teamId: teamId, templateId: templateId),
    ));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historikk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: historyAsync.when2(
                onRetry: () => ref.invalidate(miniActivityHistoryProvider(
                  MiniActivityHistoryParams(teamId: teamId, templateId: templateId),
                )),
                data: (history) {
                  if (history.isEmpty) {
                    return const Center(
                      child: Text('Ingen tidligere resultater'),
                    );
                  }

                  return ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final entry = history[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    entry.name,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatDate(entry.createdAt),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 16,
                                children: entry.teams.map((team) {
                                  final isWinner = entry.winnerTeamId == team.id ||
                                      (entry.winnerTeam?.id == team.id);
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isWinner)
                                        const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
                                      Text(
                                        '${team.name ?? "Lag"}: ${team.finalScore ?? "-"}',
                                        style: TextStyle(
                                          fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
