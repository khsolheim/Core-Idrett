class AppConfig {
  static const String appName = 'Core - Idrett';
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Supabase configuration for realtime features
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // API endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authInvite = '/auth/invite';

  static const String teams = '/teams';
  static const String activities = '/activities';
  static const String fines = '/fines';
}
