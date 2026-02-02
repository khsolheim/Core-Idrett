import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/mini_activity.dart';
import '../../activities/providers/activity_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/mini_activity_provider.dart';

class MiniActivityDetailScreen extends ConsumerWidget {
  final String miniActivityId;
  final String instanceId;
  final String teamId;

  const MiniActivityDetailScreen({
    super.key,
    required this.miniActivityId,
    required this.instanceId,
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
      body: detailAsync.when(
        data: (miniActivity) => _MiniActivityDetailContent(
          miniActivity: miniActivity,
          instanceId: instanceId,
          teamId: teamId,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Kunne ikke laste mini-aktivitet: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(miniActivityDetailProvider(miniActivityId)),
                child: const Text('Prøv igjen'),
              ),
            ],
          ),
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
        builder: (context) => _HistorySheet(
          teamId: teamId,
          templateId: miniActivity.templateId,
        ),
      );
    });
  }
}

class _MiniActivityDetailContent extends ConsumerStatefulWidget {
  final MiniActivity miniActivity;
  final String instanceId;
  final String teamId;

  const _MiniActivityDetailContent({
    required this.miniActivity,
    required this.instanceId,
    required this.teamId,
  });

  @override
  ConsumerState<_MiniActivityDetailContent> createState() => _MiniActivityDetailContentState();
}

class _MiniActivityDetailContentState extends ConsumerState<_MiniActivityDetailContent> {
  bool _isEditMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final miniActivity = widget.miniActivity;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(miniActivityDetailProvider(miniActivity.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          miniActivity.isTeamBased ? Icons.groups : Icons.person,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Chip(label: Text(miniActivity.type.displayName)),
                        if (miniActivity.divisionMethod != null) ...[
                          const SizedBox(width: 8),
                          Chip(label: Text(miniActivity.divisionMethod!.displayName)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      miniActivity.name,
                      style: theme.textTheme.headlineSmall,
                    ),
                    // Show result status
                    if (miniActivity.hasResult) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            miniActivity.isDraw ? Icons.balance : Icons.emoji_events,
                            color: miniActivity.isDraw
                                ? theme.colorScheme.secondary
                                : Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            miniActivity.isDraw
                                ? 'Uavgjort'
                                : 'Vinner: ${miniActivity.winnerTeam?.name ?? "Ukjent"}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions - Division
            if (!miniActivity.hasTeams && miniActivity.isTeamBased) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lag-inndeling',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Del inn spillerne i lag for å starte aktiviteten',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _showDivisionDialog(context, ref),
                          icon: const Icon(Icons.group_add),
                          label: const Text('Del inn lag'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Teams
            if (miniActivity.hasTeams) ...[
              Row(
                children: [
                  Text(
                    'Lag',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  // Edit mode toggle
                  TextButton.icon(
                    onPressed: () {
                      if (_isEditMode && miniActivity.hasResult) {
                        // Show warning when exiting edit mode after result
                        setState(() => _isEditMode = false);
                      } else if (!_isEditMode && miniActivity.hasResult) {
                        // Show warning when entering edit mode after result
                        _showEditWarningDialog(context);
                      } else {
                        setState(() => _isEditMode = !_isEditMode);
                      }
                    },
                    icon: Icon(_isEditMode ? Icons.check : Icons.edit),
                    label: Text(_isEditMode ? 'Ferdig' : 'Rediger lag'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Team cards
              ...miniActivity.teams!.map((team) => _TeamCard(
                    team: team,
                    miniActivity: miniActivity,
                    instanceId: widget.instanceId,
                    teamId: widget.teamId,
                    isEditMode: _isEditMode,
                    isWinner: miniActivity.winnerTeamId == team.id ||
                        (miniActivity.winnerTeam?.id == team.id),
                    isDraw: miniActivity.isDraw,
                    onWinnerSelected: () => _showSetWinnerDialog(context, team.id),
                  )),

              // Quick actions row when not in edit mode
              if (!_isEditMode) ...[
                const SizedBox(height: 8),
                // Draw button + Score button
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showSetWinnerDialog(context, null),
                        icon: const Icon(Icons.balance),
                        label: const Text('Uavgjort'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _showScoreDialog(context, ref),
                        icon: const Icon(Icons.sports_score),
                        label: const Text('Poengsum'),
                      ),
                    ),
                  ],
                ),
                // Clear result button if result exists
                if (miniActivity.hasResult) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _showClearResultDialog(context),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Nullstill resultat'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ],

              // Add team button in edit mode
              if (_isEditMode) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddTeamDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Legg til nytt lag'),
                  ),
                ),
              ],
            ],

            // Individual participants
            if (!miniActivity.isTeamBased && miniActivity.participants != null) ...[
              Text(
                'Deltakere',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: miniActivity.participants!.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final participant = miniActivity.participants![index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: participant.userAvatarUrl != null
                            ? NetworkImage(participant.userAvatarUrl!)
                            : null,
                        child: participant.userAvatarUrl == null
                            ? Text(participant.userName?.substring(0, 1).toUpperCase() ?? '?')
                            : null,
                      ),
                      title: Text(participant.userName ?? 'Ukjent'),
                      trailing: Text(
                        '${participant.points} poeng',
                        style: theme.textTheme.titleMedium,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rediger lag'),
        content: const Text(
          'Resultatet er registrert. Endring av lag kan gjøre resultatet ugyldig. Vil du fortsette?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isEditMode = true);
            },
            child: const Text('Fortsett'),
          ),
        ],
      ),
    );
  }

  void _showDivisionDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TeamDivisionSheet(
        miniActivityId: widget.miniActivity.id,
        instanceId: widget.instanceId,
        teamId: widget.teamId,
      ),
    );
  }

  void _showScoreDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecordScoresSheet(
        miniActivity: widget.miniActivity,
        instanceId: widget.instanceId,
      ),
    );
  }

  void _showSetWinnerDialog(BuildContext context, String? winnerTeamId) {
    showDialog(
      context: context,
      builder: (context) => _SetWinnerDialog(
        miniActivity: widget.miniActivity,
        instanceId: widget.instanceId,
        winnerTeamId: winnerTeamId,
      ),
    );
  }

  void _showClearResultDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nullstill resultat'),
        content: const Text(
          'Er du sikker på at du vil nullstille resultatet? Poeng og vinner vil bli slettet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(resultManagementProvider.notifier).clearResult(
                    miniActivityId: widget.miniActivity.id,
                    instanceId: widget.instanceId,
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Nullstill'),
          ),
        ],
      ),
    );
  }

  void _showAddTeamDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Legg til lag'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Lagnavn',
            hintText: 'F.eks. Grønn',
          ),
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
                await ref.read(teamManagementProvider.notifier).createTeam(
                      miniActivityId: widget.miniActivity.id,
                      instanceId: widget.instanceId,
                      name: controller.text,
                    );
              }
            },
            child: const Text('Legg til'),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends ConsumerWidget {
  final MiniActivityTeam team;
  final MiniActivity miniActivity;
  final String instanceId;
  final String teamId;
  final bool isEditMode;
  final bool isWinner;
  final bool isDraw;
  final VoidCallback onWinnerSelected;

  const _TeamCard({
    required this.team,
    required this.miniActivity,
    required this.instanceId,
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
                    color: _getTeamColor(team.name),
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
                        _ResultBadge(
                          text: 'Vinner',
                          backgroundColor: Colors.amber.withValues(alpha: 0.2),
                          textColor: Colors.amber.shade800,
                        ),
                      ] else if (isDraw && miniActivity.hasResult) ...[
                        const SizedBox(width: 8),
                        _ResultBadge(
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
                      color: _getTeamColor(t.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(t.name ?? 'Lag'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(teamManagementProvider.notifier).deleteTeam(
                          miniActivityId: miniActivity.id,
                          instanceId: instanceId,
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
                      color: _getTeamColor(t.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(t.name ?? 'Lag'),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(teamManagementProvider.notifier).moveParticipant(
                          miniActivityId: miniActivity.id,
                          instanceId: instanceId,
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
      builder: (context) => _AddParticipantSheet(
        miniActivity: miniActivity,
        instanceId: instanceId,
        teamId: teamId,
        targetTeamId: team.id,
      ),
    );
  }

  Color _getTeamColor(String? name) {
    switch (name?.toLowerCase()) {
      case 'rød':
        return Colors.red;
      case 'blå':
        return Colors.blue;
      case 'grønn':
        return Colors.green;
      case 'gul':
        return Colors.yellow;
      case 'oransje':
        return Colors.orange;
      case 'lilla':
        return Colors.purple;
      case 'rosa':
        return Colors.pink;
      case 'hvit':
        return Colors.grey.shade300;
      case 'gamle':
        return Colors.brown;
      case 'unge':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }
}

// Set Winner Dialog
class _SetWinnerDialog extends ConsumerStatefulWidget {
  final MiniActivity miniActivity;
  final String instanceId;
  final String? winnerTeamId;

  const _SetWinnerDialog({
    required this.miniActivity,
    required this.instanceId,
    required this.winnerTeamId,
  });

  @override
  ConsumerState<_SetWinnerDialog> createState() => _SetWinnerDialogState();
}

class _SetWinnerDialogState extends ConsumerState<_SetWinnerDialog> {
  bool _addToLeaderboard = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDraw = widget.winnerTeamId == null;
    final winnerTeam = widget.winnerTeamId != null
        ? widget.miniActivity.teams?.firstWhere(
            (t) => t.id == widget.winnerTeamId,
            orElse: () => widget.miniActivity.teams!.first,
          )
        : null;

    return AlertDialog(
      title: Text(isDraw ? 'Registrer uavgjort' : 'Registrer vinner'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDraw)
            const Text('Vil du registrere denne aktiviteten som uavgjort?')
          else
            Text('Vil du registrere "${winnerTeam?.name}" som vinner?'),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _addToLeaderboard,
            onChanged: (value) => setState(() => _addToLeaderboard = value ?? true),
            title: const Text('Legg til på hovedleaderboard'),
            subtitle: Text(
              isDraw
                  ? 'Alle får ${widget.miniActivity.drawPoints} poeng på sesong-leaderboard'
                  : 'Vinnere får ${widget.miniActivity.winPoints}p, tapere ${widget.miniActivity.lossPoints}p på sesong-leaderboard',
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  await ref.read(resultManagementProvider.notifier).setWinner(
                        miniActivityId: widget.miniActivity.id,
                        instanceId: widget.instanceId,
                        winnerTeamId: widget.winnerTeamId,
                        addToLeaderboard: _addToLeaderboard,
                      );
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Bekreft'),
        ),
      ],
    );
  }
}

// Add Participant Sheet
class _AddParticipantSheet extends ConsumerWidget {
  final MiniActivity miniActivity;
  final String instanceId;
  final String teamId;
  final String targetTeamId;

  const _AddParticipantSheet({
    required this.miniActivity,
    required this.instanceId,
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
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Feil: $e')),
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

class _TeamDivisionSheet extends ConsumerStatefulWidget {
  final String miniActivityId;
  final String instanceId;
  final String teamId;

  const _TeamDivisionSheet({
    required this.miniActivityId,
    required this.instanceId,
    required this.teamId,
  });

  @override
  ConsumerState<_TeamDivisionSheet> createState() => _TeamDivisionSheetState();
}

class _TeamDivisionSheetState extends ConsumerState<_TeamDivisionSheet> {
  DivisionMethod _method = DivisionMethod.random;
  int _numberOfTeams = 2;
  bool _isLoading = false;

  List<String> _getParticipantIds(ActivityInstance instance) {
    if (instance.responses == null) return [];
    return instance.responses!
        .where((r) => r.response == UserResponse.yes)
        .map((r) => r.userId)
        .toList();
  }

  Future<void> _divide(List<String> participantIds) async {
    if (participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingen deltakere har svart "Ja"')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(teamDivisionProvider.notifier).divideTeams(
          miniActivityId: widget.miniActivityId,
          instanceId: widget.instanceId,
          method: _method,
          numberOfTeams: _numberOfTeams,
          participantUserIds: participantIds,
          teamId: widget.teamId,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke dele inn lag. Prøv igjen.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instanceAsync = ref.watch(instanceDetailProvider(widget.instanceId));

    return instanceAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Feil ved lasting av deltakere: $error'),
      ),
      data: (instance) {
        final participantIds = _getParticipantIds(instance);
        final yesResponses = instance.responses
                ?.where((r) => r.response == UserResponse.yes)
                .toList() ??
            [];

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Del inn lag',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Metode',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        ...DivisionMethod.values.map((method) {
                          return RadioListTile<DivisionMethod>(
                            value: method,
                            groupValue: _method,
                            onChanged: (value) {
                              if (value != null) setState(() => _method = value);
                            },
                            title: Text(method.displayName),
                            subtitle: Text(method.description),
                          );
                        }),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Antall lag:'),
                            const Spacer(),
                            IconButton(
                              onPressed: _numberOfTeams > 2
                                  ? () => setState(() => _numberOfTeams--)
                                  : null,
                              icon: const Icon(Icons.remove),
                            ),
                            Text(
                              '$_numberOfTeams',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            IconButton(
                              onPressed: () => setState(() => _numberOfTeams++),
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${yesResponses.length} deltakere har svart "Ja"',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                        if (yesResponses.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: yesResponses.map((r) {
                              return Chip(
                                avatar: CircleAvatar(
                                  backgroundImage: r.userAvatarUrl != null
                                      ? NetworkImage(r.userAvatarUrl!)
                                      : null,
                                  child: r.userAvatarUrl == null
                                      ? Text(
                                          r.userName?.substring(0, 1).toUpperCase() ?? '?',
                                          style: const TextStyle(fontSize: 12),
                                        )
                                      : null,
                                ),
                                label: Text(r.userName ?? 'Ukjent'),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isLoading ? null : () => _divide(participantIds),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Del inn'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecordScoresSheet extends ConsumerStatefulWidget {
  final MiniActivity miniActivity;
  final String instanceId;

  const _RecordScoresSheet({
    required this.miniActivity,
    required this.instanceId,
  });

  @override
  ConsumerState<_RecordScoresSheet> createState() => _RecordScoresSheetState();
}

class _RecordScoresSheetState extends ConsumerState<_RecordScoresSheet> {
  final Map<String, TextEditingController> _controllers = {};
  bool _addToLeaderboard = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final team in widget.miniActivity.teams ?? []) {
      _controllers[team.id] = TextEditingController(
        text: team.finalScore?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    final teamScores = <String, int>{};
    for (final entry in _controllers.entries) {
      final value = int.tryParse(entry.value.text);
      if (value != null) {
        teamScores[entry.key] = value;
      }
    }

    final success = await ref.read(recordScoresProvider.notifier).recordScores(
          miniActivityId: widget.miniActivity.id,
          instanceId: widget.instanceId,
          teamScores: teamScores,
          addToLeaderboard: _addToLeaderboard,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Registrer poengsum',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          ...widget.miniActivity.teams!.map((team) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: _controllers[team.id],
                decoration: InputDecoration(
                  labelText: team.name ?? 'Lag',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getTeamColor(team.name),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            );
          }),
          CheckboxListTile(
            value: _addToLeaderboard,
            onChanged: (value) => setState(() => _addToLeaderboard = value ?? true),
            title: const Text('Legg til på hovedleaderboard'),
            subtitle: Text(
              'Vinner: ${widget.miniActivity.winPoints}p, Uavgjort: ${widget.miniActivity.drawPoints}p, Tap: ${widget.miniActivity.lossPoints}p på sesong-leaderboard',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lagre'),
          ),
        ],
      ),
    );
  }

  Color _getTeamColor(String? name) {
    switch (name?.toLowerCase()) {
      case 'rød':
        return Colors.red;
      case 'blå':
        return Colors.blue;
      case 'grønn':
        return Colors.green;
      case 'gul':
        return Colors.yellow;
      case 'oransje':
        return Colors.orange;
      case 'lilla':
        return Colors.purple;
      case 'rosa':
        return Colors.pink;
      case 'hvit':
        return Colors.grey.shade300;
      default:
        return Colors.grey;
    }
  }
}

// History Sheet
class _HistorySheet extends ConsumerWidget {
  final String teamId;
  final String? templateId;

  const _HistorySheet({
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
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Feil: $e')),
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

// Result badge for winner/draw indication
class _ResultBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _ResultBadge({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
