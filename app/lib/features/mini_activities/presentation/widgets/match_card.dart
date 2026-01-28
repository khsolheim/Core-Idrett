import 'package:flutter/material.dart';
import '../../../../data/models/tournament.dart';

/// Card widget for displaying a tournament match
class MatchCard extends StatelessWidget {
  final TournamentMatch match;
  final VoidCallback? onTap;
  final VoidCallback? onRecordResult;
  final bool showRoundInfo;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.onRecordResult,
    this.showRoundInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = match.isComplete;
    final hasTeams = match.hasTeams;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasTeams ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status badge
              Row(
                children: [
                  _StatusBadge(status: match.status),
                  const Spacer(),
                  if (match.isWalkover)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'W/O',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Teams
              _TeamRow(
                teamName: match.teamAName ?? 'TBD',
                score: hasTeams ? match.teamAScore : null,
                isWinner: match.winnerId == match.teamAId,
                isComplete: isComplete,
              ),
              const SizedBox(height: 8),
              _TeamRow(
                teamName: match.teamBName ?? 'TBD',
                score: hasTeams ? match.teamBScore : null,
                isWinner: match.winnerId == match.teamBId,
                isComplete: isComplete,
              ),

              // Actions
              if (hasTeams && match.status.isPlayable && onRecordResult != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onRecordResult,
                    child: Text(
                      match.status == MatchStatus.inProgress
                          ? 'Oppdater resultat'
                          : 'Registrer resultat',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MatchStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, bgColor) = _getColors(theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
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
      case MatchStatus.pending:
        return (theme.colorScheme.outline, theme.colorScheme.surfaceContainerHighest);
      case MatchStatus.scheduled:
        return (theme.colorScheme.primary, theme.colorScheme.primaryContainer);
      case MatchStatus.inProgress:
        return (theme.colorScheme.tertiary, theme.colorScheme.tertiaryContainer);
      case MatchStatus.completed:
        return (theme.colorScheme.primary, theme.colorScheme.primaryContainer);
      case MatchStatus.walkover:
        return (theme.colorScheme.error, theme.colorScheme.errorContainer);
      case MatchStatus.cancelled:
        return (theme.colorScheme.error, theme.colorScheme.errorContainer);
    }
  }
}

class _TeamRow extends StatelessWidget {
  final String teamName;
  final int? score;
  final bool isWinner;
  final bool isComplete;

  const _TeamRow({
    required this.teamName,
    this.score,
    required this.isWinner,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTbd = teamName == 'TBD';

    return Row(
      children: [
        if (isComplete && isWinner)
          Icon(
            Icons.emoji_events,
            size: 16,
            color: Colors.amber.shade700,
          )
        else
          const SizedBox(width: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            teamName,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              color: isTbd ? theme.colorScheme.outline : null,
              fontStyle: isTbd ? FontStyle.italic : null,
            ),
          ),
        ),
        if (score != null)
          Container(
            width: 32,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: isWinner && isComplete
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$score',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isWinner && isComplete
                    ? theme.colorScheme.onPrimaryContainer
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact match card for bracket view
class CompactMatchCard extends StatelessWidget {
  final TournamentMatch match;
  final VoidCallback? onTap;
  final double width;

  const CompactMatchCard({
    super.key,
    required this.match,
    this.onTap,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isComplete = match.isComplete;

    return SizedBox(
      width: width,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CompactTeamRow(
                teamName: match.teamAName ?? 'TBD',
                score: match.teamAScore,
                isWinner: match.winnerId == match.teamAId && isComplete,
                isTop: true,
                theme: theme,
              ),
              Divider(height: 1, color: theme.colorScheme.outlineVariant),
              _CompactTeamRow(
                teamName: match.teamBName ?? 'TBD',
                score: match.teamBScore,
                isWinner: match.winnerId == match.teamBId && isComplete,
                isTop: false,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactTeamRow extends StatelessWidget {
  final String teamName;
  final int score;
  final bool isWinner;
  final bool isTop;
  final ThemeData theme;

  const _CompactTeamRow({
    required this.teamName,
    required this.score,
    required this.isWinner,
    required this.isTop,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isTbd = teamName == 'TBD';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isWinner ? theme.colorScheme.primaryContainer.withAlpha(128) : null,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(12) : Radius.zero,
          bottom: !isTop ? const Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              teamName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isTbd ? theme.colorScheme.outline : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$score',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
