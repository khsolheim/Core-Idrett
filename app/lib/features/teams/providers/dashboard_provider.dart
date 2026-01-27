import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/activity.dart';

/// Dashboard data model
class DashboardData {
  final ActivityInstance? nextActivity;
  final List<LeaderboardEntry> topLeaderboard;
  final int unreadMessages;
  final FinesSummary finesSummary;

  const DashboardData({
    this.nextActivity,
    this.topLeaderboard = const [],
    this.unreadMessages = 0,
    this.finesSummary = const FinesSummary(),
  });
}

class LeaderboardEntry {
  final int rank;
  final String userName;
  final String? avatarUrl;
  final int points;

  const LeaderboardEntry({
    required this.rank,
    required this.userName,
    this.avatarUrl,
    required this.points,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] as int,
      userName: json['user_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      points: json['points'] as int,
    );
  }
}

class FinesSummary {
  final int unpaidCount;
  final double unpaidAmount;
  final int pendingApproval;

  const FinesSummary({
    this.unpaidCount = 0,
    this.unpaidAmount = 0,
    this.pendingApproval = 0,
  });

  factory FinesSummary.fromJson(Map<String, dynamic> json) {
    return FinesSummary(
      unpaidCount: json['unpaid_count'] as int? ?? 0,
      unpaidAmount: (json['unpaid_amount'] as num?)?.toDouble() ?? 0,
      pendingApproval: json['pending_approval'] as int? ?? 0,
    );
  }
}

/// Provider for team dashboard data
final dashboardProvider = FutureProvider.family<DashboardData, String>((ref, teamId) async {
  final client = ref.watch(apiClientProvider);

  try {
    final response = await client.get('/teams/$teamId/dashboard');
    final data = response.data as Map<String, dynamic>;

    // Parse next activity
    ActivityInstance? nextActivity;
    if (data['next_activity'] != null) {
      nextActivity = ActivityInstance.fromJson(data['next_activity'] as Map<String, dynamic>);
    }

    // Parse leaderboard
    final leaderboardData = data['leaderboard'] as List? ?? [];
    final leaderboard = leaderboardData
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse messages count
    final unreadMessages = data['unread_messages'] as int? ?? 0;

    // Parse fines summary
    FinesSummary finesSummary = const FinesSummary();
    if (data['fines_summary'] != null) {
      finesSummary = FinesSummary.fromJson(data['fines_summary'] as Map<String, dynamic>);
    }

    return DashboardData(
      nextActivity: nextActivity,
      topLeaderboard: leaderboard,
      unreadMessages: unreadMessages,
      finesSummary: finesSummary,
    );
  } catch (e) {
    // Return empty data on error
    return const DashboardData();
  }
});
