import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final notificationLocalDataSourceProvider = Provider<NotificationLocalDataSource>((ref) {
  return NotificationLocalDataSource();
});

class NotificationLocalDataSource {
  final FlutterSecureStorage _storage;

  static const _tokenKey = 'fcm_token';
  static const _timestampKey = 'fcm_token_last_sync';

  NotificationLocalDataSource({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Save FCM token and sync timestamp
  Future<void> saveToken(String token, DateTime syncedAt) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _timestampKey, value: syncedAt.toIso8601String()),
    ]);
  }

  /// Read stored token and timestamp. Returns (null, null) if not stored.
  Future<(String?, DateTime?)> getToken() async {
    final token = await _storage.read(key: _tokenKey);
    final timestampStr = await _storage.read(key: _timestampKey);
    final timestamp = timestampStr != null ? DateTime.tryParse(timestampStr) : null;
    return (token, timestamp);
  }

  /// Check if stored token needs reregistration (>24 hours since last sync)
  Future<bool> needsReregistration() async {
    final (token, timestamp) = await getToken();
    if (token == null || timestamp == null) return true;
    return DateTime.now().toUtc().difference(timestamp) > const Duration(hours: 24);
  }

  /// Clear stored token (on logout)
  Future<void> clearToken() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _timestampKey),
    ]);
  }
}
