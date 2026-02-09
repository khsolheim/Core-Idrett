import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/error_display_service.dart';
import '../../../../data/models/team.dart';
import '../../providers/team_provider.dart';

/// Shows a confirmation dialog for deactivating a team member.
/// Returns true if the member was successfully deactivated.
Future<void> showDeactivateMemberDialog(
  BuildContext context,
  WidgetRef ref,
  String teamId,
  TeamMember member,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Deaktiver medlem?'),
      content: Text(
        '${member.userName} vil ikke lenger kunne se laget. Du kan reaktivere dem senere.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Deaktiver'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final notifier = ref.read(teamNotifierProvider.notifier);
    final success = await notifier.deactivateMember(teamId, member.id);

    if (context.mounted) {
      if (success) {
        ErrorDisplayService.showSuccess('Medlem deaktivert');
      } else {
        ErrorDisplayService.showWarning('Kunne ikke deaktivere medlem');
      }
    }
  }
}

/// Shows a confirmation dialog for permanently removing a team member.
/// Returns true if the member was successfully removed.
Future<void> showRemoveMemberDialog(
  BuildContext context,
  WidgetRef ref,
  String teamId,
  TeamMember member,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Fjern medlem permanent?'),
      content: Text(
        'Er du sikker pa at du vil fjerne ${member.userName} fra laget? Dette kan ikke angres.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Avbryt'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Fjern'),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final notifier = ref.read(teamNotifierProvider.notifier);
    final success = await notifier.removeMember(teamId, member.id);

    if (context.mounted) {
      if (success) {
        ErrorDisplayService.showSuccess('Medlem fjernet');
      } else {
        ErrorDisplayService.showWarning('Kunne ikke fjerne medlem');
      }
    }
  }
}
