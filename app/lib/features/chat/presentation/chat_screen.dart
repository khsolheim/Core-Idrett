import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/message.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import 'widgets/message_widgets.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String teamId;

  const ChatScreen({super.key, required this.teamId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Message? _replyingTo;
  Message? _editingMessage;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatNotifierProvider(widget.teamId).notifier).markAsRead();
    });
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

    if (_editingMessage != null) {
      ref.read(chatNotifierProvider(widget.teamId).notifier).editMessage(
            _editingMessage!.id,
            content,
          );
      setState(() {
        _editingMessage = null;
      });
    } else {
      ref.read(chatNotifierProvider(widget.teamId).notifier).sendMessage(
            content,
            replyToId: _replyingTo?.id,
          );
      setState(() {
        _replyingTo = null;
      });
    }

    _messageController.clear();
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
    final chatState = ref.watch(chatNotifierProvider(widget.teamId));
    final currentUserId = ref.watch(
      authStateProvider.select((a) => a.value?.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lag-chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/teams/${widget.teamId}/conversations'),
            tooltip: 'Direktemeldinger',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(chatNotifierProvider(widget.teamId).notifier).refresh(),
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when2(
              onRetry: () => ref
                  .read(chatNotifierProvider(widget.teamId).notifier)
                  .refresh(),
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.chat_bubble_outline,
                    title: 'Ingen meldinger enna',
                    subtitle: 'Vær den forste til a skrive!',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwn = message.userId == currentUserId;
                    final showDate = index == messages.length - 1 ||
                        !isSameDay(
                          message.createdAt,
                          messages[index + 1].createdAt,
                        );

                    return Column(
                      children: [
                        if (showDate) DateDivider(date: message.createdAt),
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
            ReplyEditIndicator(
              replyingTo: _replyingTo,
              editingMessage: _editingMessage,
              onCancel: _cancelReplyOrEdit,
            ),
          // Message input
          MessageInputBar(
            controller: _messageController,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Message message) {
    showDeleteMessageDialog(
      context,
      onConfirm: () {
        ref
            .read(chatNotifierProvider(widget.teamId).notifier)
            .deleteMessage(message.id);
      },
    );
  }
}
