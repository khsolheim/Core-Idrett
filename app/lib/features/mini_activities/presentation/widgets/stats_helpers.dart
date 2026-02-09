import 'package:flutter/material.dart';

/// Single stat label/value display
class StatsItem extends StatelessWidget {
  final String label;
  final String value;

  const StatsItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Badge showing podium position and count
class PodiumBadge extends StatelessWidget {
  final int position;
  final int count;

  const PodiumBadge({
    super.key,
    required this.position,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    final emoji = switch (position) {
      1 => '\u{1F947}',
      2 => '\u{1F948}',
      3 => '\u{1F949}',
      _ => '',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text(
          'x$count',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
