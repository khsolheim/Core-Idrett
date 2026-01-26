import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_exceptions.dart';
import '../../services/error_display_service.dart';

/// Handler for activity-related errors
class ActivityErrorHandler {
  /// Handle an activity-related error
  /// Returns true if the error was handled and navigation occurred
  Future<bool> handle(AppException error, BuildContext context) async {
    if (error is ActivityCancelledException) {
      return _handleActivityCancelled(error, context);
    }

    if (error is ActivityDeletedException) {
      return _handleActivityDeleted(error, context);
    }

    if (error is DeadlineExpiredException) {
      return await _handleDeadlineExpired(error, context);
    }

    return false;
  }

  /// Handle activity cancelled
  bool _handleActivityCancelled(AppException error, BuildContext context) {
    ErrorDisplayService.showWarning(error.message);

    // Navigate back if possible
    if (context.mounted && context.canPop()) {
      context.pop();
    }

    return true;
  }

  /// Handle activity deleted
  bool _handleActivityDeleted(AppException error, BuildContext context) {
    ErrorDisplayService.showError(error);

    // Navigate back if possible
    if (context.mounted && context.canPop()) {
      context.pop();
    }

    return true;
  }

  /// Handle deadline expired - show dialog
  Future<bool> _handleDeadlineExpired(
    AppException error,
    BuildContext context,
  ) async {
    if (!context.mounted) return false;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.orange),
            SizedBox(width: 12),
            Text('Fristen har utløpt'),
          ],
        ),
        content: const Text(
          'Du kan ikke lenger svare på denne aktiviteten.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    return true;
  }

  /// Check if an error is an activity error that this handler can handle
  static bool canHandle(AppException error) {
    return error is ActivityCancelledException ||
        error is ActivityDeletedException ||
        error is DeadlineExpiredException;
  }
}
