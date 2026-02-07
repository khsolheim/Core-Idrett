import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';

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
            title: const Text('Legg til pa hovedleaderboard'),
            subtitle: Text(
              isDraw
                  ? 'Alle far ${widget.miniActivity.drawPoints} poeng pa sesong-leaderboard'
                  : 'Vinnere far ${widget.miniActivity.winPoints}p, tapere ${widget.miniActivity.lossPoints}p pa sesong-leaderboard',
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
