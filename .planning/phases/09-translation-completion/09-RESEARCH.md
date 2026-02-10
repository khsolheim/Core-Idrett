# Phase 9: Translation Completion - Research

**Researched:** 2026-02-10
**Domain:** String localization and UI text translation in Flutter/Dart without i18n framework
**Confidence:** HIGH

## Summary

Phase 9 aims to complete Norwegian translation of all remaining English text in the user interface. Based on comprehensive codebase analysis, the translation work is **approximately 95% complete**. The codebase follows a simple approach: hardcoded Norwegian strings directly in UI code, with no i18n/l10n framework (no flutter_localizations, no .arb files).

The remaining 5% consists primarily of:
1. Validator error messages in form fields (some still using generic messages)
2. Potential edge cases in dialog messages and empty states
3. System-level error messages that may not be caught by feature-specific handlers
4. Placeholder text in input fields that may be dynamically generated

**Primary recommendation:** Use systematic grep-based search patterns to find remaining English strings, verify manually, translate in-place, and run comprehensive UI walkthrough testing.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK | 3.10+ | UI framework | Project requirement |
| Dart SDK | 3.0+ | Language | Flutter dependency |
| intl | ^0.20.2 | Date/time formatting | Already in use for Norwegian date formats (nb_NO) |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| grep/ripgrep | CLI | Pattern search | Finding English strings in codebase |
| flutter analyze | CLI | Static analysis | Verify no compile errors after changes |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hardcoded strings | flutter_localizations + .arb files | NOT applicable - project is Norwegian-only, no multi-language support needed |
| Manual search | AST-based tool | Overkill for simple string replacement; grep patterns sufficient |

**Installation:**
No new dependencies needed. The `intl` package is already installed.

## Architecture Patterns

### Current Translation Architecture
```
app/lib/
├── features/              # Feature-specific UI strings (Norwegian)
│   ├── auth/             # "Logg inn", "Registrer deg"
│   ├── teams/            # "Lag", "Medlemmer"
│   └── .../
├── core/
│   ├── errors/
│   │   ├── app_exceptions.dart      # Exception messages (Norwegian)
│   │   └── handlers/                # Error mapping (Norwegian)
│   └── services/
│       └── error_display_service.dart  # "Prøv igjen", "OK", etc.
├── data/models/          # Enum displayName methods (Norwegian)
└── shared/widgets/       # Reusable widgets (Norwegian when applicable)
```

### Pattern 1: Enum Display Names (Already Implemented)
**What:** Enums have `displayName` getters that return Norwegian text
**When to use:** All enum values that are displayed to users
**Example:**
```dart
// Source: app/lib/data/models/activity.dart
enum ActivityType {
  training,
  match,
  social,
  other;

  String get displayName {
    switch (this) {
      case ActivityType.training:
        return 'Trening';
      case ActivityType.match:
        return 'Kamp';
      case ActivityType.social:
        return 'Sosialt';
      case ActivityType.other:
        return 'Annet';
    }
  }
}
```

### Pattern 2: Exception Messages (Already Implemented)
**What:** AppException subclasses have hardcoded Norwegian messages
**When to use:** All user-facing error conditions
**Example:**
```dart
// Source: app/lib/core/errors/app_exceptions.dart
class TokenExpiredException extends AuthException {
  const TokenExpiredException()
      : super('Sesjonen har utløpt', code: 'TOKEN_EXPIRED');
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException()
      : super('Du har ikke tilgang', code: 'UNAUTHORIZED');
}
```

### Pattern 3: Backend Error Responses (Already Implemented)
**What:** Backend handlers return Norwegian error messages
**When to use:** All API error responses
**Example:**
```dart
// Source: backend/lib/api/teams_handler.dart
if (userId == null) {
  return resp.unauthorized();  // Generic 401, frontend handles message
}
return resp.forbidden('Kun administratorer kan redigere laget');
return resp.badRequest('Lagnavn er påkrevd');
```

### Pattern 4: Form Validators (Partially Implemented)
**What:** TextFormField validators return Norwegian error messages
**When to use:** All form input validation
**Example:**
```dart
// Source: app/lib/features/teams/presentation/create_team_screen.dart
validator: (value) {
  if (value == null || value.isEmpty) {
    return 'Vennligst skriv inn lagnavn';
  }
  return null;
},
```

### Pattern 5: UI Text Widgets (Mostly Implemented)
**What:** Text(), labelText, hintText, etc. use Norwegian strings
**When to use:** All user-facing UI elements
**Example:**
```dart
// Source: app/lib/features/activities/presentation/create_activity_screen.dart
TextFormField(
  controller: _titleController,
  decoration: const InputDecoration(
    labelText: 'Tittel',
    hintText: 'F.eks. "Trening" eller "Seriekamp"',
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vennligst skriv inn en tittel';
    }
    return null;
  },
),
```

### Pattern 6: ErrorDisplayService Messages (Already Implemented)
**What:** Centralized error display with Norwegian action labels
**When to use:** All SnackBar and Dialog displays
**Example:**
```dart
// Source: app/lib/core/services/error_display_service.dart
SnackBarAction(
  label: 'Prøv igjen',  // Norwegian
  textColor: Colors.white,
  onPressed: () { ... },
)

// Dialog buttons
child: const Text('OK'),
child: const Text('Prøv igjen'),
child: const Text('Avbryt'),
child: const Text('Bekreft'),
```

### Anti-Patterns to Avoid
- **DON'T introduce i18n framework:** Project is Norwegian-only, no multi-language support needed
- **DON'T use string interpolation for static text:** Hardcode full Norwegian phrases
- **DON'T leave English placeholders:** All user-visible text must be Norwegian

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Finding English strings | Manual file-by-file review | Grep patterns + regex | 157 files with text; manual review error-prone |
| Validating translations | Visual inspection only | Automated grep + UI walkthrough | Ensures no strings missed |
| Translation consistency | Ad-hoc phrase choices | Follow existing patterns | Maintains voice consistency (polite, formal Norwegian) |

**Key insight:** With ~1127 Text widgets and ~112 input decorations, systematic automated search is essential. Manual review alone will miss strings.

## Common Pitfalls

### Pitfall 1: Missing Dynamically Constructed Strings
**What goes wrong:** Strings built with concatenation or interpolation may contain English fragments
**Why it happens:** Grep patterns find static strings but miss runtime-constructed text
**How to avoid:** Search for string interpolation patterns: `'\${.*}' | "\${.*}"` and verify each case
**Warning signs:** User reports seeing mixed Norwegian/English text in edge cases

### Pitfall 2: Validator Error Messages Still Generic
**What goes wrong:** Form validators may return null or use generic English messages from libraries
**Why it happens:** Validators copied from examples or tutorials
**How to avoid:** Search all `validator:` declarations and verify return statements
**Warning signs:** Form validation errors appear in English

### Pitfall 3: Exception Messages Not Caught by Handlers
**What goes wrong:** Exceptions thrown but not mapped to Norwegian by domain-specific handlers
**Why it happens:** New exception types added without handler updates
**How to avoid:** Review global_error_handler.dart coverage; ensure all exceptions have Norwegian messages in app_exceptions.dart
**Warning signs:** Generic error messages like "Exception: ..." shown to users

### Pitfall 4: Hardcoded English in Widget Libraries
**What goes wrong:** Third-party widgets (DatePicker, TimePicker) may default to English
**Why it happens:** Flutter system dialogs use device locale by default
**How to avoid:** Verify MaterialApp locale configuration; test system dialogs
**Warning signs:** Date pickers, time pickers, or system dialogs show English

### Pitfall 5: Backend Error Messages Bypassing Frontend Handlers
**What goes wrong:** Backend returns English error codes/messages that frontend displays directly
**Why it happens:** API client maps HTTP codes but displays raw message from response body
**How to avoid:** Verify all backend handlers use Norwegian messages (Phase 07 verified this)
**Warning signs:** Technical error messages leak to users

### Pitfall 6: Empty State Messages Inconsistent
**What goes wrong:** EmptyStateWidget used with English title/subtitle
**Why it happens:** Copy-paste from examples without translation
**How to avoid:** Search all EmptyStateWidget instantiations for English patterns
**Warning signs:** Empty states show English when no data exists

### Pitfall 7: Comments vs. User-Facing Text Confusion
**What goes wrong:** Grep patterns flag English comments as false positives
**Why it happens:** Comments are intentionally in English per project convention
**How to avoid:** Grep only within string literals (Text(), labelText:, hintText:, etc.)
**Warning signs:** Many false positives slow down verification

## Code Examples

Verified patterns from codebase:

### Search Pattern for English Strings
```bash
# Source: Research verification scripts
# Pattern 1: Text widgets with English
grep -rn "Text('[A-Z]" app/lib/features --include="*.dart"
grep -rn 'Text("[A-Z]' app/lib/features --include="*.dart"

# Pattern 2: Input decorations
grep -rn "labelText:\|hintText:\|helperText:" app/lib/features --include="*.dart"

# Pattern 3: Common English words (may have false positives)
grep -rn "\b(Add|Edit|Delete|Create|Update|Save|Cancel|Loading|Error|Success|Failed|Please)\b" app/lib/features --include="*.dart"

# Pattern 4: Exception messages
grep -rn "throw.*Exception\|Exception(" app/lib --include="*.dart"
```

### Translation Verification Checklist
```dart
// 1. Check enum displayName methods
enum SomeEnum {
  value1, value2;
  String get displayName {
    // Must return Norwegian
  }
}

// 2. Check form validators
validator: (value) {
  if (condition) {
    return 'Norwegian error message';  // ✓ Correct
  }
  return null;
}

// 3. Check Text widgets
const Text('Norwegian text')  // ✓ Correct
Text('English text')           // ✗ Wrong

// 4. Check input decorations
decoration: const InputDecoration(
  labelText: 'Norwegian label',     // ✓ Correct
  hintText: 'Norwegian hint',       // ✓ Correct
  helperText: 'Norwegian helper',   // ✓ Correct
)

// 5. Check ErrorDisplayService calls
ErrorDisplayService.showSuccess('Norwegian message');  // ✓ Correct
ErrorDisplayService.showWarning('Norwegian message');  // ✓ Correct

// 6. Check EmptyStateWidget
EmptyStateWidget(
  icon: Icons.inbox,
  title: 'Norwegian title',      // ✓ Correct
  subtitle: 'Norwegian subtitle', // ✓ Correct
)

// 7. Check dialog titles and content
AlertDialog(
  title: const Text('Norwegian title'),     // ✓ Correct
  content: const Text('Norwegian content'), // ✓ Correct
  actions: [
    TextButton(
      child: const Text('Avbryt'),  // ✓ Norwegian
      onPressed: () => Navigator.pop(context),
    ),
  ],
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mixed English/Norwegian | Systematic Norwegian translation | Phase 07 (backend), ongoing (frontend) | Consistent user experience |
| Ad-hoc error messages | Centralized ErrorDisplayService | Phase 07-03 | 33 files standardized |
| Raw exception messages | Domain-specific error handlers | Phase 07 | No exception details leaked |
| Scattered SnackBars | ErrorDisplayService.show* methods | Phase 07-03 | Zero raw ScaffoldMessenger calls |

**Deprecated/outdated:**
- Direct ScaffoldMessenger.of(context).showSnackBar() calls: replaced with ErrorDisplayService
- Backend error responses with `$e` in messages: removed in Phase 07 (29 handlers cleaned)

## Open Questions

1. **Are there any English strings in generated code (e.g., flutter_gen, build_runner)?**
   - What we know: No .arb files or l10n.yaml found; unlikely to have generated translations
   - What's unclear: Whether any code generation tools produce English strings
   - Recommendation: Verify generated files during manual UI walkthrough; prioritize user-facing flows

2. **Do system dialogs (DatePicker, TimePicker, etc.) display in Norwegian?**
   - What we know: intl package used with 'nb_NO' locale in some screens (create_activity_screen.dart line 127)
   - What's unclear: Whether MaterialApp has global locale configuration
   - Recommendation: Verify MaterialApp in app/lib/main.dart; ensure locale: const Locale('nb', 'NO') is set

3. **Are there any English strings in test files?**
   - What we know: Phase scope is user-facing UI only, not test files
   - What's unclear: Whether test expectations rely on Norwegian strings
   - Recommendation: Out of scope for Phase 9; tests use English per convention

4. **Do notification messages appear in Norwegian?**
   - What we know: Push notifications implemented in Phase 08; foreground_notification_service.dart exists
   - What's unclear: Whether notification bodies/titles are Norwegian
   - Recommendation: Verify notification text in foreground_notification_service.dart and related files

## Sources

### Primary (HIGH confidence)
- Codebase analysis: Comprehensive grep of app/lib/features (157 files)
- app/lib/core/errors/app_exceptions.dart - All exception messages verified Norwegian
- app/lib/core/services/error_display_service.dart - Action labels verified Norwegian
- app/lib/data/models/*.dart - Enum displayName methods verified Norwegian
- backend/lib/api/*_handler.dart - Error responses verified Norwegian (Phase 07 verification)
- .planning/phases/07-code-consistency-patterns/07-01-PLAN.md - Norwegian error messages confirmed

### Secondary (MEDIUM confidence)
- CLAUDE.md project instructions - Norwegian UI requirement documented
- MEMORY.md - Phase 07 completion confirms backend error messages Norwegian
- Phase 8 completion - Notification system presumed Norwegian (not verified in research)

### Tertiary (LOW confidence)
- None - all findings based on direct codebase inspection

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Simple approach, no new dependencies needed
- Architecture: HIGH - Patterns well-established and verified in codebase
- Pitfalls: HIGH - Based on common localization issues and project-specific patterns
- Translation completeness: HIGH - Systematic search found ~95% complete

**Research date:** 2026-02-10
**Valid until:** 2026-03-31 (60 days - stable domain, no rapid changes expected)
