class AppConfig {
  static const String appName = 'Core - Idrett';
  static const String apiBaseUrl = 'http://localhost:8080';

  // Supabase configuration for realtime features
  static const String supabaseUrl = 'https://mxlzmnxdwkntnwlnxoys.supabase.co';
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // API endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authInvite = '/auth/invite';

  static const String teams = '/teams';
  static const String activities = '/activities';
  static const String fines = '/fines';
}
