import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import 'mini_activity_helpers.dart';
import 'result_badge.dart';
import 'team_card_dialogs.dart';

class MiniActivityTeamCard extends ConsumerWidget {
  final MiniActivityTeam team;
  final MiniActivity miniActivity;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId;
  final bool isEditMode;
  final bool isWinner;
  final bool isDraw;
  final VoidCallback onWinnerSelected;

  const MiniActivityTeamCard({
    super.key,
    required this.team,
    required this.miniActivity,
    this.instanceId,
    required this.teamId,
    required this.isEditMode,
    required this.isWinner,
    required this.isDraw,
    required this.onWinnerSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Winner/Draw indicator
                if (isWinner && !isDraw) ...[
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                ] else if (isDraw && miniActivity.hasResult) ...[
                  Icon(Icons.balance, color: theme.colorScheme.secondary, size: 20),
                  const SizedBox(width: 4),
                ],
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: getTeamColor(team.name),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          team.name ?? 'Lag',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      if (isWinner && !isDraw) ...[
                        const SizedBox(width: 8),
                        ResultBadge(
                          text: 'Vinner',
                          backgroundColor: Colors.amber.withValues(alpha: 0.2),
                          textColor: Colors.amber.shade800,
                        ),
                      ] else if (isDraw && miniActivity.hasResult) ...[
                        const SizedBox(width: 8),
                        ResultBadge(
                          text: 'Uavgjort',
                          backgroundColor: Colors.grey.shade200,
                          textColor: Colors.grey.shade700,
                        ),
                      ],
                    ],
                  ),
                ),
                // Score badge
                if (team.finalScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isWinner && !isDraw
                          ? Colors.amber.withValues(alpha: 0.2)
                          : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${team.finalScore}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isWinner && !isDraw
                            ? Colors.amber.shade800
                            : theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                // Quick winner button (not in edit mode, no result yet)
                if (!isEditMode && !miniActivity.hasResult) ...[
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: onWinnerSelected,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Vant'),
                  ),
                ],
                // Edit mode menu
                if (isEditMode)
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Endre navn'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Slett lag', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'rename') {
                        showRenameTeamDialog(
                          context: context,
                          ref: ref,
                          team: team,
                          miniActivity: miniActivity,
                          instanceId: instanceId,
                          teamId: teamId,
                        );
                      } else if (value == 'delete') {
                        showDeleteTeamDialog(
                          context: context,
                          ref: ref,
                          team: team,
                          miniActivity: miniActivity,
                          instanceId: instanceId,
                          teamId: teamId,
                        );
                      }
                    },
                  ),
              ],
            ),
            if (team.participants != null && team.participants!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: team.participants!.map((p) {
                  if (isEditMode) {
                    return GestureDetector(
                      onTap: () => showMoveParticipantDialog(
                        context: context,
                        ref: ref,
                        team: team,
                        miniActivity: miniActivity,
                        instanceId: instanceId,
                        teamId: teamId,
                        participant: p,
                      ),
                      child: Chip(
                        avatar: CircleAvatar(
                          backgroundImage: p.userAvatarUrl != null
                              ? CachedNetworkImageProvider(p.userAvatarUrl!)
                              : null,
                          child: p.userAvatarUrl == null
                              ? Text(p.userName?.substring(0, 1).toUpperCase() ?? '?',
                                  style: const TextStyle(fontSize: 12))
                              : null,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(p.userName ?? 'Ukjent'),
                            const SizedBox(width: 4),
                            const Icon(Icons.swap_horiz, size: 16),
                          ],
                        ),
                      ),
                    );
                  }
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundImage: p.userAvatarUrl != null
                          ? CachedNetworkImageProvider(p.userAvatarUrl!)
                          : null,
                      child: p.userAvatarUrl == null
                          ? Text(p.userName?.substring(0, 1).toUpperCase() ?? '?',
                              style: const TextStyle(fontSize: 12))
                          : null,
                    ),
                    label: Text(p.userName ?? 'Ukjent'),
                  );
                }).toList(),
              ),
            ],
            // Add participant button in edit mode
            if (isEditMode) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => showAddParticipantSheet(
                  context: context,
                  miniActivity: miniActivity,
                  instanceId: instanceId,
                  teamId: teamId,
                  targetTeamId: team.id,
                ),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Legg til spiller'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
