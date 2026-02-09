import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/stopwatch.dart';
import '../../providers/stopwatch_provider.dart';
import '../../../../core/services/error_display_service.dart';

/// Bottom sheet for creating a new stopwatch session
class StopwatchSetupSheet extends ConsumerStatefulWidget {
  final String? miniActivityId;
  final String? teamId;

  const StopwatchSetupSheet({
    super.key,
    this.miniActivityId,
    this.teamId,
  });

  static Future<StopwatchSession?> show(
    BuildContext context, {
    String? miniActivityId,
    String? teamId,
  }) {
    return showModalBottomSheet<StopwatchSession>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StopwatchSetupSheet(
        miniActivityId: miniActivityId,
        teamId: teamId,
      ),
    );
  }

  @override
  ConsumerState<StopwatchSetupSheet> createState() => _StopwatchSetupSheetState();
}

class _StopwatchSetupSheetState extends ConsumerState<StopwatchSetupSheet> {
  final _nameController = TextEditingController();
  StopwatchSessionType _sessionType = StopwatchSessionType.stopwatch;
  int _countdownMinutes = 5;
  int _countdownSeconds = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  int get _countdownDurationMs => (_countdownMinutes * 60 + _countdownSeconds) * 1000;

  Future<void> _create() async {
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(stopwatchSessionNotifierProvider.notifier);
      final result = await notifier.createSession(
        miniActivityId: widget.miniActivityId,
        teamId: widget.teamId,
        name: _nameController.text.isNotEmpty ? _nameController.text : 'Stoppeklokke',
        sessionType: _sessionType,
        countdownDurationMs: _sessionType == StopwatchSessionType.countdown
            ? _countdownDurationMs
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (mounted) {
        ErrorDisplayService.showSuccess('Kunne ikke opprette stoppeklokke. Prøv igjen.');
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

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Ny stoppeklokke',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),

            // Content
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  // Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Navn (valgfritt)',
                      hintText: 'F.eks. Sprint 60m',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Type selection
                  Text(
                    'Type',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<StopwatchSessionType>(
                    segments: const [
                      ButtonSegment(
                        value: StopwatchSessionType.stopwatch,
                        label: Text('Stoppeklokke'),
                        icon: Icon(Icons.timer_outlined),
                      ),
                      ButtonSegment(
                        value: StopwatchSessionType.countdown,
                        label: Text('Nedtelling'),
                        icon: Icon(Icons.hourglass_bottom),
                      ),
                    ],
                    selected: {_sessionType},
                    onSelectionChanged: (selection) {
                      setState(() => _sessionType = selection.first);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Countdown duration (only for countdown)
                  if (_sessionType == StopwatchSessionType.countdown) ...[
                    Text(
                      'Nedtellingstid',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Minutes
                        _TimePickerColumn(
                          value: _countdownMinutes,
                          max: 59,
                          label: 'min',
                          onChanged: (v) => setState(() => _countdownMinutes = v),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            ':',
                            style: theme.textTheme.headlineMedium,
                          ),
                        ),
                        // Seconds
                        _TimePickerColumn(
                          value: _countdownSeconds,
                          max: 59,
                          label: 'sek',
                          onChanged: (v) => setState(() => _countdownSeconds = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick select
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _QuickTimeChip(
                          label: '1 min',
                          onTap: () => setState(() {
                            _countdownMinutes = 1;
                            _countdownSeconds = 0;
                          }),
                        ),
                        _QuickTimeChip(
                          label: '2 min',
                          onTap: () => setState(() {
                            _countdownMinutes = 2;
                            _countdownSeconds = 0;
                          }),
                        ),
                        _QuickTimeChip(
                          label: '5 min',
                          onTap: () => setState(() {
                            _countdownMinutes = 5;
                            _countdownSeconds = 0;
                          }),
                        ),
                        _QuickTimeChip(
                          label: '10 min',
                          onTap: () => setState(() {
                            _countdownMinutes = 10;
                            _countdownSeconds = 0;
                          }),
                        ),
                        _QuickTimeChip(
                          label: '30 sek',
                          onTap: () => setState(() {
                            _countdownMinutes = 0;
                            _countdownSeconds = 30;
                          }),
                        ),
                      ],
                    ),
                  ],

                  // Description
                  if (_sessionType == StopwatchSessionType.stopwatch) ...[
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Stoppeklokken teller oppover fra 00:00 og lar deg registrere tider for deltakere.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Card(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Nedtelling teller nedover fra valgt tid til 00:00.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Create button
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: FilledButton(
                onPressed: _isLoading ? null : _create,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Opprett'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimePickerColumn extends StatelessWidget {
  final int value;
  final int max;
  final String label;
  final ValueChanged<int> onChanged;

  const _TimePickerColumn({
    required this.value,
    required this.max,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          onPressed: value > 0 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.keyboard_arrow_down),
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

class _QuickTimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickTimeChip({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
