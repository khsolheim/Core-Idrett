import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/message.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/direct_message_provider.dart';

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
            child: chatState.when(
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
                          'Send en melding for a starte samtalen!',
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text('Kunne ikke laste meldinger: $error'),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref
                          .read(directMessageNotifierProvider(widget.recipientId).notifier)
                          .refresh(),
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

class _DateDivider extends StatelessWidget {
  final DateTime date;

  const _DateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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
                        color: message.isDeleted
                            ? theme.colorScheme.outline
                            : null,
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
