import 'package:flutter/material.dart';
import '../../../../data/models/achievement.dart';

/// A stat item showing an icon, value, and label (used in the stats summary card).
class AchievementStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const AchievementStatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, size: 28, color: color ?? theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
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

/// A section grouping achievement definitions by category with a header.
class AchievementCategorySection extends StatelessWidget {
  final String teamId;
  final AchievementCategory category;
  final List<AchievementDefinition> definitions;
  final void Function(AchievementDefinition) onEdit;
  final void Function(AchievementDefinition) onDelete;
  final void Function(AchievementDefinition) onToggleActive;

  const AchievementCategorySection({
    super.key,
    required this.teamId,
    required this.category,
    required this.definitions,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                category.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${definitions.length})',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        ...definitions.map((def) => AchievementAdminCard(
              definition: def,
              onEdit: () => onEdit(def),
              onDelete: () => onDelete(def),
              onToggleActive: () => onToggleActive(def),
            )),
      ],
    );
  }
}

/// Card for displaying an achievement definition in the admin list,
/// with edit, toggle active, and delete actions.
class AchievementAdminCard extends StatelessWidget {
  final AchievementDefinition definition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const AchievementAdminCard({
    super.key,
    required this.definition,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: definition.isActive
                ? _getTierColor(definition.tier)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              definition.icon ?? definition.tier.emoji,
              style: TextStyle(
                fontSize: 24,
                color: definition.isActive ? null : theme.colorScheme.outline,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                definition.name,
                style: TextStyle(
                  color:
                      definition.isActive ? null : theme.colorScheme.outline,
                ),
              ),
            ),
            if (!definition.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Inaktiv',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
            if (definition.isSecret) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.visibility_off,
                size: 16,
                color: theme.colorScheme.outline,
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${definition.tier.displayName} \u2022 ${_getCriteriaText(definition.criteria)} \u2022 +${definition.bonusPoints}p',
          style: theme.textTheme.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'toggle':
                onToggleActive();
                break;
              case 'delete':
                onDelete();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Rediger'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: ListTile(
                leading: Icon(
                  definition.isActive ? Icons.pause : Icons.play_arrow,
                ),
                title: Text(
                    definition.isActive ? 'Deaktiver' : 'Aktiver'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title:
                    Text('Slett', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.bronze:
        return Colors.brown.shade200;
      case AchievementTier.silver:
        return Colors.grey.shade300;
      case AchievementTier.gold:
        return Colors.amber.shade200;
      case AchievementTier.platinum:
        return Colors.blue.shade100;
    }
  }

  String _getCriteriaText(AchievementCriteria criteria) {
    final threshold = criteria.threshold;
    switch (criteria.type) {
      case AchievementCriteriaType.attendanceStreak:
        return '$threshold p\u00e5 rad';
      case AchievementCriteriaType.attendanceTotal:
        return '$threshold oppm\u00f8ter';
      case AchievementCriteriaType.attendanceRate:
        return '${criteria.percentage ?? threshold}% oppm\u00f8te';
      case AchievementCriteriaType.pointsTotal:
        return '$threshold poeng';
      case AchievementCriteriaType.miniActivityWins:
        return '$threshold seire';
      case AchievementCriteriaType.perfectAttendance:
        return '100% oppm\u00f8te';
      case AchievementCriteriaType.socialEvents:
        return '$threshold sosiale';
      case AchievementCriteriaType.custom:
        return 'Egendefinert';
    }
  }
}
