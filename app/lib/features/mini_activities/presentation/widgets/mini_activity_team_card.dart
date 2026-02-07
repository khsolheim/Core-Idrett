import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/mini_activity.dart';
import '../../../teams/providers/team_provider.dart';
import '../../providers/mini_activity_provider.dart';
import 'mini_activity_detail_content.dart';
import 'mini_activity_helpers.dart';

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
                        _showRenameDialog(context, ref);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context, ref);
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
                      onTap: () => _showMoveParticipantDialog(context, ref, p),
                      child: Chip(
                        avatar: CircleAvatar(
                          backgroundImage: p.userAvatarUrl != null
                              ? NetworkImage(p.userAvatarUrl!)
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
                          ? NetworkImage(p.userAvatarUrl!)
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
                onPressed: () => _showAddParticipantDialog(context, ref),
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Legg til spiller'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: team.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Endre lagnavn'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Lagnavn'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                await ref.read(miniActivityOperationsProvider.notifier).updateTeamName(
                      miniActivityId: miniActivity.id,
                      instanceId: instanceId,
                      teamId: teamId,
                      miniTeamId: team.id,
                      name: controller.text,
                    );
              }
            },
            child: const Text('Lagre'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final hasParticipants = team.participants?.isNotEmpty ?? false;
    final otherTeams = miniActivity.teams?.where((t) => t.id != team.id).toList() ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett lag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Er du sikker på at du vil slette "${team.name}"?'),
            if (hasParticipants) ...[
              const SizedBox(height: 12),
              Text(
                'Laget har ${team.participants!.length} spiller(e). Spillerne vil bli fjernet fra aktiviteten.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          if (hasParticipants && otherTeams.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showMoveAllParticipantsDialog(context, ref, otherTeams);
              },
              child: const Text('Flytt spillere'),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(teamManagementProvider.notifier).deleteTeam(
                    miniActivityId: miniActivity.id,
                    instanceId: instanceId,
                    teamId: teamId,
                    miniTeamId: team.id,
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }

  void _showMoveAllParticipantsDialog(
    BuildContext context,
    WidgetRef ref,
    List<MiniActivityTeam> otherTeams,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Flytt spillere'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Velg lag å flytte spillerne til:'),
            const SizedBox(height: 16),
            ...otherTeams.map((t) => ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: getTeamColor(t.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(t.name ?? 'Lag'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(teamManagementProvider.notifier).deleteTeam(
                          miniActivityId: miniActivity.id,
                          instanceId: instanceId,
                          teamId: teamId,
                          miniTeamId: team.id,
                          moveParticipantsToTeamId: t.id,
                        );
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
        ],
      ),
    );
  }

  void _showMoveParticipantDialog(
    BuildContext context,
    WidgetRef ref,
    MiniActivityParticipant participant,
  ) {
    final otherTeams = miniActivity.teams?.where((t) => t.id != team.id).toList() ?? [];

    if (otherTeams.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingen andre lag å flytte til')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Flytt ${participant.userName ?? "spiller"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Velg lag å flytte spilleren til:'),
            const SizedBox(height: 16),
            ...otherTeams.map((t) => ListTile(
                  leading: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: getTeamColor(t.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(t.name ?? 'Lag'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(teamManagementProvider.notifier).moveParticipant(
                          miniActivityId: miniActivity.id,
                          instanceId: instanceId,
                          teamId: teamId,
                          participantId: participant.id,
                          targetTeamId: t.id,
                        );
                  },
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
        ],
      ),
    );
  }

  void _showAddParticipantDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddParticipantSheet(
        miniActivity: miniActivity,
        instanceId: instanceId,
        teamId: teamId,
        targetTeamId: team.id,
      ),
    );
  }
}

class AddParticipantSheet extends ConsumerWidget {
  final MiniActivity miniActivity;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId;
  final String targetTeamId;

  const AddParticipantSheet({
    super.key,
    required this.miniActivity,
    this.instanceId,
    required this.teamId,
    required this.targetTeamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));

    // Get existing participant user IDs
    final existingUserIds = <String>{};
    for (final team in miniActivity.teams ?? []) {
      for (final p in team.participants ?? []) {
        existingUserIds.add(p.userId);
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legg til spiller',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: membersAsync.when2(
                onRetry: () => ref.invalidate(teamMembersProvider(teamId)),
                data: (members) {
                  final availableMembers = members
                      .where((m) => !existingUserIds.contains(m.userId))
                      .toList();

                  if (availableMembers.isEmpty) {
                    return const Center(
                      child: Text('Alle lagmedlemmer er allerede med'),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableMembers.length,
                    itemBuilder: (context, index) {
                      final member = availableMembers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: member.userAvatarUrl != null
                              ? NetworkImage(member.userAvatarUrl!)
                              : null,
                          child: member.userAvatarUrl == null
                              ? Text(member.userName.substring(0, 1).toUpperCase())
                              : null,
                        ),
                        title: Text(member.userName),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(miniActivityOperationsProvider.notifier).addLateParticipant(
                                miniActivityId: miniActivity.id,
                                instanceId: instanceId,
                                teamId: teamId,
                                userId: member.userId,
                                miniTeamId: targetTeamId,
                              );
                        },
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
}
