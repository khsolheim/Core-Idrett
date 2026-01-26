import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/statistics.dart';
import '../providers/statistics_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  final String teamId;

  const LeaderboardScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Poengtavle'),
      ),
      body: leaderboardAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.leaderboard_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ingen poeng ennå',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Delta i aktiviteter for å tjene poeng',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaderboardProvider(teamId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                return _LeaderboardCard(entry: entries[index]);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Kunne ikke laste poengtavle: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(leaderboardProvider(teamId)),
                child: const Text('Prøv igjen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const _LeaderboardCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Rank
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getRankColor(entry.rank, theme),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: entry.rank <= 3 ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              backgroundImage: entry.userAvatarUrl != null ? NetworkImage(entry.userAvatarUrl!) : null,
              child: entry.userAvatarUrl == null
                  ? Text(entry.userName.substring(0, 1).toUpperCase())
                  : null,
            ),
            const SizedBox(width: 12),

            // Name and stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.userName,
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    'Rating: ${entry.rating.round()} • ${entry.wins}V/${entry.draws}U/${entry.losses}T',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),

            // Points
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${entry.totalPoints}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank, ThemeData theme) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.brown.shade300;
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }
}
