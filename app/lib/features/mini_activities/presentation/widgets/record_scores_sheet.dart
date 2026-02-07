import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';
import 'mini_activity_helpers.dart';

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
            title: const Text('Legg til pa hovedleaderboard'),
            subtitle: Text(
              'Vinner: ${widget.miniActivity.winPoints}p, Uavgjort: ${widget.miniActivity.drawPoints}p, Tap: ${widget.miniActivity.lossPoints}p pa sesong-leaderboard',
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
