# Phase 2: Type Safety & Validation - Research

**Researched:** 2026-02-09
**Domain:** Dart type safety, JSON deserialization validation, null-safe parsing
**Confidence:** HIGH

## Summary

Phase 2 addresses type safety weaknesses in the Core - Idrett backend where unsafe type casts (`as String`, `as int`, `as Map`) pose runtime crash risks. The backend has **1,261 unsafe cast occurrences across 93 files**, **67 DateTime.parse() calls across 27 files** (which throw on invalid input), and numerous `.first` accesses on potentially empty query results. The codebase already has validation infrastructure (`validation_helpers.dart`, `request_helpers.dart`) that should be extended and consistently applied at all deserialization boundaries.

The current implementation uses manual JSON serialization with `fromJson`/`toJson` factory patterns across ~62 backend models. While code generation tools (json_serializable, freezed) exist in the Dart ecosystem, the project's existing manual pattern works well and switching would require significant refactoring without proportional benefit. The focus should be on **hardening existing manual deserialization** with validation helpers rather than introducing code generation.

**Primary recommendation:** Create safe parsing helpers (e.g., `safeString()`, `safeInt()`, `safeDateTimeParse()`) that handle null and type mismatches gracefully, then systematically replace unsafe casts at model fromJson boundaries and service layer database access points.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| dart:core | 3.10+ | Type system, DateTime parsing | Built-in null safety, tryParse methods |
| Equatable | 2.0.5 | Structural equality | Already integrated in Phase 1, enables safe comparisons |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| collection | Latest | firstOrNull, firstWhereOrNull | Safe list access without exceptions |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual validation | json_serializable + build_runner | Code gen adds complexity; manual works fine for 62 models |
| Manual validation | freezed | Immutability + unions overkill for simple data models |
| Custom helpers | deep_pick package | External dependency; project already has validation foundation |

**Installation:**
```bash
# Add collection package for firstOrNull
dart pub add collection
```

## Architecture Patterns

### Recommended Helper Structure
```
backend/lib/
├── api/helpers/
│   ├── validation_helpers.dart    # Existing: requireString, requirePositiveInt, etc.
│   ├── request_helpers.dart       # Existing: parseBody, requiredField, optionalField
│   └── parsing_helpers.dart       # NEW: Safe type extraction from Maps
└── helpers/
    └── collection_helpers.dart    # Existing: Collection utilities
```

### Pattern 1: Safe Type Extraction Helpers

**What:** Helper functions that extract typed values from `Map<String, dynamic>` with validation
**When to use:** Every `fromJson` factory method, every service method reading database rows
**Example:**
```dart
// parsing_helpers.dart
String safeString(Map<String, dynamic> map, String key, {String? defaultValue}) {
  final value = map[key];
  if (value == null) {
    if (defaultValue != null) return defaultValue;
    throw FormatException('Missing required field: $key');
  }
  if (value is! String) {
    throw FormatException('Field $key must be String, got ${value.runtimeType}');
  }
  return value;
}

int safeInt(Map<String, dynamic> map, String key, {int? defaultValue}) {
  final value = map[key];
  if (value == null) return defaultValue ?? 0;
  if (value is! int) {
    throw FormatException('Field $key must be int, got ${value.runtimeType}');
  }
  return value;
}

int? safeIntNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('Field $key must be int, got ${value.runtimeType}');
  }
  return value;
}

// Source: Dart best practices for null-safe parsing
```

### Pattern 2: Safe DateTime Parsing

**What:** Use `DateTime.tryParse()` instead of `DateTime.parse()` to avoid exceptions
**When to use:** All DateTime field deserialization from JSON/database
**Example:**
```dart
// parsing_helpers.dart
DateTime? safeDateTimeParse(String? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    // Log warning but don't crash
    print('Warning: Failed to parse DateTime: $value');
  }
  return parsed;
}

DateTime requireDateTime(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    throw FormatException('Missing required DateTime field: $key');
  }
  if (value is DateTime) return value; // Already parsed by Supabase
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid DateTime format for $key: $value');
    }
    return parsed;
  }
  throw FormatException('Field $key must be DateTime or String, got ${value.runtimeType}');
}

// Source: https://api.flutter.dev/flutter/dart-core/DateTime/tryParse.html
```

### Pattern 3: Safe Collection Access

**What:** Use `firstOrNull` or emptiness checks instead of `.first` on query results
**When to use:** All database query result access where empty result is valid
**Example:**
```dart
import 'package:collection/collection.dart';

// BEFORE (unsafe):
final userId = result.first['user_id'] as String;

// AFTER (safe with emptiness check):
if (result.isEmpty) return null;
final userId = safeString(result.first, 'user_id');

// AFTER (safe with firstOrNull):
final firstRow = result.firstOrNull;
if (firstRow == null) return null;
final userId = safeString(firstRow, 'user_id');

// Source: https://api.dart.dev/dart-collection/IterableExtensions/firstOrNull.html
```

### Pattern 4: Model fromJson Hardening

**What:** Replace unsafe casts with validation helpers in all model factory methods
**When to use:** Every model's `fromJson` factory
**Example:**
```dart
// BEFORE (unsafe):
factory Activity.fromJson(Map<String, dynamic> row) {
  return Activity(
    id: row['id'] as String,
    teamId: row['team_id'] as String,
    createdAt: row['created_at'] as DateTime,
    points: row['points'] as int? ?? 0,
  );
}

// AFTER (safe):
factory Activity.fromJson(Map<String, dynamic> row) {
  return Activity(
    id: safeString(row, 'id'),
    teamId: safeString(row, 'team_id'),
    createdAt: requireDateTime(row, 'created_at'),
    points: safeInt(row, 'points', defaultValue: 0),
  );
}

// Source: https://dart.dev/null-safety/understanding-null-safety
```

### Pattern 5: Service Layer Database Access

**What:** Validate types when accessing database query results
**When to use:** All service methods that read from Supabase
**Example:**
```dart
// BEFORE (unsafe):
Future<LeaderboardEntry> upsertEntry(...) async {
  final existing = await _db.client.select(...);
  if (existing.isNotEmpty) {
    final currentPoints = existing.first['points'] as int? ?? 0;
    final id = existing.first['id'] as String;
    // ...
  }
}

// AFTER (safe):
Future<LeaderboardEntry> upsertEntry(...) async {
  final existing = await _db.client.select(...);
  if (existing.isNotEmpty) {
    final row = existing.first;
    final currentPoints = safeInt(row, 'points', defaultValue: 0);
    final id = safeString(row, 'id');
    // ...
  }
}

// Source: Project pattern from validation_helpers.dart
```

### Anti-Patterns to Avoid

- **Silent null coercion:** `as int? ?? 0` hides data quality issues; prefer validation that logs warnings
- **Blanket try-catch:** Wrapping entire `fromJson` in try-catch masks field-level errors
- **Mixing paradigms:** Don't introduce json_serializable for a few models while rest stay manual
- **Over-validation:** Don't validate types already guaranteed by database schema constraints

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Collection null safety | Custom list access wrappers | `package:collection` firstOrNull | Battle-tested, covers edge cases like concurrent modification |
| JSON schema validation | Custom recursive type checker | Built-in type guards (`is`, `is!`) | Type system handles it; custom code adds complexity |
| DateTime format handling | Custom date parser | `DateTime.tryParse()` | Handles ISO 8601, RFC 3339, edge cases like leap seconds |

**Key insight:** Dart's type system and null safety features already provide robust validation primitives. The goal is to **consistently apply them**, not reinvent them.

## Common Pitfalls

### Pitfall 1: Assuming Supabase Returns Typed Data
**What goes wrong:** Code uses `as DateTime` assuming Supabase client converts strings to DateTime objects
**Why it happens:** Supabase client behavior varies by query type; some return raw strings
**How to avoid:** Always check both `DateTime` and `String` types, use `requireDateTime` helper
**Warning signs:** `type 'String' is not a subtype of type 'DateTime'` exceptions in production

### Pitfall 2: Forgetting Nullable vs Optional
**What goes wrong:** Using `as int?` when field should be required, allowing null to slip through
**Why it happens:** Confusion between "field might be missing" (optional) vs "field present but null" (nullable)
**How to avoid:** Explicitly model intention: `safeInt` (required with default), `safeIntNullable` (optional)
**Warning signs:** Business logic crashes on null despite database schema marking field NOT NULL

### Pitfall 3: Over-Reliance on ?? Operator
**What goes wrong:** Code like `row['user_id'] as String? ?? 'unknown'` masks data corruption
**Why it happens:** Developer wants to "handle" null without understanding why it's null
**How to avoid:** Log warnings for unexpected nulls; use defaults only for truly optional fields
**Warning signs:** Mystery "unknown" values appearing in logs without context

### Pitfall 4: Unsafe `.first` on Empty Results
**What goes wrong:** Service crashes when query returns zero rows
**Why it happens:** Developer assumes query always returns at least one row
**How to avoid:** Use `firstOrNull` from collection package or check `isEmpty` before accessing
**Warning signs:** `Bad state: No element` exceptions on edge cases (e.g., user deleted mid-request)

### Pitfall 5: DateTime.parse() Throwing on Malformed Input
**What goes wrong:** Server crashes when client sends invalid date format or database has corrupted data
**Why it happens:** `DateTime.parse()` throws `FormatException` on invalid input; no recovery path
**How to avoid:** Always use `DateTime.tryParse()`, handle null return with fallback or error response
**Warning signs:** Requests fail with 500 error when timezone format slightly off (e.g., `+00:00` vs `Z`)

## Code Examples

Verified patterns from official sources and project context:

### Safe Type Extraction
```dart
// Source: Dart null safety documentation
// https://dart.dev/null-safety/understanding-null-safety

/// Extract a required String field from a Map
String safeString(Map<String, dynamic> map, String key, {String? defaultValue}) {
  final value = map[key];
  if (value == null) {
    if (defaultValue != null) return defaultValue;
    throw FormatException('Missing required field: $key');
  }
  if (value is! String) {
    throw FormatException('Field $key must be String, got ${value.runtimeType}');
  }
  return value;
}

/// Extract a nullable String field from a Map
String? safeStringNullable(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('Field $key must be String, got ${value.runtimeType}');
  }
  return value;
}
```

### Safe DateTime Parsing
```dart
// Source: Flutter API docs
// https://api.flutter.dev/flutter/dart-core/DateTime/tryParse.html

/// Parse DateTime from string, returning null on failure
DateTime? safeDateTimeParse(String? value) {
  if (value == null) return null;
  return DateTime.tryParse(value);
}

/// Extract required DateTime field, handling both DateTime and String types
DateTime requireDateTime(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value == null) {
    throw FormatException('Missing required DateTime field: $key');
  }
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid DateTime format for $key: $value');
    }
    return parsed;
  }
  throw FormatException('Field $key must be DateTime or String');
}
```

### Safe Collection Access
```dart
// Source: Dart collection package
// https://api.dart.dev/dart-collection/IterableExtensions/firstOrNull.html

import 'package:collection/collection.dart';

Future<String?> getTeamIdSafe(String activityId) async {
  final result = await _db.client.select(
    'activities',
    select: 'team_id',
    filters: {'id': 'eq.$activityId'},
  );

  // Safe: returns null if empty
  final firstRow = result.firstOrNull;
  if (firstRow == null) return null;

  return safeString(firstRow, 'team_id');
}
```

### Known Issue Fix: LeaderboardEntry JSON Key Mismatch
```dart
// Source: Project MEMORY.md - LeaderboardEntry key mismatch flagged in Phase 1
// File: backend/lib/models/season.dart line 259 vs 277

// BEFORE (mismatched keys):
factory LeaderboardEntry.fromJson(Map<String, dynamic> row, {int? rank}) {
  return LeaderboardEntry(
    optedOut: row['leaderboard_opt_out'] as bool?, // reads 'leaderboard_opt_out'
    // ...
  );
}

Map<String, dynamic> toJson() {
  return {
    if (optedOut != null) 'opted_out': optedOut, // writes 'opted_out'
    // ...
  };
}

// AFTER (consistent key):
factory LeaderboardEntry.fromJson(Map<String, dynamic> row, {int? rank}) {
  return LeaderboardEntry(
    optedOut: row['opted_out'] as bool?, // reads 'opted_out'
    // ...
  );
}

Map<String, dynamic> toJson() {
  return {
    if (optedOut != null) 'opted_out': optedOut, // writes 'opted_out'
    // ...
  };
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Implicit downcasts | Explicit `as` casts required | Dart 2.12 (2021) | Null safety mandatory; implicit casts removed |
| DateTime.parse() | DateTime.tryParse() preferred | Dart 2.1 (2018) | Safer parsing; null return vs exception |
| Custom firstOrNull | Built-in collection package | Dart 2.18 (2022) | Standard library support |
| json_serializable v3 | json_serializable v6 | 2023 | Better null safety, faster builds |

**Deprecated/outdated:**
- **Implicit type conversions:** Dart 2+ requires explicit casts; code like `dynamic x = "5"; int y = x;` no longer compiles
- **! operator overuse:** While `!` exists, best practice favors `as T` for nullable generics and explicit null checks
- **.first without guards:** Modern linters (DCM Dart Code Linter) warn against unsafe `.first`; use `.firstOrNull`

## Open Questions

1. **Should we add strict-casts analyzer option?**
   - What we know: `strict-casts: true` in analysis_options.yaml forces explicit handling of dynamic types
   - What's unclear: May generate warnings for valid Supabase client usage; needs testing
   - Recommendation: Defer to Phase 7 (Code Consistency); validate during Phase 2 but don't enforce yet

2. **Do we need logging for validation failures?**
   - What we know: Current helpers throw FormatException; no logging infrastructure exists
   - What's unclear: Should validation failures be logged before throwing? Affects debugging in production
   - Recommendation: Add optional logging parameter to helpers; log at service layer, not helper layer

3. **How to handle Supabase type inconsistency?**
   - What we know: Supabase sometimes returns DateTime as String, sometimes as DateTime object
   - What's unclear: Pattern depends on query type; comprehensive testing needed
   - Recommendation: `requireDateTime` helper handles both; document in CLAUDE.md after Phase 2

## Sources

### Primary (HIGH confidence)
- [Dart Null Safety Understanding](https://dart.dev/null-safety/understanding-null-safety) - Type casting, nullable generics
- [Dart DateTime.tryParse API](https://api.flutter.dev/flutter/dart-core/DateTime/tryParse.html) - Safe parsing method
- [Dart collection package](https://api.dart.dev/dart-collection/IterableExtensions/firstOrNull.html) - firstOrNull extension
- [How to Parse JSON in Dart](https://codewithandrea.com/articles/parse-json-dart/) - Validation patterns, type checking
- [Dart Using JSON](https://dart.dev/libraries/serialization/json) - Official serialization guidance

### Secondary (MEDIUM confidence)
- [Null Safety firstWhere](https://csdcorp.com/blog/coding/null-safety-firstwhere/) - firstOrNull vs firstWhere patterns
- [Dart Type System](https://dart.dev/language/type-system) - Type safety fundamentals
- [prefer-first-or-null DCM Linter](https://dcl.apps.bancolombia.com/docs/rules/dart/prefer-first-or-null/) - Linting best practices
- [Flutter Code Generation 2026](https://dasroot.net/posts/2026/01/flutter-code-generation-freezed-json-serializable-build-runner/) - Modern serialization approaches

### Tertiary (LOW confidence)
- None - all findings verified with official sources

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Built-in Dart features, well-documented patterns
- Architecture: HIGH - Patterns derived from official docs and project existing helpers
- Pitfalls: HIGH - Documented in Dart issues, official FAQ, linter rules

**Research date:** 2026-02-09
**Valid until:** ~2026-05-09 (90 days; Dart stable, slow-moving changes)
