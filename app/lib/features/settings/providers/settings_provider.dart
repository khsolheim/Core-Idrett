import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'theme_mode';
const _localeKey = 'app_locale';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeModeKey);
    if (themeModeIndex != null) {
      state = ThemeMode.values[themeModeIndex];
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }
}

extension ThemeModeExtension on ThemeMode {
  String get displayName {
    switch (this) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Lys';
      case ThemeMode.dark:
        return 'Mork';
    }
  }

  IconData get icon {
    switch (this) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}

// ============ LOCALE ============

enum AppLocale {
  system,
  norwegian,
  english;

  String get displayName {
    switch (this) {
      case AppLocale.system:
        return 'Systemsprak';
      case AppLocale.norwegian:
        return 'Norsk';
      case AppLocale.english:
        return 'English';
    }
  }

  String get code {
    switch (this) {
      case AppLocale.system:
        return '';
      case AppLocale.norwegian:
        return 'nb_NO';
      case AppLocale.english:
        return 'en_US';
    }
  }

  Locale? get locale {
    switch (this) {
      case AppLocale.system:
        return null;
      case AppLocale.norwegian:
        return const Locale('nb', 'NO');
      case AppLocale.english:
        return const Locale('en', 'US');
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, AppLocale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<AppLocale> {
  LocaleNotifier() : super(AppLocale.system) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final localeIndex = prefs.getInt(_localeKey);
    if (localeIndex != null && localeIndex < AppLocale.values.length) {
      state = AppLocale.values[localeIndex];
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localeKey, locale.index);
  }
}
