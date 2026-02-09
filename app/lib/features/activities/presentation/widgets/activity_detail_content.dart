import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/activity.dart';
import '../../../../data/models/team.dart';
import '../../../../data/models/user.dart';
import '../../providers/activity_provider.dart';
import 'absence_button.dart';
import 'activity_info_widgets.dart';
import 'activity_response_widgets.dart';
import 'admin_actions_section.dart';
import 'mini_activities_section.dart';

class ActivityDetailContent extends ConsumerStatefulWidget {
  final ActivityInstance instance;
  final String teamId;
  final Team? team;
  final User? user;

  const ActivityDetailContent({
    super.key,
    required this.instance,
    required this.teamId,
    this.team,
    this.user,
  });

  @override
  ConsumerState<ActivityDetailContent> createState() => _ActivityDetailContentState();
}

class _ActivityDetailContentState extends ConsumerState<ActivityDetailContent> {
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
