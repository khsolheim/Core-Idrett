import 'app_exceptions.dart';

/// Enum of all error codes with their default messages
enum ErrorCode {
  // Network errors
  noInternet('NO_INTERNET', 'Ingen internettforbindelse'),
  timeout('TIMEOUT', 'Forespørselen tok for lang tid'),
  connectionFailed('CONNECTION_FAILED', 'Kunne ikke koble til server'),

  // Authentication errors
  tokenExpired('TOKEN_EXPIRED', 'Sesjonen har utløpt. Logg inn på nytt.'),
  unauthorized('UNAUTHORIZED', 'Du har ikke tilgang'),
  invalidCredentials('INVALID_CREDENTIALS', 'Feil e-post eller passord'),
  invalidInviteCode('INVALID_INVITE', 'Invitasjonskoden er ugyldig eller utløpt'),
  inviteCodeUsed('INVITE_USED', 'Invitasjonskoden er allerede brukt'),
  sessionInvalidated('SESSION_INVALIDATED', 'Du er logget inn på en annen enhet'),

  // Resource errors
  notFound('NOT_FOUND', 'Ressursen ble ikke funnet'),
  deleted('DELETED', 'Ressursen er slettet'),
  conflict('CONFLICT', 'En konflikt oppstod'),

  // Team errors
  teamNotFound('TEAM_NOT_FOUND', 'Laget finnes ikke'),
  removedFromTeam('REMOVED_FROM_TEAM', 'Du er fjernet fra dette laget'),
  roleChanged('ROLE_CHANGED', 'Tilgangen din er endret'),
  noTeams('NO_TEAMS', 'Du er ikke medlem av noen lag'),

  // Activity errors
  activityCancelled('ACTIVITY_CANCELLED', 'Aktiviteten er avlyst'),
  deadlineExpired('DEADLINE_EXPIRED', 'Fristen har utløpt'),
  activityDeleted('ACTIVITY_DELETED', 'Aktiviteten er slettet'),

  // Fine errors
  fineAlreadyProcessed('FINE_PROCESSED', 'Boten er allerede behandlet av en annen'),
  appealNotAllowed('APPEAL_NOT_ALLOWED', 'Du kan ikke klage på denne boten'),
  fineRuleDeleted('RULE_DELETED', 'Bøteregelen er slettet'),

  // Server errors
  serverError('SERVER_ERROR', 'En serverfeil oppstod'),
  serviceUnavailable('SERVICE_UNAVAILABLE', 'Tjenesten er midlertidig utilgjengelig'),

  // Validation errors
  validationError('VALIDATION_ERROR', 'Ugyldig data'),

  // Rate limiting
  rateLimited('RATE_LIMITED', 'For mange forespørsler. Vent litt.'),

  // Unknown
  unknown('UNKNOWN', 'En ukjent feil oppstod');

  final String code;
  final String message;

  const ErrorCode(this.code, this.message);

  /// Get ErrorCode from string code
  static ErrorCode fromCode(String? code) {
    if (code == null) return ErrorCode.unknown;

    return ErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ErrorCode.unknown,
    );
  }

  /// Convert to AppException
  AppException toException({String? customMessage}) {
    final msg = customMessage ?? message;

    switch (this) {
      case ErrorCode.noInternet:
        return const NoInternetException();
      case ErrorCode.timeout:
        return const TimeoutException();
      case ErrorCode.connectionFailed:
        return const ConnectionFailedException();
      case ErrorCode.tokenExpired:
        return const TokenExpiredException();
      case ErrorCode.unauthorized:
        return const UnauthorizedException();
      case ErrorCode.invalidCredentials:
        return const InvalidCredentialsException();
      case ErrorCode.invalidInviteCode:
        return const InvalidInviteCodeException();
      case ErrorCode.inviteCodeUsed:
        return const InviteCodeUsedException();
      case ErrorCode.sessionInvalidated:
        return const SessionInvalidatedException();
      case ErrorCode.notFound:
        return NotFoundException(msg);
      case ErrorCode.deleted:
        return ResourceDeletedException(msg);
      case ErrorCode.conflict:
        return ConflictException(msg);
      case ErrorCode.teamNotFound:
        return const TeamNotFoundException();
      case ErrorCode.removedFromTeam:
        return const RemovedFromTeamException();
      case ErrorCode.roleChanged:
        return const RoleChangedException();
      case ErrorCode.noTeams:
        return const NoTeamsException();
      case ErrorCode.activityCancelled:
        return const ActivityCancelledException();
      case ErrorCode.deadlineExpired:
        return const DeadlineExpiredException();
      case ErrorCode.activityDeleted:
        return const ActivityDeletedException();
      case ErrorCode.fineAlreadyProcessed:
        return const FineAlreadyProcessedException();
      case ErrorCode.appealNotAllowed:
        return const AppealNotAllowedException();
      case ErrorCode.fineRuleDeleted:
        return const FineRuleDeletedException();
      case ErrorCode.serverError:
        return ServerException(msg);
      case ErrorCode.serviceUnavailable:
        return const ServiceUnavailableException();
      case ErrorCode.validationError:
        return ValidationException(msg);
      case ErrorCode.rateLimited:
        return const RateLimitException();
      case ErrorCode.unknown:
        return UnknownException(msg);
    }
  }

  /// Check if this error code represents a retriable error
  bool get isRetriable {
    switch (this) {
      case ErrorCode.noInternet:
      case ErrorCode.timeout:
      case ErrorCode.connectionFailed:
      case ErrorCode.serverError:
      case ErrorCode.serviceUnavailable:
      case ErrorCode.rateLimited:
        return true;
      default:
        return false;
    }
  }

  /// Check if this error code requires re-authentication
  bool get requiresReauth {
    switch (this) {
      case ErrorCode.tokenExpired:
      case ErrorCode.sessionInvalidated:
        return true;
      default:
        return false;
    }
  }
}
