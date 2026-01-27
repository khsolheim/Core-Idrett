import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/message.dart';
import '../data/chat_repository.dart';

// Messages provider - fetches initial messages
final messagesProvider = FutureProvider.family<List<Message>, String>((ref, teamId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getMessages(teamId);
});

// Unread count provider
final unreadCountProvider = FutureProvider.family<int, String>((ref, teamId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getUnreadCount(teamId);
});

// Chat state notifier for real-time-like updates
class ChatNotifier extends StateNotifier<AsyncValue<List<Message>>> {
  final ChatRepository _repo;
  final String _teamId;
  final Ref _ref;
  Timer? _pollTimer;
  DateTime? _lastMessageTime;

  ChatNotifier(this._repo, this._teamId, this._ref)
      : super(const AsyncValue.loading()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _repo.getMessages(_teamId);
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
      final newMessages = await _repo.getMessages(
        _teamId,
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
      final message = await _repo.sendMessage(
        teamId: _teamId,
        content: content,
        replyToId: replyToId,
      );

      final currentMessages = state.valueOrNull ?? [];
      state = AsyncValue.data([message, ...currentMessages]);
      _lastMessageTime = message.createdAt;
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
      await _repo.deleteMessage(messageId, teamId: _teamId);

      // Update message to show as deleted
      final currentMessages = state.valueOrNull ?? [];
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updated = List<Message>.from(currentMessages);
        final msg = updated[index];
        updated[index] = Message(
          id: msg.id,
          teamId: msg.teamId,
          userId: msg.userId,
          content: '[Slettet melding]',
          replyToId: msg.replyToId,
          isEdited: msg.isEdited,
          isDeleted: true,
          createdAt: msg.createdAt,
          updatedAt: DateTime.now(),
          userName: msg.userName,
          userAvatarUrl: msg.userAvatarUrl,
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
      await _repo.markAsRead(_teamId);
      _ref.invalidate(unreadCountProvider(_teamId));
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

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, AsyncValue<List<Message>>, String>(
        (ref, teamId) {
  final repo = ref.watch(chatRepositoryProvider);
  return ChatNotifier(repo, teamId, ref);
});
