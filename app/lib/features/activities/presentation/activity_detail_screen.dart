import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/team.dart';
import '../../../data/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../providers/activity_provider.dart';
import 'widgets/absence_button.dart';
import 'widgets/activity_info_widgets.dart';
import 'widgets/activity_response_widgets.dart';
import 'widgets/admin_actions_section.dart';
import 'widgets/mini_activities_section.dart';
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
        data: (instance) => _ActivityDetailContent(
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            context.pop(); // Go back after successful delete
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kunne ikke slette aktivitet')),
            );
          }
        }
      }
    }
  }
}

class _ActivityDetailContent extends ConsumerStatefulWidget {
  final ActivityInstance instance;
  final String teamId;
  final Team? team;
  final User? user;

  const _ActivityDetailContent({
    required this.instance,
    required this.teamId,
    this.team,
    this.user,
  });

  @override
  ConsumerState<_ActivityDetailContent> createState() => _ActivityDetailContentState();
}

class _ActivityDetailContentState extends ConsumerState<_ActivityDetailContent> {
  bool _isResponding = false;
  bool _isAwardingPoints = false;

  Future<void> _respond(UserResponse? response) async {
    setState(() => _isResponding = true);

    final success = await ref.read(activityResponseProvider.notifier).respond(
          instanceId: widget.instance.id,
          teamId: widget.teamId,
          response: response,
        );

    if (mounted) {
      setState(() => _isResponding = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Svar registrert')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke registrere svar')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE d. MMMM yyyy', 'nb_NO');
    final instance = widget.instance;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(instanceDetailProvider(widget.instance.id));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TypeChip(type: instance.type ?? ActivityType.other),
                        const SizedBox(width: 8),
                        if (instance.status == InstanceStatus.cancelled)
                          Chip(
                            label: const Text('Avlyst'),
                            backgroundColor: theme.colorScheme.errorContainer,
                            labelStyle: TextStyle(color: theme.colorScheme.onErrorContainer),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      instance.title ?? 'Aktivitet',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    InfoRow(
                      icon: Icons.calendar_today,
                      text: dateFormat.format(instance.date),
                    ),
                    if (instance.startTime != null) ...[
                      const SizedBox(height: 8),
                      InfoRow(
                        icon: Icons.access_time,
                        text: instance.formattedTime,
                      ),
                    ],
                    if (instance.location != null) ...[
                      const SizedBox(height: 8),
                      InfoRow(
                        icon: Icons.location_on,
                        text: instance.location!,
                      ),
                    ],
                    if (instance.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        instance.description!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Response section
            if (instance.status != InstanceStatus.cancelled) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ditt svar',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      if (_isResponding)
                        const Center(child: CircularProgressIndicator())
                      else
                        ResponseButtons(
                          currentResponse: instance.userResponse,
                          responseType: instance.responseType ?? ResponseType.yesNo,
                          onRespond: _respond,
                        ),
                      // Absence button for players
                      if (widget.user != null) ...[
                        const SizedBox(height: 12),
                        AbsenceButton(
                          teamId: widget.teamId,
                          instanceId: instance.id,
                          userId: widget.user!.id,
                          activityTitle: instance.title ?? 'Aktivitet',
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Responses list
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Svar',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        ResponseSummary(
                          yesCount: instance.yesCount ?? 0,
                          noCount: instance.noCount ?? 0,
                          maybeCount: instance.maybeCount ?? 0,
                          showMaybe: instance.responseType == ResponseType.yesNoMaybe,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (instance.responses?.isEmpty ?? true)
                      Text(
                        'Ingen har svart enn\u00E5',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      )
                    else
                      ...instance.responses!.map(
                        (response) => ResponseListItem(response: response),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mini-activities section
            MiniActivitiesSection(
              instanceId: instance.id,
              teamId: widget.teamId,
              canCreate: _canManageMiniActivities(widget.team, widget.user, instance),
            ),

            // Admin section for awarding attendance points
            if (_canAwardAttendancePoints(widget.team, instance)) ...[
              const SizedBox(height: 16),
              AdminActionsSection(
                instance: instance,
                teamId: widget.teamId,
                isAwardingPoints: _isAwardingPoints,
                onAwardPoints: _awardAttendancePoints,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Determine if user can award attendance points
  bool _canAwardAttendancePoints(Team? team, ActivityInstance instance) {
    if (team == null) return false;
    // Only admin can award attendance points
    if (!team.userIsAdmin) return false;
    // Activity must be in the past
    final today = DateTime.now();
    final activityDate = DateTime(instance.date.year, instance.date.month, instance.date.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    if (!activityDate.isBefore(todayDate)) return false;
    // Activity must not be cancelled
    if (instance.status == InstanceStatus.cancelled) return false;
    return true;
  }

  Future<void> _awardAttendancePoints() async {
    setState(() => _isAwardingPoints = true);

    final result = await ref.read(attendancePointsProvider.notifier).awardPoints(
          instanceId: widget.instance.id,
          teamId: widget.teamId,
        );

    if (mounted) {
      setState(() => _isAwardingPoints = false);

      if (result != null && result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      } else {
        final error = ref.read(attendancePointsProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error?.toString() ?? 'Kunne ikke tildele oppm\u00F8tepoeng'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Determine if user can create/manage mini-activities
  bool _canManageMiniActivities(Team? team, User? user, ActivityInstance instance) {
    if (team == null || user == null) return false;
    // Admin can always manage
    if (team.userIsAdmin) return true;
    // Coach can manage
    if (team.userIsCoach) return true;
    // Creator of the activity can manage
    if (instance.createdBy == user.id) return true;
    return false;
  }
}
