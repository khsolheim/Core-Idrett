import 'package:flutter/material.dart';
import '../../../../data/models/activity.dart';

class TypeChip extends StatelessWidget {
  final ActivityType type;

  const TypeChip({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_getIcon(), size: 18),
      label: Text(type.displayName),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ActivityType.training:
        return Icons.fitness_center;
      case ActivityType.match:
        return Icons.sports_soccer;
      case ActivityType.social:
        return Icons.celebration;
      case ActivityType.other:
        return Icons.event;
    }
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
