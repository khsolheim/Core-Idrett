import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../data/models/activity.dart';
import '../../../data/models/team.dart';
import '../../../data/models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../../teams/providers/team_provider.dart';
import '../../absence/presentation/absence_registration_dialog.dart';
import '../../absence/providers/absence_provider.dart';
import '../../points/providers/points_provider.dart';
import '../providers/activity_provider.dart';
import 'widgets/series_action_dialog.dart';
import 'widgets/mini_activities_section.dart';

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
      body: instanceAsync.when(
        data: (instance) => _ActivityDetailContent(
          instance: instance,
          teamId: teamId,
          team: teamAsync.value,
          user: userAsync.value,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Kunne ikke laste aktivitet: $error'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(instanceDetailProvider(instanceId)),
                child: const Text('Prøv igjen'),
              ),
            ],
          ),
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
        context.push(
          '/teams/$teamId/activities/$instanceId/edit',
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
                        _TypeChip(type: instance.type ?? ActivityType.other),
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
                    _InfoRow(
                      icon: Icons.calendar_today,
                      text: dateFormat.format(instance.date),
                    ),
                    if (instance.startTime != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.access_time,
                        text: instance.formattedTime,
                      ),
                    ],
                    if (instance.location != null) ...[
                      const SizedBox(height: 8),
                      _InfoRow(
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
                        _ResponseButtons(
                          currentResponse: instance.userResponse,
                          responseType: instance.responseType ?? ResponseType.yesNo,
                          onRespond: _respond,
                        ),
                      // Absence button for players
                      if (widget.user != null) ...[
                        const SizedBox(height: 12),
                        _AbsenceButton(
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
                        _ResponseSummary(
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
                        'Ingen har svart ennå',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      )
                    else
                      ...instance.responses!.map(
                        (response) => _ResponseListItem(response: response),
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
              _AdminActionsSection(
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
            content: Text(error?.toString() ?? 'Kunne ikke tildele oppmøtepoeng'),
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

class _TypeChip extends StatelessWidget {
  final ActivityType type;

  const _TypeChip({required this.type});

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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

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

class _ResponseButtons extends StatelessWidget {
  final UserResponse? currentResponse;
  final ResponseType responseType;
  final void Function(UserResponse?) onRespond;

  const _ResponseButtons({
    required this.currentResponse,
    required this.responseType,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ResponseButton(
            response: UserResponse.yes,
            isSelected: currentResponse == UserResponse.yes,
            onTap: () => onRespond(UserResponse.yes),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ResponseButton(
            response: UserResponse.no,
            isSelected: currentResponse == UserResponse.no,
            onTap: () => onRespond(UserResponse.no),
          ),
        ),
        if (responseType == ResponseType.yesNoMaybe) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ResponseButton(
              response: UserResponse.maybe,
              isSelected: currentResponse == UserResponse.maybe,
              onTap: () => onRespond(UserResponse.maybe),
            ),
          ),
        ],
      ],
    );
  }
}

class _ResponseButton extends StatelessWidget {
  final UserResponse response;
  final bool isSelected;
  final VoidCallback onTap;

  const _ResponseButton({
    required this.response,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (response) {
      case UserResponse.yes:
        color = Colors.green;
        icon = Icons.check;
        break;
      case UserResponse.no:
        color = Colors.red;
        icon = Icons.close;
        break;
      case UserResponse.maybe:
        color = Colors.orange;
        icon = Icons.help_outline;
        break;
    }

    if (isSelected) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(response.displayName),
        style: FilledButton.styleFrom(backgroundColor: color),
      );
    }

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(response.displayName),
    );
  }
}

class _ResponseSummary extends StatelessWidget {
  final int yesCount;
  final int noCount;
  final int maybeCount;
  final bool showMaybe;

  const _ResponseSummary({
    required this.yesCount,
    required this.noCount,
    required this.maybeCount,
    required this.showMaybe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 16, color: Colors.green),
        const SizedBox(width: 2),
        Text('$yesCount'),
        const SizedBox(width: 8),
        Icon(Icons.cancel, size: 16, color: Colors.red),
        const SizedBox(width: 2),
        Text('$noCount'),
        if (showMaybe) ...[
          const SizedBox(width: 8),
          Icon(Icons.help, size: 16, color: Colors.orange),
          const SizedBox(width: 2),
          Text('$maybeCount'),
        ],
      ],
    );
  }
}

class _ResponseListItem extends StatelessWidget {
  final ActivityResponseItem response;

  const _ResponseListItem({required this.response});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? indicatorColor;
    switch (response.response) {
      case UserResponse.yes:
        indicatorColor = Colors.green;
        break;
      case UserResponse.no:
        indicatorColor = Colors.red;
        break;
      case UserResponse.maybe:
        indicatorColor = Colors.orange;
        break;
      default:
        indicatorColor = theme.colorScheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundImage: response.userAvatarUrl != null
                ? NetworkImage(response.userAvatarUrl!)
                : null,
            child: response.userAvatarUrl == null
                ? Text(response.userName?.substring(0, 1).toUpperCase() ?? '?')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  response.userName ?? 'Ukjent',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (response.comment != null)
                  Text(
                    response.comment!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            response.response?.displayName ?? 'Ikke svart',
            style: theme.textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionsSection extends StatelessWidget {
  final ActivityInstance instance;
  final String teamId;
  final bool isAwardingPoints;
  final VoidCallback onAwardPoints;

  const _AdminActionsSection({
    required this.instance,
    required this.teamId,
    required this.isAwardingPoints,
    required this.onAwardPoints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final yesCount = instance.yesCount ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Admin',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tildel oppmøtepoeng til alle som svarte "Ja" ($yesCount spillere)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isAwardingPoints ? null : onAwardPoints,
                icon: isAwardingPoints
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.emoji_events),
                label: Text(isAwardingPoints ? 'Tildeler poeng...' : 'Tildel oppmøtepoeng'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Poeng legges til på sesong-leaderboard. Allerede tildelte poeng hoppes over.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Button to register absence from an activity
class _AbsenceButton extends ConsumerWidget {
  final String teamId;
  final String instanceId;
  final String userId;
  final String activityTitle;

  const _AbsenceButton({
    required this.teamId,
    required this.instanceId,
    required this.userId,
    required this.activityTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final existingAbsenceAsync = ref.watch(
      instanceAbsenceProvider((userId: userId, instanceId: instanceId)),
    );
    final configAsync = ref.watch(teamPointsConfigProvider(teamId));
    final requireReason = configAsync.value?.requireAbsenceReason ?? false;

    return existingAbsenceAsync.when(
      data: (existingAbsence) {
        if (existingAbsence != null) {
          // Already registered absence
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: existingAbsence.isPending
                  ? theme.colorScheme.secondaryContainer
                  : existingAbsence.isApproved
                      ? theme.colorScheme.tertiaryContainer
                      : theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  existingAbsence.isPending
                      ? Icons.hourglass_empty
                      : existingAbsence.isApproved
                          ? Icons.check_circle
                          : Icons.cancel,
                  size: 20,
                  color: existingAbsence.isPending
                      ? theme.colorScheme.onSecondaryContainer
                      : existingAbsence.isApproved
                          ? theme.colorScheme.onTertiaryContainer
                          : theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        existingAbsence.isPending
                            ? 'Fravær meldt - venter på godkjenning'
                            : existingAbsence.isApproved
                                ? 'Fravær godkjent'
                                : 'Fravær avvist',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (existingAbsence.categoryName != null)
                        Text(
                          existingAbsence.categoryName!,
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // No existing absence - show button
        return TextButton.icon(
          onPressed: () async {
            final result = await showAbsenceRegistrationDialog(
              context,
              teamId: teamId,
              instanceId: instanceId,
              userId: userId,
              activityTitle: activityTitle,
              requireReason: requireReason,
            );
            if (result) {
              // Refresh absence status
              ref.invalidate(
                instanceAbsenceProvider((userId: userId, instanceId: instanceId)),
              );
            }
          },
          icon: const Icon(Icons.event_busy),
          label: const Text('Meld fravær'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.outline,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => TextButton.icon(
        onPressed: () async {
          final result = await showAbsenceRegistrationDialog(
            context,
            teamId: teamId,
            instanceId: instanceId,
            userId: userId,
            activityTitle: activityTitle,
            requireReason: requireReason,
          );
          if (result) {
            ref.invalidate(
              instanceAbsenceProvider((userId: userId, instanceId: instanceId)),
            );
          }
        },
        icon: const Icon(Icons.event_busy),
        label: const Text('Meld fravær'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.outline,
        ),
      ),
    );
  }
}
