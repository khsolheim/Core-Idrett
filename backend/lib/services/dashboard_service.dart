import '../db/database.dart';
import 'user_service.dart';

class DashboardService {
  final Database _db;
  final UserService _userService;

  DashboardService(this._db, this._userService);

  Future<Map<String, dynamic>> getDashboardData(String teamId, String userId) async {
    // Get next upcoming activity
    Map<String, dynamic>? nextActivity;
    try {
      // Get today's date in YYYY-MM-DD format for comparison
      final today = DateTime.now().toIso8601String().split('T').first;

      // Query activity_instances with join to activities for team filtering
      final instances = await _db.client.select(
        'activity_instances',
        select: '*,activities!inner(team_id,title,type,location,description)',
        filters: {
          'activities.team_id': 'eq.$teamId',
          'date': 'gte.$today',
          'status': 'eq.scheduled',
        },
        order: 'date.asc,start_time.asc',
        limit: 1,
      );

      if (instances.isNotEmpty) {
        final instance = instances.first;
        final activity = instance['activities'] as Map<String, dynamic>?;

        // Build the response with activity details
        nextActivity = {
          'id': instance['id'],
          'activity_id': instance['activity_id'],
          'date': instance['date'],
          'start_time': instance['start_time'],
          'end_time': instance['end_time'],
          'status': instance['status'],
          'title': instance['title_override'] ?? activity?['title'],
          'type': activity?['type'],
          'location': instance['location_override'] ?? activity?['location'],
          'description': instance['description_override'] ?? activity?['description'],
        };
      }
    } catch (e) {
      // Ignore errors, return null for next activity
    }

    // Get top 3 leaderboard entries (main leaderboard)
    List<Map<String, dynamic>> leaderboard = [];
    try {
      final entries = await _db.client.select(
        'leaderboard_entries',
        select: 'user_id,points',
        filters: {'team_id': 'eq.$teamId'},
        order: 'points.desc',
        limit: 5,
      );

      if (entries.isNotEmpty) {
        // Get user details
        final userIds = entries.map((e) => e['user_id'] as String).toList();
        final userMap = await _userService.getUserMap(userIds);

        int rank = 1;
        for (final entry in entries) {
          final user = userMap[entry['user_id']];
          if (user != null) {
            leaderboard.add({
              'rank': rank,
              'user_name': user['name'],
              'avatar_url': user['avatar_url'],
              'points': entry['points'],
            });
            rank++;
          }
        }
      }
    } catch (e) {
      // Ignore errors, return empty leaderboard
    }

    // Get unread messages count
    int unreadMessages = 0;
    try {
      // Get last read timestamp for user
      final lastRead = await _db.client.select(
        'message_reads',
        select: 'last_read_at',
        filters: {
          'team_id': 'eq.$teamId',
          'user_id': 'eq.$userId',
        },
      );

      String? lastReadAt;
      if (lastRead.isNotEmpty) {
        lastReadAt = lastRead.first['last_read_at'] as String?;
      }

      // Count messages after last read
      final filters = <String, String>{
        'team_id': 'eq.$teamId',
        'user_id': 'neq.$userId', // Don't count own messages
      };
      if (lastReadAt != null) {
        filters['created_at'] = 'gt.$lastReadAt';
      }

      final messages = await _db.client.select(
        'messages',
        select: 'id',
        filters: filters,
      );
      unreadMessages = messages.length;
    } catch (e) {
      // Ignore errors, return 0
    }

    // Get fines summary
    int unpaidCount = 0;
    double unpaidAmount = 0;
    int pendingApproval = 0;
    try {
      // Get unpaid fines for user
      final unpaidFines = await _db.client.select(
        'fines',
        select: 'amount',
        filters: {
          'team_id': 'eq.$teamId',
          'user_id': 'eq.$userId',
          'status': 'eq.approved',
          'paid_at': 'is.null',
        },
      );

      unpaidCount = unpaidFines.length;
      for (final fine in unpaidFines) {
        unpaidAmount += (fine['amount'] as num?)?.toDouble() ?? 0;
      }

      // Get pending approval count (if user is fine boss)
      final membership = await _db.client.select(
        'team_members',
        select: 'is_fine_boss,is_admin',
        filters: {
          'team_id': 'eq.$teamId',
          'user_id': 'eq.$userId',
        },
      );

      if (membership.isNotEmpty) {
        final isFineBoss = membership.first['is_fine_boss'] == true ||
            membership.first['is_admin'] == true;
        if (isFineBoss) {
          final pendingFines = await _db.client.select(
            'fines',
            select: 'id',
            filters: {
              'team_id': 'eq.$teamId',
              'status': 'eq.pending',
            },
          );
          pendingApproval = pendingFines.length;
        }
      }
    } catch (e) {
      // Ignore errors
    }

    return {
      'next_activity': nextActivity,
      'leaderboard': leaderboard,
      'unread_messages': unreadMessages,
      'fines_summary': {
        'unpaid_count': unpaidCount,
        'unpaid_amount': unpaidAmount,
        'pending_approval': pendingApproval,
      },
    };
  }
}
