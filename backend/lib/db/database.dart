import 'dart:io';
import 'supabase_client.dart';

class Database {
  late SupabaseClient _client;

  SupabaseClient get client => _client;

  Future<void> connect() async {
    final projectUrl = Platform.environment['SUPABASE_URL'] ?? '';
    final anonKey = Platform.environment['SUPABASE_ANON_KEY'] ?? '';
    final serviceKey = Platform.environment['SUPABASE_SERVICE_KEY'] ?? '';

    if (projectUrl.isEmpty) {
      throw Exception('SUPABASE_URL is required');
    }
    if (serviceKey.isEmpty) {
      throw Exception('SUPABASE_SERVICE_KEY is required');
    }

    _client = SupabaseClient(
      projectUrl: projectUrl,
      anonKey: anonKey,
      serviceKey: serviceKey,
    );

    print('Connected to Supabase: $projectUrl');
  }

  Future<void> close() async {
    // HTTP client doesn't need explicit closing
  }

  // Legacy query method for compatibility - converts to REST API calls
  Future<List<Map<String, dynamic>>> query(String sql, {Map<String, dynamic>? parameters}) async {
    // This is a simplified compatibility layer
    // For complex queries, services should use the client directly
    throw UnimplementedError('Direct SQL queries not supported with REST API. Use client methods instead.');
  }
}
