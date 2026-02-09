import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/error_display_service.dart';
import '../../../../data/models/team.dart';
import '../../providers/team_provider.dart';
import 'member_action_dialogs.dart';

/// Tile displaying team member information with expandable options
class MemberTile extends ConsumerWidget {
  final TeamMember member;
  final List<TrainerType> trainerTypes;
  final String teamId;

  const MemberTile({
    super.key,
    required this.member,
    required this.trainerTypes,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInactive = !member.isActive;

    return Opacity(
      opacity: isInactive ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundImage: member.userAvatarUrl != null
                ? CachedNetworkImageProvider(member.userAvatarUrl!)
                : null,
            child: member.userAvatarUrl == null
                ? Text(member.userName[0].toUpperCase())
                : null,
          ),
          title: Row(
            children: [
              Expanded(child: Text(member.userName)),
              if (member.isInjured) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Skadet',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
              if (isInactive) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Inaktiv',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(member.roleDisplayName),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin toggle
                  SwitchListTile(
                    title: const Text('Administrator'),
                    subtitle: const Text('Kan administrere laget'),
                    value: member.isAdmin,
                    onChanged: (value) => _updateMemberPermissions(
                      ref,
                      context,
                      isAdmin: value,
                    ),
                  ),

                  // Fine boss toggle
                  SwitchListTile(
                    title: const Text('Botesjef'),
                    subtitle: const Text('Kan godkjenne boter'),
                    value: member.isFineBoss,
                    onChanged: (value) => _updateMemberPermissions(
                      ref,
                      context,
                      isFineBoss: value,
                    ),
                  ),

                  const Divider(),

                  // Injured status toggle
                  SwitchListTile(
                    title: const Text('Skadet'),
                    subtitle:
                        const Text('Ekskluderes fra automatisk pamelding'),
                    value: member.isInjured,
                    activeTrackColor: Colors.orange.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.orange;
                      }
                      return null;
                    }),
                    onChanged: (value) =>
                        _setMemberInjuredStatus(ref, context, value),
                  ),

                  const Divider(),

                  // Trainer type dropdown
                  ListTile(
                    title: const Text('Trenerrolle'),
                    trailing: DropdownButton<String?>(
                      value: member.trainerType?.id,
                      hint: const Text('Ingen'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Ingen'),
                        ),
                        ...trainerTypes.map((tt) => DropdownMenuItem(
                              value: tt.id,
                              child: Text(tt.name),
                            )),
                      ],
                      onChanged: (value) => _updateMemberPermissions(
                        ref,
                        context,
                        trainerTypeId: value,
                        clearTrainerType: value == null,
                      ),
                    ),
                  ),

                  const Divider(),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isInactive)
                        TextButton.icon(
                          icon: const Icon(Icons.restore),
                          label: const Text('Reaktiver'),
                          onPressed: () => _reactivateMember(ref, context),
                        )
                      else
                        TextButton.icon(
                          icon: const Icon(Icons.person_off),
                          label: const Text('Deaktiver'),
                          onPressed: () =>
                              showDeactivateMemberDialog(context, ref, teamId, member),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Fjern',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () =>
                            showRemoveMemberDialog(context, ref, teamId, member),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateMemberPermissions(
    WidgetRef ref,
    BuildContext context, {
    bool? isAdmin,
    bool? isFineBoss,
    String? trainerTypeId,
    bool clearTrainerType = false,
  }) async {
    final notifier = ref.read(teamNotifierProvider.notifier);
    final success = await notifier.updateMemberPermissions(
      teamId: teamId,
      memberId: member.id,
      isAdmin: isAdmin,
      isFineBoss: isFineBoss,
      trainerTypeId: trainerTypeId,
      clearTrainerType: clearTrainerType,
    );

    if (!success && context.mounted) {
      ErrorDisplayService.showWarning('Kunne ikke oppdatere tilganger');
    }
  }

  Future<void> _setMemberInjuredStatus(
    WidgetRef ref,
    BuildContext context,
    bool isInjured,
  ) async {
    final notifier = ref.read(teamNotifierProvider.notifier);
    final success = await notifier.setInjuredStatus(
      teamId,
      member.id,
      isInjured,
    );

    if (context.mounted) {
      if (success) {
        final message = isInjured
            ? '${member.userName} markert som skadet'
            : '${member.userName} markert som frisk';
        ErrorDisplayService.showSuccess(message);
      } else {
        ErrorDisplayService.showWarning('Kunne ikke oppdatere skadet-status');
      }
    }
  }

  Future<void> _reactivateMember(WidgetRef ref, BuildContext context) async {
    final notifier = ref.read(teamNotifierProvider.notifier);
    final success = await notifier.reactivateMember(teamId, member.id);

    if (context.mounted) {
      if (success) {
        ErrorDisplayService.showSuccess('Medlem reaktivert');
      } else {
        ErrorDisplayService.showWarning('Kunne ikke reaktivere medlem');
      }
    }
  }
}
