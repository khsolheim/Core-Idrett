import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/achievement.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/achievement_provider.dart';
import 'create_edit_achievement_sheet.dart';

/// Admin screen for managing team-specific achievements
class AchievementAdminScreen extends ConsumerWidget {
  final String teamId;

  const AchievementAdminScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final definitionsAsync = ref.watch(achievementDefinitionsProvider((
      teamId: teamId,
      includeGlobal: false,
      activeOnly: false,
      category: null,
    )));

    final isAdmin = teamAsync.value?.userIsAdmin ?? false;

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Achievements Admin')),
        body: const Center(
          child: Text('Du har ikke tilgang til denne siden'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrer Achievements'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ny achievement'),
      ),
      body: definitionsAsync.when2(
        onRetry: () => ref.invalidate(achievementDefinitionsProvider((
          teamId: teamId,
          includeGlobal: false,
          activeOnly: false,
          category: null,
        ))),
        data: (definitions) {
          if (definitions.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.emoji_events_outlined,
              title: 'Ingen egendefinerte achievements',
              subtitle: 'Trykk + for å opprette en ny',
            );
          }

          // Group by category
          final grouped = <AchievementCategory, List<AchievementDefinition>>{};
          for (final def in definitions) {
            grouped.putIfAbsent(def.category, () => []).add(def);
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(achievementDefinitionsProvider((
                teamId: teamId,
                includeGlobal: false,
                activeOnly: false,
                category: null,
              )));
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // Stats card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: 'Totalt',
                            value: definitions.length.toString(),
                            icon: Icons.emoji_events,
                          ),
                          _StatItem(
                            label: 'Aktive',
                            value: definitions.where((d) => d.isActive).length.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _StatItem(
                            label: 'Inaktive',
                            value: definitions.where((d) => !d.isActive).length.toString(),
                            icon: Icons.pause_circle,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Grouped lists
                ...grouped.entries.map((entry) => _CategorySection(
                      teamId: teamId,
                      category: entry.key,
                      definitions: entry.value,
                      onEdit: (def) => _showEditSheet(context, ref, def),
                      onDelete: (def) => _confirmDelete(context, ref, def),
                      onToggleActive: (def) => _toggleActive(ref, def),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CreateEditAchievementSheet(
        teamId: teamId,
      ),
    );
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    AchievementDefinition definition,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CreateEditAchievementSheet(
        teamId: teamId,
        existingDefinition: definition,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AchievementDefinition definition,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett achievement?'),
        content: Text(
          'Er du sikker på at du vil slette "${definition.name}"? '
          'Spillere som allerede har oppnådd denne vil beholde den.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Slett'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(achievementDefinitionNotifierProvider.notifier)
          .deleteDefinition(teamId, definition.id);

      if (success) {
        ErrorDisplayService.showSuccess('Achievement slettet');
      } else {
        ErrorDisplayService.showWarning('Kunne ikke slette achievement');
      }
    }
  }

  Future<void> _toggleActive(WidgetRef ref, AchievementDefinition definition) async {
    final result = await ref
        .read(achievementDefinitionNotifierProvider.notifier)
        .updateDefinition(
          teamId: teamId,
          definitionId: definition.id,
          isActive: !definition.isActive,
        );

    if (result != null) {
      ErrorDisplayService.showSuccess(
        definition.isActive ? 'Achievement deaktivert' : 'Achievement aktivert',
      );
    } else {
      ErrorDisplayService.showWarning('Kunne ikke oppdatere achievement');
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
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

class _CategorySection extends StatelessWidget {
  final String teamId;
  final AchievementCategory category;
  final List<AchievementDefinition> definitions;
  final void Function(AchievementDefinition) onEdit;
  final void Function(AchievementDefinition) onDelete;
  final void Function(AchievementDefinition) onToggleActive;

  const _CategorySection({
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
        ...definitions.map((def) => _AchievementAdminCard(
              definition: def,
              onEdit: () => onEdit(def),
              onDelete: () => onDelete(def),
              onToggleActive: () => onToggleActive(def),
            )),
      ],
    );
  }
}

class _AchievementAdminCard extends StatelessWidget {
  final AchievementDefinition definition;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _AchievementAdminCard({
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
                  color: definition.isActive ? null : theme.colorScheme.outline,
                ),
              ),
            ),
            if (!definition.isActive) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          '${definition.tier.displayName} • ${_getCriteriaText(definition.criteria)} • +${definition.bonusPoints}p',
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
                title: Text(definition.isActive ? 'Deaktiver' : 'Aktiver'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Slett', style: TextStyle(color: Colors.red)),
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
        return '$threshold på rad';
      case AchievementCriteriaType.attendanceTotal:
        return '$threshold oppmøter';
      case AchievementCriteriaType.attendanceRate:
        return '${criteria.percentage ?? threshold}% oppmøte';
      case AchievementCriteriaType.pointsTotal:
        return '$threshold poeng';
      case AchievementCriteriaType.miniActivityWins:
        return '$threshold seire';
      case AchievementCriteriaType.perfectAttendance:
        return '100% oppmøte';
      case AchievementCriteriaType.socialEvents:
        return '$threshold sosiale';
      case AchievementCriteriaType.custom:
        return 'Egendefinert';
    }
  }
}
