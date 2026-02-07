import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/team.dart';
import '../../providers/team_provider.dart';

class CollapsibleMembersSection extends ConsumerStatefulWidget {
  final List<TeamMember> members;
  final String teamId;
  final bool isAdmin;

  const CollapsibleMembersSection({
    super.key,
    required this.members,
    required this.teamId,
    required this.isAdmin,
  });

  @override
  ConsumerState<CollapsibleMembersSection> createState() => _CollapsibleMembersSectionState();
}

class _CollapsibleMembersSectionState extends ConsumerState<CollapsibleMembersSection> {
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
                onTap: () => context.pushNamed(
                  'player-profile',
                  pathParameters: {'teamId': widget.teamId, 'userId': member.userId},
                ),
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
      builder: (context) => MemberOptionsSheet(
        member: member,
        teamId: widget.teamId,
      ),
    );
  }
}

class MemberOptionsSheet extends ConsumerStatefulWidget {
  final TeamMember member;
  final String teamId;

  const MemberOptionsSheet({
    super.key,
    required this.member,
    required this.teamId,
  });

  @override
  ConsumerState<MemberOptionsSheet> createState() => _MemberOptionsSheetState();
}

class _MemberOptionsSheetState extends ConsumerState<MemberOptionsSheet> {
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
