import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app_exceptions.dart';
import '../../services/error_display_service.dart';

/// Provider for the auth error handler
final authErrorHandlerProvider = Provider<AuthErrorHandler>((ref) {
  return AuthErrorHandler(ref);
});

/// Handler for authentication-related errors
class AuthErrorHandler {
  // ignore: unused_field - kept for future auth state management
  final Ref _ref;

  AuthErrorHandler(this._ref);

  /// Handle an authentication error
  /// Returns true if the error was handled and navigation occurred
  Future<bool> handle(AppException error, BuildContext context) async {
    if (error is TokenExpiredException || error is SessionInvalidatedException) {
      return await _handleSessionExpired(error, context);
    }

    if (error is UnauthorizedException) {
      return _handleUnauthorized(error, context);
    }

    if (error is InvalidCredentialsException) {
      return _handleInvalidCredentials(error, context);
    }

    if (error is InvalidInviteCodeException || error is InviteCodeUsedException) {
      return _handleInviteError(error, context);
    }

    return false;
  }

  /// Handle expired session - navigate to login
  Future<bool> _handleSessionExpired(
    AppException error,
    BuildContext context,
  ) async {
    if (!context.mounted) return false;

    // Show dialog explaining the session expired
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.orange),
            SizedBox(width: 12),
            Text('Sesjon utløpt'),
          ],
        ),
        content: Text(error.message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Logg inn på nytt'),
          ),
        ],
      ),
    );

    if (!context.mounted) return true;

    // Navigate to login and clear the navigation stack
    context.go('/login');

    return true;
  }

  /// Handle unauthorized access
  bool _handleUnauthorized(AppException error, BuildContext context) {
    ErrorDisplayService.showError(error);

    // Navigate back if possible
    if (context.mounted && context.canPop()) {
      context.pop();
    }

    return true;
  }

  /// Handle invalid credentials during login
  bool _handleInvalidCredentials(AppException error, BuildContext context) {
    // Just show the error - user should stay on login page
    ErrorDisplayService.showError(error);
    return true;
  }

  /// Handle invite code errors
  bool _handleInviteError(AppException error, BuildContext context) {
    ErrorDisplayService.showError(error);
    return true;
  }

  /// Check if an error is an auth error that this handler can handle
  static bool canHandle(AppException error) {
    return error is AuthException;
  }
}
