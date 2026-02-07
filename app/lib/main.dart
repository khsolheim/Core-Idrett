import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/router.dart';
import 'core/services/error_display_service.dart';
import 'core/services/supabase_service.dart';
import 'features/settings/providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-cache SharedPreferences so subsequent calls (auth token, settings) resolve instantly
  await Future.wait([
    initializeDateFormatting('nb_NO', null),
    SharedPreferences.getInstance(),
  ]);

  // Initialize Supabase for realtime features (non-blocking)
  try {
    await SupabaseService.initialize();
  } catch (e) {
    // Log but don't fail - realtime features will be disabled
    if (kDebugMode) {
      print('Supabase initialization failed: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: CoreIdrettApp(),
    ),
  );
}

class CoreIdrettApp extends ConsumerWidget {
  const CoreIdrettApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Core - Idrett',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // Global scaffold messenger key for error display service
      scaffoldMessengerKey: ErrorDisplayService.scaffoldKey,
    );
  }
}
