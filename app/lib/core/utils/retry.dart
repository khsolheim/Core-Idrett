import '../errors/app_exceptions.dart';

/// Retry an async operation with exponential backoff
///
/// [action] - The async function to retry
/// [maxAttempts] - Maximum number of attempts (default: 3)
/// [initialDelay] - Initial delay before first retry (default: 1 second)
/// [maxDelay] - Maximum delay between retries (default: 30 seconds)
/// [shouldRetry] - Optional function to determine if an exception should be retried
///
/// Throws the last exception if all attempts fail
Future<T> retry<T>({
  required Future<T> Function() action,
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 30),
  bool Function(Exception)? shouldRetry,
}) async {
  int attempts = 0;
  Duration currentDelay = initialDelay;

  while (true) {
    try {
      attempts++;
      return await action();
    } catch (e) {
      if (attempts >= maxAttempts) {
        rethrow;
      }

      // Check if we should retry this type of error
      if (!_shouldRetryError(e, shouldRetry)) {
        rethrow;
      }

      // Wait before retrying with exponential backoff
      await Future.delayed(currentDelay);

      // Calculate next delay with exponential backoff
      currentDelay = Duration(
        milliseconds: (currentDelay.inMilliseconds * 2).clamp(
          0,
          maxDelay.inMilliseconds,
        ),
      );
    }
  }
}

/// Determine if an error should be retried
bool _shouldRetryError(Object e, bool Function(Exception)? customCheck) {
  // Check custom retry logic first
  if (customCheck != null && e is Exception) {
    return customCheck(e);
  }

  // Don't retry authentication or validation errors
  if (e is AuthException || e is ValidationException) {
    return false;
  }

  // Don't retry resource errors (not found, deleted, etc.)
  if (e is NotFoundException ||
      e is ResourceDeletedException ||
      e is ConflictException) {
    return false;
  }

  // Don't retry business logic errors
  if (e is FineAlreadyProcessedException ||
      e is AppealNotAllowedException ||
      e is DeadlineExpiredException) {
    return false;
  }

  // Retry network errors
  if (e is NetworkException) {
    return true;
  }

  // Retry server errors
  if (e is ServerException || e is ServiceUnavailableException) {
    return true;
  }

  // Retry rate limit errors (they include a retry-after hint)
  if (e is RateLimitException) {
    return true;
  }

  // Don't retry unknown errors by default
  return false;
}

/// Retry with callback for each attempt
///
/// [onAttempt] is called before each retry with the current attempt number
/// and the previous exception
Future<T> retryWithCallback<T>({
  required Future<T> Function() action,
  required void Function(int attempt, Object error) onAttempt,
  int maxAttempts = 3,
  Duration initialDelay = const Duration(seconds: 1),
  Duration maxDelay = const Duration(seconds: 30),
  bool Function(Exception)? shouldRetry,
}) async {
  int attempts = 0;
  Duration currentDelay = initialDelay;

  while (true) {
    try {
      attempts++;
      return await action();
    } catch (e) {
      if (attempts >= maxAttempts) {
        rethrow;
      }

      if (!_shouldRetryError(e, shouldRetry)) {
        rethrow;
      }

      // Notify about retry attempt
      onAttempt(attempts, e);

      await Future.delayed(currentDelay);

      currentDelay = Duration(
        milliseconds: (currentDelay.inMilliseconds * 2).clamp(
          0,
          maxDelay.inMilliseconds,
        ),
      );
    }
  }
}

/// Retry specifically for rate-limited operations
/// Respects the retry-after hint from RateLimitException
Future<T> retryRateLimited<T>({
  required Future<T> Function() action,
  int maxAttempts = 3,
  Duration defaultDelay = const Duration(seconds: 5),
}) async {
  int attempts = 0;

  while (true) {
    try {
      attempts++;
      return await action();
    } on RateLimitException catch (e) {
      if (attempts >= maxAttempts) {
        rethrow;
      }

      // Use the server-provided delay or fall back to default
      final delay = e.retryAfter ?? defaultDelay;
      await Future.delayed(delay);
    }
  }
}

/// Extension to add retry capability to any Future
extension RetryFuture<T> on Future<T> {
  /// Retry this future with the given configuration
  Future<T> withRetry({
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    return retry(
      action: () => this,
      maxAttempts: maxAttempts,
      initialDelay: initialDelay,
    );
  }
}
