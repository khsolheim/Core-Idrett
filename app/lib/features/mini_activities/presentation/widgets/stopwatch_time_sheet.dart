import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/stopwatch.dart';
import '../../providers/stopwatch_provider.dart';

/// Bottom sheet for recording a stopwatch time for a user
class StopwatchTimeSheet extends ConsumerStatefulWidget {
  final String sessionId;
  final int currentTimeMs;
  final List<StopwatchParticipant> participants;

  const StopwatchTimeSheet({
    super.key,
    required this.sessionId,
    required this.currentTimeMs,
    required this.participants,
  });

  static Future<StopwatchTime?> show(
    BuildContext context, {
    required String sessionId,
    required int currentTimeMs,
    required List<StopwatchParticipant> participants,
  }) {
    return showModalBottomSheet<StopwatchTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StopwatchTimeSheet(
        sessionId: sessionId,
        currentTimeMs: currentTimeMs,
        participants: participants,
      ),
    );
  }

  @override
  ConsumerState<StopwatchTimeSheet> createState() => _StopwatchTimeSheetState();
}

class _StopwatchTimeSheetState extends ConsumerState<StopwatchTimeSheet> {
  String? _selectedUserId;
  bool _isLoading = false;

  String _formatTime(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = (ms % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
  }

  Future<void> _recordTime() async {
    if (_selectedUserId == null) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(stopwatchTimeNotifierProvider.notifier);
      final result = await notifier.recordTime(
        sessionId: widget.sessionId,
        userId: _selectedUserId!,
        timeMs: widget.currentTimeMs,
      );

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunne ikke registrere tid. Prøv igjen.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter out participants who already have a time recorded
    final availableParticipants = widget.participants
        .where((p) => !p.hasRecordedTime)
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withAlpha(102),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header with time display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Registrer tid',
                        style: theme.textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatTime(widget.currentTimeMs),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),

            // Participant list
            Expanded(
              child: availableParticipants.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Alle deltakere har registrert tid',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: availableParticipants.length,
                      itemBuilder: (context, index) {
                        final participant = availableParticipants[index];
                        final isSelected = _selectedUserId == participant.userId;

                        return Card(
                          color: isSelected
                              ? theme.colorScheme.primaryContainer
                              : null,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: participant.profileImageUrl != null
                                  ? NetworkImage(participant.profileImageUrl!)
                                  : null,
                              child: participant.profileImageUrl == null
                                  ? Text(
                                      participant.userName?.substring(0, 1).toUpperCase() ?? '?',
                                    )
                                  : null,
                            ),
                            title: Text(
                              participant.userName ?? 'Ukjent',
                              style: isSelected
                                  ? TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    )
                                  : null,
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () {
                              setState(() => _selectedUserId = participant.userId);
                            },
                          ),
                        );
                      },
                    ),
            ),

            // Record button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton(
                onPressed: _selectedUserId == null || _isLoading ? null : _recordTime,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Registrer tid'),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Model for participant in stopwatch session
class StopwatchParticipant {
  final String userId;
  final String? userName;
  final String? profileImageUrl;
  final bool hasRecordedTime;

  const StopwatchParticipant({
    required this.userId,
    this.userName,
    this.profileImageUrl,
    this.hasRecordedTime = false,
  });
}
