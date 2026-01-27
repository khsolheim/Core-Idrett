class AppConfig {
  static const String appName = 'Core - Idrett';
  static const String apiBaseUrl = 'http://localhost:8080';

  // Supabase configuration for realtime features
  static const String supabaseUrl = 'https://mxlzmnxdwkntnwlnxoys.supabase.co';
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im14bHptbnhkd2tudG53bG54b3lzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0MjU3NTAsImV4cCI6MjA4NTAwMTc1MH0.13uYPTd0MKzXBi6G3alZzRWEuveitX9Zn3WwjH7kImE',
  );

  // API endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authInvite = '/auth/invite';

  static const String teams = '/teams';
  static const String activities = '/activities';
  static const String fines = '/fines';
}
