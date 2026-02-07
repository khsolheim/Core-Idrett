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
    final currentUser = ref.watch(authStateProvider).value;
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));
    final theme = Theme.of(context);

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
                    final isOwn = message.userId == currentUser?.id;
                    final showDate = index == messages.length - 1 ||
                        !_isSameDay(
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
              ref
                  .read(directMessageNotifierProvider(widget.recipientId).notifier)
                  .deleteMessage(message.id);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Slett'),
          ),
        ],
      ),
    );
  }
}
