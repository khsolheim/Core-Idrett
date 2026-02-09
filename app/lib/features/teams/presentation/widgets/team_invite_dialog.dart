import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/team.dart';
import '../../providers/team_provider.dart';
import '../../../../core/services/error_display_service.dart';

class TeamInviteDialog extends ConsumerStatefulWidget {
  final String teamId;
  final Team team;

  const TeamInviteDialog({super.key, required this.teamId, required this.team});

  @override
  ConsumerState<TeamInviteDialog> createState() => _TeamInviteDialogState();
}

class _TeamInviteDialogState extends ConsumerState<TeamInviteDialog> {
  String? _inviteCode;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _inviteCode = widget.team.inviteCode;
  }

  @override
  Widget build(BuildContext context) {
    final inviteUrl = _inviteCode != null
        ? 'https://core-idrett.app/invite/$_inviteCode'
        : null;

    return AlertDialog(
      title: const Text('Inviter medlemmer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Del denne lenken med de du vil invitere:'),
          const SizedBox(height: 16),
          if (_inviteCode != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteUrl!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteUrl));
                      ErrorDisplayService.showSuccess('Lenke kopiert!');
                    },
                  ),
                ],
              ),
            )
          else
            const Text('Ingen invitasjonskode generert enda.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Lukk'),
        ),
        TextButton(
          onPressed: _loading ? null : _generateNewCode,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_inviteCode != null ? 'Ny kode' : 'Generer kode'),
        ),
      ],
    );
  }

  Future<void> _generateNewCode() async {
    setState(() => _loading = true);
    final code = await ref.read(teamNotifierProvider.notifier).generateInviteCode(widget.teamId);
    if (mounted) {
      setState(() {
        _inviteCode = code;
        _loading = false;
      });
    }
  }
}
