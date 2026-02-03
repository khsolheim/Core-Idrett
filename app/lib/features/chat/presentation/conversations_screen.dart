import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/conversation.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/direct_message_provider.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  final String teamId;

  const ConversationsScreen({super.key, required this.teamId});

  @override
  ConsumerState<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meldinger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showNewConversationDialog(context),
            tooltip: 'Ny samtale',
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ingen samtaler enna',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start en ny samtale med en lagkamerat!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showNewConversationDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Ny samtale'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(conversationsProvider);
            },
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return _ConversationTile(
                  conversation: conversation,
                  onTap: () => context.push(
                    '/teams/${widget.teamId}/conversations/${conversation.recipientId}',
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Kunne ikke laste samtaler: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(conversationsProvider),
                child: const Text('Prov igjen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _NewConversationSheet(teamId: widget.teamId),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: conversation.recipientAvatarUrl != null
            ? NetworkImage(conversation.recipientAvatarUrl!)
            : null,
        child: conversation.recipientAvatarUrl == null
            ? Text(conversation.recipientName.isNotEmpty
                ? conversation.recipientName[0].toUpperCase()
                : '?')
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.recipientName,
              style: hasUnread
                  ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.titleMedium,
            ),
          ),
          if (conversation.lastMessageAt != null)
            Text(
              _formatTime(conversation.lastMessageAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              conversation.lastMessage ?? 'Ingen meldinger',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hasUnread
                  ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;

    if (isToday) {
      return DateFormat('HH:mm').format(time);
    }

    final isYesterday = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day - 1;

    if (isYesterday) {
      return 'I gar';
    }

    final isThisWeek = now.difference(time).inDays < 7;
    if (isThisWeek) {
      return DateFormat('EEEE', 'nb_NO').format(time);
    }

    return DateFormat('d. MMM', 'nb_NO').format(time);
  }
}

class _NewConversationSheet extends ConsumerWidget {
  final String teamId;

  const _NewConversationSheet({required this.teamId});

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
                    'Velg mottaker',
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
              child: membersAsync.when(
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
                          context.push(
                            '/teams/$teamId/conversations/${member.userId}',
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Kunne ikke laste lagmedlemmer: $error'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
