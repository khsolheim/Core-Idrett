import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/activity.dart';
import '../../../../data/models/mini_activity.dart';
import '../../../activities/providers/activity_provider.dart';
import '../../../teams/providers/team_provider.dart';
import '../../providers/mini_activity_provider.dart';
import 'mini_activity_helpers.dart';

// Set Winner Dialog
class SetWinnerDialog extends ConsumerStatefulWidget {
  final MiniActivity miniActivity;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId; // For invalidating standalone provider
  final String? winnerTeamId;

  const SetWinnerDialog({
    super.key,
    required this.miniActivity,
    this.instanceId,
    required this.teamId,
    required this.winnerTeamId,
  });

  @override
  ConsumerState<SetWinnerDialog> createState() => SetWinnerDialogState();
}

class SetWinnerDialogState extends ConsumerState<SetWinnerDialog> {
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
                        teamId: widget.teamId,
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

class TeamDivisionSheet extends ConsumerStatefulWidget {
  final String miniActivityId;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId;

  const TeamDivisionSheet({
    super.key,
    required this.miniActivityId,
    this.instanceId,
    required this.teamId,
  });

  @override
  ConsumerState<TeamDivisionSheet> createState() => TeamDivisionSheetState();
}

class TeamDivisionSheetState extends ConsumerState<TeamDivisionSheet> {
  DivisionMethod _method = DivisionMethod.random;
  int _numberOfTeams = 2;
  bool _isLoading = false;
  final Set<String> _selectedMemberIds = {}; // For standalone activities

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
        SnackBar(
          content: Text(widget.instanceId != null
              ? 'Ingen deltakere har svart "Ja"'
              : 'Velg minst én deltaker'),
        ),
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
    // For standalone activities (no instanceId), fetch team members
    if (widget.instanceId == null) {
      return _buildStandaloneContent(context);
    }

    // For instance-based activities, fetch from instance responses
    final instanceAsync = ref.watch(instanceDetailProvider(widget.instanceId!));

    return instanceAsync.when2(
      onRetry: () => ref.invalidate(instanceDetailProvider(widget.instanceId!)),
      data: (instance) {
        final participantIds = _getParticipantIds(instance);
        final yesResponses = instance.responses
                ?.where((r) => r.response == UserResponse.yes)
                .toList() ??
            [];

        return _buildSheetContent(
          context: context,
          participantIds: participantIds,
          participantCount: yesResponses.length,
          participantLabel: '${yesResponses.length} deltakere har svart "Ja"',
          participantChips: yesResponses.map((r) {
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
        );
      },
    );
  }

  Widget _buildStandaloneContent(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));

    return membersAsync.when2(
      onRetry: () => ref.invalidate(teamMembersProvider(widget.teamId)),
      data: (members) {
        return _buildSheetContent(
          context: context,
          participantIds: _selectedMemberIds.toList(),
          participantCount: _selectedMemberIds.length,
          participantLabel: '${_selectedMemberIds.length} av ${members.length} valgt',
          memberSelectionWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Velg deltakere',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMemberIds.length == members.length) {
                          _selectedMemberIds.clear();
                        } else {
                          _selectedMemberIds.addAll(members.map((m) => m.userId));
                        }
                      });
                    },
                    child: Text(_selectedMemberIds.length == members.length
                        ? 'Velg ingen'
                        : 'Velg alle'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: members.map((member) {
                  final isSelected = _selectedMemberIds.contains(member.userId);
                  return FilterChip(
                    selected: isSelected,
                    avatar: CircleAvatar(
                      backgroundImage: member.userAvatarUrl != null
                          ? NetworkImage(member.userAvatarUrl!)
                          : null,
                      child: member.userAvatarUrl == null
                          ? Text(
                              member.userName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    label: Text(member.userName),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMemberIds.add(member.userId);
                        } else {
                          _selectedMemberIds.remove(member.userId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetContent({
    required BuildContext context,
    required List<String> participantIds,
    required int participantCount,
    required String participantLabel,
    List<Widget>? participantChips,
    Widget? memberSelectionWidget,
  }) {
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
                    // Member selection for standalone activities
                    if (memberSelectionWidget != null) ...[
                      memberSelectionWidget,
                      const SizedBox(height: 16),
                    ],
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
                      participantLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    if (participantChips != null && participantChips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: participantChips,
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
  }
}

class RecordScoresSheet extends ConsumerStatefulWidget {
  final MiniActivity miniActivity;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId; // For invalidating standalone provider

  const RecordScoresSheet({
    super.key,
    required this.miniActivity,
    this.instanceId,
    required this.teamId,
  });

  @override
  ConsumerState<RecordScoresSheet> createState() => RecordScoresSheetState();
}

class RecordScoresSheetState extends ConsumerState<RecordScoresSheet> {
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
          teamId: widget.teamId,
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
                      color: getTeamColor(team.name),
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
}

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
