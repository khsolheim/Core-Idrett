import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/mini_activity.dart';
import '../../providers/mini_activity_provider.dart';
import '../widgets/create_standalone_activity_sheet.dart';
import '../widgets/standalone_activity_list.dart';

/// Screen for viewing and managing standalone mini-activities for a team
class StandaloneActivitiesScreen extends ConsumerWidget {
  final String teamId;

  const StandaloneActivitiesScreen({
    super.key,
    required this.teamId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(teamStandaloneMiniActivitiesProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini-aktiviteter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId)),
            tooltip: 'Oppdater',
          ),
        ],
      ),
      body: activitiesAsync.when2(
        onRetry: () => ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId)),
        data: (activities) => StandaloneActivityList(
          activities: activities,
          teamId: teamId,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Ny aktivitet'),
      ),
    );
  }

  Future<void> _showCreateSheet(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<MiniActivity>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => CreateStandaloneActivitySheet(teamId: teamId),
    );

    if (result != null && context.mounted) {
      ref.invalidate(teamStandaloneMiniActivitiesProvider(teamId));
    }
  }
}
