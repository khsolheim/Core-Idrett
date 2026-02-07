import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../absence/presentation/absence_registration_dialog.dart';
import '../../../absence/providers/absence_provider.dart';
import '../../../points/providers/points_provider.dart';

/// Button to register absence from an activity
class AbsenceButton extends ConsumerWidget {
  final String teamId;
  final String instanceId;
  final String userId;
  final String activityTitle;

  const AbsenceButton({
    super.key,
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

    return existingAbsenceAsync.when2(
      onRetry: () => ref.invalidate(
        instanceAbsenceProvider((userId: userId, instanceId: instanceId)),
      ),
      loading: () => const SizedBox.shrink(),
      error: (error, retry) => TextButton.icon(
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
        label: const Text('Meld frav\u00E6r'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.outline,
        ),
      ),
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
                            ? 'Frav\u00E6r meldt - venter p\u00E5 godkjenning'
                            : existingAbsence.isApproved
                                ? 'Frav\u00E6r godkjent'
                                : 'Frav\u00E6r avvist',
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
          label: const Text('Meld frav\u00E6r'),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.outline,
          ),
        );
      },
    );
  }
}
