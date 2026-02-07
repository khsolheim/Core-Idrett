import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/async_value_extensions.dart';
import '../../../../data/models/stopwatch.dart';
import '../../providers/stopwatch_provider.dart';
import '../widgets/stopwatch_display.dart';
import '../widgets/stopwatch_time_sheet.dart';

/// Screen for viewing and controlling a stopwatch session
class StopwatchScreen extends ConsumerWidget {
  final String sessionId;

  const StopwatchScreen({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(stopwatchSessionWithTimesProvider(sessionId));

    return sessionAsync.when2(
      onRetry: () => ref.invalidate(stopwatchSessionWithTimesProvider(sessionId)),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      data: (sessionWithTimes) => _StopwatchContent(
        session: sessionWithTimes.session,
        times: sessionWithTimes.times,
      ),
    );
  }
}

class _StopwatchContent extends ConsumerStatefulWidget {
  final StopwatchSession session;
  final List<StopwatchTime> times;

  const _StopwatchContent({
    required this.session,
    required this.times,
  });

  @override
  ConsumerState<_StopwatchContent> createState() => _StopwatchContentState();
}

class _StopwatchContentState extends ConsumerState<_StopwatchContent> {
  late int _currentTimeMs;

  @override
  void initState() {
    super.initState();
    _currentTimeMs = widget.session.elapsedMs;
  }

  Future<void> _recordTime() async {
    // For now, show the time sheet with sample participants
    // In a real implementation, you'd fetch the actual participants
    final result = await StopwatchTimeSheet.show(
      context,
      sessionId: widget.session.id,
      currentTimeMs: _currentTimeMs,
      participants: [], // Would be populated from actual participants
    );

    if (result != null && mounted) {
      ref.invalidate(stopwatchSessionWithTimesProvider(widget.session.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session.name),
        actions: [
          if (widget.times.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.leaderboard_outlined),
              onPressed: () => _showLeaderboard(context),
              tooltip: 'Resultater',
            ),
        ],
      ),
      body: Column(
        children: [
          // Stopwatch display
          Padding(
            padding: const EdgeInsets.all(24),
            child: StopwatchDisplay(
              sessionId: widget.session.id,
              session: widget.session,
              onRecordTime: widget.session.isRunning ? _recordTime : null,
            ),
          ),

          // Leaderboard
          Expanded(
            child: _TimesLeaderboard(
              times: widget.times,
              session: widget.session,
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _FullLeaderboard(
          times: widget.times,
          session: widget.session,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _TimesLeaderboard extends StatelessWidget {
  final List<StopwatchTime> times;
  final StopwatchSession session;

  const _TimesLeaderboard({
    required this.times,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (times.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Ingen tider registrert ennå',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (session.isPending || session.isRunning) ...[
              const SizedBox(height: 8),
              Text(
                session.isPending
                    ? 'Start stoppeklokken for å registrere tider'
                    : 'Trykk "Registrer" for å legge til en tid',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    // Sort times for leaderboard
    final sortedTimes = List<StopwatchTime>.from(times);
    if (session.isCountdown) {
      // For countdown, higher time is better (closer to target)
      sortedTimes.sort((a, b) => b.timeMs.compareTo(a.timeMs));
    } else {
      // For stopwatch, lower time is better
      sortedTimes.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Resultater',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${times.length} deltakere',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: sortedTimes.length.clamp(0, 10), // Show top 10
            itemBuilder: (context, index) {
              final time = sortedTimes[index];
              return StopwatchTimeRow(
                time: time,
                position: index + 1,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FullLeaderboard extends StatelessWidget {
  final List<StopwatchTime> times;
  final StopwatchSession session;
  final ScrollController scrollController;

  const _FullLeaderboard({
    required this.times,
    required this.session,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sort times
    final sortedTimes = List<StopwatchTime>.from(times);
    if (session.isCountdown) {
      sortedTimes.sort((a, b) => b.timeMs.compareTo(a.timeMs));
    } else {
      sortedTimes.sort((a, b) => a.timeMs.compareTo(b.timeMs));
    }

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
                'Alle resultater',
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

        // List
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: sortedTimes.length,
            itemBuilder: (context, index) {
              final time = sortedTimes[index];
              return StopwatchTimeRow(
                time: time,
                position: index + 1,
              );
            },
          ),
        ),
      ],
    );
  }
}
