import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/mini_activity.dart';
import '../../../teams/providers/team_provider.dart';
import '../../providers/mini_activity_provider.dart';

class AddParticipantSheet extends ConsumerWidget {
  final MiniActivity miniActivity;
  final String? instanceId; // Nullable for standalone mini-activities
  final String teamId;
  final String targetTeamId;

  const AddParticipantSheet({
    super.key,
    required this.miniActivity,
    this.instanceId,
    required this.teamId,
    required this.targetTeamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));

    // Get existing participant user IDs
    final existingUserIds = <String>{};
    for (final team in miniActivity.teams ?? []) {
      for (final p in team.participants ?? []) {
        existingUserIds.add(p.userId);
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legg til spiller',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: membersAsync.when2(
                onRetry: () => ref.invalidate(teamMembersProvider(teamId)),
                data: (members) {
                  final availableMembers = members
                      .where((m) => !existingUserIds.contains(m.userId))
                      .toList();

                  if (availableMembers.isEmpty) {
                    return const Center(
                      child: Text('Alle lagmedlemmer er allerede med'),
                    );
                  }

                  return ListView.builder(
                    itemCount: availableMembers.length,
                    itemBuilder: (context, index) {
                      final member = availableMembers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: member.userAvatarUrl != null
                              ? CachedNetworkImageProvider(member.userAvatarUrl!)
                              : null,
                          child: member.userAvatarUrl == null
                              ? Text(member.userName.substring(0, 1).toUpperCase())
                              : null,
                        ),
                        title: Text(member.userName),
                        onTap: () async {
                          Navigator.pop(context);
                          await ref.read(miniActivityOperationsProvider.notifier).addLateParticipant(
                                miniActivityId: miniActivity.id,
                                instanceId: instanceId,
                                teamId: teamId,
                                userId: member.userId,
                                miniTeamId: targetTeamId,
                              );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
