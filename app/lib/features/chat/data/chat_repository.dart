import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/message.dart';
import '../../../data/models/conversation.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

class ChatRepository {
  final ApiClient _client;

  ChatRepository(this._client);

  Future<List<Message>> getMessages(
    String teamId, {
    int limit = 50,
    String? before,
    String? after,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (before != null) queryParams['before'] = before;
    if (after != null) queryParams['after'] = after;

    final response = await _client.get(
      '/messages/teams/$teamId',
      queryParameters: queryParams,
    );
    final data = response.data['messages'] as List;
    return data.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Message> sendMessage({
    required String teamId,
    required String content,
    String? replyToId,
  }) async {
    final response = await _client.post('/messages/teams/$teamId', data: {
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Message> editMessage({
    required String messageId,
    required String content,
  }) async {
    final response = await _client.patch('/messages/$messageId', data: {
      'content': content,
    });
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteMessage(String messageId, {String? teamId}) async {
    final path = teamId != null
        ? '/messages/$messageId?team_id=$teamId'
        : '/messages/$messageId';
    await _client.delete(path);
  }

  Future<void> markAsRead(String teamId) async {
    await _client.post('/messages/teams/$teamId/read', data: {});
  }

  Future<int> getUnreadCount(String teamId) async {
    final response = await _client.get('/messages/teams/$teamId/unread');
    return response.data['unread_count'] as int;
  }

  // ============ Unified Conversations ============

  Future<List<ChatConversation>> getAllConversations(String teamId) async {
    final response = await _client.get(
      '/messages/all-conversations',
      queryParameters: {'team_id': teamId},
    );
    final data = response.data['conversations'] as List;
    return data.map((c) => ChatConversation.fromJson(c as Map<String, dynamic>)).toList();
  }

  // ============ Direct Message Methods ============

  Future<List<Conversation>> getConversations() async {
    final response = await _client.get('/messages/conversations');
    final data = response.data['conversations'] as List;
    return data.map((c) => Conversation.fromJson(c as Map<String, dynamic>)).toList();
  }

  Future<List<Message>> getDirectMessages(
    String recipientId, {
    int limit = 50,
    String? before,
    String? after,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (before != null) queryParams['before'] = before;
    if (after != null) queryParams['after'] = after;

    final response = await _client.get(
      '/messages/direct/$recipientId',
      queryParameters: queryParams,
    );
    final data = response.data['messages'] as List;
    return data.map((m) => Message.fromJson(m as Map<String, dynamic>)).toList();
  }

  Future<Message> sendDirectMessage({
    required String recipientId,
    required String content,
    String? replyToId,
  }) async {
    final response = await _client.post('/messages/direct/$recipientId', data: {
      'content': content,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
    return Message.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> markDirectAsRead(String recipientId) async {
    await _client.post('/messages/direct/$recipientId/read', data: {});
  }

  Future<int> getDirectUnreadCount(String recipientId) async {
    final response = await _client.get('/messages/direct/$recipientId/unread');
    return response.data['unread_count'] as int;
  }
}
