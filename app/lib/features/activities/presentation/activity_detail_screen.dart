import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../core/services/error_display_service.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/team.dart';
import '../../../data/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/activity_provider.dart';
import 'widgets/activity_detail_content.dart';
import 'widgets/series_action_dialog.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String teamId;
  final String instanceId;

  const ActivityDetailScreen({
    super.key,
    required this.teamId,
    required this.instanceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instanceAsync = ref.watch(instanceDetailProvider(instanceId));
    final teamAsync = ref.watch(teamDetailProvider(teamId));
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitet'),
        actions: [
          // Show menu only when data is available
          if (instanceAsync.hasValue && teamAsync.hasValue && userAsync.hasValue)
            _buildMenuButton(
              context,
              ref,
              instanceAsync.value!,
              teamAsync.value,
              userAsync.value,
            ),
        ],
      ),
      body: instanceAsync.when2(
        onRetry: () => ref.invalidate(instanceDetailProvider(instanceId)),
        data: (instance) => ActivityDetailContent(
          instance: instance,
          teamId: teamId,
          team: teamAsync.value,
          user: userAsync.value,
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    WidgetRef ref,
    ActivityInstance instance,
    Team? team,
    User? user,
  ) {
    // Check if user can manage this activity
    final isAdmin = team?.userIsAdmin ?? false;
    final isCreator = user != null && instance.createdBy == user.id;
    final canManage = isAdmin || isCreator;

    if (!canManage) return const SizedBox.shrink();

    // Don't show menu for cancelled or past activities
    final isPast = instance.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    if (instance.status == InstanceStatus.cancelled || isPast) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => _handleMenuAction(context, ref, action, instance),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rediger'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('Slett'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    ActivityInstance instance,
  ) async {
    final isPartOfSeries = instance.isPartOfSeries;

    if (action == 'edit') {
      EditScope scope = EditScope.single;

      // If part of a series, ask which scope
      if (isPartOfSeries) {
        final selectedScope = await SeriesActionDialog.show(
          context: context,
          isDelete: false,
          seriesInfo: instance.seriesInfo,
        );
        if (selectedScope == null) return; // Cancelled
        scope = selectedScope;
      }

      // Navigate to edit screen
      if (context.mounted) {
        context.pushNamed(
          'edit-instance',
          pathParameters: {'teamId': teamId, 'instanceId': instanceId},
          extra: {'scope': scope},
        );
      }
    } else if (action == 'delete') {
      EditScope scope = EditScope.single;

      // If part of a series, ask which scope
      if (isPartOfSeries) {
        final selectedScope = await SeriesActionDialog.show(
          context: context,
          isDelete: true,
          seriesInfo: instance.seriesInfo,
        );
        if (selectedScope == null) return; // Cancelled
        scope = selectedScope;
      }

      // Show confirmation dialog
      if (context.mounted) {
        final confirmed = await DeleteConfirmationDialog.show(
          context: context,
          scope: scope,
        );
        if (!confirmed) return;

        // Perform delete
        final result = await ref.read(deleteInstanceProvider.notifier).deleteInstance(
              instanceId: instanceId,
              teamId: teamId,
              scope: scope,
            );

        if (context.mounted) {
          if (result != null) {
            final message = scope == EditScope.single
                ? 'Aktivitet slettet'
                : '${result.affectedCount} aktiviteter slettet';
            ErrorDisplayService.showSuccess(message);
            context.pop(); // Go back after successful delete
          } else {
            ErrorDisplayService.showWarning('Kunne ikke slette aktivitet');
          }
        }
      }
    }
  }
}
