/// Base exception class for all app exceptions
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

// ============================================================================
// Network Exceptions
// ============================================================================

/// Base class for network-related errors
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// No internet connection available
class NoInternetException extends NetworkException {
  const NoInternetException()
      : super('Ingen internettforbindelse', code: 'NO_INTERNET');
}

/// Request timed out
class TimeoutException extends NetworkException {
  const TimeoutException()
      : super('Forespørselen tok for lang tid', code: 'TIMEOUT');
}

/// Failed to connect to server
class ConnectionFailedException extends NetworkException {
  const ConnectionFailedException()
      : super('Kunne ikke koble til server', code: 'CONNECTION_FAILED');
}

// ============================================================================
// Authentication Exceptions
// ============================================================================

/// Base class for authentication-related errors
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Token has expired, user needs to re-authenticate
class TokenExpiredException extends AuthException {
  const TokenExpiredException()
      : super('Sesjonen har utløpt', code: 'TOKEN_EXPIRED');
}

/// User does not have permission to access resource
class UnauthorizedException extends AuthException {
  const UnauthorizedException()
      : super('Du har ikke tilgang', code: 'UNAUTHORIZED');
}

/// Invalid email or password during login
class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
      : super('Feil e-post eller passord', code: 'INVALID_CREDENTIALS');
}

/// Invite code is invalid or expired
class InvalidInviteCodeException extends AuthException {
  const InvalidInviteCodeException()
      : super(
          'Invitasjonskoden er ugyldig eller utløpt',
          code: 'INVALID_INVITE',
        );
}

/// Invite code has already been used
class InviteCodeUsedException extends AuthException {
  const InviteCodeUsedException()
      : super('Invitasjonskoden er allerede brukt', code: 'INVITE_USED');
}

/// Session was invalidated (logged in on another device)
class SessionInvalidatedException extends AuthException {
  const SessionInvalidatedException()
      : super('Du er logget inn på en annen enhet', code: 'SESSION_INVALIDATED');
}

// ============================================================================
// Resource Exceptions
// ============================================================================

/// Base class for resource-related errors
class ResourceException extends AppException {
  const ResourceException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Resource was not found
class NotFoundException extends ResourceException {
  final String resourceType;

  const NotFoundException(this.resourceType)
      : super('$resourceType ble ikke funnet', code: 'NOT_FOUND');
}

/// Conflict occurred (e.g., duplicate entry)
class ConflictException extends ResourceException {
  const ConflictException(super.message) : super(code: 'CONFLICT');
}

/// Resource has been deleted
class ResourceDeletedException extends ResourceException {
  final String resourceType;

  const ResourceDeletedException(this.resourceType)
      : super('$resourceType er slettet', code: 'DELETED');
}

// ============================================================================
// Team Exceptions
// ============================================================================

/// Team was not found
class TeamNotFoundException extends ResourceException {
  const TeamNotFoundException()
      : super('Laget finnes ikke', code: 'TEAM_NOT_FOUND');
}

/// User was removed from team
class RemovedFromTeamException extends ResourceException {
  const RemovedFromTeamException()
      : super('Du er fjernet fra dette laget', code: 'REMOVED_FROM_TEAM');
}

/// User's role in team has changed
class RoleChangedException extends ResourceException {
  const RoleChangedException()
      : super('Tilgangen din er endret', code: 'ROLE_CHANGED');
}

/// User is not a member of any teams
class NoTeamsException extends ResourceException {
  const NoTeamsException()
      : super('Du er ikke medlem av noen lag', code: 'NO_TEAMS');
}

// ============================================================================
// Activity Exceptions
// ============================================================================

/// Activity has been cancelled
class ActivityCancelledException extends ResourceException {
  const ActivityCancelledException()
      : super('Aktiviteten er avlyst', code: 'ACTIVITY_CANCELLED');
}

/// Activity deadline has expired
class DeadlineExpiredException extends ResourceException {
  const DeadlineExpiredException()
      : super('Fristen har utløpt', code: 'DEADLINE_EXPIRED');
}

/// Activity has been deleted
class ActivityDeletedException extends ResourceException {
  const ActivityDeletedException()
      : super('Aktiviteten er slettet', code: 'ACTIVITY_DELETED');
}

// ============================================================================
// Fine Exceptions
// ============================================================================

/// Fine has already been processed by another user
class FineAlreadyProcessedException extends ResourceException {
  const FineAlreadyProcessedException()
      : super('Boten er allerede behandlet', code: 'FINE_PROCESSED');
}

/// User cannot appeal this fine
class AppealNotAllowedException extends ResourceException {
  const AppealNotAllowedException()
      : super('Du kan ikke klage på denne boten', code: 'APPEAL_NOT_ALLOWED');
}

/// Fine rule has been deleted
class FineRuleDeletedException extends ResourceException {
  const FineRuleDeletedException()
      : super('Bøteregelen er slettet', code: 'RULE_DELETED');
}

// ============================================================================
// Validation Exceptions
// ============================================================================

/// Validation error with optional field-specific errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  }) : super(code: 'VALIDATION_ERROR');

  /// Get error message for a specific field
  String? getFieldError(String field) => fieldErrors?[field];

  /// Check if a specific field has an error
  bool hasFieldError(String field) => fieldErrors?.containsKey(field) ?? false;
}

// ============================================================================
// Server Exceptions
// ============================================================================

/// Generic server error
class ServerException extends AppException {
  const ServerException([String? message])
      : super(message ?? 'En serverfeil oppstod', code: 'SERVER_ERROR');
}

/// Service is temporarily unavailable
class ServiceUnavailableException extends AppException {
  const ServiceUnavailableException()
      : super(
          'Tjenesten er midlertidig utilgjengelig',
          code: 'SERVICE_UNAVAILABLE',
        );
}

// ============================================================================
// Rate Limiting
// ============================================================================

/// Too many requests - rate limited
class RateLimitException extends AppException {
  final Duration? retryAfter;

  const RateLimitException({this.retryAfter})
      : super('For mange forespørsler. Vent litt.', code: 'RATE_LIMITED');
}

// ============================================================================
// Unknown/Generic Exceptions
// ============================================================================

/// Unknown error occurred
class UnknownException extends AppException {
  const UnknownException([String? message])
      : super(message ?? 'En ukjent feil oppstod', code: 'UNKNOWN');
}
