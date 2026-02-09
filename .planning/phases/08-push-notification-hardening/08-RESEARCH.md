# Phase 8: Push Notification Hardening - Research

**Researched:** 2026-02-09
**Domain:** Firebase Cloud Messaging (FCM) with Flutter, Push Notification Reliability
**Confidence:** HIGH

## Summary

Phase 8 focuses on hardening the existing push notification implementation to ensure reliable FCM token management and foreground notification display. The current implementation has basic token registration but lacks retry logic, persistence for recovery, and proper foreground notification display.

Research reveals that Firebase's recommended approach emphasizes **proactive token management** (removing invalid tokens, tracking freshness) over reactive retry logic. For foreground notifications, Flutter requires platform-specific handling: iOS uses `setForegroundNotificationPresentationOptions()` while Android requires `flutter_local_notifications` integration.

The existing codebase already has `device_tokens` table with `last_used_at` tracking, `firebase_messaging: ^16.1.1`, error handling infrastructure via `GlobalErrorHandler`, and `ErrorDisplayService` for user feedback. Missing components are: exponential backoff retry logic, secure local token persistence, foreground notification display, and error logging/tracking integration.

**Primary recommendation:** Implement retry logic using Google's `retry` package (8 attempts with exponential backoff), add `flutter_local_notifications` for foreground display, persist token locally with `flutter_secure_storage` (not SharedPreferences due to security), and integrate error logging for token registration failures.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| firebase_messaging | ^16.1.1 | FCM token management, push notification reception | Official Firebase plugin, already in project |
| flutter_local_notifications | ^18.0.1 | Display foreground notifications on Android/iOS | De facto standard for local notifications, 88.8 Context7 benchmark score |
| retry | ^3.1.2 | Exponential backoff retry logic | Google Dart-Neats official package, battle-tested |
| flutter_secure_storage | ^9.2.2 | Secure token persistence | Industry standard for sensitive data (Keychain/Keystore) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| firebase_crashlytics | ^4.2.5 | Error tracking for production | Optional: for centralized error monitoring |
| connectivity_plus | ^7.0.0 | Network state detection | Already in project, useful for retry condition checks |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| retry package | backoff package | backoff has more config options but retry is Google-maintained and simpler |
| flutter_secure_storage | encrypted_shared_preferences | encrypted_shared_preferences adds encryption layer but secure_storage uses native Keychain/Keystore |
| flutter_local_notifications | awesome_notifications | awesome_notifications has more features but flutter_local_notifications is lighter and sufficient |

**Installation:**
```bash
cd "/Users/karsten/NextCore/Core - Idrett/app"
flutter pub add flutter_local_notifications retry flutter_secure_storage
```

## Architecture Patterns

### Recommended Project Structure
```
app/lib/features/notifications/
├── data/
│   ├── notification_repository.dart        # Existing - API calls
│   └── notification_local_data_source.dart # NEW - local token persistence
├── providers/
│   └── notification_provider.dart          # MODIFY - add retry + foreground display
└── services/
    └── foreground_notification_service.dart # NEW - flutter_local_notifications wrapper
```

### Pattern 1: Token Registration with Exponential Backoff
**What:** Wrap token registration API calls with retry logic that backs off exponentially on failure
**When to use:** During initial token fetch, token refresh events, and app restart recovery
**Example:**
```dart
// Source: Google retry package + Firebase best practices
import 'package:retry/retry.dart';

Future<void> _registerTokenWithRetry(String token) async {
  const retryOptions = RetryOptions(
    maxAttempts: 8,        // Default: 400ms, 800ms, 1.6s, 3.2s, 6.4s, 12.8s, 25.6s, 51.2s
    delayFactor: Duration(milliseconds: 400),
    randomizationFactor: 0.25,
    maxDelay: Duration(seconds: 60),
  );

  try {
    await retryOptions.retry(
      () => _repo.registerToken(token: token, platform: platform),
      retryIf: (e) => e is NetworkException || e is ServerException || e is TimeoutException,
    );
    _lastSuccessfulSync = DateTime.now();
    await _persistTokenLocally(token);
  } catch (e, stackTrace) {
    // Log to error tracking service
    _logTokenRegistrationError(e, stackTrace);
    // Still persist locally for next retry attempt
    await _persistTokenLocally(token);
  }
}
```

### Pattern 2: Token Persistence with Timestamp
**What:** Store FCM token locally with last-sync timestamp for recovery after app restart
**When to use:** After successful registration, on token refresh, on app startup recovery
**Example:**
```dart
// Source: Firebase best practices + flutter_secure_storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationLocalDataSource {
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'fcm_token';
  static const _timestampKey = 'fcm_token_timestamp';

  Future<void> saveToken(String token, DateTime timestamp) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _timestampKey, value: timestamp.toIso8601String()),
    ]);
  }

  Future<(String?, DateTime?)> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    final timestampStr = await _storage.read(key: _timestampKey);
    final timestamp = timestampStr != null ? DateTime.tryParse(timestampStr) : null;
    return (token, timestamp);
  }

  Future<bool> needsReregistration() async {
    final (token, timestamp) = await getToken();
    if (token == null || timestamp == null) return true;

    // Reregister if last sync was >24 hours ago
    return DateTime.now().difference(timestamp) > Duration(hours: 24);
  }
}
```

### Pattern 3: Foreground Notification Display
**What:** Display notifications when app is in foreground using flutter_local_notifications
**When to use:** When `FirebaseMessaging.onMessage` stream emits message
**Example:**
```dart
// Source: FlutterFire docs + flutter_local_notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      InitializationSettings(android: androidSettings, iOS: darwinSettings),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'fcm_default_channel',
      'Default Notifications',
      description: 'Notifications from Core - Idrett',
      importance: Importance.high,
    );
    await _plugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
  }

  Future<void> showNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'fcm_default_channel',
          'Default Notifications',
          channelDescription: 'Notifications from Core - Idrett',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'],
    );
  }
}
```

### Pattern 4: iOS Foreground Presentation Options
**What:** Configure iOS to show notifications when app is in foreground
**When to use:** During FCM initialization on iOS platform
**Example:**
```dart
// Source: FlutterFire official docs
if (Platform.isIOS) {
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,  // Shows banner
    badge: true,  // Updates badge count
    sound: true,  // Plays notification sound
  );
}
```

### Anti-Patterns to Avoid
- **Don't retry forever:** Use finite retry attempts (8 is Firebase's recommendation) with max delay cap (60s)
- **Don't use SharedPreferences for tokens:** FCM tokens are sensitive, use flutter_secure_storage with native encryption
- **Don't silently fail:** Log token registration errors to error tracking service for production monitoring
- **Don't block app startup:** Token registration should be fire-and-forget, retry in background
- **Don't ignore 404/400 errors:** These indicate invalid tokens, should delete local storage and request new token

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Exponential backoff | Custom sleep/delay logic | retry package | Handles jitter, maxDelay, retryIf conditions, well-tested by Google |
| Secure token storage | Custom encryption wrapper | flutter_secure_storage | Uses platform-native Keychain (iOS) and Keystore (Android), handles edge cases |
| Local notifications | Custom notification channels | flutter_local_notifications | Manages Android channels, iOS categories, permissions, handles OS version differences |
| Network detection | Polling connectivity | connectivity_plus | Already in project, efficient stream-based updates |

**Key insight:** Push notification reliability is deceptively complex. Exponential backoff needs jitter to avoid thundering herd, secure storage needs platform-specific encryption, foreground notifications need channel management on Android. These libraries handle OS fragmentation, permission flows, and edge cases that would take weeks to implement and test manually.

## Common Pitfalls

### Pitfall 1: Retry Amplification
**What goes wrong:** All users retry failed token registration at same time, overwhelming backend
**Why it happens:** No randomization/jitter in retry delays, all devices retry on same schedule
**How to avoid:** Use `retry` package's built-in randomizationFactor (±25%) and exponential backoff
**Warning signs:** Backend sees traffic spikes at regular intervals after outages

### Pitfall 2: Token Staleness Not Tracked
**What goes wrong:** App continues using stale token that backend already deleted/invalidated
**Why it happens:** No last-sync timestamp, can't detect when token needs reregistration
**How to avoid:** Persist token with timestamp, check age on startup, reregister if >24 hours old
**Warning signs:** Users report not receiving notifications, backend logs show UNREGISTERED errors

### Pitfall 3: Android Foreground Notifications Don't Show
**What goes wrong:** Notifications received via `onMessage` but nothing displays to user
**Why it happens:** Firebase SDK blocks foreground notifications on Android by design
**How to avoid:** Handle `onMessage` stream, use flutter_local_notifications to display manually
**Warning signs:** iOS notifications work in foreground, Android only works in background

### Pitfall 4: Using SharedPreferences for Tokens
**What goes wrong:** FCM tokens stored in plain text, readable by malicious apps on rooted devices
**Why it happens:** Developer assumes SharedPreferences is "good enough" for all preferences
**How to avoid:** Use flutter_secure_storage for tokens (AES + Keystore), SharedPreferences only for UI state
**Warning signs:** Security audits flag unencrypted token storage

### Pitfall 5: No Error Tracking for Registration Failures
**What goes wrong:** Silent failures in production, no visibility into how many users can't receive notifications
**Why it happens:** try/catch without logging, errors swallowed to prevent app crashes
**How to avoid:** Log all token registration errors with context (platform, error type, attempt count)
**Warning signs:** Users report missing notifications but no error logs to diagnose

### Pitfall 6: Blocking UI on Token Registration
**What goes wrong:** App startup delayed 10+ seconds while waiting for token registration to succeed/fail through all retries
**Why it happens:** Awaiting token registration synchronously during app initialization
**How to avoid:** Fire-and-forget registration, retry in background, don't await during startup
**Warning signs:** Slow app startup times, users see splash screen too long

## Code Examples

Verified patterns from official sources:

### Token Refresh Listener with Error Handling
```dart
// Source: Firebase Cloud Messaging Flutter docs
// https://firebase.google.com/docs/cloud-messaging/flutter/client
FirebaseMessaging.instance.onTokenRefresh
    .listen((fcmToken) {
      // Triggered at app startup and whenever token is regenerated
      _registerTokenWithRetry(fcmToken);
    })
    .onError((err) {
      // Log error but don't crash app
      _logTokenRefreshError(err);
    });
```

### Checking for Stale Local Token on Startup
```dart
// Source: Firebase best practices + secure storage pattern
Future<void> recoverTokenOnStartup() async {
  final (localToken, lastSync) = await _localDataSource.getToken();

  if (localToken == null || lastSync == null) {
    // No local token, will get fresh one from FCM
    return;
  }

  final tokenAge = DateTime.now().difference(lastSync);

  if (tokenAge > Duration(hours: 24)) {
    // Token might be stale, attempt reregistration
    try {
      await _registerTokenWithRetry(localToken);
    } catch (e) {
      // Reregistration failed, will retry on next token refresh event
      _logTokenRecoveryError(e);
    }
  }
}
```

### FCM Initialization with Foreground Handling
```dart
// Source: FlutterFire official docs
// https://firebase.flutter.dev/docs/messaging/notifications/
Future<void> initialize() async {
  if (_initialized) return;
  _initialized = true;

  final messaging = FirebaseMessaging.instance;

  // Request permissions
  final settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    // Configure iOS foreground presentation
    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // Get initial token
    final token = await messaging.getToken();
    if (token != null) {
      await _registerTokenWithRetry(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_registerTokenWithRetry).onError(_logTokenError);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _foregroundService.showNotification(message);
    });
  }
}
```

### Android Notification Channel Creation
```dart
// Source: flutter_local_notifications documentation
// https://pub.dev/packages/flutter_local_notifications
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'fcm_default_channel',           // id
  'Default Notifications',         // name
  description: 'Notifications from Core - Idrett',
  importance: Importance.high,     // Must be high for heads-up display
  playSound: true,
  enableVibration: true,
);

final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

await plugin
    .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
    ?.createNotificationChannel(channel);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Plain SharedPreferences | flutter_secure_storage with Keychain/Keystore | 2024+ | Tokens now encrypted at rest, secure on rooted devices |
| Manual retry loops | retry package with jitter | 2023+ | Exponential backoff with randomization prevents retry storms |
| firebase_messaging only | firebase_messaging + flutter_local_notifications | 2022+ | Android foreground notifications require manual display |
| HTTP/2 FCM API | HTTP v1 API | 2023 (deprecated 2024) | Old API removed, v1 required for new features |
| Legacy FCM channel config | AndroidManifest.xml meta-data | 2021+ | Default channel configured via manifest for background msgs |

**Deprecated/outdated:**
- **FCM HTTP v1 legacy API:** Deprecated June 2023, removed June 2024. Use HTTP v1 API (already default in firebase_messaging 16.x)
- **Background isolate handlers:** Old approach used top-level functions, now integrated into main isolate with onBackgroundMessage
- **Manual token deletion:** Firebase now auto-deletes tokens after 270 days of inactivity (since 2022)

## Open Questions

1. **Should we implement Firebase Crashlytics for error tracking?**
   - What we know: GlobalErrorHandler exists, ErrorDisplayService shows user feedback
   - What's unclear: Whether team wants centralized production error monitoring vs local logs
   - Recommendation: Optional for Phase 8, can defer to Phase 10 (Final Quality Pass). Include logging hooks now to make integration easier later.

2. **What should the reregistration threshold be (24h vs 7d vs 30d)?**
   - What we know: Firebase marks tokens stale after 30 days of inactivity, expires after 270 days
   - What's unclear: How often users restart app, balance between API calls and reliability
   - Recommendation: Start with 24 hours (conservative), can increase to 7 days after monitoring in production

3. **Should we persist notification payload for offline handling?**
   - What we know: Current implementation doesn't persist notification data locally
   - What's unclear: Whether team wants users to see "missed" notifications from when device was offline
   - Recommendation: Out of scope for Phase 8. Token management is the priority. Can revisit in Phase 10 if needed.

## Sources

### Primary (HIGH confidence)
- [Firebase Cloud Messaging - FlutterFire](https://firebase.flutter.dev/docs/messaging/notifications/) - Official FlutterFire documentation for FCM integration
- [Firebase Cloud Messaging Flutter Client](https://firebase.google.com/docs/cloud-messaging/flutter/client) - Official Firebase docs for token management
- [Firebase - Best practices for FCM registration token management](https://firebase.google.com/docs/cloud-messaging/manage-tokens) - Token lifecycle and error handling
- [Context7 - Flutter Local Notifications](https://context7.com/maikub/flutter_local_notifications/llms.txt) - Initialization and display patterns
- [Context7 - Firebase Documentation](https://firebase.google.com/docs) - FCM retry strategies and error codes
- [retry package - pub.dev](https://pub.dev/packages/retry) - Google Dart-Neats official retry package
- [flutter_local_notifications - pub.dev](https://pub.dev/packages/flutter_local_notifications) - Official package documentation

### Secondary (MEDIUM confidence)
- [Store key-value data on disk - Flutter Cookbook](https://docs.flutter.dev/cookbook/persistence/key-value) - SharedPreferences best practices
- [Report errors to a service - Flutter](https://docs.flutter.dev/cookbook/maintenance/error-reporting) - Error tracking patterns
- [Medium - How to Implement a Retry Interceptor in Flutter with Dio](https://medium.com/@jdavifranco/how-to-implement-a-retry-interceptor-in-flutter-with-dio-26ab3c157483) - Dio retry patterns
- [Medium - Using Flutter Secure Storage Vs Flutter Shared Preferences](https://medium.com/@dev.alababidy/using-flutter-secure-storage-vs-flutter-shared-preferences-b79c2f358fe8) - Security comparison
- [Medium - Flutter vs FCM: Handling Notifications in foreground/background/terminated lifecycles](https://medium.com/@lazizbekfayziyev/flutter-vs-fcm-handling-notifications-in-foreground-background-terminated-lifecycles-part-4-5dd36a06d5ec) - FCM lifecycle patterns

### Tertiary (LOW confidence)
- [10 best Flutter monitoring tools for 2026 - Embrace.io](https://embrace.io/blog/top-flutter-monitoring-tools/) - Error tracking tool overview
- [GitHub - patoliavishal/flutter-FCM](https://github.com/patoliavishal/flutter-FCM) - Community implementation example

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Firebase and Google packages, verified versions from pub.dev
- Architecture: HIGH - Patterns from official Firebase docs and Context7, verified with package documentation
- Pitfalls: MEDIUM-HIGH - Based on Firebase best practices docs and community reported issues, not all experienced firsthand

**Research date:** 2026-02-09
**Valid until:** 2026-03-09 (30 days - stable ecosystem, FCM API stable since 2024)

**Current project state:**
- ✅ firebase_messaging: ^16.1.1 already installed
- ✅ Device tokens table with last_used_at exists (migration 006)
- ✅ Backend token registration endpoint exists
- ✅ Basic token registration in notification_provider.dart
- ✅ GlobalErrorHandler and ErrorDisplayService for error display
- ❌ No retry logic on registration failure
- ❌ No local token persistence
- ❌ No foreground notification display
- ❌ No error logging/tracking integration
- ❌ flutter_local_notifications not installed
- ❌ retry package not installed
- ❌ flutter_secure_storage not installed
