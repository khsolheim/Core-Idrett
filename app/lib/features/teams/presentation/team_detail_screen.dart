import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/team.dart';
import '../providers/team_provider.dart';
import 'widgets/team_dashboard_body.dart';
import 'widgets/team_invite_dialog.dart';

class TeamDetailScreen extends ConsumerStatefulWidget {
  final String teamId;

  const TeamDetailScreen({super.key, required this.teamId});

  @override
  ConsumerState<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends ConsumerState<TeamDetailScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final teamAsync = ref.watch(teamDetailProvider(widget.teamId));
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));

    return Scaffold(
      body: teamAsync.when2(
        onRetry: () => ref.invalidate(teamDetailProvider(widget.teamId)),
        data: (team) {
          if (team == null) {
            return const Center(child: Text('Lag ikke funnet'));
          }

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(team.name),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Icon(
                            _getSportIcon(team.sport),
                            size: 48,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          if (team.sport != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              team.sport!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  if (team.userIsAdmin)
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () => _showInviteDialog(context, team),
                      tooltip: 'Inviter medlemmer',
                    ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => _showTeamSettings(context, team),
                    tooltip: 'Innstillinger',
                  ),
                ],
              ),
            ],
            body: DashboardBody(
              teamId: widget.teamId,
              team: team,
              membersAsync: membersAsync,
            ),
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              context.push('/teams/${widget.teamId}/activities');
              break;
            case 2:
              context.push('/teams/${widget.teamId}/leaderboard');
              break;
            case 3:
              context.push('/teams/${widget.teamId}/fines');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Hjem',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Aktiviteter',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Statistikk',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Bøter',
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(String? sport) {
    switch (sport?.toLowerCase()) {
      case 'fotball':
      case 'football':
      case 'soccer':
        return Icons.sports_soccer;
      case 'handball':
      case 'håndball':
        return Icons.sports_handball;
      case 'basketball':
      case 'basket':
        return Icons.sports_basketball;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'hockey':
      case 'ishockey':
        return Icons.sports_hockey;
      case 'tennis':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }

  void _showInviteDialog(BuildContext context, Team team) {
    showDialog(
      context: context,
      builder: (context) => TeamInviteDialog(teamId: widget.teamId, team: team),
    );
  }

  void _showTeamSettings(BuildContext context, Team team) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.event_available),
                title: const Text('Oppmote'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/teams/${widget.teamId}/attendance');
                },
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events),
                title: const Text('Achievements'),
                subtitle: const Text('Se badges og milepaeler'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/teams/${widget.teamId}/achievements');
                },
              ),
              if (team.userIsAdmin) ...[
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: const Text('Administrer achievements'),
                  subtitle: const Text('Opprett og rediger achievements'),
                  onTap: () {
                    Navigator.pop(context);
                    context.pushNamed(
                      'achievements-admin',
                      pathParameters: {'teamId': widget.teamId},
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sports_esports),
                  title: const Text('Mini-aktivitet maler'),
                  subtitle: const Text('Maler for raske konkurranser'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/teams/${widget.teamId}/templates');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Poenginnstillinger'),
                  subtitle: const Text('Konfigurer poengsystem'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/teams/${widget.teamId}/points-config');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.event_busy),
                  title: const Text('Fravaersadministrasjon'),
                  subtitle: const Text('Godkjenn fravaer'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/teams/${widget.teamId}/absence-management');
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Rediger lag'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/teams/${widget.teamId}/edit');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
