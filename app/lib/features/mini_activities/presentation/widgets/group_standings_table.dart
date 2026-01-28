import 'package:flutter/material.dart';
import '../../../../data/models/tournament.dart';

/// Table widget for displaying group standings
class GroupStandingsTable extends StatelessWidget {
  final TournamentGroup group;
  final VoidCallback? onTeamTap;

  const GroupStandingsTable({
    super.key,
    required this.group,
    this.onTeamTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final standings = group.sortedStandings;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Group header
          Container(
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.primaryContainer,
            child: Text(
              group.name,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                const SizedBox(width: 24), // Position
                const Expanded(flex: 3, child: Text('Lag', style: TextStyle(fontWeight: FontWeight.bold))),
                _HeaderCell('K', tooltip: 'Kamper'),
                _HeaderCell('S', tooltip: 'Seire'),
                _HeaderCell('U', tooltip: 'Uavgjort'),
                _HeaderCell('T', tooltip: 'Tap'),
                _HeaderCell('+/-', tooltip: 'Målforskjell'),
                _HeaderCell('P', tooltip: 'Poeng', highlighted: true),
              ],
            ),
          ),

          // Standings rows
          if (standings.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Ingen lag i gruppen',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...standings.asMap().entries.map((entry) {
              final index = entry.key;
              final standing = entry.value;
              final advances = index < group.advanceCount;

              return _StandingsRow(
                standing: standing,
                position: index + 1,
                advances: advances,
                isLast: index == standings.length - 1,
              );
            }),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final String? tooltip;
  final bool highlighted;

  const _HeaderCell(
    this.text, {
    this.tooltip,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final child = SizedBox(
      width: 32,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: highlighted ? theme.colorScheme.primary : null,
        ),
        textAlign: TextAlign.center,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: child);
    }
    return child;
  }
}

class _StandingsRow extends StatelessWidget {
  final GroupStanding standing;
  final int position;
  final bool advances;
  final bool isLast;

  const _StandingsRow({
    required this.standing,
    required this.position,
    required this.advances,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: advances ? theme.colorScheme.primaryContainer.withAlpha(77) : null,
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: theme.colorScheme.outlineVariant),
          left: advances
              ? BorderSide(color: theme.colorScheme.primary, width: 3)
              : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$position.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              standing.teamName ?? 'Lag ${standing.teamId.substring(0, 6)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: advances ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _StatCell('${standing.played}'),
          _StatCell('${standing.won}'),
          _StatCell('${standing.drawn}'),
          _StatCell('${standing.lost}'),
          _StatCell(standing.goalDifferenceDisplay),
          _StatCell(
            '${standing.points}',
            highlighted: true,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final bool highlighted;

  const _StatCell(
    this.value, {
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 32,
      child: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
          color: highlighted ? theme.colorScheme.primary : null,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Compact group card for overview
class GroupCard extends StatelessWidget {
  final TournamentGroup group;
  final VoidCallback? onTap;

  const GroupCard({
    super.key,
    required this.group,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final standings = group.sortedStandings;
    final topTeams = standings.take(group.advanceCount).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    group.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (topTeams.isEmpty)
                Text(
                  'Ingen lag',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                )
              else
                ...topTeams.asMap().entries.map((entry) {
                  final position = entry.key + 1;
                  final standing = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          child: Text(
                            '$position.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            standing.teamName ?? 'Lag',
                            style: theme.textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${standing.points}p',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
