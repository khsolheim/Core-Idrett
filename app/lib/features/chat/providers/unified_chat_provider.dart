import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/conversation.dart';
import '../data/chat_repository.dart';

/// Provider for all conversations (team chat + DMs) for a specific team
final allConversationsProvider =
    FutureProvider.family<List<ChatConversation>, String>((ref, teamId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.getAllConversations(teamId);
});

/// Provider for the currently selected conversation
final selectedConversationProvider = StateProvider<ChatConversation?>((ref) => null);

/// Provider for search query in conversation list
final conversationSearchQueryProvider = StateProvider<String>((ref) => '');

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
