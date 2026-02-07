import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/message.dart';
import '../data/chat_repository.dart';

// Direct unread count provider
final directUnreadCountProvider = FutureProvider.family<int, String>((ref, recipientId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getDirectUnreadCount(recipientId);
});

// Direct message state notifier for real-time-like updates
class DirectMessageNotifier extends AsyncNotifier<List<Message>> {
  DirectMessageNotifier(this._recipientId);
  final String _recipientId;

  late final ChatRepository _repo;
  Timer? _pollTimer;
  DateTime? _lastMessageTime;

  @override
  Future<List<Message>> build() async {
    _repo = ref.watch(chatRepositoryProvider);

    // Clean up timer when disposed
    ref.onDispose(() {
      _pollTimer?.cancel();
    });

    // Load messages
    final messages = await _repo.getDirectMessages(_recipientId);
    if (messages.isNotEmpty) {
      _lastMessageTime = messages.first.createdAt;
    }
    // Start polling for new messages
    _startPolling();
    return messages;
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
        final currentMessages = state.value ?? [];
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

      final currentMessages = state.value ?? [];
      state = AsyncValue.data([message, ...currentMessages]);
      _lastMessageTime = message.createdAt;

      return true;
    } catch (e) {
      ErrorDisplayService.showWarning('Kunne ikke sende melding. Prøv igjen.');
      return false;
    }
  }

  Future<bool> editMessage(String messageId, String content) async {
    try {
      final updatedMessage = await _repo.editMessage(
        messageId: messageId,
        content: content,
      );

      final currentMessages = state.value ?? [];
      final index = currentMessages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final updated = List<Message>.from(currentMessages);
        updated[index] = updatedMessage;
        state = AsyncValue.data(updated);
      }
      return true;
    } catch (e) {
      ErrorDisplayService.showWarning('Kunne ikke redigere melding. Prøv igjen.');
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId) async {
    try {
      await _repo.deleteMessage(messageId);

      // Update message to show as deleted
      final currentMessages = state.value ?? [];
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
      ErrorDisplayService.showWarning('Kunne ikke slette melding. Prøv igjen.');
      return false;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.getDirectMessages(_recipientId));
    if (state.hasValue && state.value!.isNotEmpty) {
      _lastMessageTime = state.value!.first.createdAt;
    }
  }

  Future<void> markAsRead() async {
    try {
      await _repo.markDirectAsRead(_recipientId);
      ref.invalidate(directUnreadCountProvider(_recipientId));
    } catch (e) {
      // Ignore errors
    }
  }
}

final directMessageNotifierProvider =
    AsyncNotifierProvider.family<DirectMessageNotifier, List<Message>, String>(
        DirectMessageNotifier.new);
