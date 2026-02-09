import 'package:uuid/uuid.dart';
import '../db/database.dart';
import 'user_service.dart';
import '../helpers/parsing_helpers.dart';

/// Service for conversation aggregation (getAllConversations, markAsRead, etc.)
class MessageService {
  final Database _db;
  final UserService _userService;
  final _uuid = const Uuid();

  MessageService(this._db, this._userService);

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
        ? requireDateTime(reads.first, 'last_read_at')
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
    final teamName = teams.isNotEmpty ? safeStringNullable(teams.first, 'name') : 'Lag-chat';

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
        .map((m) => safeString(m, 'user_id'))
        .where((id) => id != userId)
        .toSet();

    if (teamMemberIds.isNotEmpty) {
      // Get direct messages involving this user (DB-level filtering)
      final allMessages = await _db.client.select(
        'messages',
        filters: {
          'recipient_id': 'not.is.null',
          'or': '(user_id.eq.$userId,recipient_id.eq.$userId)',
        },
        order: 'created_at.desc',
      );

      // Filter to only direct messages with team members
      final directMessages = allMessages.where((m) {
        final recipientId = safeStringNullable(m, 'recipient_id');
        if (recipientId == null) return false;
        final senderId = safeString(m, 'user_id');
        final partnerId = senderId == userId ? recipientId : senderId;
        return teamMemberIds.contains(partnerId);
      }).toList();

      // Group by conversation partner
      final conversationMap = <String, Map<String, dynamic>>{};
      for (final msg in directMessages) {
        final senderId = safeString(msg, 'user_id');
        final recipientId = safeString(msg, 'recipient_id');
        final partnerId = senderId == userId ? recipientId : senderId;

        if (!conversationMap.containsKey(partnerId)) {
          conversationMap[partnerId] = msg;
        }
      }

      if (conversationMap.isNotEmpty) {
        // Get user info for all conversation partners
        final partnerIds = conversationMap.keys.toList();
        final userMap = await _userService.getUserMap(partnerIds);

        // Batch fetch unread counts: get all message_reads for this user's DMs
        final allReads = await _db.client.select(
          'message_reads',
          filters: {
            'user_id': 'eq.$userId',
            'recipient_id': 'not.is.null',
          },
        );
        final readMap = <String, DateTime>{};
        for (final r in allReads) {
          final rid = safeString(r, 'recipient_id');
          readMap[rid] = requireDateTime(r, 'last_read_at');
        }

        // Count unread per partner from the direct messages we already have
        final unreadCounts = <String, int>{};
        for (final msg in directMessages) {
          final senderId = safeString(msg, 'user_id');
          final recipientId = safeString(msg, 'recipient_id');
          // Only count messages FROM partner TO us
          if (recipientId == userId) {
            final lastRead = readMap[senderId] ?? DateTime(1970);
            final msgTime = requireDateTime(msg, 'created_at');
            if (msgTime.isAfter(lastRead) && msg['is_deleted'] != true) {
              unreadCounts[senderId] = (unreadCounts[senderId] ?? 0) + 1;
            }
          }
        }

        // Build conversation entries
        for (final entry in conversationMap.entries) {
          final partnerId = entry.key;
          final lastMessage = entry.value;
          final partner = userMap[partnerId] ?? {};

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
            'unread_count': unreadCounts[partnerId] ?? 0,
          });
        }
      }
    }

    // Sort by last message time (most recent first), with team chat first if no messages
    conversations.sort((a, b) {
      final aTime = safeStringNullable(a, 'last_message_at');
      final bTime = safeStringNullable(b, 'last_message_at');
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
    // Get direct messages involving this user (DB-level filtering)
    final directMessages = await _db.client.select(
      'messages',
      filters: {
        'recipient_id': 'not.is.null',
        'or': '(user_id.eq.$userId,recipient_id.eq.$userId)',
      },
      order: 'created_at.desc',
    );

    // Group by conversation partner
    final conversationMap = <String, Map<String, dynamic>>{};
    for (final msg in directMessages) {
      final senderId = safeString(msg, 'user_id');
      final recipientId = safeString(msg, 'recipient_id');
      final partnerId = senderId == userId ? recipientId : senderId;

      if (!conversationMap.containsKey(partnerId)) {
        conversationMap[partnerId] = msg;
      }
    }

    if (conversationMap.isEmpty) return [];

    // Get user info for all conversation partners
    final partnerIds = conversationMap.keys.toList();
    final userMap = await _userService.getUserMap(partnerIds);

    // Batch fetch unread counts: get all message_reads for this user's DMs
    final allReads = await _db.client.select(
      'message_reads',
      filters: {
        'user_id': 'eq.$userId',
        'recipient_id': 'not.is.null',
      },
    );
    final readMap = <String, DateTime>{};
    for (final r in allReads) {
      final rid = safeString(r, 'recipient_id');
      readMap[rid] = requireDateTime(r, 'last_read_at');
    }

    // Count unread per partner from the direct messages we already have
    final unreadCounts = <String, int>{};
    for (final msg in directMessages) {
      final senderId = safeString(msg, 'user_id');
      final recipientId = safeString(msg, 'recipient_id');
      if (recipientId == userId) {
        final lastRead = readMap[senderId] ?? DateTime(1970);
        final msgTime = requireDateTime(msg, 'created_at');
        if (msgTime.isAfter(lastRead) && msg['is_deleted'] != true) {
          unreadCounts[senderId] = (unreadCounts[senderId] ?? 0) + 1;
        }
      }
    }

    // Build conversation entries
    final conversations = <Map<String, dynamic>>[];
    for (final entry in conversationMap.entries) {
      final partnerId = entry.key;
      final lastMessage = entry.value;
      final partner = userMap[partnerId] ?? {};

      conversations.add({
        'oder_id': '${userId}_$partnerId',
        'recipient_id': partnerId,
        'recipient_name': partner['name'],
        'recipient_avatar_url': partner['avatar_url'],
        'last_message': lastMessage['is_deleted'] == true
            ? '[Slettet melding]'
            : lastMessage['content'],
        'last_message_at': lastMessage['created_at'],
        'unread_count': unreadCounts[partnerId] ?? 0,
      });
    }

    // Sort by last message time (most recent first)
    conversations.sort((a, b) {
      final aTime = safeStringNullable(a, 'last_message_at');
      final bTime = safeStringNullable(b, 'last_message_at');
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return conversations;
  }
}
