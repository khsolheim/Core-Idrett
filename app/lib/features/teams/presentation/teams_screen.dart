import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/team.dart';
import '../providers/team_provider.dart';
import '../../auth/providers/auth_provider.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsProvider);
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mine lag'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => _showProfileSheet(context, ref, user),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teamsProvider);
        },
        child: teamsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Feil: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(teamsProvider),
                  child: const Text('Prøv igjen'),
                ),
              ],
            ),
          ),
          data: (teams) {
            if (teams.isEmpty) {
              return _EmptyState(
                onCreateTeam: () => context.goNamed('create-team'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return _TeamCard(
                  team: team,
                  onTap: () => context.push('/teams/${team.id}'),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed('create-team'),
        icon: const Icon(Icons.add),
        label: const Text('Nytt lag'),
      ),
    );
  }

  void _showProfileSheet(BuildContext context, WidgetRef ref, dynamic user) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Text(
                      user?.name?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(fontSize: 32),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'Bruker',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              user?.email ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Innstillinger'),
              onTap: () {
                Navigator.pop(context);
                context.push('/settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logg ut', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authStateProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreateTeam;

  const _EmptyState({required this.onCreateTeam});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Ingen lag enda',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Opprett et lag eller bli invitert av noen andre',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateTeam,
              icon: const Icon(Icons.add),
              label: const Text('Opprett lag'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getSportIcon(team.sport),
                  size: 28,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (team.sport != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        team.sport!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (team.userRole != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(team.userRole!).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          team.userRole!.displayName,
                          style: TextStyle(
                            color: _getRoleColor(team.userRole!),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
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

  Color _getRoleColor(TeamRole role) {
    switch (role) {
      case TeamRole.admin:
        return Colors.blue;
      case TeamRole.fineBoss:
        return Colors.orange;
      case TeamRole.player:
        return Colors.green;
    }
  }
}
