import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';
import 'add_participant_sheet.dart';
import 'mini_activity_helpers.dart';
import '../../../../core/services/error_display_service.dart';

void showRenameTeamDialog({
  required BuildContext context,
  required WidgetRef ref,
  required MiniActivityTeam team,
  required MiniActivity miniActivity,
  required String? instanceId,
  required String teamId,
}) {
  final controller = TextEditingController(text: team.name);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Endre lagnavn'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Lagnavn'),
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
              await ref.read(miniActivityOperationsProvider.notifier).updateTeamName(
                    miniActivityId: miniActivity.id,
                    instanceId: instanceId,
                    teamId: teamId,
                    miniTeamId: team.id,
                    name: controller.text,
                  );
            }
          },
          child: const Text('Lagre'),
        ),
      ],
    ),
  );
}

void showDeleteTeamDialog({
  required BuildContext context,
  required WidgetRef ref,
  required MiniActivityTeam team,
  required MiniActivity miniActivity,
  required String? instanceId,
  required String teamId,
}) {
  final hasParticipants = team.participants?.isNotEmpty ?? false;
  final otherTeams = miniActivity.teams?.where((t) => t.id != team.id).toList() ?? [];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Slett lag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Er du sikker pa at du vil slette "${team.name}"?'),
          if (hasParticipants) ...[
            const SizedBox(height: 12),
            Text(
              'Laget har ${team.participants!.length} spiller(e). Spillerne vil bli fjernet fra aktiviteten.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
        if (hasParticipants && otherTeams.isNotEmpty)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showMoveAllParticipantsDialog(
                context: context,
                ref: ref,
                team: team,
                miniActivity: miniActivity,
                instanceId: instanceId,
                teamId: teamId,
                otherTeams: otherTeams,
              );
            },
            child: const Text('Flytt spillere'),
          ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(teamManagementProvider.notifier).deleteTeam(
                  miniActivityId: miniActivity.id,
                  instanceId: instanceId,
                  teamId: teamId,
                  miniTeamId: team.id,
                );
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Slett'),
        ),
      ],
    ),
  );
}

void showMoveAllParticipantsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required MiniActivityTeam team,
  required MiniActivity miniActivity,
  required String? instanceId,
  required String teamId,
  required List<MiniActivityTeam> otherTeams,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Flytt spillere'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Velg lag a flytte spillerne til:'),
          const SizedBox(height: 16),
          ...otherTeams.map((t) => ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: getTeamColor(t.name),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(t.name ?? 'Lag'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(teamManagementProvider.notifier).deleteTeam(
                        miniActivityId: miniActivity.id,
                        instanceId: instanceId,
                        teamId: teamId,
                        miniTeamId: team.id,
                        moveParticipantsToTeamId: t.id,
                      );
                },
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
      ],
    ),
  );
}

void showMoveParticipantDialog({
  required BuildContext context,
  required WidgetRef ref,
  required MiniActivityTeam team,
  required MiniActivity miniActivity,
  required String? instanceId,
  required String teamId,
  required MiniActivityParticipant participant,
}) {
  final otherTeams = miniActivity.teams?.where((t) => t.id != team.id).toList() ?? [];

  if (otherTeams.isEmpty) {
    ErrorDisplayService.showSuccess('Ingen andre lag a flytte til');
    return;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Flytt ${participant.userName ?? "spiller"}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Velg lag a flytte spilleren til:'),
          const SizedBox(height: 16),
          ...otherTeams.map((t) => ListTile(
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: getTeamColor(t.name),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(t.name ?? 'Lag'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(teamManagementProvider.notifier).moveParticipant(
                        miniActivityId: miniActivity.id,
                        instanceId: instanceId,
                        teamId: teamId,
                        participantId: participant.id,
                        targetTeamId: t.id,
                      );
                },
              )),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Avbryt'),
        ),
      ],
    ),
  );
}

void showAddParticipantSheet({
  required BuildContext context,
  required MiniActivity miniActivity,
  required String? instanceId,
  required String teamId,
  required String targetTeamId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => AddParticipantSheet(
      miniActivity: miniActivity,
      instanceId: instanceId,
      teamId: teamId,
      targetTeamId: targetTeamId,
    ),
  );
}
