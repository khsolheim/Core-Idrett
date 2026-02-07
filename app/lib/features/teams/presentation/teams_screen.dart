import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/team.dart';
import '../../../shared/widgets/widgets.dart';
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
        child: teamsAsync.when2(
          onRetry: () => ref.invalidate(teamsProvider),
          data: (teams) {
            if (teams.isEmpty) {
              return EmptyStateWidget(
                icon: Icons.groups_outlined,
                title: 'Ingen lag enda',
                subtitle: 'Opprett et lag eller bli invitert av noen andre',
                action: ElevatedButton.icon(
                  onPressed: () => context.goNamed('create-team'),
                  icon: const Icon(Icons.add),
                  label: const Text('Opprett lag'),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                return _TeamCard(
                  key: ValueKey(team.id),
                  team: team,
                  onTap: () => context.pushNamed('team-detail', pathParameters: {'teamId': team.id}),
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
                  ? CachedNetworkImageProvider(user.avatarUrl!)
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
                context.pushNamed('settings');
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

class _TeamCard extends StatelessWidget {
  final Team team;
  final VoidCallback onTap;

  const _TeamCard({super.key, required this.team, required this.onTap});

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
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRoleColor(team.userRoleColorKey).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        team.userRoleDisplayName,
                        style: TextStyle(
                          color: _getRoleColor(team.userRoleColorKey),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
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

  Color _getRoleColor(String roleKey) {
    switch (roleKey) {
      case 'admin':
        return Colors.blue;
      case 'coach':
        return Colors.teal;
      case 'fineBoss':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
