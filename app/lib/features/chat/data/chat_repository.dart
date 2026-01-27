import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/message.dart';

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
    await _client.delete('/messages/$messageId');
  }

  Future<void> markAsRead(String teamId) async {
    await _client.post('/messages/teams/$teamId/read', data: {});
  }

  Future<int> getUnreadCount(String teamId) async {
    final response = await _client.get('/messages/teams/$teamId/unread');
    return response.data['unread_count'] as int;
  }
}
