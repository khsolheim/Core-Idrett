import 'package:flutter/material.dart';
import '../../../../data/models/mini_activity.dart';

/// Card for displaying a bonus/penalty adjustment
class AdjustmentCard extends StatelessWidget {
  final MiniActivityAdjustment adjustment;
  final VoidCallback? onDelete;

  const AdjustmentCard({
    super.key,
    required this.adjustment,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBonus = adjustment.isBonus;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isBonus
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isBonus ? Icons.add_circle : Icons.remove_circle,
                color: isBonus ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    adjustment.displayDescription,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    adjustment.targetDisplay,
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
                color: isBonus
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                adjustment.formattedPoints,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isBonus ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
            ),

            // Delete button
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                onPressed: onDelete,
                tooltip: 'Slett',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// List of adjustments
class AdjustmentsList extends StatelessWidget {
  final List<MiniActivityAdjustment> adjustments;
  final Function(MiniActivityAdjustment)? onDelete;
  final VoidCallback? onAdd;

  const AdjustmentsList({
    super.key,
    required this.adjustments,
    this.onDelete,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bonuser og straffer',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            if (onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Legg til'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (adjustments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ingen bonuser eller straffer',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...adjustments.map((adj) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AdjustmentCard(
                  adjustment: adj,
                  onDelete: onDelete != null ? () => onDelete!(adj) : null,
                ),
              )),
      ],
    );
  }
}

/// Handicap row display
class HandicapRow extends StatelessWidget {
  final MiniActivityHandicap handicap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HandicapRow({
    super.key,
    required this.handicap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            child: Text(
              handicap.userName?.substring(0, 1).toUpperCase() ?? '?',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              handicap.userName ?? 'Ukjent',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              handicap.formattedHandicap,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: 'Rediger',
            ),
          if (onDelete != null)
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: theme.colorScheme.error,
              ),
              onPressed: onDelete,
              tooltip: 'Fjern',
            ),
        ],
      ),
    );
  }
}

/// List of handicaps
class HandicapsList extends StatelessWidget {
  final List<MiniActivityHandicap> handicaps;
  final Function(MiniActivityHandicap)? onEdit;
  final Function(MiniActivityHandicap)? onDelete;
  final VoidCallback? onAdd;

  const HandicapsList({
    super.key,
    required this.handicaps,
    this.onEdit,
    this.onDelete,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Handicap',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            if (onAdd != null)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Legg til'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          clipBehavior: Clip.antiAlias,
          child: handicaps.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.balance_outlined,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ingen handicap satt',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: handicaps
                      .map((h) => HandicapRow(
                            handicap: h,
                            onEdit: onEdit != null ? () => onEdit!(h) : null,
                            onDelete: onDelete != null ? () => onDelete!(h) : null,
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}
