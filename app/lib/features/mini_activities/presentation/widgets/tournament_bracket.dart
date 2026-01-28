import 'package:flutter/material.dart';
import '../../../../data/models/tournament.dart';
import 'match_card.dart';

/// Widget for displaying a tournament bracket (single/double elimination)
class TournamentBracket extends StatelessWidget {
  final Tournament tournament;
  final List<TournamentRound> rounds;
  final List<TournamentMatch> matches;
  final Function(TournamentMatch)? onMatchTap;

  const TournamentBracket({
    super.key,
    required this.tournament,
    required this.rounds,
    required this.matches,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (rounds.isEmpty) {
      return _EmptyBracket(tournament: tournament);
    }

    final winnersRounds = rounds.where((r) => r.roundType == RoundType.winners).toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    final losersRounds = rounds.where((r) => r.roundType == RoundType.losers).toList()
      ..sort((a, b) => a.roundNumber.compareTo(b.roundNumber));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Winners bracket
              if (winnersRounds.isNotEmpty) ...[
                Text(
                  tournament.tournamentType == TournamentType.doubleElimination
                      ? 'Vinner-bracket'
                      : 'Sluttspill',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _BracketView(
                  rounds: winnersRounds,
                  matches: matches,
                  onMatchTap: onMatchTap,
                ),
              ],

              // Losers bracket (double elimination only)
              if (losersRounds.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Taper-bracket',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _BracketView(
                  rounds: losersRounds,
                  matches: matches,
                  onMatchTap: onMatchTap,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BracketView extends StatelessWidget {
  final List<TournamentRound> rounds;
  final List<TournamentMatch> matches;
  final Function(TournamentMatch)? onMatchTap;

  const _BracketView({
    required this.rounds,
    required this.matches,
    this.onMatchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rounds.asMap().entries.map((entry) {
        final index = entry.key;
        final round = entry.value;
        final roundMatches = matches
            .where((m) => m.roundId == round.id)
            .toList()
          ..sort((a, b) => a.matchOrder.compareTo(b.matchOrder));

        // Calculate spacing based on round depth
        final spacing = 20.0 * (index + 1);

        return Padding(
          padding: EdgeInsets.only(right: index < rounds.length - 1 ? 24 : 0),
          child: Column(
            children: [
              // Round header
              Container(
                width: 160,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  round.roundName,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),

              // Matches
              ...roundMatches.asMap().entries.map((matchEntry) {
                final matchIndex = matchEntry.key;
                final match = matchEntry.value;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: matchIndex < roundMatches.length - 1 ? spacing : 0,
                  ),
                  child: CompactMatchCard(
                    match: match,
                    onTap: onMatchTap != null ? () => onMatchTap!(match) : null,
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyBracket extends StatelessWidget {
  final Tournament tournament;

  const _EmptyBracket({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Bracket ikke generert',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generer bracket for å starte turneringen',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple bracket overview card
class BracketOverviewCard extends StatelessWidget {
  final Tournament tournament;
  final int totalMatches;
  final int completedMatches;
  final VoidCallback? onTap;

  const BracketOverviewCard({
    super.key,
    required this.tournament,
    required this.totalMatches,
    required this.completedMatches,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalMatches > 0 ? completedMatches / totalMatches : 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_tree,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tournament.tournamentType.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _StatusChip(status: tournament.status),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    '$completedMatches / $totalMatches kamper',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                  if (tournament.bestOf > 1)
                    Text(
                      'Best of ${tournament.bestOf}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TournamentStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, bgColor) = _getColors(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  (Color, Color) _getColors(ThemeData theme) {
    switch (status) {
      case TournamentStatus.draft:
        return (theme.colorScheme.outline, theme.colorScheme.surfaceContainerHighest);
      case TournamentStatus.registration:
        return (theme.colorScheme.primary, theme.colorScheme.primaryContainer);
      case TournamentStatus.seeding:
        return (theme.colorScheme.secondary, theme.colorScheme.secondaryContainer);
      case TournamentStatus.inProgress:
        return (theme.colorScheme.tertiary, theme.colorScheme.tertiaryContainer);
      case TournamentStatus.completed:
        return (Colors.green.shade700, Colors.green.shade100);
      case TournamentStatus.cancelled:
        return (theme.colorScheme.error, theme.colorScheme.errorContainer);
    }
  }
}
