import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

/// Provider for the Supabase service
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Service for Supabase realtime subscriptions
class SupabaseService {
  static bool _initialized = false;
  static SupabaseClient? _client;

  /// Initialize Supabase client (call once at app startup)
  static Future<void> initialize() async {
    if (_initialized) return;

    final url = AppConfig.supabaseUrl;
    final anonKey = AppConfig.supabaseAnonKey;
    if (url.isEmpty || anonKey.isEmpty) {
      // Skip initialization if config is missing
      // This allows the app to work without realtime features
      return;
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _client = Supabase.instance.client;
    _initialized = true;
  }

  /// Get the Supabase client (null if not initialized)
  SupabaseClient? get client => _client;

  /// Check if Supabase is initialized
  bool get isInitialized => _initialized;

  /// Subscribe to activity_responses changes for a specific team
  /// Returns a channel that can be used to unsubscribe later
  RealtimeChannel? subscribeToActivityResponses({
    required String teamId,
    required void Function() onUpdate,
  }) {
    if (!_initialized || _client == null) return null;

    final channel = _client!
        .channel('activity_responses_$teamId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'activity_responses',
          callback: (payload) {
            // Trigger update callback when any response changes
            onUpdate();
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await channel.unsubscribe();
  }
}
