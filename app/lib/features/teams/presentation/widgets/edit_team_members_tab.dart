import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/team.dart';
import '../../providers/team_provider.dart';

class EditTeamMembersTab extends ConsumerStatefulWidget {
  final String teamId;

  const EditTeamMembersTab({super.key, required this.teamId});

  @override
  ConsumerState<EditTeamMembersTab> createState() =>
      _EditTeamMembersTabState();
}

class _EditTeamMembersTabState extends ConsumerState<EditTeamMembersTab> {
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final membersProvider = _showInactive
        ? teamMembersWithInactiveProvider(widget.teamId)
        : teamMembersProvider(widget.teamId);

    final membersAsync = ref.watch(membersProvider);
    final trainerTypesAsync = ref.watch(trainerTypesProvider(widget.teamId));

    return Column(
      children: [
        // Filter toggle
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Medlemmer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Vis inaktive'),
                selected: _showInactive,
                onSelected: (value) => setState(() => _showInactive = value),
              ),
            ],
          ),
        ),

        Expanded(
          child: membersAsync.when2(
            onRetry: () => ref.invalidate(membersProvider),
            data: (members) {
              if (members.isEmpty) {
                return const Center(child: Text('Ingen medlemmer'));
              }

              return trainerTypesAsync.when2(
                onRetry: () =>
                    ref.invalidate(trainerTypesProvider(widget.teamId)),
                error: (error, retry) => ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) =>
                      _MemberTile(
                        member: members[index],
                        trainerTypes: const [],
                        teamId: widget.teamId,
                      ),
                ),
                data: (trainerTypes) => ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) =>
                      _MemberTile(
                        member: members[index],
                        trainerTypes: trainerTypes,
                        teamId: widget.teamId,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final TeamMember member;
  final List<TrainerType> trainerTypes;
  final String teamId;

  const _MemberTile({
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
                ? NetworkImage(member.userAvatarUrl!)
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
                          onPressed: () => _deactivateMember(ref, context),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          'Fjern',
                          style: TextStyle(color: Colors.red),
                        ),
                        onPressed: () => _removeMember(ref, context),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunne ikke oppdatere tilganger'),
          backgroundColor: Colors.red,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? (isInjured
                    ? '${member.userName} markert som skadet'
                    : '${member.userName} markert som frisk')
                : 'Kunne ikke oppdatere skadet-status',
          ),
          backgroundColor: success ? null : Colors.red,
        ),
      );
    }
  }

  Future<void> _deactivateMember(WidgetRef ref, BuildContext context) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Medlem deaktivert' : 'Kunne ikke deaktivere medlem',
            ),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reactivateMember(WidgetRef ref, BuildContext context) async {
    final notifier = ref.read(teamNotifierProvider.notifier);
    final success = await notifier.reactivateMember(teamId, member.id);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Medlem reaktivert' : 'Kunne ikke reaktivere medlem',
          ),
          backgroundColor: success ? null : Colors.red,
        ),
      );
    }
  }

  Future<void> _removeMember(WidgetRef ref, BuildContext context) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Medlem fjernet' : 'Kunne ikke fjerne medlem',
            ),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }
}
