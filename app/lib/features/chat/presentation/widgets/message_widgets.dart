import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/conversation.dart';
import '../../../../data/models/message.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../teams/providers/team_provider.dart';
import '../../providers/unified_chat_provider.dart';

/// Date divider between messages
class DateDivider extends StatelessWidget {
  final DateTime date;

  const DateDivider({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final isYesterday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1;

    String text;
    if (isToday) {
      text = 'I dag';
    } else if (isYesterday) {
      text = 'I gar';
    } else {
      text = DateFormat('EEEE d. MMMM', 'nb_NO').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: theme.colorScheme.outline)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(child: Divider(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}

/// Message bubble widget
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isOwn)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    message.userName ?? 'Ukjent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              if (message.replyTo != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyTo!.userName ?? 'Ukjent',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        message.replyTo!.displayContent,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isOwn
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.displayContent,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            message.isDeleted ? theme.colorScheme.outline : null,
                        fontStyle:
                            message.isDeleted ? FontStyle.italic : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeFormat.format(message.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontSize: 11,
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '(redigert)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Svar'),
              onTap: () {
                Navigator.pop(context);
                onReply();
              },
            ),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rediger'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Slett', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Sheet for starting a new conversation
class NewConversationSheet extends ConsumerWidget {
  final String teamId;

  const NewConversationSheet({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final currentUser = ref.watch(authStateProvider).value;
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
                      .where((m) => m.userId != currentUser?.id)
                      .toList();

                  if (otherMembers.isEmpty) {
                    return Center(
                      child: Text(
                        'Ingen lagkamerater a sende melding til',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
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
                              ? NetworkImage(member.userAvatarUrl!)
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
