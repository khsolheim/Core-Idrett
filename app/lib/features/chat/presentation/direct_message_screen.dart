import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/message.dart';
import '../../../shared/widgets/widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/direct_message_provider.dart';
import 'widgets/message_widgets.dart';

class DirectMessageScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String recipientId;

  const DirectMessageScreen({
    super.key,
    required this.teamId,
    required this.recipientId,
  });

  @override
  ConsumerState<DirectMessageScreen> createState() => _DirectMessageScreenState();
}

class _DirectMessageScreenState extends ConsumerState<DirectMessageScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  Message? _replyingTo;
  Message? _editingMessage;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(directMessageNotifierProvider(widget.recipientId).notifier).markAsRead();
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
      ref.read(directMessageNotifierProvider(widget.recipientId).notifier).editMessage(
            _editingMessage!.id,
            content,
          );
      setState(() {
        _editingMessage = null;
      });
    } else {
      ref.read(directMessageNotifierProvider(widget.recipientId).notifier).sendMessage(
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
    final chatState = ref.watch(directMessageNotifierProvider(widget.recipientId));
    final currentUserId = ref.watch(
      authStateProvider.select((a) => a.value?.id),
    );
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));

    // Get recipient name from team members
    final recipientName = membersAsync.when(
      data: (members) {
        final recipient = members.where((m) => m.userId == widget.recipientId).firstOrNull;
        return recipient?.userName ?? 'Ukjent';
      },
      loading: () => 'Laster...',
      error: (error, stackTrace) => 'Ukjent',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(recipientName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(directMessageNotifierProvider(widget.recipientId).notifier).refresh(),
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatState.when2(
              onRetry: () => ref.invalidate(directMessageNotifierProvider(widget.recipientId)),
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.chat_bubble_outline,
                    title: 'Ingen meldinger enna',
                    subtitle: 'Send en melding for a starte samtalen!',
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
                      key: ValueKey(message.id),
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
            .read(directMessageNotifierProvider(widget.recipientId).notifier)
            .deleteMessage(message.id);
      },
    );
  }
}
