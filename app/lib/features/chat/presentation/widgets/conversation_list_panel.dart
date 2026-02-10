import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/conversation.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../providers/unified_chat_provider.dart';
import 'message_widgets.dart';

/// Panel showing the list of conversations
class ConversationListPanel extends ConsumerStatefulWidget {
  final String teamId;
  final bool showAppBar;

  const ConversationListPanel({
    super.key,
    required this.teamId,
    this.showAppBar = false,
  });

  @override
  ConsumerState<ConversationListPanel> createState() =>
      ConversationListPanelState();
}

class ConversationListPanelState extends ConsumerState<ConversationListPanel> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync =
        ref.watch(filteredConversationsProvider(widget.teamId));

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Sok...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        ref
                            .read(conversationSearchQueryProvider.notifier)
                            .setQuery(value);
                      },
                    )
                  : const Text('Meldinger'),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ref
                            .read(conversationSearchQueryProvider.notifier)
                            .clear();
                      }
                    });
                  },
                ),
              ],
            )
          : null,
      body: Column(
        children: [
          if (!widget.showAppBar)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Sok...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                ),
                onChanged: (value) {
                  ref
                      .read(conversationSearchQueryProvider.notifier)
                      .setQuery(value);
                },
              ),
            ),
          Expanded(
            child: conversationsAsync.when2(
              onRetry: () =>
                  ref.invalidate(allConversationsProvider(widget.teamId)),
              data: (conversations) {
                if (conversations.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.forum_outlined,
                    title: 'Ingen samtaler',
                    subtitle: 'Start en ny samtale',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        allConversationsProvider(widget.teamId));
                  },
                  child: ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final selected =
                          ref.watch(selectedConversationProvider);
                      final isSelected =
                          selected?.id == conversation.id;

                      return ConversationTile(
                        key: ValueKey(conversation.id),
                        conversation: conversation,
                        isSelected: isSelected,
                        onTap: () {
                          ref
                              .read(selectedConversationProvider
                                  .notifier)
                              .select(conversation);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversationSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showNewConversationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => NewConversationSheet(teamId: widget.teamId),
    );
  }
}

/// Tile for a single conversation in the list
class ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;

    return ListTile(
      selected: isSelected,
      leading: CircleAvatar(
        backgroundImage: conversation.avatarUrl != null
            ? CachedNetworkImageProvider(conversation.avatarUrl!)
            : null,
        child: conversation.avatarUrl == null
            ? Icon(
                conversation.isTeamChat ? Icons.groups : Icons.person,
                size: 24,
              )
            : null,
      ),
      title: Row(
        children: [
          if (conversation.isTeamChat)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.groups,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
          Expanded(
            child: Text(
              conversation.name,
              style: hasUnread
                  ? theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
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
                  ? theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500)
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
            ),
          ),
          if (hasUnread)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;

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
