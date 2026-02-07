import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';

/// Bottom sheet for creating a standalone mini-activity
class CreateStandaloneActivitySheet extends ConsumerStatefulWidget {
  final String teamId;

  const CreateStandaloneActivitySheet({super.key, required this.teamId});

  @override
  ConsumerState<CreateStandaloneActivitySheet> createState() =>
      _CreateStandaloneActivitySheetState();
}

class _CreateStandaloneActivitySheetState
    extends ConsumerState<CreateStandaloneActivitySheet> {
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
        const SnackBar(content: Text('Navn er pakrevd')),
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
          const SnackBar(content: Text('Kunne ikke opprette aktivitet. Prøv igjen.')),
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
