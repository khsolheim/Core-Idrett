import 'package:uuid/uuid.dart';
import '../db/database.dart';
import 'user_service.dart';
import '../helpers/parsing_helpers.dart';

/// Service for team chat messages (send, get, edit, delete)
class TeamChatService {
  final Database _db;
  final UserService _userService;
  final _uuid = const Uuid();

  TeamChatService(this._db, this._userService);

  Future<List<Map<String, dynamic>>> getMessages(
    String teamId, {
    int limit = 50,
    String? before,
    String? after,
  }) async {
    // Build filters
    final filters = <String, String>{
      'team_id': 'eq.$teamId',
      if (before != null) 'created_at': 'lt.$before',
      if (after != null) 'created_at': 'gt.$after',
    };

    String order = 'created_at.desc';

    // Get messages
    final messages = await _db.client.select(
      'messages',
      filters: filters,
      order: order,
      limit: limit,
    );

    if (messages.isEmpty) return [];

    final filteredMessages = messages;

    // Get user info
    final userIds = filteredMessages.map((m) => safeString(m, 'user_id')).toSet().toList();
    final userMap = await _userService.getUserMap(userIds);

    // Get reply-to messages if any
    final replyIds = filteredMessages
        .where((m) => m['reply_to_id'] != null)
        .map((m) => safeString(m, 'reply_to_id'))
        .toSet()
        .toList();

    final replyMap = <String, Map<String, dynamic>>{};
    if (replyIds.isNotEmpty) {
      final replies = await _db.client.select(
        'messages',
        filters: {'id': 'in.(${replyIds.join(',')})'},
      );
      for (final r in replies) {
        final user = userMap[r['user_id']] ?? {};
        replyMap[safeString(r, 'id')] = {
          ...r,
          'user_name': user['name'],
          'user_avatar_url': user['avatar_url'],
        };
      }
    }

    // Build result
    return filteredMessages.map((m) {
      final user = userMap[m['user_id']] ?? {};
      final replyTo = m['reply_to_id'] != null ? replyMap[m['reply_to_id']] : null;
      return {
        ...m,
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
        if (replyTo != null) 'reply_to': replyTo,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> sendMessage({
    required String teamId,
    required String userId,
    required String content,
    String? replyToId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.client.insert('messages', {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'content': content,
      'reply_to_id': replyToId,
      'created_at': now,
      'updated_at': now,
    });

    // Get user info
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'eq.$userId'},
    );
    final user = users.isNotEmpty ? users.first : <String, dynamic>{};

    // Get reply-to message if provided
    Map<String, dynamic>? replyTo;
    if (replyToId != null) {
      final replies = await _db.client.select(
        'messages',
        filters: {'id': 'eq.$replyToId'},
      );
      if (replies.isNotEmpty) {
        final replyUser = await _db.client.select(
          'users',
          select: 'id,name,avatar_url',
          filters: {'id': 'eq.${replies.first['user_id']}'},
        );
        replyTo = {
          ...replies.first,
          'user_name': replyUser.isNotEmpty ? replyUser.first['name'] : null,
          'user_avatar_url': replyUser.isNotEmpty ? replyUser.first['avatar_url'] : null,
        };
      }
    }

    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'content': content,
      'reply_to_id': replyToId,
      'is_edited': false,
      'is_deleted': false,
      'created_at': now,
      'updated_at': now,
      'user_name': user['name'],
      'user_avatar_url': user['avatar_url'],
      if (replyTo != null) 'reply_to': replyTo,
    };
  }

  Future<Map<String, dynamic>?> editMessage({
    required String messageId,
    required String userId,
    required String content,
  }) async {
    // Verify ownership
    final messages = await _db.client.select(
      'messages',
      filters: {'id': 'eq.$messageId', 'user_id': 'eq.$userId'},
    );

    if (messages.isEmpty) return null;

    final now = DateTime.now().toIso8601String();
    final result = await _db.client.update(
      'messages',
      {
        'content': content,
        'is_edited': true,
        'updated_at': now,
      },
      filters: {'id': 'eq.$messageId'},
    );

    if (result.isEmpty) return null;

    // Get user info
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'eq.$userId'},
    );
    final user = users.isNotEmpty ? users.first : <String, dynamic>{};

    return {
      ...result.first,
      'user_name': user['name'],
      'user_avatar_url': user['avatar_url'],
    };
  }

  Future<bool> deleteMessage({
    required String messageId,
    required String userId,
    bool isAdmin = false,
  }) async {
    // Build filter - admin can delete any message
    final filters = <String, String>{'id': 'eq.$messageId'};
    if (!isAdmin) {
      filters['user_id'] = 'eq.$userId';
    }

    final messages = await _db.client.select('messages', filters: filters);
    if (messages.isEmpty) return false;

    await _db.client.update(
      'messages',
      {
        'is_deleted': true,
        'updated_at': DateTime.now().toIso8601String(),
      },
      filters: {'id': 'eq.$messageId'},
    );

    return true;
  }
}
