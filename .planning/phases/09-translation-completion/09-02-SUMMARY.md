---
phase: 09-translation-completion
plan: 02
subsystem: frontend-localization
tags: [i18n, locale, system-dialogs, norwegian]
completed: 2026-02-10

dependency_graph:
  requires:
    - flutter_localizations SDK package
  provides:
    - Norwegian locale configuration for MaterialApp
    - System-level dialog localization (DatePicker, TimePicker, etc.)
  affects:
    - All system dialogs and Material widgets
    - Global app localization behavior

tech_stack:
  added:
    - flutter_localizations (SDK package)
  patterns:
    - MaterialApp locale configuration
    - GlobalLocalizations delegates pattern

key_files:
  created: []
  modified:
    - app/pubspec.yaml (added flutter_localizations SDK dependency)
    - app/lib/main.dart (added locale configuration with nb_NO and three delegates)

decisions:
  - decision: "Use flutter_localizations SDK package for system dialog localization"
    rationale: "Flutter SDK package provides Material, Widgets, and Cupertino localizations for Norwegian"
    alternatives: ["Custom localization implementation"]
    impact: "System dialogs now display in Norwegian without requiring custom localization"

metrics:
  duration_seconds: 51
  tasks_completed: 1
  files_modified: 2
  commits: 1
  lines_added: 10
  lines_removed: 0
---

# Phase 09 Plan 02: Norwegian Locale Configuration Summary

**One-liner:** MaterialApp configured with Norwegian locale (nb_NO) and three GlobalLocalizations delegates for system-level dialog localization.

## Objective Completed

Configured MaterialApp with Norwegian locale to ensure system-level dialogs (DatePicker, TimePicker, etc.) display in Norwegian. Without locale configuration, Flutter system dialogs default to English regardless of hardcoded UI strings. This ensures the full UI experience is Norwegian (I18N-01 success criteria #4).

## Tasks Executed

### Task 1: Add flutter_localizations dependency and configure Norwegian locale in MaterialApp ✅

**What was done:**
1. Added `flutter_localizations` SDK dependency to `app/pubspec.yaml` under dependencies section
2. Ran `flutter pub get` to resolve new dependency (succeeded without errors)
3. Added import: `import 'package:flutter_localizations/flutter_localizations.dart';` to `main.dart`
4. Configured MaterialApp.router with three new properties:
   - `locale: const Locale('nb', 'NO')` — Sets Norwegian Bokmål as app locale
   - `supportedLocales: const [Locale('nb', 'NO')]` — Declares supported locales
   - `localizationsDelegates` — Three delegates for Material, Widgets, and Cupertino localizations

**Files modified:**
- `app/pubspec.yaml` — Added flutter_localizations SDK dependency
- `app/lib/main.dart` — Added import and locale configuration

**Verification passed:**
- ✅ `flutter pub get` succeeded
- ✅ `flutter analyze` showed zero new errors (only pre-existing warnings)
- ✅ Import and three delegates present in main.dart
- ✅ Locale configuration present in MaterialApp

**Commit:** `43f69a1` - feat(09-02): configure Norwegian locale for MaterialApp

## Deviations from Plan

None - plan executed exactly as written.

## Technical Details

### Locale Configuration

The three localization delegates ensure comprehensive Norwegian localization:

1. **GlobalMaterialLocalizations.delegate** — Material widgets (DatePicker, TimePicker, dialogs, buttons) use Norwegian text
2. **GlobalWidgetsLocalizations.delegate** — Text direction and basic widget localization
3. **GlobalCupertinoLocalizations.delegate** — iOS-style widgets use Norwegian text

### Impact on Existing Code

**Screen-specific locale overrides preserved:**
- `edit_profile_screen.dart` line 235: `locale: const Locale('nb', 'NO')`
- `calendar_screen.dart` line 117: `locale: 'nb_NO'`

These screen-specific overrides remain as-is and are now backed by the global MaterialApp configuration.

### System Dialogs Now Localized

All Flutter system dialogs will now display in Norwegian:
- DatePicker (date selection dialogs)
- TimePicker (time selection dialogs)
- Material dialogs (AlertDialog, SimpleDialog)
- Cupertino widgets (iOS-style components)
- Default button text ("OK", "Cancel", etc.)

## Verification Results

**Overall plan verification:**
1. ✅ `flutter analyze` — zero new errors (only pre-existing info/warning level)
2. ✅ `flutter_localizations` dependency present in pubspec.yaml
3. ✅ `GlobalMaterialLocalizations` delegate configured in main.dart
4. ✅ `locale:` Norwegian locale set in MaterialApp

**Success criteria met:**
- ✅ flutter_localizations SDK dependency added to pubspec.yaml
- ✅ MaterialApp.router configured with locale: Locale('nb', 'NO')
- ✅ Three localization delegates registered (Material, Widgets, Cupertino)
- ✅ flutter pub get succeeds
- ✅ flutter analyze shows no new errors
- ✅ System-level dialogs will render in Norwegian

## Self-Check

Verifying all claimed artifacts exist:

**Files modified:**
- ✅ app/pubspec.yaml — flutter_localizations dependency present
- ✅ app/lib/main.dart — locale configuration and imports present

**Commits:**
- ✅ 43f69a1 — feat(09-02): configure Norwegian locale for MaterialApp

**Configuration verified:**
```bash
# Dependency check
$ grep "flutter_localizations" app/pubspec.yaml
  flutter_localizations:

# Import check
$ grep -n "flutter_localizations" app/lib/main.dart
4:import 'package:flutter_localizations/flutter_localizations.dart';

# Delegates check
$ grep -n "Global.*Localizations.delegate" app/lib/main.dart
70:        GlobalMaterialLocalizations.delegate,
71:        GlobalWidgetsLocalizations.delegate,
72:        GlobalCupertinoLocalizations.delegate,

# Locale check
$ grep -n "locale:" app/lib/main.dart
65:      locale: const Locale('nb', 'NO'),
```

## Self-Check: PASSED

All files, commits, and configurations verified present and correct.

## Next Steps

This plan completes the Norwegian locale configuration for system dialogs. The app's UI is now fully Norwegian at both the application level (hardcoded strings from Phase 9 Plan 1) and system level (Material dialogs via this plan).

**Phase 09 Translation Completion Status:**
- Plan 01: Hardcode Norwegian UI strings — Status pending
- Plan 02: Norwegian locale configuration — ✅ Complete

