import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retry/retry.dart';
import '../../../core/errors/app_exceptions.dart';
import '../../../data/models/notification.dart';
import '../data/notification_local_data_source.dart';
import '../data/notification_repository.dart';
import '../services/foreground_notification_service.dart';

// FCM token provider
final fcmTokenProvider = NotifierProvider<FcmTokenNotifier, String?>(() {
  return FcmTokenNotifier();
});

class FcmTokenNotifier extends Notifier<String?> {
  late final NotificationRepository _repo;
  late final NotificationLocalDataSource _localDataSource;
  late final ForegroundNotificationService _foregroundService;
  bool _initialized = false;

  static const _retryOptions = RetryOptions(
    maxAttempts: 8,
    delayFactor: Duration(milliseconds: 400),
    randomizationFactor: 0.25,
    maxDelay: Duration(seconds: 60),
  );

  @override
  String? build() {
    _repo = ref.watch(notificationRepositoryProvider);
    _localDataSource = ref.watch(notificationLocalDataSourceProvider);
    _foregroundService = ref.watch(foregroundNotificationServiceProvider);
    return null;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    // Request permission
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      // Configure iOS to show notifications when app is in foreground
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Initialize local notifications for foreground display
      await _foregroundService.initialize();

      // Get the token
      final token = await messaging.getToken();
      if (token != null) {
        // Fire-and-forget: don't block startup
        unawaited(_registerTokenWithRetry(token));
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((token) {
        unawaited(_registerTokenWithRetry(token));
      }).onError((error) {
        _logRegistrationError(error, Platform.isIOS ? 'ios' : 'android');
      });

      // Check for stale local token and reregister if needed
      unawaited(_recoverStaleToken());
    }

    // Handle foreground messages (delegated to Plan 08-03)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _registerTokenWithRetry(String token) async {
    state = token;
    final platform = Platform.isIOS ? 'ios' : 'android';

    try {
      await _retryOptions.retry(
        () => _repo.registerToken(token: token, platform: platform),
        retryIf: (e) => _isRetryableError(e),
      );
      // Success: persist locally with timestamp
      await _localDataSource.saveToken(token, DateTime.now().toUtc());
    } catch (e) {
      // All retries exhausted — log error, persist token for next startup attempt
      _logRegistrationError(e, platform);
      // Still save token locally so we can retry on next startup
      await _localDataSource.saveToken(token, DateTime.fromMillisecondsSinceEpoch(0));
    }
  }

  /// Determines if an error is retryable (network/server issues)
  /// Does NOT retry on 400/401/403/404 (client errors that won't change on retry)
  bool _isRetryableError(Exception e) {
    if (e is NetworkException) return true;
    if (e is TimeoutException) return true;
    if (e is ServerException) return true;
    if (e is ServiceUnavailableException) return true;
    // DioException wrapping — check inner error
    return false;
  }

  void _logRegistrationError(Object error, String platform) {
    if (kDebugMode) {
      print('[FCM] Token registration failed after ${_retryOptions.maxAttempts} attempts '
          '(platform: $platform, error: $error)');
    }
    // TODO: Send to error tracking service (Crashlytics) when integrated
  }

  Future<void> _recoverStaleToken() async {
    try {
      if (await _localDataSource.needsReregistration()) {
        final (localToken, _) = await _localDataSource.getToken();
        if (localToken != null) {
          await _registerTokenWithRetry(localToken);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Stale token recovery failed: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Display foreground notification via flutter_local_notifications
    _foregroundService.showNotification(message);
  }

  Future<void> removeToken() async {
    if (state != null) {
      try {
        await _repo.removeToken(state!);
      } catch (e) {
        // Ignore errors when removing token
      }
      state = null;
    }
    await _localDataSource.clearToken();
  }
}

// Notification preferences provider
final notificationPreferencesProvider = FutureProvider.family<
    NotificationPreferences,
    String?>((ref, teamId) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getPreferences(teamId: teamId);
});

// Notification preferences notifier
class NotificationPreferencesNotifier extends Notifier<AsyncValue<NotificationPreferences?>> {
  late final NotificationRepository _repo;

  @override
  AsyncValue<NotificationPreferences?> build() {
    _repo = ref.watch(notificationRepositoryProvider);
    return const AsyncValue.data(null);
  }

  Future<bool> updatePreferences({
    String? teamId,
    bool? newActivity,
    bool? activityReminder,
    bool? activityCancelled,
    bool? newFine,
    bool? fineDecision,
    bool? teamMessage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _repo.updatePreferences(
        teamId: teamId,
        newActivity: newActivity,
        activityReminder: activityReminder,
        activityCancelled: activityCancelled,
        newFine: newFine,
        fineDecision: fineDecision,
        teamMessage: teamMessage,
      );
      state = AsyncValue.data(prefs);
      // Invalidate the preferences provider to refresh
      ref.invalidate(notificationPreferencesProvider(teamId));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final notificationPreferencesNotifierProvider =
    NotifierProvider<NotificationPreferencesNotifier, AsyncValue<NotificationPreferences?>>(() {
  return NotificationPreferencesNotifier();
});
