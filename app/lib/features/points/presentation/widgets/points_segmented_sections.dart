import 'package:flutter/material.dart';
import '../../../../data/models/points_config.dart';
import 'points_config_fields.dart';

/// Card with mini-activity distribution segmented button
class MiniActivityDistributionCard extends StatelessWidget {
  final MiniActivityDistribution value;
  final ValueChanged<MiniActivityDistribution> onChanged;

  const MiniActivityDistributionCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Mini-aktiviteter'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Poengfordeling',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<MiniActivityDistribution>(
                  segments: const [
                    ButtonSegment(
                      value: MiniActivityDistribution.winnerOnly,
                      label: Text('Kun vinner'),
                    ),
                    ButtonSegment(
                      value: MiniActivityDistribution.topThree,
                      label: Text('Topp 3'),
                    ),
                    ButtonSegment(
                      value: MiniActivityDistribution.allParticipants,
                      label: Text('Alle'),
                    ),
                  ],
                  selected: {value},
                  onSelectionChanged: (set) => onChanged(set.first),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Card with leaderboard visibility segmented button
class VisibilityCard extends StatelessWidget {
  final LeaderboardVisibility value;
  final ValueChanged<LeaderboardVisibility> onChanged;

  const VisibilityCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Synlighet'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hvem kan se poeng?',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<LeaderboardVisibility>(
                  segments: const [
                    ButtonSegment(
                      value: LeaderboardVisibility.all,
                      label: Text('Alle'),
                    ),
                    ButtonSegment(
                      value: LeaderboardVisibility.rankingOnly,
                      label: Text('Rangering'),
                    ),
                    ButtonSegment(
                      value: LeaderboardVisibility.ownOnly,
                      label: Text('Kun egen'),
                    ),
                  ],
                  selected: {value},
                  onSelectionChanged: (set) => onChanged(set.first),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Card with new player start mode segmented button
class NewPlayerStartCard extends StatelessWidget {
  final NewPlayerStartMode value;
  final ValueChanged<NewPlayerStartMode> onChanged;

  const NewPlayerStartCard({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Nye spillere'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starter med poeng fra',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<NewPlayerStartMode>(
                  segments: const [
                    ButtonSegment(
                      value: NewPlayerStartMode.fromJoin,
                      label: Text('Fra start'),
                    ),
                    ButtonSegment(
                      value: NewPlayerStartMode.wholeSeason,
                      label: Text('Hele sesong'),
                    ),
                    ButtonSegment(
                      value: NewPlayerStartMode.adminChooses,
                      label: Text('Admin velger'),
                    ),
                  ],
                  selected: {value},
                  onSelectionChanged: (set) => onChanged(set.first),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
