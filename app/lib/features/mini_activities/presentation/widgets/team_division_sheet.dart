import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../core/services/error_display_service.dart';
import '../../../../data/models/activity.dart';
import '../../../../data/models/mini_activity.dart';
import '../../../activities/providers/activity_provider.dart';
import '../../../teams/providers/team_provider.dart';
import '../../providers/mini_activity_provider.dart';

class TeamDivisionSheet extends ConsumerStatefulWidget {
  final String miniActivityId;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId;

  const TeamDivisionSheet({
    super.key,
    required this.miniActivityId,
    this.instanceId,
    required this.teamId,
  });

  @override
  ConsumerState<TeamDivisionSheet> createState() => TeamDivisionSheetState();
}

class TeamDivisionSheetState extends ConsumerState<TeamDivisionSheet> {
  DivisionMethod _method = DivisionMethod.random;
  int _numberOfTeams = 2;
  bool _isLoading = false;
  final Set<String> _selectedMemberIds = {}; // For standalone activities

  List<String> _getParticipantIds(ActivityInstance instance) {
    if (instance.responses == null) return [];
    return instance.responses!
        .where((r) => r.response == UserResponse.yes)
        .map((r) => r.userId)
        .toList();
  }

  Future<void> _divide(List<String> participantIds) async {
    if (participantIds.isEmpty) {
      final message = widget.instanceId != null
          ? 'Ingen deltakere har svart "Ja"'
          : 'Velg minst en deltaker';
      ErrorDisplayService.showWarning(message);
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref.read(teamDivisionProvider.notifier).divideTeams(
          miniActivityId: widget.miniActivityId,
          instanceId: widget.instanceId,
          method: _method,
          numberOfTeams: _numberOfTeams,
          participantUserIds: participantIds,
          teamId: widget.teamId,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result != null) {
        Navigator.pop(context);
      } else {
        ErrorDisplayService.showWarning('Kunne ikke dele inn lag. Prøv igjen.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // For standalone activities (no instanceId), fetch team members
    if (widget.instanceId == null) {
      return _buildStandaloneContent(context);
    }

    // For instance-based activities, fetch from instance responses
    final instanceAsync = ref.watch(instanceDetailProvider(widget.instanceId!));

    return instanceAsync.when2(
      onRetry: () => ref.invalidate(instanceDetailProvider(widget.instanceId!)),
      data: (instance) {
        final participantIds = _getParticipantIds(instance);
        final yesResponses = instance.responses
                ?.where((r) => r.response == UserResponse.yes)
                .toList() ??
            [];

        return _buildSheetContent(
          context: context,
          participantIds: participantIds,
          participantCount: yesResponses.length,
          participantLabel: '${yesResponses.length} deltakere har svart "Ja"',
          participantChips: yesResponses.map((r) {
            return Chip(
              avatar: CircleAvatar(
                backgroundImage: r.userAvatarUrl != null
                    ? CachedNetworkImageProvider(r.userAvatarUrl!)
                    : null,
                child: r.userAvatarUrl == null
                    ? Text(
                        r.userName?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              label: Text(r.userName ?? 'Ukjent'),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildStandaloneContent(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));

    return membersAsync.when2(
      onRetry: () => ref.invalidate(teamMembersProvider(widget.teamId)),
      data: (members) {
        return _buildSheetContent(
          context: context,
          participantIds: _selectedMemberIds.toList(),
          participantCount: _selectedMemberIds.length,
          participantLabel: '${_selectedMemberIds.length} av ${members.length} valgt',
          memberSelectionWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Velg deltakere',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (_selectedMemberIds.length == members.length) {
                          _selectedMemberIds.clear();
                        } else {
                          _selectedMemberIds.addAll(members.map((m) => m.userId));
                        }
                      });
                    },
                    child: Text(_selectedMemberIds.length == members.length
                        ? 'Velg ingen'
                        : 'Velg alle'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: members.map((member) {
                  final isSelected = _selectedMemberIds.contains(member.userId);
                  return FilterChip(
                    selected: isSelected,
                    avatar: CircleAvatar(
                      backgroundImage: member.userAvatarUrl != null
                          ? CachedNetworkImageProvider(member.userAvatarUrl!)
                          : null,
                      child: member.userAvatarUrl == null
                          ? Text(
                              member.userName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                    label: Text(member.userName),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedMemberIds.add(member.userId);
                        } else {
                          _selectedMemberIds.remove(member.userId);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetContent({
    required BuildContext context,
    required List<String> participantIds,
    required int participantCount,
    required String participantLabel,
    List<Widget>? participantChips,
    Widget? memberSelectionWidget,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Padding(
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
              'Del inn lag',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Member selection for standalone activities
                    if (memberSelectionWidget != null) ...[
                      memberSelectionWidget,
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Metode',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...DivisionMethod.values.map((method) {
                      return RadioListTile<DivisionMethod>(
                        value: method,
                        groupValue: _method,
                        onChanged: (value) {
                          if (value != null) setState(() => _method = value);
                        },
                        title: Text(method.displayName),
                        subtitle: Text(method.description),
                      );
                    }),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Antall lag:'),
                        const Spacer(),
                        IconButton(
                          onPressed: _numberOfTeams > 2
                              ? () => setState(() => _numberOfTeams--)
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        Text(
                          '$_numberOfTeams',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: () => setState(() => _numberOfTeams++),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      participantLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    if (participantChips != null && participantChips.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: participantChips,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isLoading ? null : () => _divide(participantIds),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Del inn'),
            ),
          ],
        ),
      ),
    );
  }
}
