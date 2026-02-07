import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/team.dart';
import '../../providers/team_provider.dart';
import '../../providers/dashboard_provider.dart';
import 'dashboard_widgets.dart';
import 'dashboard_info_widgets.dart';
import 'team_members_section.dart';

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardBody extends ConsumerWidget {
  final String teamId;
  final Team team;
  final AsyncValue<List<TeamMember>> membersAsync;

  const DashboardBody({
    super.key,
    required this.teamId,
    required this.team,
    required this.membersAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider(teamId));
    final isAdmin = team.userIsAdmin;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardProvider(teamId));
        ref.invalidate(teamMembersProvider(teamId));
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick action buttons
          Row(
            children: [
              QuickActionButton(
                icon: Icons.calendar_today,
                label: 'Aktiviteter',
                onTap: () => context.pushNamed('activities', pathParameters: {'teamId': teamId}),
              ),
              const SizedBox(width: 12),
              QuickActionButton(
                icon: Icons.leaderboard,
                label: 'Statistikk',
                onTap: () => context.pushNamed('leaderboard', pathParameters: {'teamId': teamId}),
              ),
              const SizedBox(width: 12),
              QuickActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Botekasse',
                onTap: () => context.pushNamed('fines', pathParameters: {'teamId': teamId}),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dashboard widgets
          dashboardAsync.when2(
            onRetry: () => ref.invalidate(dashboardProvider(teamId)),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            data: (dashboard) => Column(
              children: [
                // Next activity
                NextActivityWidget(
                  activity: dashboard.nextActivity,
                  teamId: teamId,
                ),
                const SizedBox(height: 12),

                // Messages and Fines in a row
                Row(
                  children: [
                    Expanded(
                      child: MessagesWidget(
                        unreadCount: dashboard.unreadMessages,
                        teamId: teamId,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FinesWidget(
                        summary: dashboard.finesSummary,
                        teamId: teamId,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Leaderboard
                LeaderboardWidget(
                  entries: dashboard.topLeaderboard,
                  teamId: teamId,
                ),
                const SizedBox(height: 12),

                // Quick links
                QuickLinksWidget(
                  teamId: teamId,
                  isAdmin: isAdmin,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Members section
          membersAsync.when2(
            onRetry: () => ref.invalidate(teamMembersProvider(teamId)),
            data: (members) => CollapsibleMembersSection(
              members: members,
              teamId: teamId,
              isAdmin: isAdmin,
            ),
          ),
        ],
      ),
    );
  }
}
