import 'package:uuid/uuid.dart';
import '../db/database.dart';
import 'user_service.dart';
import '../helpers/parsing_helpers.dart';

/// Service for direct messages (send, get, edit, delete DMs)
class DirectMessageService {
  final Database _db;
  final UserService _userService;
  final _uuid = const Uuid();

  DirectMessageService(this._db, this._userService);

  Future<List<Map<String, dynamic>>> getDirectMessages(
    String userId,
    String recipientId, {
    int limit = 50,
    String? before,
    String? after,
  }) async {
    // Get messages between the two users (in both directions)
    final filters = <String, String>{
      'or': '(and(user_id.eq.$userId,recipient_id.eq.$recipientId),and(user_id.eq.$recipientId,recipient_id.eq.$userId))',
      if (before != null) 'created_at': 'lt.$before',
      if (after != null) 'created_at': 'gt.$after',
    };

    final filteredMessages = await _db.client.select(
      'messages',
      filters: filters,
      order: 'created_at.desc',
      limit: limit,
    );

    // Get user info for both participants
    final userMap = await _userService.getUserMap([userId, recipientId]);

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
      final recipient = userMap[m['recipient_id']] ?? {};
      final replyTo = m['reply_to_id'] != null ? replyMap[m['reply_to_id']] : null;
      return {
        ...m,
        'user_name': user['name'],
        'user_avatar_url': user['avatar_url'],
        'recipient_name': recipient['name'],
        'recipient_avatar_url': recipient['avatar_url'],
        if (replyTo != null) 'reply_to': replyTo,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> sendDirectMessage({
    required String userId,
    required String recipientId,
    required String content,
    String? replyToId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    await _db.client.insert('messages', {
      'id': id,
      'user_id': userId,
      'recipient_id': recipientId,
      'content': content,
      'reply_to_id': replyToId,
      'created_at': now,
      'updated_at': now,
    });

    // Get user info
    final userMap = await _userService.getUserMap([userId, recipientId]);

    final user = userMap[userId] ?? {};
    final recipient = userMap[recipientId] ?? {};

    // Get reply-to message if provided
    Map<String, dynamic>? replyTo;
    if (replyToId != null) {
      final replies = await _db.client.select(
        'messages',
        filters: {'id': 'eq.$replyToId'},
      );
      if (replies.isNotEmpty) {
        final replyUser = userMap[replies.first['user_id']] ?? {};
        replyTo = {
          ...replies.first,
          'user_name': replyUser['name'],
          'user_avatar_url': replyUser['avatar_url'],
        };
      }
    }

    return {
      'id': id,
      'user_id': userId,
      'recipient_id': recipientId,
      'content': content,
      'reply_to_id': replyToId,
      'is_edited': false,
      'is_deleted': false,
      'created_at': now,
      'updated_at': now,
      'user_name': user['name'],
      'user_avatar_url': user['avatar_url'],
      'recipient_name': recipient['name'],
      'recipient_avatar_url': recipient['avatar_url'],
      if (replyTo != null) 'reply_to': replyTo,
    };
  }

  Future<void> markDirectAsRead(String userId, String recipientId) async {
    final now = DateTime.now().toIso8601String();

    // Check if record exists
    final existing = await _db.client.select(
      'message_reads',
      filters: {
        'user_id': 'eq.$userId',
        'recipient_id': 'eq.$recipientId',
      },
    );

    if (existing.isNotEmpty) {
      await _db.client.update(
        'message_reads',
        {'last_read_at': now},
        filters: {
          'user_id': 'eq.$userId',
          'recipient_id': 'eq.$recipientId',
        },
      );
    } else {
      await _db.client.insert('message_reads', {
        'id': _uuid.v4(),
        'user_id': userId,
        'recipient_id': recipientId,
        'last_read_at': now,
      });
    }
  }

  Future<int> getDirectUnreadCount(String userId, String recipientId) async {
    // Get last read time
    final reads = await _db.client.select(
      'message_reads',
      filters: {
        'user_id': 'eq.$userId',
        'recipient_id': 'eq.$recipientId',
      },
    );

    final lastReadAt = reads.isNotEmpty
        ? requireDateTime(reads.first, 'last_read_at')
        : DateTime(1970);

    // Get all messages from the recipient to this user
    final messages = await _db.client.select(
      'messages',
      select: 'id,created_at',
      filters: {
        'recipient_id': 'eq.$userId',
        'user_id': 'eq.$recipientId',
        'is_deleted': 'eq.false',
      },
    );

    // Count messages after last read
    return messages.where((m) {
      final createdAt = requireDateTime(m, 'created_at');
      return createdAt.isAfter(lastReadAt);
    }).length;
  }
}
