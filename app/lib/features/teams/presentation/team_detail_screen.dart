import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/team.dart';
import '../providers/team_provider.dart';

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
      body: teamAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Feil: $e')),
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
                  if (team.userRole == TeamRole.admin)
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
            body: Column(
              children: [
                // Quick action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _QuickActionButton(
                        icon: Icons.calendar_today,
                        label: 'Aktiviteter',
                        onTap: () => context.push('/teams/${widget.teamId}/activities'),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        icon: Icons.leaderboard,
                        label: 'Statistikk',
                        onTap: () => context.push('/teams/${widget.teamId}/leaderboard'),
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        icon: Icons.account_balance_wallet,
                        label: 'Bøtekasse',
                        onTap: () => context.push('/teams/${widget.teamId}/fines'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Members section
                Expanded(
                  child: membersAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Feil: $e')),
                    data: (members) => _MembersList(
                      members: members,
                      teamId: widget.teamId,
                      currentUserRole: team.userRole,
                    ),
                  ),
                ),
              ],
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
      builder: (context) => _InviteDialog(teamId: widget.teamId, team: team),
    );
  }

  void _showTeamSettings(BuildContext context, Team team) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Aktivitetsmaler'),
              onTap: () {
                Navigator.pop(context);
                context.push('/teams/${widget.teamId}/templates');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available),
              title: const Text('Oppmøte'),
              onTap: () {
                Navigator.pop(context);
                context.push('/teams/${widget.teamId}/attendance');
              },
            ),
            if (team.userRole == TeamRole.admin) ...[
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
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
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

class _MembersList extends StatelessWidget {
  final List<TeamMember> members;
  final String teamId;
  final TeamRole? currentUserRole;

  const _MembersList({
    required this.members,
    required this.teamId,
    required this.currentUserRole,
  });

  @override
  Widget build(BuildContext context) {
    final admins = members.where((m) => m.role == TeamRole.admin).toList();
    final fineBosses = members.where((m) => m.role == TeamRole.fineBoss).toList();
    final players = members.where((m) => m.role == TeamRole.player).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Medlemmer (${members.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (admins.isNotEmpty) ...[
          _RoleHeader(role: 'Administratorer', count: admins.length),
          ...admins.map((m) => _MemberTile(
                member: m,
                teamId: teamId,
                canManage: currentUserRole == TeamRole.admin,
              )),
          const SizedBox(height: 8),
        ],
        if (fineBosses.isNotEmpty) ...[
          _RoleHeader(role: 'Bøtesjefer', count: fineBosses.length),
          ...fineBosses.map((m) => _MemberTile(
                member: m,
                teamId: teamId,
                canManage: currentUserRole == TeamRole.admin,
              )),
          const SizedBox(height: 8),
        ],
        if (players.isNotEmpty) ...[
          _RoleHeader(role: 'Spillere', count: players.length),
          ...players.map((m) => _MemberTile(
                member: m,
                teamId: teamId,
                canManage: currentUserRole == TeamRole.admin,
              )),
        ],
      ],
    );
  }
}

class _RoleHeader extends StatelessWidget {
  final String role;
  final int count;

  const _RoleHeader({required this.role, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        '$role ($count)',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final TeamMember member;
  final String teamId;
  final bool canManage;

  const _MemberTile({
    required this.member,
    required this.teamId,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: member.userAvatarUrl != null
              ? NetworkImage(member.userAvatarUrl!)
              : null,
          child: member.userAvatarUrl == null
              ? Text(member.userName.substring(0, 1).toUpperCase())
              : null,
        ),
        title: Text(member.userName),
        subtitle: Text(member.role.displayName),
        trailing: canManage && member.role != TeamRole.admin
            ? PopupMenuButton<TeamRole>(
                onSelected: (role) => _changeRole(context, ref, role),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: TeamRole.admin,
                    child: Text('Gjør til administrator'),
                  ),
                  const PopupMenuItem(
                    value: TeamRole.fineBoss,
                    child: Text('Gjør til bøtesjef'),
                  ),
                  const PopupMenuItem(
                    value: TeamRole.player,
                    child: Text('Gjør til spiller'),
                  ),
                ],
              )
            : null,
        onTap: () => context.push('/teams/$teamId/player/${member.userId}'),
      ),
    );
  }

  void _changeRole(BuildContext context, WidgetRef ref, TeamRole role) async {
    final success = await ref.read(teamNotifierProvider.notifier).updateMemberRole(
          teamId: teamId,
          memberId: member.id,
          role: role,
        );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.userName} er nå ${role.displayName.toLowerCase()}')),
      );
    }
  }
}

class _InviteDialog extends ConsumerStatefulWidget {
  final String teamId;
  final Team team;

  const _InviteDialog({required this.teamId, required this.team});

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  String? _inviteCode;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _inviteCode = widget.team.inviteCode;
  }

  @override
  Widget build(BuildContext context) {
    final inviteUrl = _inviteCode != null
        ? 'https://core-idrett.app/invite/$_inviteCode'
        : null;

    return AlertDialog(
      title: const Text('Inviter medlemmer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Del denne lenken med de du vil invitere:'),
          const SizedBox(height: 16),
          if (_inviteCode != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inviteUrl!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lenke kopiert!')),
                      );
                    },
                  ),
                ],
              ),
            )
          else
            const Text('Ingen invitasjonskode generert enda.'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Lukk'),
        ),
        TextButton(
          onPressed: _loading ? null : _generateNewCode,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_inviteCode != null ? 'Ny kode' : 'Generer kode'),
        ),
      ],
    );
  }

  Future<void> _generateNewCode() async {
    setState(() => _loading = true);
    final code = await ref.read(teamNotifierProvider.notifier).generateInviteCode(widget.teamId);
    if (mounted) {
      setState(() {
        _inviteCode = code;
        _loading = false;
      });
    }
  }
}
