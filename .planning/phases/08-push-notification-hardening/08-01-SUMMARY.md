---
phase: 08-push-notification-hardening
plan: 01
subsystem: notifications
tags: [firebase, fcm, flutter_local_notifications, flutter_secure_storage, retry, push-notifications]

# Dependency graph
requires:
  - phase: existing-notifications
    provides: "Basic FCM setup with firebase_messaging, NotificationService, notification_repository"
provides:
  - "Firebase Core initialization at app startup with graceful failure handling"
  - "NotificationLocalDataSource for secure FCM token persistence with timestamp tracking"
  - "ForegroundNotificationService for local notification display on Android/iOS"
  - "flutter_local_notifications, retry, flutter_secure_storage packages installed"
  - "Android notification channel configuration for FCM background messages"
affects: [08-02-token-retry, 08-03-foreground-display, notifications]

# Tech tracking
tech-stack:
  added: [flutter_local_notifications ^18.0.1, retry ^3.1.2, flutter_secure_storage ^9.2.2, firebase_core]
  patterns: [secure-token-persistence, graceful-firebase-initialization, local-notification-display]

key-files:
  created:
    - app/lib/features/notifications/data/notification_local_data_source.dart
    - app/lib/features/notifications/services/foreground_notification_service.dart
  modified:
    - app/pubspec.yaml
    - app/lib/main.dart
    - app/android/app/src/main/AndroidManifest.xml

key-decisions:
  - "Firebase.initializeApp() wrapped in try/catch - allows app to run without Firebase config, FCM fails gracefully until configured"
  - "NotificationLocalDataSource uses flutter_secure_storage for FCM token - more secure than SharedPreferences"
  - "24-hour token reregistration threshold - balances server load with token freshness"
  - "ForegroundNotificationService uses notification.hashCode as ID - avoids manual ID management"
  - "Android notification channel 'core_idrett_default' with high importance - ensures visibility"
  - "Firebase configuration skipped (user choice) - code ready, user will configure later via flutterfire CLI"

patterns-established:
  - "Graceful service initialization: try/catch around Firebase.initializeApp() with debug logging only"
  - "Secure local storage: FlutterSecureStorage for sensitive data (FCM tokens)"
  - "Timestamp-based sync: Store last-sync time to detect when token needs reregistration"
  - "Injectable dependencies: Services accept optional dependencies for testing (storage, plugin)"

# Metrics
duration: 10min
completed: 2026-02-09
---

# Phase 08 Plan 01: Foundation Services Summary

**Firebase Core initialization with secure FCM token persistence and local notification display foundation ready for token retry and foreground handling**

## Performance

- **Duration:** 10 min
- **Started:** 2026-02-09T15:17:00Z (Task 1 commit)
- **Completed:** 2026-02-09T15:27:00Z (User skipped Task 2)
- **Tasks:** 2 (1 auto, 1 checkpoint:human-action skipped)
- **Files modified:** 6

## Accomplishments
- Three new packages installed: flutter_local_notifications (local notification display), retry (token registration retry logic), flutter_secure_storage (secure token persistence)
- Firebase Core initialization added to main.dart with graceful failure handling (try/catch) - app runs without Firebase config
- NotificationLocalDataSource created with secure token persistence using FlutterSecureStorage, timestamp tracking, and 24-hour reregistration check
- ForegroundNotificationService created with flutter_local_notifications plugin, Android notification channel setup, and FCM message display
- Android notification channel configured in AndroidManifest.xml for background FCM message consistency

## Task Commits

Each task was committed atomically:

1. **Task 1: Install packages and create foundation services** - `68fec53` (feat)
2. **Task 2: Configure Firebase for the project** - Skipped (user choice - Firebase config deferred)

**Plan metadata:** (Will be committed with SUMMARY.md and STATE.md updates)

## Files Created/Modified

**Created:**
- `app/lib/features/notifications/data/notification_local_data_source.dart` (47 lines) - Secure FCM token storage with FlutterSecureStorage, timestamp tracking, 24-hour reregistration check, logout cleanup
- `app/lib/features/notifications/services/foreground_notification_service.dart` (82 lines) - Local notification display using flutter_local_notifications, Android notification channel setup, foreground FCM message handling

**Modified:**
- `app/pubspec.yaml` - Added flutter_local_notifications ^18.0.1, retry ^3.1.2, flutter_secure_storage ^9.2.2
- `app/lib/main.dart` - Added Firebase.initializeApp() in try/catch (non-blocking, graceful failure if not configured)
- `app/android/app/src/main/AndroidManifest.xml` - Added FCM default notification channel meta-data (core_idrett_default)
- `app/pubspec.lock` - Updated with new dependencies (86 lines changed)

## Decisions Made

**1. Firebase graceful initialization pattern**
- Wrapped Firebase.initializeApp() in try/catch with debug-only logging
- Allows app to run without Firebase configuration files
- FCM functionality fails gracefully at runtime until Firebase is configured
- User can defer Firebase setup without blocking development

**2. Secure token storage with FlutterSecureStorage**
- More secure than SharedPreferences for sensitive FCM tokens
- Encrypted storage on iOS keychain and Android keystore
- Token + timestamp stored together for reregistration logic

**3. 24-hour token reregistration threshold**
- Balances server load with token freshness
- Prevents unnecessary backend calls on every app launch
- Ensures tokens stay relatively fresh for reliability

**4. Injectable dependencies for testing**
- NotificationLocalDataSource accepts optional FlutterSecureStorage
- ForegroundNotificationService accepts optional FlutterLocalNotificationsPlugin
- Enables unit testing without platform dependencies

**5. Firebase configuration deferred (user choice)**
- User skipped Task 2 checkpoint (Firebase config via flutterfire CLI)
- Code is ready, Firebase will be configured later
- No blockers for Plans 08-02 and 08-03 - code compiles and runs

## Deviations from Plan

None - plan executed exactly as written. Task 2 (Firebase configuration) was a checkpoint:human-action that the user chose to skip as per the plan's resume-signal option.

## Issues Encountered

None - all steps executed as planned.

## User Setup Required

**Firebase configuration deferred (user skipped).**

When ready to enable FCM functionality:
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Log in to Firebase: `firebase login`
4. From app directory: `flutterfire configure`
   - Generates `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`
5. Update main.dart to import and use generated options:
   ```dart
   import 'firebase_options.dart';
   // Change Firebase.initializeApp() to:
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
   ```

**Until configured:** App runs normally, FCM functionality fails gracefully with debug logs only.

## Next Phase Readiness

**Ready for Phase 08-02 (Token Retry/Persistence):**
- NotificationLocalDataSource provides token storage and reregistration check
- retry package installed for exponential backoff logic
- Graceful Firebase initialization won't block token registration attempts

**Ready for Phase 08-03 (Foreground Notification Display):**
- ForegroundNotificationService provides local notification display
- flutter_local_notifications configured with Android channel
- FCM message handling ready for foreground integration

**No blockers:** Firebase configuration is optional at this stage - Plans 08-02 and 08-03 will implement the logic that uses these foundation services. Firebase can be configured anytime before production deployment.

## Self-Check: PASSED

**Files verified:**
- ✓ notification_local_data_source.dart exists
- ✓ foreground_notification_service.dart exists
- ✓ pubspec.yaml contains all three packages
- ✓ main.dart contains Firebase.initializeApp()
- ✓ AndroidManifest.xml exists

**Commits verified:**
- ✓ 68fec53 exists (Task 1: feat)

---
*Phase: 08-push-notification-hardening*
*Completed: 2026-02-09*
