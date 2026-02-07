import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/stopwatch.dart';
import '../../providers/stopwatch_provider.dart';

/// Large stopwatch display widget with controls
class StopwatchDisplay extends ConsumerStatefulWidget {
  final String sessionId;
  final StopwatchSession session;
  final VoidCallback? onRecordTime;
  final Function(String userId, int timeMs)? onTimeRecorded;

  const StopwatchDisplay({
    super.key,
    required this.sessionId,
    required this.session,
    this.onRecordTime,
    this.onTimeRecorded,
  });

  @override
  ConsumerState<StopwatchDisplay> createState() => _StopwatchDisplayState();
}

class _StopwatchDisplayState extends ConsumerState<StopwatchDisplay> {
  Timer? _timer;
  int _elapsedMs = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _initializeFromSession();
  }

  @override
  void didUpdateWidget(StopwatchDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.status != widget.session.status) {
      _initializeFromSession();
    }
  }

  void _initializeFromSession() {
    if (widget.session.isRunning && widget.session.startedAt != null) {
      _startTime = widget.session.startedAt;
      _elapsedMs = DateTime.now().difference(_startTime!).inMilliseconds;
      _startTimer();
    } else if (widget.session.isPaused) {
      _elapsedMs = widget.session.elapsedMs;
      _stopTimer();
    } else if (widget.session.isComplete) {
      _elapsedMs = widget.session.elapsedMs;
      _stopTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (_startTime != null) {
        setState(() {
          _elapsedMs = DateTime.now().difference(_startTime!).inMilliseconds;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int ms) {
    final minutes = ms ~/ 60000;
    final seconds = (ms % 60000) ~/ 1000;
    final millis = (ms % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(2, '0')}';
  }

  Future<void> _handleStart() async {
    await ref.read(stopwatchControlNotifierProvider.notifier).startSession(widget.sessionId);
  }

  Future<void> _handlePause() async {
    await ref.read(stopwatchControlNotifierProvider.notifier).pauseSession(widget.sessionId);
  }

  Future<void> _handleResume() async {
    await ref.read(stopwatchControlNotifierProvider.notifier).resumeSession(widget.sessionId);
  }

  Future<void> _handleStop() async {
    await ref.read(stopwatchControlNotifierProvider.notifier).completeSession(widget.sessionId);
  }

  Future<void> _handleReset() async {
    await ref.read(stopwatchControlNotifierProvider.notifier).resetSession(widget.sessionId);
    setState(() {
      _elapsedMs = 0;
      _startTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCountdown = widget.session.isCountdown;
    final displayMs = isCountdown
        ? ((widget.session.countdownDurationMs ?? 0) - _elapsedMs).clamp(0, double.infinity).toInt()
        : _elapsedMs;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                _formatTime(displayMs),
                style: theme.textTheme.displayLarge?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: widget.session.isRunning
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (isCountdown) ...[
                const SizedBox(height: 8),
                Text(
                  'Nedtelling',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.session.isPending) ...[
              _ControlButton(
                icon: Icons.play_arrow,
                label: 'Start',
                onPressed: _handleStart,
                isPrimary: true,
              ),
            ] else if (widget.session.isRunning) ...[
              _ControlButton(
                icon: Icons.pause,
                label: 'Pause',
                onPressed: _handlePause,
              ),
              const SizedBox(width: 16),
              if (widget.onRecordTime != null)
                _ControlButton(
                  icon: Icons.flag,
                  label: 'Registrer',
                  onPressed: widget.onRecordTime,
                  isPrimary: true,
                ),
              const SizedBox(width: 16),
              _ControlButton(
                icon: Icons.stop,
                label: 'Stopp',
                onPressed: _handleStop,
                isDestructive: true,
              ),
            ] else if (widget.session.isPaused) ...[
              _ControlButton(
                icon: Icons.play_arrow,
                label: 'Fortsett',
                onPressed: _handleResume,
                isPrimary: true,
              ),
              const SizedBox(width: 16),
              _ControlButton(
                icon: Icons.stop,
                label: 'Stopp',
                onPressed: _handleStop,
                isDestructive: true,
              ),
            ] else if (widget.session.isComplete) ...[
              _ControlButton(
                icon: Icons.refresh,
                label: 'Nullstill',
                onPressed: _handleReset,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = isDestructive
        ? theme.colorScheme.errorContainer
        : isPrimary
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest;

    final foregroundColor = isDestructive
        ? theme.colorScheme.onErrorContainer
        : isPrimary
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Icon(
                icon,
                size: 32,
                color: foregroundColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

/// Compact stopwatch time row for leaderboard
class StopwatchTimeRow extends StatelessWidget {
  final StopwatchTime time;
  final int position;
  final bool isCurrentUser;

  const StopwatchTimeRow({
    super.key,
    required this.time,
    required this.position,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? theme.colorScheme.primaryContainer.withAlpha(77) : null,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: _PositionBadge(position: position),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 16,
            backgroundImage: time.userProfileImageUrl != null
                ? CachedNetworkImageProvider(time.userProfileImageUrl!)
                : null,
            child: time.userProfileImageUrl == null
                ? Text(
                    time.userName?.substring(0, 1).toUpperCase() ?? '?',
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              time.userName ?? 'Ukjent',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            time.formattedTime,
            style: theme.textTheme.titleMedium?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  final int position;

  const _PositionBadge({required this.position});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (position <= 3) {
      final colors = [Colors.amber, Colors.grey.shade400, Colors.brown.shade300];
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: colors[position - 1],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$position',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Text(
      '$position.',
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }
}
