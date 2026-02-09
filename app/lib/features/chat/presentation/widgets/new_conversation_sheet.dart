import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/conversation.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../teams/providers/team_provider.dart';
import '../../providers/unified_chat_provider.dart';

/// Sheet for starting a new conversation
class NewConversationSheet extends ConsumerWidget {
  final String teamId;

  const NewConversationSheet({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final currentUserId = ref.watch(
      authStateProvider.select((a) => a.value?.id),
    );
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Ny samtale',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: membersAsync.when2(
                onRetry: () =>
                    ref.invalidate(teamMembersProvider(teamId)),
                data: (members) {
                  // Filter out current user
                  final otherMembers = members
                      .where((m) => m.userId != currentUserId)
                      .toList();

                  if (otherMembers.isEmpty) {
                    return const EmptyStateWidget(
                      icon: Icons.group_outlined,
                      title: 'Ingen medlemmer',
                      subtitle: 'Ingen medlemmer å vise',
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: otherMembers.length,
                    itemBuilder: (context, index) {
                      final member = otherMembers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: member.userAvatarUrl != null
                              ? CachedNetworkImageProvider(member.userAvatarUrl!)
                              : null,
                          child: member.userAvatarUrl == null
                              ? Text(member.userName.isNotEmpty
                                  ? member.userName[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(member.userName),
                        subtitle: Text(member.roleDisplayName),
                        onTap: () {
                          Navigator.pop(context);
                          // Create a direct message conversation and select it
                          final conversation = ChatConversation(
                            type: ConversationType.direct,
                            recipientId: member.userId,
                            name: member.userName,
                            avatarUrl: member.userAvatarUrl,
                            unreadCount: 0,
                          );
                          ref
                              .read(
                                  selectedConversationProvider.notifier)
                              .select(conversation);
                          // Refresh conversations list
                          ref.invalidate(
                              allConversationsProvider(teamId));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
