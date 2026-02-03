import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/notification.dart';
import '../data/notification_repository.dart';

// FCM token provider
final fcmTokenProvider = NotifierProvider<FcmTokenNotifier, String?>(() {
  return FcmTokenNotifier();
});

class FcmTokenNotifier extends Notifier<String?> {
  late final NotificationRepository _repo;
  bool _initialized = false;

  @override
  String? build() {
    _repo = ref.watch(notificationRepositoryProvider);
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
      // Get the token
      final token = await messaging.getToken();
      if (token != null) {
        await _registerToken(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen(_registerToken);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _registerToken(String token) async {
    state = token;
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      await _repo.registerToken(
        token: token,
        platform: platform,
      );
    } catch (e) {
      // Token registration failed - will retry on next app start
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // This is called when the app is in the foreground
    // You can show a local notification or update UI here
    // For now, we just log it
    final notification = message.notification;
    if (notification != null) {
      // Could trigger a local notification or update a badge count
    }
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
