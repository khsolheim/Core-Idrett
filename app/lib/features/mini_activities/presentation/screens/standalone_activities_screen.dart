import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';

/// Screen for viewing and managing standalone mini-activities for a team
class StandaloneActivitiesScreen extends ConsumerWidget {
  final String teamId;

  const StandaloneActivitiesScreen({
    super.key,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(teamStandaloneMiniActivitiesProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-aktiviteter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId)),
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: activitiesAsync.when(
        data: (activities) => _ActivityList(
          activities: activities,
          teamId: teamId,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Feil: $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId)),
                child: const Text('Prøv igjen'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ny aktivitet'),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<MiniActivity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CreateStandaloneActivitySheet(teamId: teamId),
    );

    if (result != null && context.mounted) {
      ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId));
    }
  }
}

class _ActivityList extends StatelessWidget {
  final List<MiniActivity> activities;
  final String teamId;

  const _ActivityList({
    required this.activities,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sports_esports_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen mini-aktiviteter ennå',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trykk + for å opprette en ny aktivitet',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Group by archived status
    final active = activities.where((a) => !a.isArchived).toList();
    final archived = activities.where((a) => a.isArchived).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          _SectionHeader(
            title: 'Aktive',
            count: active.length,
          ),
          const SizedBox(height: 8),
          ...active.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActivityCard(activity: a),
              )),
          const SizedBox(height: 16),
        ],
        if (archived.isNotEmpty) ...[
          _SectionHeader(
            title: 'Arkiverte',
            count: archived.length,
          ),
          const SizedBox(height: 8),
          ...archived.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActivityCard(activity: a, isArchived: true),
              )),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final MiniActivity activity;
  final bool isArchived;

  const _ActivityCard({
    required this.activity,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openActivity(context),
        child: Opacity(
          opacity: isArchived ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ActivityTypeIcon(type: activity.type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (activity.description != null)
                            Text(
                              activity.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    _TypeChip(type: activity.type, isArchived: isArchived),
                  ],
                ),
                if (activity.teams != null && activity.teams!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.teams!.length} lag',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const Spacer(),
                      if (activity.enableLeaderboard)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.leaderboard_outlined,
                              size: 16,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ledertavle',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openActivity(BuildContext context) {
    // TODO: Navigate to mini-activity detail screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Åpner: ${activity.name}')),
    );
  }
}

class _ActivityTypeIcon extends StatelessWidget {
  final MiniActivityType type;

  const _ActivityTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      MiniActivityType.team => (Icons.groups_outlined, Colors.blue),
      MiniActivityType.individual => (Icons.person_outline, Colors.green),
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final MiniActivityType type;
  final bool isArchived;

  const _TypeChip({
    required this.type,
    this.isArchived = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isArchived) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Arkivert',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Bottom sheet for creating a standalone mini-activity
class _CreateStandaloneActivitySheet extends ConsumerStatefulWidget {
  final String teamId;

  const _CreateStandaloneActivitySheet({required this.teamId});

  @override
  ConsumerState<_CreateStandaloneActivitySheet> createState() =>
      _CreateStandaloneActivitySheetState();
}

class _CreateStandaloneActivitySheetState
    extends ConsumerState<_CreateStandaloneActivitySheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  MiniActivityType _type = MiniActivityType.team;
  bool _enableLeaderboard = true;
  int _winPoints = 3;
  int _drawPoints = 1;
  int _lossPoints = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navn er påkrevd')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(standaloneMiniActivityProvider.notifier);
      final result = await notifier.createStandaloneMiniActivity(
        teamId: widget.teamId,
        name: _nameController.text.trim(),
        type: _type,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        enableLeaderboard: _enableLeaderboard,
        winPoints: _winPoints,
        drawPoints: _drawPoints,
        lossPoints: _lossPoints,
      );

      if (mounted && result != null) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Ny mini-aktivitet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Navn *',
                      hintText: 'F.eks. Bordtennis-turnering',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Beskrivelse (valgfritt)',
                      hintText: 'Kort beskrivelse av aktiviteten',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),

                  // Type
                  Text(
                    'Type',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<MiniActivityType>(
                    segments: const [
                      ButtonSegment(
                        value: MiniActivityType.team,
                        label: Text('Lag'),
                        icon: Icon(Icons.groups_outlined),
                      ),
                      ButtonSegment(
                        value: MiniActivityType.individual,
                        label: Text('Individuell'),
                        icon: Icon(Icons.person_outline),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (selection) {
                      setState(() => _type = selection.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Leaderboard
                  SwitchListTile(
                    title: const Text('Ledertavle'),
                    subtitle: const Text('Oppdater lagets ledertavle med resultater'),
                    value: _enableLeaderboard,
                    onChanged: (value) {
                      setState(() => _enableLeaderboard = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Points
                  if (_enableLeaderboard) ...[
                    Text(
                      'Poenggivning',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PointsInput(
                            label: 'Seier',
                            value: _winPoints,
                            onChanged: (v) => setState(() => _winPoints = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PointsInput(
                            label: 'Uavgjort',
                            value: _drawPoints,
                            onChanged: (v) => setState(() => _drawPoints = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PointsInput(
                            label: 'Tap',
                            value: _lossPoints,
                            onChanged: (v) => setState(() => _lossPoints = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Create button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton(
                onPressed: _isLoading ? null : _create,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Opprett'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PointsInput extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _PointsInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: value > 0 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove, size: 16),
              visualDensity: VisualDensity.compact,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$value',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton.filledTonal(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add, size: 16),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}
