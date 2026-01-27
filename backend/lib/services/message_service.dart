import 'package:uuid/uuid.dart';
import '../db/database.dart';

class MessageService {
  final Database _db;
  final _uuid = const Uuid();

  MessageService(this._db);

  Future<List<Map<String, dynamic>>> getMessages(
    String teamId, {
    int limit = 50,
    String? before,
    String? after,
  }) async {
    // Build filters
    final filters = <String, String>{
      'team_id': 'eq.$teamId',
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

    // Filter by before/after if provided
    List<Map<String, dynamic>> filteredMessages = messages;
    if (before != null) {
      filteredMessages = messages.where((m) {
        final createdAt = DateTime.parse(m['created_at'] as String);
        final beforeTime = DateTime.parse(before);
        return createdAt.isBefore(beforeTime);
      }).toList();
    } else if (after != null) {
      filteredMessages = messages.where((m) {
        final createdAt = DateTime.parse(m['created_at'] as String);
        final afterTime = DateTime.parse(after);
        return createdAt.isAfter(afterTime);
      }).toList();
    }

    // Get user info
    final userIds = filteredMessages.map((m) => m['user_id'] as String).toSet().toList();
    final users = userIds.isNotEmpty
        ? await _db.client.select(
            'users',
            select: 'id,name,avatar_url',
            filters: {'id': 'in.(${userIds.join(',')})'},
          )
        : <Map<String, dynamic>>[];

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    // Get reply-to messages if any
    final replyIds = filteredMessages
        .where((m) => m['reply_to_id'] != null)
        .map((m) => m['reply_to_id'] as String)
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
        replyMap[r['id'] as String] = {
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

  Future<void> markAsRead(String userId, String teamId) async {
    final now = DateTime.now().toIso8601String();

    // Check if record exists
    final existing = await _db.client.select(
      'message_reads',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );

    if (existing.isNotEmpty) {
      await _db.client.update(
        'message_reads',
        {'last_read_at': now},
        filters: {
          'user_id': 'eq.$userId',
          'team_id': 'eq.$teamId',
        },
      );
    } else {
      await _db.client.insert('message_reads', {
        'id': _uuid.v4(),
        'user_id': userId,
        'team_id': teamId,
        'last_read_at': now,
      });
    }
  }

  Future<int> getUnreadCount(String userId, String teamId) async {
    // Get last read time
    final reads = await _db.client.select(
      'message_reads',
      filters: {
        'user_id': 'eq.$userId',
        'team_id': 'eq.$teamId',
      },
    );

    final lastReadAt = reads.isNotEmpty
        ? DateTime.parse(reads.first['last_read_at'] as String)
        : DateTime(1970);

    // Count messages after last read
    final messages = await _db.client.select(
      'messages',
      select: 'id',
      filters: {
        'team_id': 'eq.$teamId',
        'created_at': 'gt.${lastReadAt.toIso8601String()}',
        'user_id': 'neq.$userId',
        'is_deleted': 'eq.false',
      },
    );

    return messages.length;
  }
}
