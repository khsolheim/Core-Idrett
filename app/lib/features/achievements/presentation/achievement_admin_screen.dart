import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/achievement.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/achievement_provider.dart';
import 'create_edit_achievement_sheet.dart';
import 'widgets/achievement_admin_widgets.dart';

/// Admin screen for managing team-specific achievements
class AchievementAdminScreen extends ConsumerWidget {
  final String teamId;

  const AchievementAdminScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(
      teamDetailProvider(teamId).select((t) => t.value?.userIsAdmin ?? false),
    );
    final definitionsAsync = ref.watch(achievementDefinitionsProvider((
      teamId: teamId,
      includeGlobal: false,
      activeOnly: false,
      category: null,
    )));

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
                          AchievementStatItem(
                            label: 'Totalt',
                            value: definitions.length.toString(),
                            icon: Icons.emoji_events,
                          ),
                          AchievementStatItem(
                            label: 'Aktive',
                            value: definitions.where((d) => d.isActive).length.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          AchievementStatItem(
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
                ...grouped.entries.map((entry) => AchievementCategorySection(
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
