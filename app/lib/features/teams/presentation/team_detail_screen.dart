import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/team.dart';
import '../providers/team_provider.dart';
import '../providers/dashboard_provider.dart';
import 'widgets/dashboard_widgets.dart';

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
            body: _DashboardBody(
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
      builder: (context) => _InviteDialog(teamId: widget.teamId, team: team),
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

class _DashboardBody extends ConsumerWidget {
  final String teamId;
  final Team team;
  final AsyncValue<List<TeamMember>> membersAsync;

  const _DashboardBody({
    required this.teamId,
    required this.team,
    required this.membersAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider(teamId));
    final isAdmin = team.userRole == TeamRole.admin;

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
              _QuickActionButton(
                icon: Icons.calendar_today,
                label: 'Aktiviteter',
                onTap: () => context.push('/teams/$teamId/activities'),
              ),
              const SizedBox(width: 12),
              _QuickActionButton(
                icon: Icons.leaderboard,
                label: 'Statistikk',
                onTap: () => context.push('/teams/$teamId/leaderboard'),
              ),
              const SizedBox(width: 12),
              _QuickActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Botekasse',
                onTap: () => context.push('/teams/$teamId/fines'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dashboard widgets
          dashboardAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Kunne ikke laste dashboard: $e'),
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
          membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Feil: $e')),
            data: (members) => _CollapsibleMembersSection(
              members: members,
              teamId: teamId,
              currentUserRole: team.userRole,
              isAdmin: isAdmin,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleMembersSection extends ConsumerStatefulWidget {
  final List<TeamMember> members;
  final String teamId;
  final TeamRole? currentUserRole;
  final bool isAdmin;

  const _CollapsibleMembersSection({
    required this.members,
    required this.teamId,
    required this.currentUserRole,
    required this.isAdmin,
  });

  @override
  ConsumerState<_CollapsibleMembersSection> createState() => _CollapsibleMembersSectionState();
}

class _CollapsibleMembersSectionState extends ConsumerState<_CollapsibleMembersSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayMembers = _expanded ? widget.members : widget.members.take(3).toList();

    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.people, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Medlemmer (${widget.members.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (displayMembers.isNotEmpty) const Divider(height: 1),
          ...displayMembers.map((member) => ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundImage: member.userAvatarUrl != null
                      ? NetworkImage(member.userAvatarUrl!)
                      : null,
                  child: member.userAvatarUrl == null
                      ? Text(
                          member.userName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 14),
                        )
                      : null,
                ),
                title: Text(member.userName),
                subtitle: Text(
                  member.roleDisplayName,
                  style: theme.textTheme.bodySmall,
                ),
                trailing: widget.isAdmin
                    ? IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: theme.colorScheme.outline,
                        ),
                        onPressed: () => _showMemberOptions(context, member),
                      )
                    : Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.outline,
                      ),
                onTap: () => context.push('/teams/${widget.teamId}/player/${member.userId}'),
              )),
          if (!_expanded && widget.members.length > 3)
            TextButton(
              onPressed: () => setState(() => _expanded = true),
              child: Text('Vis alle ${widget.members.length} medlemmer'),
            ),
        ],
      ),
    );
  }

  void _showMemberOptions(BuildContext context, TeamMember member) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MemberOptionsSheet(
        member: member,
        teamId: widget.teamId,
      ),
    );
  }
}

class _MemberOptionsSheet extends ConsumerStatefulWidget {
  final TeamMember member;
  final String teamId;

  const _MemberOptionsSheet({
    required this.member,
    required this.teamId,
  });

  @override
  ConsumerState<_MemberOptionsSheet> createState() => _MemberOptionsSheetState();
}

class _MemberOptionsSheetState extends ConsumerState<_MemberOptionsSheet> {
  late bool _isAdmin;
  late bool _isCoach;
  late bool _isFineBoss;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isAdmin = widget.member.isAdmin;
    _isCoach = widget.member.isCoach;
    _isFineBoss = widget.member.isFineBoss;
  }

  Future<void> _saveChanges() async {
    // Only save if something changed
    if (_isAdmin == widget.member.isAdmin &&
        _isCoach == widget.member.isCoach &&
        _isFineBoss == widget.member.isFineBoss) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isLoading = true);

    final success = await ref.read(teamNotifierProvider.notifier).updateMemberPermissions(
          teamId: widget.teamId,
          memberId: widget.member.id,
          isAdmin: _isAdmin != widget.member.isAdmin ? _isAdmin : null,
          isCoach: _isCoach != widget.member.isCoach ? _isCoach : null,
          isFineBoss: _isFineBoss != widget.member.isFineBoss ? _isFineBoss : null,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tilganger oppdatert')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke oppdatere tilganger')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: widget.member.userAvatarUrl != null
                      ? NetworkImage(widget.member.userAvatarUrl!)
                      : null,
                  child: widget.member.userAvatarUrl == null
                      ? Text(widget.member.userName.substring(0, 1).toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.member.userName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'Administrer tilganger',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              value: _isAdmin,
              onChanged: (value) => setState(() => _isAdmin = value),
              title: const Text('Administrator'),
              subtitle: const Text('Full tilgang til alle funksjoner'),
              secondary: const Icon(Icons.admin_panel_settings),
            ),
            SwitchListTile(
              value: _isCoach,
              onChanged: (value) => setState(() => _isCoach = value),
              title: const Text('Trener'),
              subtitle: const Text('Kan opprette og administrere aktiviteter'),
              secondary: const Icon(Icons.sports),
            ),
            SwitchListTile(
              value: _isFineBoss,
              onChanged: (value) => setState(() => _isFineBoss = value),
              title: const Text('Botesjef'),
              subtitle: const Text('Kan administrere bøter'),
              secondary: const Icon(Icons.account_balance_wallet),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Lagre endringer'),
              ),
            ),
          ],
        ),
      ),
    );
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
