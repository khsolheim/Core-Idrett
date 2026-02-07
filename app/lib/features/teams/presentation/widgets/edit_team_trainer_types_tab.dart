import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/team.dart';
import '../../providers/team_provider.dart';

class EditTeamTrainerTypesTab extends ConsumerWidget {
  final String teamId;

  const EditTeamTrainerTypesTab({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainerTypesAsync = ref.watch(trainerTypesProvider(teamId));

    return trainerTypesAsync.when2(
      onRetry: () => ref.invalidate(trainerTypesProvider(teamId)),
      data: (trainerTypes) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Trenertyper',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Legg til'),
                    onPressed: () => _addTrainerType(ref, context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: trainerTypes.isEmpty
                  ? const Center(child: Text('Ingen trenertyper'))
                  : ListView.builder(
                      itemCount: trainerTypes.length,
                      itemBuilder: (context, index) {
                        final tt = trainerTypes[index];
                        return ListTile(
                          leading: const Icon(Icons.sports),
                          title: Text(tt.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deleteTrainerType(ref, context, tt),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addTrainerType(WidgetRef ref, BuildContext context) async {
    final nameController = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ny trenertype'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Navn',
            hintText: 'f.eks. Keepertrener',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, nameController.text.trim()),
            child: const Text('Legg til'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final notifier = ref.read(teamNotifierProvider.notifier);
      final result = await notifier.createTrainerType(
        teamId: teamId,
        name: name,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result != null
                  ? 'Trenertype opprettet'
                  : 'Kunne ikke opprette trenertype',
            ),
            backgroundColor: result != null ? null : Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteTrainerType(
    WidgetRef ref,
    BuildContext context,
    TrainerType trainerType,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Slett trenertype?'),
        content: Text(
          'Er du sikker pa at du vil slette "${trainerType.name}"? Medlemmer med denne rollen vil miste den.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Slett'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final notifier = ref.read(teamNotifierProvider.notifier);
      final success =
          await notifier.deleteTrainerType(teamId, trainerType.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Trenertype slettet'
                  : 'Kunne ikke slette trenertype',
            ),
            backgroundColor: success ? null : Colors.red,
          ),
        );
      }
    }
  }
}
