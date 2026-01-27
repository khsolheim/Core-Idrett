import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/conversation.dart';
import '../../../data/models/message.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/unified_chat_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/direct_message_provider.dart';

class UnifiedChatScreen extends ConsumerStatefulWidget {
  final String teamId;

  const UnifiedChatScreen({super.key, required this.teamId});

  @override
  ConsumerState<UnifiedChatScreen> createState() => _UnifiedChatScreenState();
}

class _UnifiedChatScreenState extends ConsumerState<UnifiedChatScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return _WideLayout(teamId: widget.teamId);
        } else {
          return _NarrowLayout(teamId: widget.teamId);
        }
      },
    );
  }
}

/// Wide layout with split view (conversation list + chat panel)
class _WideLayout extends ConsumerWidget {
  final String teamId;

  const _WideLayout({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedConversationProvider);

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: _ConversationListPanel(teamId: teamId),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selected != null
                ? _ChatPanel(teamId: teamId, conversation: selected)
                : _EmptyChatPanel(),
          ),
        ],
      ),
    );
  }
}

/// Narrow layout with navigation between list and chat
class _NarrowLayout extends ConsumerWidget {
  final String teamId;

  const _NarrowLayout({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedConversationProvider);

    if (selected == null) {
      return _ConversationListPanel(teamId: teamId, showAppBar: true);
    } else {
      return _ChatPanel(
        teamId: teamId,
        conversation: selected,
        showBackButton: true,
      );
    }
  }
}

/// Panel showing the list of conversations
class _ConversationListPanel extends ConsumerStatefulWidget {
  final String teamId;
  final bool showAppBar;

  const _ConversationListPanel({
    required this.teamId,
    this.showAppBar = false,
  });

  @override
  ConsumerState<_ConversationListPanel> createState() => _ConversationListPanelState();
}

class _ConversationListPanelState extends ConsumerState<_ConversationListPanel> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(filteredConversationsProvider(widget.teamId));
    final theme = Theme.of(context);

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
                        ref.read(conversationSearchQueryProvider.notifier).state = value;
                      },
                    )
                  : const Text('Chat'),
              actions: [
                IconButton(
                  icon: Icon(_isSearching ? Icons.close : Icons.search),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        ref.read(conversationSearchQueryProvider.notifier).state = '';
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  isDense: true,
                ),
                onChanged: (value) {
                  ref.read(conversationSearchQueryProvider.notifier).state = value;
                },
              ),
            ),
          Expanded(
            child: conversationsAsync.when(
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
                          'Ingen samtaler',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(allConversationsProvider(widget.teamId));
                  },
                  child: ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final selected = ref.watch(selectedConversationProvider);
                      final isSelected = selected?.id == conversation.id;

                      return _ConversationTile(
                        conversation: conversation,
                        isSelected: isSelected,
                        onTap: () {
                          ref.read(selectedConversationProvider.notifier).state =
                              conversation;
                        },
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
                    Text('Kunne ikke laste samtaler'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(allConversationsProvider(widget.teamId)),
                      child: const Text('Prov igjen'),
                    ),
                  ],
                ),
              ),
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
      builder: (context) => _NewConversationSheet(teamId: widget.teamId),
    );
  }
}

/// Tile for a single conversation in the list
class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConversationTile({
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
            ? NetworkImage(conversation.avatarUrl!)
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
                  ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
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

/// Empty state when no conversation is selected (wide layout only)
class _EmptyChatPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Velg en samtale',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Velg en samtale fra listen til venstre',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chat panel that shows messages for the selected conversation
class _ChatPanel extends ConsumerStatefulWidget {
  final String teamId;
  final ChatConversation conversation;
  final bool showBackButton;

  const _ChatPanel({
    required this.teamId,
    required this.conversation,
    this.showBackButton = false,
  });

  @override
  ConsumerState<_ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<_ChatPanel> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Message? _replyingTo;
  Message? _editingMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAsRead();
    });
  }

  @override
  void didUpdateWidget(_ChatPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _cancelReplyOrEdit();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _markAsRead();
      });
    }
  }

  void _markAsRead() {
    if (widget.conversation.isTeamChat) {
      ref.read(chatNotifierProvider(widget.teamId).notifier).markAsRead();
    } else {
      ref
          .read(directMessageNotifierProvider(widget.conversation.recipientId!).notifier)
          .markAsRead();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (widget.conversation.isTeamChat) {
      if (_editingMessage != null) {
        ref.read(chatNotifierProvider(widget.teamId).notifier).editMessage(
              _editingMessage!.id,
              content,
            );
      } else {
        ref.read(chatNotifierProvider(widget.teamId).notifier).sendMessage(
              content,
              replyToId: _replyingTo?.id,
            );
      }
    } else {
      if (_editingMessage != null) {
        ref
            .read(directMessageNotifierProvider(widget.conversation.recipientId!).notifier)
            .editMessage(_editingMessage!.id, content);
      } else {
        ref
            .read(directMessageNotifierProvider(widget.conversation.recipientId!).notifier)
            .sendMessage(content, replyToId: _replyingTo?.id);
      }
    }

    setState(() {
      _replyingTo = null;
      _editingMessage = null;
    });
    _messageController.clear();

    // Refresh conversations to update last message
    ref.invalidate(allConversationsProvider(widget.teamId));
  }

  void _startReply(Message message) {
    setState(() {
      _replyingTo = message;
      _editingMessage = null;
    });
  }

  void _startEdit(Message message) {
    setState(() {
      _editingMessage = message;
      _replyingTo = null;
      _messageController.text = message.content;
    });
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyingTo = null;
      _editingMessage = null;
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = ref.watch(authStateProvider).valueOrNull;

    final AsyncValue<List<Message>> messagesState;
    if (widget.conversation.isTeamChat) {
      messagesState = ref.watch(chatNotifierProvider(widget.teamId));
    } else {
      messagesState =
          ref.watch(directMessageNotifierProvider(widget.conversation.recipientId!));
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedConversationProvider.notifier).state = null;
                },
              )
            : null,
        title: Row(
          children: [
            if (widget.conversation.isTeamChat)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.groups, size: 20, color: theme.colorScheme.primary),
              ),
            Expanded(
              child: Text(
                widget.conversation.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (widget.conversation.isTeamChat) {
                ref.read(chatNotifierProvider(widget.teamId).notifier).refresh();
              } else {
                ref
                    .read(directMessageNotifierProvider(widget.conversation.recipientId!)
                        .notifier)
                    .refresh();
              }
            },
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesState.when(
              data: (messages) {
                if (messages.isEmpty) {
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
                          'Ingen meldinger enna',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vær den forste til a skrive!',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwn = message.userId == currentUser?.id;
                    final showDate = index == messages.length - 1 ||
                        !_isSameDay(
                          message.createdAt,
                          messages[index + 1].createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate) _DateDivider(date: message.createdAt),
                        _MessageBubble(
                          message: message,
                          isOwn: isOwn,
                          onReply: () => _startReply(message),
                          onEdit:
                              isOwn && !message.isDeleted ? () => _startEdit(message) : null,
                          onDelete: isOwn && !message.isDeleted
                              ? () => _showDeleteConfirmation(message)
                              : null,
                        ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text('Kunne ikke laste meldinger'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (widget.conversation.isTeamChat) {
                          ref.read(chatNotifierProvider(widget.teamId).notifier).refresh();
                        } else {
                          ref
                              .read(directMessageNotifierProvider(
                                      widget.conversation.recipientId!)
                                  .notifier)
                              .refresh();
                        }
                      },
                      child: const Text('Prov igjen'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Reply/Edit indicator
          if (_replyingTo != null || _editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    _editingMessage != null ? Icons.edit : Icons.reply,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _editingMessage != null
                          ? 'Redigerer melding'
                          : 'Svarer ${_replyingTo!.userName ?? 'ukjent'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _cancelReplyOrEdit,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Skriv en melding...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showDeleteConfirmation(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett melding'),
        content: const Text('Er du sikker pa at du vil slette denne meldingen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.conversation.isTeamChat) {
                ref
                    .read(chatNotifierProvider(widget.teamId).notifier)
                    .deleteMessage(message.id);
              } else {
                ref
                    .read(directMessageNotifierProvider(widget.conversation.recipientId!)
                        .notifier)
                    .deleteMessage(message.id);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}

/// Date divider between messages
class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

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
class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _MessageBubble({
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        color: message.isDeleted ? theme.colorScheme.outline : null,
                        fontStyle: message.isDeleted ? FontStyle.italic : null,
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
                title: const Text('Slett', style: TextStyle(color: Colors.red)),
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
class _NewConversationSheet extends ConsumerWidget {
  final String teamId;

  const _NewConversationSheet({required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final currentUser = ref.watch(authStateProvider).valueOrNull;
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
              child: membersAsync.when(
                data: (members) {
                  // Filter out current user
                  final otherMembers =
                      members.where((m) => m.userId != currentUser?.id).toList();

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
                          ref.read(selectedConversationProvider.notifier).state =
                              conversation;
                          // Refresh conversations list
                          ref.invalidate(allConversationsProvider(teamId));
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Kunne ikke laste lagmedlemmer'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
