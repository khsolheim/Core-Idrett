import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../providers/team_provider.dart';
import 'member_tile.dart';

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
                      MemberTile(
                        member: members[index],
                        trainerTypes: const [],
                        teamId: widget.teamId,
                      ),
                ),
                data: (trainerTypes) => ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) =>
                      MemberTile(
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
