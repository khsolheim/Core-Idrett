---
phase: 08-push-notification-hardening
plan: 02
subsystem: notifications
tags: [fcm, retry, persistence, error-logging, push-notifications]

# Dependency graph
requires:
  - phase: 08-01
    provides: "NotificationLocalDataSource, retry package, firebase_core initialization"
provides:
  - "FCM token registration with exponential backoff retry (8 attempts, 400ms-60s)"
  - "Token + timestamp persistence locally after successful registration"
  - "Stale token recovery on startup (>24h triggers reregistration)"
  - "Structured error logging with platform and error context"
  - "Non-blocking token registration (fire-and-forget with unawaited)"
affects: [08-03-foreground-display, notifications]

# Tech tracking
tech-stack:
  added: []
  patterns: [exponential-backoff-retry, fire-and-forget-async, stale-token-recovery, selective-retry-logic]

key-files:
  created: []
  modified:
    - app/lib/features/notifications/providers/notification_provider.dart

key-decisions:
  - "8 retry attempts with exponential backoff - balances persistence with resource usage"
  - "400ms-60s delay range with 0.25 jitter - prevents thundering herd while remaining responsive"
  - "Selective retry logic - only retry network/timeout/server errors, not client errors (400/401/403/404)"
  - "Failed registrations save token with epoch 0 timestamp - triggers immediate retry on next startup"
  - "Fire-and-forget pattern with unawaited() - token registration never blocks app startup or UI thread"
  - "Debug-only error logging - production errors deferred to future Crashlytics integration"

patterns-established:
  - "Exponential backoff retry: RetryOptions with maxAttempts, delayFactor, randomizationFactor, maxDelay"
  - "Selective retry predicate: _isRetryableError() checks exception type to avoid pointless retries"
  - "Fire-and-forget async: unawaited() makes non-blocking intent explicit, avoids lint warnings"
  - "Stale recovery pattern: Check needsReregistration() on startup, reregister if >24h old"

# Metrics
duration: 19min
completed: 2026-02-09
---

# Phase 08 Plan 02: Token Retry and Persistence Summary

**FCM token registration hardened with exponential backoff retry, local persistence, stale token recovery, and structured error logging**

## Performance

- **Duration:** 19 min
- **Started:** 2026-02-09T15:39:26Z
- **Completed:** 2026-02-09T15:59:00Z
- **Tasks:** 1 (1 auto)
- **Files modified:** 1

## Accomplishments
- Exponential backoff retry added to FCM token registration (8 attempts, 400ms-60s delay, 0.25 jitter)
- Selective retry logic - retries network/timeout/server errors, skips client errors (400/401/403/404)
- Token + timestamp persisted locally via NotificationLocalDataSource after successful registration
- Failed registrations save token with epoch 0 timestamp to trigger immediate retry on next startup
- Stale token recovery runs on initialize() - reregisters tokens >24h since last sync
- Fire-and-forget pattern with unawaited() ensures token registration never blocks app startup
- Structured error logging with platform context and debug-only output
- removeToken() updated to clear both remote and local token data

## Task Commits

Each task was committed atomically:

1. **Task 1: Add retry logic, local persistence, and error logging to FcmTokenNotifier** - `fedd174` (feat)

**Plan metadata commit:** (Will be committed with SUMMARY.md and STATE.md updates)

## Files Created/Modified

**Modified:**
- `app/lib/features/notifications/providers/notification_provider.dart` (+72/-9 lines)
  - Added imports: dart:async, flutter/foundation.dart, retry package, app_exceptions.dart, notification_local_data_source.dart
  - Added NotificationLocalDataSource dependency via notificationLocalDataSourceProvider
  - Replaced _registerToken() with _registerTokenWithRetry() using RetryOptions
  - Added _isRetryableError() predicate for selective retry (network/timeout/server only)
  - Added _logRegistrationError() with platform context and debug-only output
  - Added _recoverStaleToken() to check and reregister stale tokens on startup
  - Updated initialize() to use unawaited() for fire-and-forget token registration
  - Updated removeToken() to call _localDataSource.clearToken()

## Decisions Made

**1. 8 retry attempts with exponential backoff**
- maxAttempts: 8 - provides ~5 minutes of retries (400ms, 800ms, 1.6s, 3.2s, 6.4s, 12.8s, 25.6s, 60s)
- Balances persistence (high chance of success) with resource usage (avoids infinite retry)
- Combined with jitter (0.25 randomization factor) prevents thundering herd on server recovery

**2. Selective retry logic**
- Only retry NetworkException, TimeoutException, ServerException, ServiceUnavailableException
- Skip client errors (400/401/403/404) - these won't change on retry
- Avoids wasting retry attempts on permanent failures
- Reduces server load from pointless retry attempts

**3. Failed registrations save token with epoch 0 timestamp**
- Ensures stale token recovery will trigger immediate reregistration on next startup
- Provides automatic recovery mechanism without manual intervention
- Persists token locally even on failure so it's not lost

**4. Fire-and-forget pattern with unawaited()**
- Makes non-blocking intent explicit in code
- Avoids dart analyzer warnings about unhandled futures
- Ensures token registration never blocks app startup or UI thread
- Users can interact with app immediately, registration happens in background

**5. Debug-only error logging**
- Uses kDebugMode check to prevent production logging overhead
- Includes platform (ios/android) and error details for debugging
- TODO marker for future Crashlytics integration
- Production errors fail silently (user continues using app)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - all steps executed as planned.

## Technical Details

**RetryOptions Configuration:**
```dart
static const _retryOptions = RetryOptions(
  maxAttempts: 8,
  delayFactor: Duration(milliseconds: 400),
  randomizationFactor: 0.25,
  maxDelay: Duration(seconds: 60),
);
```

**Retry Timing (with jitter):**
- Attempt 1: immediate
- Attempt 2: 300-500ms
- Attempt 3: 600-1000ms
- Attempt 4: 1.2-2.0s
- Attempt 5: 2.4-4.0s
- Attempt 6: 4.8-8.0s
- Attempt 7: 9.6-16.0s
- Attempt 8: 19.2-32.0s (capped at 60s: 45-60s)

**Retryable Errors:**
- NetworkException - no internet connection
- TimeoutException - request timeout
- ServerException - 5xx server errors
- ServiceUnavailableException - 503 service unavailable

**Non-Retryable Errors:**
- Client errors (400, 401, 403, 404) - won't change on retry
- ValidationException - invalid token format
- Unknown exceptions - avoid retry loops

**Token Lifecycle:**
1. FCM generates token
2. initialize() calls _registerTokenWithRetry(token) with unawaited()
3. RetryOptions.retry() attempts backend registration up to 8 times
4. On success: saveToken(token, DateTime.now().toUtc())
5. On failure: saveToken(token, DateTime.fromMillisecondsSinceEpoch(0))
6. On next startup: _recoverStaleToken() checks needsReregistration()
7. If >24h or epoch 0: call _registerTokenWithRetry() again

## Next Phase Readiness

**Ready for Phase 08-03 (Foreground Notification Display):**
- Token registration is now reliable with retry and persistence
- ForegroundNotificationService installed in 08-01 ready for integration
- _handleForegroundMessage() stub ready to be updated to use ForegroundNotificationService
- Error logging foundation in place for tracking notification display issues

**No blockers:** Plan 08-03 can proceed to integrate ForegroundNotificationService with the hardened token registration.

## Self-Check: PASSED

**Files verified:**
- ✓ notification_provider.dart contains RetryOptions
- ✓ notification_provider.dart contains notificationLocalDataSourceProvider
- ✓ notification_provider.dart contains _registerTokenWithRetry
- ✓ notification_provider.dart contains _recoverStaleToken
- ✓ notification_provider.dart contains _isRetryableError
- ✓ notification_provider.dart contains _logRegistrationError
- ✓ notification_provider.dart contains unawaited
- ✓ flutter analyze passes with no new errors

**Commits verified:**
- ✓ fedd174 exists (Task 1: feat)

**Configuration verified:**
- ✓ maxAttempts: 8
- ✓ delayFactor: Duration(milliseconds: 400)
- ✓ randomizationFactor: 0.25
- ✓ maxDelay: Duration(seconds: 60)
- ✓ Retry logic checks NetworkException, TimeoutException, ServerException, ServiceUnavailableException
- ✓ Success path saves token with DateTime.now().toUtc()
- ✓ Failure path saves token with DateTime.fromMillisecondsSinceEpoch(0)
- ✓ removeToken() calls _localDataSource.clearToken()

---
*Phase: 08-push-notification-hardening*
*Completed: 2026-02-09*
