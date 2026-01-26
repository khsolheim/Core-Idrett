import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/mini_activity.dart';
import '../../activities/providers/activity_provider.dart';
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
}

class _MiniActivityDetailContent extends ConsumerWidget {
  final MiniActivity miniActivity;
  final String instanceId;
  final String teamId;

  const _MiniActivityDetailContent({
    required this.miniActivity,
    required this.instanceId,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
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
                  TextButton.icon(
                    onPressed: () => _showScoreDialog(context, ref),
                    icon: const Icon(Icons.edit),
                    label: const Text('Registrer resultat'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...miniActivity.teams!.map((team) => _TeamCard(team: team)),
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
                  separatorBuilder: (_, _) => const Divider(height: 1),
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

  void _showDivisionDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TeamDivisionSheet(
        miniActivityId: miniActivity.id,
        instanceId: instanceId,
        teamId: teamId,
      ),
    );
  }

  void _showScoreDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _RecordScoresSheet(
        miniActivity: miniActivity,
        instanceId: instanceId,
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final MiniActivityTeam team;

  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
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
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getTeamColor(team.name),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  team.name ?? 'Lag',
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (team.finalScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${team.finalScore}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (team.participants != null && team.participants!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: team.participants!.map((p) {
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
          ],
        ),
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
                'Del inn lag',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'Metode',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              RadioGroup<DivisionMethod>(
                groupValue: _method,
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
                child: Column(
                  children: DivisionMethod.values.map((method) {
                    return ListTile(
                      leading: Radio<DivisionMethod>(value: method),
                      title: Text(method.displayName),
                      subtitle: Text(method.description),
                      onTap: () => setState(() => _method = method),
                    );
                  }).toList(),
                ),
              ),
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
              const SizedBox(height: 24),
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
            'Registrer resultat',
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
