import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';
import 'mini_activity_sheets.dart';

/// Show warning dialog when editing teams after result is set
void showEditWarningDialog(
  BuildContext context, {
  required VoidCallback onConfirm,
}) {
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
            onConfirm();
          },
          child: const Text('Fortsett'),
        ),
      ],
    ),
  );
}

/// Show team division bottom sheet
void showMiniActivityDivisionDialog(
  BuildContext context, {
  required String miniActivityId,
  required String? instanceId,
  required String teamId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => TeamDivisionSheet(
      miniActivityId: miniActivityId,
      instanceId: instanceId,
      teamId: teamId,
    ),
  );
}

/// Show score recording bottom sheet
void showMiniActivityScoreDialog(
  BuildContext context, {
  required MiniActivity miniActivity,
  required String? instanceId,
  required String teamId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => RecordScoresSheet(
      miniActivity: miniActivity,
      instanceId: instanceId,
      teamId: teamId,
    ),
  );
}

/// Show set winner dialog
void showSetWinnerDialog(
  BuildContext context, {
  required MiniActivity miniActivity,
  required String? instanceId,
  required String teamId,
  required String? winnerTeamId,
}) {
  showDialog(
    context: context,
    builder: (context) => SetWinnerDialog(
      miniActivity: miniActivity,
      instanceId: instanceId,
      teamId: teamId,
      winnerTeamId: winnerTeamId,
    ),
  );
}

/// Show clear result confirmation dialog
void showClearResultDialog(
  BuildContext context, {
  required WidgetRef ref,
  required String miniActivityId,
  required String? instanceId,
  required String teamId,
}) {
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
                  miniActivityId: miniActivityId,
                  instanceId: instanceId,
                  teamId: teamId,
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

/// Show add team dialog
void showAddTeamDialog(
  BuildContext context, {
  required WidgetRef ref,
  required String miniActivityId,
  required String? instanceId,
  required String teamId,
}) {
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
                    miniActivityId: miniActivityId,
                    instanceId: instanceId,
                    teamId: teamId,
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
