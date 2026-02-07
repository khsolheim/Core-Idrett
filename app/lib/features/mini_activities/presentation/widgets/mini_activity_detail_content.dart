import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';
import 'mini_activity_sheets.dart';
import 'mini_activity_team_card.dart';

class MiniActivityDetailContent extends ConsumerStatefulWidget {
  final MiniActivity miniActivity;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId;

  const MiniActivityDetailContent({
    super.key,
    required this.miniActivity,
    this.instanceId,
    required this.teamId,
  });

  @override
  ConsumerState<MiniActivityDetailContent> createState() => MiniActivityDetailContentState();
}

class MiniActivityDetailContentState extends ConsumerState<MiniActivityDetailContent> {
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
              ...miniActivity.teams!.map((team) => MiniActivityTeamCard(
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
                            ? CachedNetworkImageProvider(participant.userAvatarUrl!)
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
      builder: (context) => TeamDivisionSheet(
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
      builder: (context) => RecordScoresSheet(
        miniActivity: widget.miniActivity,
        instanceId: widget.instanceId,
        teamId: widget.teamId,
      ),
    );
  }

  void _showSetWinnerDialog(BuildContext context, String? winnerTeamId) {
    showDialog(
      context: context,
      builder: (context) => SetWinnerDialog(
        miniActivity: widget.miniActivity,
        instanceId: widget.instanceId,
        teamId: widget.teamId,
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
                    teamId: widget.teamId,
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
                      teamId: widget.teamId,
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

// Result badge for winner/draw indication
class ResultBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const ResultBadge({
    super.key,
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
