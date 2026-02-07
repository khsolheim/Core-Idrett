import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/mini_activity_statistics.dart';
import '../../providers/mini_activity_statistics_provider.dart';
import '../widgets/leaderboard_tab.dart';
import '../widgets/rivalries_tab.dart';
import '../widgets/team_stats_tab.dart';
import 'player_stats_screen.dart';

/// Screen for viewing team mini-activity statistics and leaderboard
class MiniActivityStatisticsScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String? currentUserId;

  const MiniActivityStatisticsScreen({
    super.key,
    required this.teamId,
    this.currentUserId,
  });

  @override
  ConsumerState<MiniActivityStatisticsScreen> createState() =>
      _MiniActivityStatisticsScreenState();
}

class _MiniActivityStatisticsScreenState
    extends ConsumerState<MiniActivityStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'total_points';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamStatsAsync = ref.watch(teamMiniActivityStatsProvider(widget.teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-aktiviteter'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ledertavle'),
            Tab(text: 'Rivaler'),
            Tab(text: 'Statistikk'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(),
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          LeaderboardTab(
            teamId: widget.teamId,
            currentUserId: widget.currentUserId,
            sortBy: _sortBy,
            onSortChanged: (value) => setState(() => _sortBy = value),
            onPlayerTap: _showPlayerStats,
          ),
          RivalriesTab(
            teamId: widget.teamId,
            currentUserId: widget.currentUserId,
          ),
          TeamStatsTab(
            teamId: widget.teamId,
            teamStats: teamStatsAsync,
          ),
        ],
      ),
    );
  }

  void _refresh() {
    ref.invalidate(teamMiniActivityStatsProvider(widget.teamId));
    ref.invalidate(topRivalriesProvider(widget.teamId));
    ref.invalidate(teamLeaderboardProvider(TeamLeaderboardParams(
      teamId: widget.teamId,
      sortBy: _sortBy,
    )));
  }

  void _showPlayerStats(MiniActivityPlayerStats stats) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerStatsScreen(
          teamId: widget.teamId,
          userId: stats.userId,
          userName: stats.userName,
        ),
      ),
    );
  }
}
