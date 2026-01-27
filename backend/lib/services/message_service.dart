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

  // ============ Direct Message Methods ============

  Future<List<Map<String, dynamic>>> getDirectMessages(
    String userId,
    String recipientId, {
    int limit = 50,
    String? before,
    String? after,
  }) async {
    // Get messages between the two users (in both directions)
    final messages = await _db.client.select(
      'messages',
      order: 'created_at.desc',
      limit: limit,
    );

    // Filter to only messages between these two users
    List<Map<String, dynamic>> filteredMessages = messages.where((m) {
      final senderId = m['user_id'] as String;
      final recipId = m['recipient_id'] as String?;
      if (recipId == null) return false;
      return (senderId == userId && recipId == recipientId) ||
             (senderId == recipientId && recipId == userId);
    }).toList();

    // Filter by before/after if provided
    if (before != null) {
      filteredMessages = filteredMessages.where((m) {
        final createdAt = DateTime.parse(m['created_at'] as String);
        final beforeTime = DateTime.parse(before);
        return createdAt.isBefore(beforeTime);
      }).toList();
    } else if (after != null) {
      filteredMessages = filteredMessages.where((m) {
        final createdAt = DateTime.parse(m['created_at'] as String);
        final afterTime = DateTime.parse(after);
        return createdAt.isAfter(afterTime);
      }).toList();
    }

    // Get user info for both participants
    final userIds = {userId, recipientId};
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${userIds.join(',')})'},
    );

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
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.($userId,$recipientId)'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

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
        ? DateTime.parse(reads.first['last_read_at'] as String)
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
      final createdAt = DateTime.parse(m['created_at'] as String);
      return createdAt.isAfter(lastReadAt);
    }).length;
  }

  /// Returns all conversations (team chat + direct messages) for a user in a team,
  /// sorted by last message time (most recent first).
  Future<List<Map<String, dynamic>>> getAllConversations(
    String userId,
    String teamId,
  ) async {
    final conversations = <Map<String, dynamic>>[];

    // 1. Add team chat conversation
    final teamMessages = await _db.client.select(
      'messages',
      filters: {
        'team_id': 'eq.$teamId',
        'recipient_id': 'is.null',
      },
      order: 'created_at.desc',
      limit: 1,
    );

    final teamUnreadCount = await getUnreadCount(userId, teamId);

    // Get team name
    final teams = await _db.client.select(
      'teams',
      select: 'id,name',
      filters: {'id': 'eq.$teamId'},
    );
    final teamName = teams.isNotEmpty ? teams.first['name'] as String? : 'Lag-chat';

    conversations.add({
      'type': 'team',
      'team_id': teamId,
      'recipient_id': null,
      'name': teamName ?? 'Lag-chat',
      'avatar_url': null,
      'last_message': teamMessages.isNotEmpty
          ? (teamMessages.first['is_deleted'] == true
              ? '[Slettet melding]'
              : teamMessages.first['content'])
          : null,
      'last_message_at': teamMessages.isNotEmpty
          ? teamMessages.first['created_at']
          : null,
      'unread_count': teamUnreadCount,
    });

    // 2. Get direct message conversations (only with team members)
    // First, get team member user IDs
    final teamMembers = await _db.client.select(
      'team_members',
      select: 'user_id',
      filters: {'team_id': 'eq.$teamId'},
    );
    final teamMemberIds = teamMembers
        .map((m) => m['user_id'] as String)
        .where((id) => id != userId)
        .toSet();

    if (teamMemberIds.isNotEmpty) {
      // Get all direct messages involving this user
      final allMessages = await _db.client.select(
        'messages',
        filters: {'recipient_id': 'not.is.null'},
        order: 'created_at.desc',
      );

      // Filter to only direct messages with team members
      final directMessages = allMessages.where((m) {
        final recipientId = m['recipient_id'] as String?;
        if (recipientId == null) return false;
        final senderId = m['user_id'] as String;
        // Must involve current user and a team member
        final isUserInvolved = senderId == userId || recipientId == userId;
        final partnerId = senderId == userId ? recipientId : senderId;
        final isTeamMember = teamMemberIds.contains(partnerId);
        return isUserInvolved && isTeamMember;
      }).toList();

      // Group by conversation partner
      final conversationMap = <String, Map<String, dynamic>>{};
      for (final msg in directMessages) {
        final senderId = msg['user_id'] as String;
        final recipientId = msg['recipient_id'] as String;
        final partnerId = senderId == userId ? recipientId : senderId;

        if (!conversationMap.containsKey(partnerId)) {
          conversationMap[partnerId] = msg;
        }
      }

      if (conversationMap.isNotEmpty) {
        // Get user info for all conversation partners
        final partnerIds = conversationMap.keys.toList();
        final users = await _db.client.select(
          'users',
          select: 'id,name,avatar_url',
          filters: {'id': 'in.(${partnerIds.join(',')})'},
        );

        final userMap = <String, Map<String, dynamic>>{};
        for (final u in users) {
          userMap[u['id'] as String] = u;
        }

        // Build conversation entries
        for (final entry in conversationMap.entries) {
          final partnerId = entry.key;
          final lastMessage = entry.value;
          final partner = userMap[partnerId] ?? {};
          final unreadCount = await getDirectUnreadCount(userId, partnerId);

          conversations.add({
            'type': 'direct',
            'team_id': null,
            'recipient_id': partnerId,
            'name': partner['name'] ?? 'Ukjent',
            'avatar_url': partner['avatar_url'],
            'last_message': lastMessage['is_deleted'] == true
                ? '[Slettet melding]'
                : lastMessage['content'],
            'last_message_at': lastMessage['created_at'],
            'unread_count': unreadCount,
          });
        }
      }
    }

    // Sort by last message time (most recent first), with team chat first if no messages
    conversations.sort((a, b) {
      final aTime = a['last_message_at'] as String?;
      final bTime = b['last_message_at'] as String?;
      if (aTime == null && bTime == null) {
        // Team chat comes first
        return a['type'] == 'team' ? -1 : 1;
      }
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    // Get all direct messages involving this user
    final allMessages = await _db.client.select(
      'messages',
      order: 'created_at.desc',
    );

    // Filter to only direct messages involving this user
    final directMessages = allMessages.where((m) {
      final recipientId = m['recipient_id'] as String?;
      if (recipientId == null) return false;
      final senderId = m['user_id'] as String;
      return senderId == userId || recipientId == userId;
    }).toList();

    // Group by conversation partner
    final conversationMap = <String, Map<String, dynamic>>{};
    for (final msg in directMessages) {
      final senderId = msg['user_id'] as String;
      final recipientId = msg['recipient_id'] as String;
      final partnerId = senderId == userId ? recipientId : senderId;

      if (!conversationMap.containsKey(partnerId)) {
        conversationMap[partnerId] = msg;
      }
    }

    if (conversationMap.isEmpty) return [];

    // Get user info for all conversation partners
    final partnerIds = conversationMap.keys.toList();
    final users = await _db.client.select(
      'users',
      select: 'id,name,avatar_url',
      filters: {'id': 'in.(${partnerIds.join(',')})'},
    );

    final userMap = <String, Map<String, dynamic>>{};
    for (final u in users) {
      userMap[u['id'] as String] = u;
    }

    // Get unread counts for each conversation
    final conversations = <Map<String, dynamic>>[];
    for (final entry in conversationMap.entries) {
      final partnerId = entry.key;
      final lastMessage = entry.value;
      final partner = userMap[partnerId] ?? {};
      final unreadCount = await getDirectUnreadCount(userId, partnerId);

      conversations.add({
        'oder_id': '${userId}_$partnerId',
        'recipient_id': partnerId,
        'recipient_name': partner['name'],
        'recipient_avatar_url': partner['avatar_url'],
        'last_message': lastMessage['is_deleted'] == true
            ? '[Slettet melding]'
            : lastMessage['content'],
        'last_message_at': lastMessage['created_at'],
        'unread_count': unreadCount,
      });
    }

    // Sort by last message time (most recent first)
    conversations.sort((a, b) {
      final aTime = a['last_message_at'] as String?;
      final bTime = b['last_message_at'] as String?;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return conversations;
  }
}
