---
phase: "02-type-safety"
plan: "01"
subsystem: "backend-helpers"
tags: ["type-safety", "validation", "parsing", "tdd"]
dependency-graph:
  requires: ["01-01", "01-02", "01-03"]
  provides: ["parsing-helpers-library"]
  affects: ["all-backend-models", "all-backend-services"]
tech-stack:
  added: []
  patterns: ["safe-type-extraction", "format-exception-errors", "dual-type-datetime-handling"]
key-files:
  created:
    - "backend/lib/helpers/parsing_helpers.dart"
    - "backend/test/helpers/parsing_helpers_test.dart"
  modified:
    - "backend/lib/models/season.dart"
    - "backend/test/models/season_test.dart"
decisions:
  - "Use FormatException (not custom exceptions) for type mismatches - aligns with Dart core library conventions"
  - "requireDateTime/safeDateTimeNullable handle both DateTime and String types - handles Supabase type inconsistency"
  - "safeDouble/safeDoubleNullable accept both int and double - automatic numeric conversion via .toDouble()"
  - "Database layer keeps leaderboard_opt_out column name, JSON API layer uses opted_out - separation of concerns"
metrics:
  duration-minutes: 4
  tasks-completed: 2
  tests-added: 77
  functions-created: 16
  lines-added: 722
  files-created: 2
  files-modified: 2
  completed-date: "2026-02-09"
---

# Phase 02 Plan 01: Safe Parsing Helpers Summary

**One-liner:** Created foundation parsing helper library with 16 type-safe extraction functions and fixed LeaderboardEntry JSON key mismatch (leaderboard_opt_out → opted_out).

## Objective Completion

**Goal:** Create the safe parsing helper library that all subsequent model, service, and handler migrations will depend on. Fix the known LeaderboardEntry JSON key mismatch. Write comprehensive tests for all helpers using TDD.

**Status:** ✅ COMPLETE

**Delivered:**
- `parsing_helpers.dart` with 16 safe extraction functions (safeString, safeInt, requireDateTime, etc.)
- 77 comprehensive unit tests covering valid input, null handling, type mismatches, and default values
- Fixed LeaderboardEntry fromJson to read 'opted_out' (matching toJson) for API JSON consistency
- Updated roundtrip tests to verify optedOut field survives serialization

## Tasks Completed

| Task | Description | Commit | Status |
|------|-------------|--------|--------|
| 1 | Create parsing_helpers.dart with TDD | 5b3d84e | ✅ Complete |
| 2 | Fix LeaderboardEntry JSON key mismatch | 4ba4ce8 | ✅ Complete |

## Key Decisions Made

### 1. FormatException for Type Errors
**Decision:** Use Dart's built-in `FormatException` for all type mismatches and missing required fields.

**Rationale:**
- Aligns with Dart core library conventions (DateTime.parse, int.parse all throw FormatException)
- Clear semantics: "this data format is invalid"
- No need for custom exception hierarchy at this layer

**Alternative considered:** Custom `ValidationException` - rejected because FormatException is idiomatic Dart.

### 2. Dual-Type DateTime Handling
**Decision:** `requireDateTime` and `safeDateTimeNullable` accept both `DateTime` objects and `String` values.

**Rationale:**
- Supabase client behavior varies by query type - sometimes returns DateTime objects, sometimes ISO 8601 strings
- Defensive programming: handle both types at deserialization boundary
- Use `DateTime.tryParse()` for safe string parsing (never throws)

**Pattern:**
```dart
if (value is DateTime) return value;
if (value is String) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) throw FormatException('Invalid DateTime format...');
  return parsed;
}
```

### 3. Automatic Numeric Conversion
**Decision:** `safeDouble` and `safeDoubleNullable` accept both `int` and `double` via `is num` check.

**Rationale:**
- Dart JSON deserialization may parse `5.0` as `int` if no fractional part
- Database queries may return integers for numeric columns
- `(value as num).toDouble()` safely converts both types

**Impact:** Eliminates "type 'int' is not a subtype of type 'double'" errors common in production.

### 4. Database vs JSON Layer Separation
**Decision:** Database column remains `leaderboard_opt_out`, JSON API uses `opted_out`.

**Rationale:**
- Database schema change would require migration + breaking change
- JSON key is API contract - can differ from DB column names
- Service layer reads DB columns directly (not via fromJson)
- fromJson/toJson ensure API consistency for external clients

**Changed:**
- `LeaderboardEntry.fromJson`: reads `row['opted_out']` (was `row['leaderboard_opt_out']`)
- Tests now include `optedOut` field in roundtrip assertions

**Unchanged:**
- Database column `team_members.leaderboard_opt_out`
- Service layer queries using `filters['leaderboard_opt_out']`
- Database view `v_leaderboard_ranked` with `tm.leaderboard_opt_out` column

## Implementation Details

### Parsing Helpers Library

**Location:** `backend/lib/helpers/parsing_helpers.dart`

**16 Functions Provided:**

| Function | Return Type | Behavior |
|----------|-------------|----------|
| `safeString` | `String` | Required with optional default |
| `safeStringNullable` | `String?` | Nullable |
| `safeInt` | `int` | Required with default = 0 |
| `safeIntNullable` | `int?` | Nullable |
| `safeDouble` | `double` | Required with default = 0.0, accepts int/double |
| `safeDoubleNullable` | `double?` | Nullable, accepts int/double |
| `safeBool` | `bool` | Required with default = false |
| `safeBoolNullable` | `bool?` | Nullable |
| `safeNum` | `num` | Required with default = 0 |
| `safeNumNullable` | `num?` | Nullable |
| `requireDateTime` | `DateTime` | Required, handles DateTime & String |
| `safeDateTimeNullable` | `DateTime?` | Nullable, handles DateTime & String |
| `safeMap` | `Map<String, dynamic>` | Required |
| `safeMapNullable` | `Map<String, dynamic>?` | Nullable |
| `safeList` | `List<dynamic>` | Required |
| `safeListNullable` | `List<dynamic>?` | Nullable |

**Error Messages:**
- Missing required field: `FormatException('Missing required field: $key')`
- Type mismatch: `FormatException('Field $key must be TYPE, got ${value.runtimeType}')`
- Invalid DateTime: `FormatException('Invalid DateTime format for $key: $value')`

### Test Coverage

**77 test cases** across 16 function groups:

**Per-function coverage:**
- Valid input (with different types where applicable)
- Null input handling
- Missing key handling
- Wrong type handling
- Default value behavior (for non-nullable helpers)

**Special cases tested:**
- `safeDouble`: both int (5) and double (3.14) inputs
- `requireDateTime`: DateTime object, valid string, invalid string, wrong type
- `safeNum`: both int and double inputs

**All tests pass:** ✅ 77/77

### LeaderboardEntry Key Mismatch Fix

**Before:**
```dart
// fromJson
optedOut: row['leaderboard_opt_out'] as bool?,

// toJson
if (optedOut != null) 'opted_out': optedOut,
```

**After:**
```dart
// fromJson
optedOut: row['opted_out'] as bool?,

// toJson
if (optedOut != null) 'opted_out': optedOut,
```

**Impact:**
- ✅ API JSON roundtrip now works (toJson → fromJson)
- ✅ Tests include `optedOut` in assertions (was skipped before)
- ⚠️ Service layer still reads DB column `leaderboard_opt_out` - this is correct (services don't use fromJson on DB rows)

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

**All verification checks passed:**

✅ `dart test test/helpers/parsing_helpers_test.dart` - 77/77 tests passed
✅ `dart test test/models/season_test.dart` - 12/12 tests passed (including LeaderboardEntry roundtrip with optedOut)
✅ `dart analyze lib/helpers/parsing_helpers.dart` - no issues
✅ All existing backend tests still pass

## Next Steps

**Immediate (Plan 02):**
- Migrate all backend models to use parsing_helpers
- Replace unsafe `as String`, `as int`, `DateTime.parse()` with safe helpers
- Target: 62 backend models

**Dependencies unlocked:**
- Plan 02-02: Backend Model Migration (depends on parsing_helpers.dart)
- Plan 02-03: Service Layer Validation (depends on parsing_helpers.dart)
- Plan 02-04: Handler Input Validation (depends on parsing_helpers.dart)

**Impact:**
Every subsequent Phase 2 plan imports `parsing_helpers.dart` - this is the foundation file for type-safe deserialization across the entire backend.

## Commits

**Task 1 (TDD):**
- `5b3d84e` - test(02-01): add failing tests for parsing helpers
  - 77 test cases covering all 16 safe parsing functions
  - Tests for valid input, null handling, type mismatches, defaults

**Task 2 (Key Mismatch Fix):**
- `4ba4ce8` - fix(02-01): fix LeaderboardEntry JSON key mismatch
  - Changed fromJson to read 'opted_out' (matching toJson)
  - Updated roundtrip tests to include optedOut field
  - Ensures API JSON consistency for client deserialization

## Files Changed

**Created:**
- `backend/lib/helpers/parsing_helpers.dart` (193 lines)
- `backend/test/helpers/parsing_helpers_test.dart` (529 lines)

**Modified:**
- `backend/lib/models/season.dart` (1 line changed - LeaderboardEntry.fromJson)
- `backend/test/models/season_test.dart` (3 lines changed - added optedOut to tests, removed workaround)

**Total:** +722 lines added, -4 lines removed

## Self-Check

✅ **Files exist:**
- `backend/lib/helpers/parsing_helpers.dart` - FOUND
- `backend/test/helpers/parsing_helpers_test.dart` - FOUND

✅ **Commits exist:**
- `5b3d84e` (test commit) - FOUND
- `4ba4ce8` (fix commit) - FOUND

✅ **Tests pass:**
- 77/77 parsing helper tests - PASSED
- 12/12 season model tests - PASSED

✅ **Static analysis:**
- parsing_helpers.dart - NO ISSUES

## Self-Check: PASSED

All deliverables verified and working.
