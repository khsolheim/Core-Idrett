import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/message.dart';
import '../../../data/models/conversation.dart';
import '../data/chat_repository.dart';

// Conversations provider - fetches list of DM conversations
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getConversations();
});

// Direct messages provider - fetches messages with a specific user
final directMessagesProvider = FutureProvider.family<List<Message>, String>((ref, recipientId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getDirectMessages(recipientId);
});

// Direct unread count provider
final directUnreadCountProvider = FutureProvider.family<int, String>((ref, recipientId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getDirectUnreadCount(recipientId);
});

// Direct message state notifier for real-time-like updates
class DirectMessageNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final ChatRepository _repo;
  final String _recipientId;
  final Ref _ref;
  Timer? _pollTimer;
  DateTime? _lastMessageTime;

  DirectMessageNotifier(this._repo, this._recipientId, this._ref)
      : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _repo.getDirectMessages(_recipientId);
      state = AsyncValue.data(messages);
      if (messages.isNotEmpty) {
        _lastMessageTime = messages.first.createdAt;
      }
      // Start polling for new messages
      _startPolling();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _pollNewMessages());
  }

  Future<void> _pollNewMessages() async {
    if (_lastMessageTime == null) return;

    try {
      final newMessages = await _repo.getDirectMessages(
        _recipientId,
        after: _lastMessageTime!.toIso8601String(),
      );

      if (newMessages.isNotEmpty) {
        final currentMessages = state.valueOrNull ?? [];
        // Add new messages at the beginning (newest first)
        final updatedMessages = [...newMessages, ...currentMessages];
        state = AsyncValue.data(updatedMessages);
        _lastMessageTime = newMessages.first.createdAt;
      }
    } catch (e) {
      // Silently fail polling - don't update state
    }
  }

  Future<bool> sendMessage(String content, {String? replyToId}) async {
    try {
      final message = await _repo.sendDirectMessage(
        recipientId: _recipientId,
        content: content,
        replyToId: replyToId,
      );

      final currentMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([message, ...currentMessages]);
      _lastMessageTime = message.createdAt;

      // Invalidate conversations to update the list
      _ref.invalidate(conversationsProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> editMessage(String messageId, String content) async {
    try {
      final updatedMessage = await _repo.editMessage(
        messageId: messageId,
        content: content,
      );

      final currentMessages = state.valueOrNull ?? [];
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updated = List<Message>.from(currentMessages);
        updated[index] = updatedMessage;
        state = AsyncValue.data(updated);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      await _repo.deleteMessage(messageId);

      // Update message to show as deleted
      final currentMessages = state.valueOrNull ?? [];
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updated = List<Message>.from(currentMessages);
        final msg = updated[index];
        updated[index] = Message(
          id: msg.id,
          teamId: msg.teamId,
          recipientId: msg.recipientId,
          userId: msg.userId,
          content: '[Slettet melding]',
          replyToId: msg.replyToId,
          isEdited: msg.isEdited,
          isDeleted: true,
          createdAt: msg.createdAt,
          updatedAt: DateTime.now(),
          userName: msg.userName,
          userAvatarUrl: msg.userAvatarUrl,
          recipientName: msg.recipientName,
          recipientAvatarUrl: msg.recipientAvatarUrl,
          replyTo: msg.replyTo,
        );
        state = AsyncValue.data(updated);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadMessages();
  }

  Future<void> markAsRead() async {
    try {
      await _repo.markDirectAsRead(_recipientId);
      _ref.invalidate(directUnreadCountProvider(_recipientId));
      _ref.invalidate(conversationsProvider);
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final directMessageNotifierProvider =
    StateNotifierProvider.family<DirectMessageNotifier, AsyncValue<List<Message>>, String>(
        (ref, recipientId) {
  final repo = ref.watch(chatRepositoryProvider);
  return DirectMessageNotifier(repo, recipientId, ref);
});
