import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/conversation.dart';
import '../../../../data/models/message.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/unified_chat_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/direct_message_provider.dart';
import 'message_widgets.dart';

/// Empty state when no conversation is selected (wide layout only)
class EmptyChatPanel extends StatelessWidget {
  const EmptyChatPanel({super.key});

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
class ChatPanel extends ConsumerStatefulWidget {
  final String teamId;
  final ChatConversation conversation;
  final bool showBackButton;

  const ChatPanel({
    super.key,
    required this.teamId,
    required this.conversation,
    this.showBackButton = false,
  });

  @override
  ConsumerState<ChatPanel> createState() => ChatPanelState();
}

class ChatPanelState extends ConsumerState<ChatPanel> {
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
  void didUpdateWidget(ChatPanel oldWidget) {
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
          .read(directMessageNotifierProvider(widget.conversation.recipientId!)
              .notifier)
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
            .read(directMessageNotifierProvider(
                    widget.conversation.recipientId!)
                .notifier)
            .editMessage(_editingMessage!.id, content);
      } else {
        ref
            .read(directMessageNotifierProvider(
                    widget.conversation.recipientId!)
                .notifier)
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
    final currentUser = ref.watch(authStateProvider).value;

    final AsyncValue<List<Message>> messagesState;
    if (widget.conversation.isTeamChat) {
      messagesState = ref.watch(chatNotifierProvider(widget.teamId));
    } else {
      messagesState = ref.watch(
          directMessageNotifierProvider(widget.conversation.recipientId!));
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref.read(selectedConversationProvider.notifier).clear();
                },
              )
            : null,
        title: Row(
          children: [
            if (widget.conversation.isTeamChat)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.groups,
                    size: 20, color: theme.colorScheme.primary),
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
                ref
                    .read(chatNotifierProvider(widget.teamId).notifier)
                    .refresh();
              } else {
                ref
                    .read(directMessageNotifierProvider(
                            widget.conversation.recipientId!)
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
            child: messagesState.when2(
              onRetry: () {
                if (widget.conversation.isTeamChat) {
                  ref.invalidate(chatNotifierProvider(widget.teamId));
                } else {
                  ref.invalidate(directMessageNotifierProvider(
                      widget.conversation.recipientId!));
                }
              },
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
                        if (showDate)
                          DateDivider(date: message.createdAt),
                        MessageBubble(
                          message: message,
                          isOwn: isOwn,
                          onReply: () => _startReply(message),
                          onEdit: isOwn && !message.isDeleted
                              ? () => _startEdit(message)
                              : null,
                          onDelete: isOwn && !message.isDeleted
                              ? () => _showDeleteConfirmation(message)
                              : null,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Reply/Edit indicator
          if (_replyingTo != null || _editingMessage != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        content: const Text(
            'Er du sikker pa at du vil slette denne meldingen?'),
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
                    .read(directMessageNotifierProvider(
                            widget.conversation.recipientId!)
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
