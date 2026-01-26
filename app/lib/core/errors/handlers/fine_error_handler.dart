import 'package:flutter/material.dart';
import '../app_exceptions.dart';
import '../../services/error_display_service.dart';

/// Handler for fine-related errors
class FineErrorHandler {
  /// Callback to refresh fine list after handling
  final VoidCallback? onRefreshFines;

  FineErrorHandler({this.onRefreshFines});

  /// Handle a fine-related error
  /// Returns true if the error was handled
  Future<bool> handle(AppException error, BuildContext context) async {
    if (error is FineAlreadyProcessedException) {
      return _handleFineAlreadyProcessed(error, context);
    }

    if (error is AppealNotAllowedException) {
      return _handleAppealNotAllowed(error, context);
    }

    if (error is FineRuleDeletedException) {
      return _handleFineRuleDeleted(error, context);
    }

    return false;
  }

  /// Handle fine already processed by another user
  bool _handleFineAlreadyProcessed(AppException error, BuildContext context) {
    ErrorDisplayService.showWarning(
      '${error.message}. Oppdaterer listen...',
    );

    // Trigger refresh of fine list
    onRefreshFines?.call();

    return true;
  }

  /// Handle appeal not allowed
  bool _handleAppealNotAllowed(AppException error, BuildContext context) {
    ErrorDisplayService.showError(error);
    return true;
  }

  /// Handle fine rule deleted
  bool _handleFineRuleDeleted(AppException error, BuildContext context) {
    if (!context.mounted) return false;

    // Show dialog asking user to select another rule
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.rule, color: Colors.orange),
            SizedBox(width: 12),
            Text('Regel slettet'),
          ],
        ),
        content: const Text(
          'Bøteregelen du valgte er slettet. Velg en annen regel.',
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

  /// Check if an error is a fine error that this handler can handle
  static bool canHandle(AppException error) {
    return error is FineAlreadyProcessedException ||
        error is AppealNotAllowedException ||
        error is FineRuleDeletedException;
  }
}
