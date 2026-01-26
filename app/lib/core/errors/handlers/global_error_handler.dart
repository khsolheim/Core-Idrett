import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_exceptions.dart';
import '../../services/error_display_service.dart';
import 'auth_error_handler.dart';
import 'team_error_handler.dart';
import 'activity_error_handler.dart';
import 'fine_error_handler.dart';

/// Provider for the global error handler
final globalErrorHandlerProvider = Provider<GlobalErrorHandler>((ref) {
  return GlobalErrorHandler(ref);
});

/// Global error handler that delegates to domain-specific handlers
class GlobalErrorHandler {
  final Ref _ref;

  // Domain-specific handlers
  late final AuthErrorHandler _authHandler;
  final TeamErrorHandler _teamHandler = TeamErrorHandler();
  final ActivityErrorHandler _activityHandler = ActivityErrorHandler();

  GlobalErrorHandler(this._ref) {
    _authHandler = AuthErrorHandler(_ref);
  }

  /// Handle any AppException, routing to the appropriate domain handler
  ///
  /// [error] - The exception to handle
  /// [context] - BuildContext for navigation/dialogs
  /// [onRetry] - Optional callback for retry action
  /// [onRefreshFines] - Optional callback to refresh fines (for fine errors)
  ///
  /// Returns true if the error was fully handled
  Future<bool> handle(
    AppException error,
    BuildContext context, {
    VoidCallback? onRetry,
    VoidCallback? onRefreshFines,
  }) async {
    // Try auth handler first (session issues take priority)
    if (AuthErrorHandler.canHandle(error)) {
      return await _authHandler.handle(error, context);
    }

    // Try team handler
    if (TeamErrorHandler.canHandle(error)) {
      return await _teamHandler.handle(error, context);
    }

    // Try activity handler
    if (ActivityErrorHandler.canHandle(error)) {
      return await _activityHandler.handle(error, context);
    }

    // Try fine handler
    if (FineErrorHandler.canHandle(error)) {
      final fineHandler = FineErrorHandler(onRefreshFines: onRefreshFines);
      return await fineHandler.handle(error, context);
    }

    // Handle generic errors
    return _handleGenericError(error, context, onRetry: onRetry);
  }

  /// Handle generic errors not covered by domain handlers
  bool _handleGenericError(
    AppException error,
    BuildContext context, {
    VoidCallback? onRetry,
  }) {
    // Network errors with retry
    if (error is NetworkException) {
      ErrorDisplayService.showError(error, onRetry: onRetry);
      return true;
    }

    // Server errors with retry
    if (error is ServerException || error is ServiceUnavailableException) {
      ErrorDisplayService.showError(error, onRetry: onRetry);
      return true;
    }

    // Rate limit errors
    if (error is RateLimitException) {
      final message = error.retryAfter != null
          ? '${error.message} Prøv igjen om ${error.retryAfter!.inSeconds} sekunder.'
          : error.message;
      ErrorDisplayService.showWarning(message);
      return true;
    }

    // Validation errors - show as warning
    if (error is ValidationException) {
      ErrorDisplayService.showWarning(error.message);
      return true;
    }

    // Not found errors
    if (error is NotFoundException) {
      ErrorDisplayService.showError(error);
      return true;
    }

    // Conflict errors
    if (error is ConflictException) {
      ErrorDisplayService.showWarning(error.message);
      return true;
    }

    // Default: show error
    ErrorDisplayService.showError(error, onRetry: onRetry);
    return true;
  }

  /// Show an error without any special handling
  void showError(AppException error, {VoidCallback? onRetry}) {
    ErrorDisplayService.showError(error, onRetry: onRetry);
  }

  /// Show a success message
  void showSuccess(String message) {
    ErrorDisplayService.showSuccess(message);
  }

  /// Show a warning message
  void showWarning(String message) {
    ErrorDisplayService.showWarning(message);
  }
}
