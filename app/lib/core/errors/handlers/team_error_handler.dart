import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app_exceptions.dart';
import '../../services/error_display_service.dart';

/// Handler for team-related errors
class TeamErrorHandler {
  /// Handle a team-related error
  /// Returns true if the error was handled and navigation occurred
  Future<bool> handle(AppException error, BuildContext context) async {
    if (error is TeamNotFoundException) {
      return _handleTeamNotFound(error, context);
    }

    if (error is RemovedFromTeamException) {
      return _handleRemovedFromTeam(error, context);
    }

    if (error is RoleChangedException) {
      return _handleRoleChanged(error, context);
    }

    if (error is NoTeamsException) {
      return _handleNoTeams(error, context);
    }

    return false;
  }

  /// Handle team not found - navigate to team list
  bool _handleTeamNotFound(AppException error, BuildContext context) {
    ErrorDisplayService.showError(error);

    if (context.mounted) {
      context.goNamed('teams');
    }

    return true;
  }

  /// Handle user removed from team - navigate to team list
  bool _handleRemovedFromTeam(AppException error, BuildContext context) {
    if (!context.mounted) return false;

    // Show informative snackbar
    ErrorDisplayService.showWarning(error.message);

    // Navigate to team list
    context.goNamed('teams');

    return true;
  }

  /// Handle role change - refresh and notify
  bool _handleRoleChanged(AppException error, BuildContext context) {
    // Show the role changed message
    ErrorDisplayService.showInfo(error.message);

    // Don't navigate - let the screen refresh to show new permissions
    return true;
  }

  /// Handle no teams - navigate to team creation
  bool _handleNoTeams(AppException error, BuildContext context) {
    if (!context.mounted) return false;

    // Navigate to team creation
    context.goNamed('create-team');

    return true;
  }

  /// Check if an error is a team error that this handler can handle
  static bool canHandle(AppException error) {
    return error is TeamNotFoundException ||
        error is RemovedFromTeamException ||
        error is RoleChangedException ||
        error is NoTeamsException;
  }
}
