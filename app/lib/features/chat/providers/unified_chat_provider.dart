import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/conversation.dart';
import '../data/chat_repository.dart';

/// Provider for all conversations (team chat + DMs) for a specific team
final allConversationsProvider =
    FutureProvider.family<List<ChatConversation>, String>((ref, teamId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getAllConversations(teamId);
});

/// Notifier for the currently selected conversation
class SelectedConversationNotifier extends Notifier<ChatConversation?> {
  @override
  ChatConversation? build() => null;

  void select(ChatConversation? conversation) {
    state = conversation;
  }

  void clear() {
    state = null;
  }
}

/// Provider for the currently selected conversation
final selectedConversationProvider =
    NotifierProvider<SelectedConversationNotifier, ChatConversation?>(
        SelectedConversationNotifier.new);

/// Notifier for search query in conversation list
class ConversationSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Provider for search query in conversation list
final conversationSearchQueryProvider =
    NotifierProvider<ConversationSearchQueryNotifier, String>(
        ConversationSearchQueryNotifier.new);

/// Filtered conversations based on search query
final filteredConversationsProvider =
    Provider.family<AsyncValue<List<ChatConversation>>, String>((ref, teamId) {
  final conversationsAsync = ref.watch(allConversationsProvider(teamId));
  final searchQuery = ref.watch(conversationSearchQueryProvider).toLowerCase();

  return conversationsAsync.whenData((conversations) {
    if (searchQuery.isEmpty) {
      return conversations;
    }
    return conversations
        .where((c) => c.name.toLowerCase().contains(searchQuery))
        .toList();
  });
});
