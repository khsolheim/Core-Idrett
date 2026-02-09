---
phase: "02"
plan: "03"
subsystem: "backend-services"
tags: ["type-safety", "parsing-helpers", "services", "database-access"]
dependency_graph:
  requires: ["02-01-parsing-helpers"]
  provides: ["safe-service-layer"]
  affects: ["all-backend-services", "database-queries"]
tech_stack:
  added: []
  patterns: ["safe-db-parsing", "guarded-first-access"]
key_files:
  created: []
  modified:
    - "backend/lib/services/*.dart (all 34 files)"
    - "backend/lib/helpers/collection_helpers.dart"
decisions:
  - id: "automated-migration"
    summary: "Python regex-based migration for service files"
    rationale: "34 service files with hundreds of casts - manual migration would be error-prone and time-consuming"
    alternatives: ["manual-migration", "codemod-tool"]
    outcome: "Created Python script with v3 regex patterns handling .first['key'] correctly"
  - id: "safe-map-nullable"
    summary: "Manual fix for safeMap(...)?  syntax error"
    rationale: "Regex transformed `as Map<String, dynamic>?` to `safeMap(...)?` which is syntactically invalid"
    outcome: "Changed to safeMapNullable() in dashboard_service.dart"
  - id: "keep-null-conditional-casts"
    summary: "Left 30 safe null-conditional casts unchanged"
    rationale: "Patterns like `(value as num?)?.toDouble()` are already safe due to null-conditional operator"
    files: ["leaderboard_service.dart", "achievement_progress_service.dart", "player_rating_service.dart"]
    outcome: "Focused on unsafe direct casts; null-conditional patterns can be migrated later if needed"
metrics:
  duration_minutes: 7
  completed: "2026-02-09"
  tasks: 2
  files: 35
  commits: 1
---

# Phase 02 Plan 03: Backend Service Layer Safe Parsing Summary

Migrated all 34 backend service files to use safe parsing helpers for database result extraction.

## Tasks Completed

### Task 1: Migrate core services + collection_helpers (19 files)

**Services migrated:**
- auth_service.dart — JWT extraction, user creation (25 casts → safe)
- user_service.dart — getUserMap batch fetch (1 cast → safe)
- team_service.dart — team CRUD, memberships (17 casts → safe)
- team_member_service.dart — trainer types, permissions (18 casts → safe)
- activity_service.dart — activity CRUD, recurrence (17 casts → safe)
- activity_instance_service.dart — instance responses (14 casts → safe)
- fine_service.dart — fine rules, appeals, payments (28 casts → safe)
- season_service.dart — season management (3 casts → safe)
- leaderboard_service.dart — scoring, rankings (34 casts → safe)
- leaderboard_entry_service.dart — entry CRUD (13 casts → safe)
- message_service.dart — team chat, threads (23 casts → safe)
- direct_message_service.dart — DMs, conversations (4 casts → safe)
- team_chat_service.dart — chat helpers (3 casts → safe)
- notification_service.dart — push notifications (7 casts → safe)
- document_service.dart — file uploads (4 casts → safe)
- absence_service.dart — absence reporting (5 casts → safe)
- statistics_service.dart — team stats (25 casts → safe)
- dashboard_service.dart — dashboard data (4 casts → safe)
- collection_helpers.dart — groupBy, groupByCount (2 casts → safe)

**Changes:**
- Added `import '../helpers/parsing_helpers.dart';` to each file
- Replaced `row['key'] as String` → `safeString(row, 'key')`
- Replaced `row['key'] as String?` → `safeStringNullable(row, 'key')`
- Replaced `row['key'] as int` → `safeInt(row, 'key')`
- Replaced `(row['key'] as num).toDouble()` → `safeDouble(row, 'key')`
- Replaced `row['key'] as bool` → `safeBool(row, 'key')`
- Replaced `DateTime.parse(row['key'])` → `requireDateTime(row, 'key')`
- Guarded `.first` accesses (no unguarded .first found — services already had isEmpty checks)

### Task 2: Migrate remaining services (16 files)

**Note:** Completed simultaneously with Task 1 — all 34 service files migrated in single pass.

**Services migrated:**
- export_service.dart — CSV export (27 casts → safe)
- test_service.dart — physical tests (41 casts → safe, 4 DateTime.parse → safe)
- stopwatch_service.dart — stopwatch timing (6 casts → safe)
- player_rating_service.dart — Elo ratings (9 casts → safe)
- match_stats_service.dart — match statistics (4 casts → safe)
- points_config_service.dart — point configuration (6 casts → safe, 1 DateTime.parse → safe)
- tournament_service.dart — tournament CRUD (4 casts → safe)
- tournament_group_service.dart — groups, brackets (13 casts → safe)
- mini_activity_service.dart — mini-activity CRUD (10 casts → safe)
- mini_activity_result_service.dart — result tracking (26 casts → safe)
- mini_activity_template_service.dart — templates (2 casts → safe)
- mini_activity_division_service.dart — divisions (6 casts → safe)
- mini_activity_statistics_service.dart — mini-activity stats (11 casts → safe)
- achievement_service.dart — achievement system (1 cast → safe)
- achievement_definition_service.dart — definitions (1 cast → safe)
- achievement_progress_service.dart — progress tracking (18 casts → safe)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed regex pattern for .first['key'] transformation**
- **Found during:** Initial migration attempt
- **Issue:** Regex `(\w+)\['key'\]` captured `first` instead of `result.first`, transforming `result.first['id'] as String` to `result.safeString(first, 'id')` (syntax error)
- **Fix:** Updated regex to `([\w\.]+)\['key'\]` to capture dotted identifiers like `result.first`
- **Files modified:** All service files (via script v3)
- **Commit:** 22c882a (same commit, after revert + re-run)

**2. [Rule 3 - Blocking] Fixed safeMap(...)? syntax error**
- **Found during:** dart analyze after automated migration
- **Issue:** Regex transformed `instance['activities'] as Map<String, dynamic>?` to `safeMap(instance, 'activities')?` which is syntactically invalid (can't put `?` after function call)
- **Fix:** Changed to `safeMapNullable(instance, 'activities')`
- **Files modified:** dashboard_service.dart:33
- **Commit:** 22c882a (manual fix before commit)

### Migration Approach

**Tool:** Python script with regex-based transformation (3 iterations)

**v1:** Basic regex, added duplicate imports (sed issue)
**v2:** Improved regex, but `.first` handling broken
**v3:** Final regex with `[\w\.]+` pattern — handles `result.first['key']` correctly

**Script features:**
- Adds `import '../helpers/parsing_helpers.dart';` after last import
- DateTime.parse() transformation FIRST (before other transforms)
- Nullable patterns BEFORE non-nullable (avoids conflicts)
- Handles dotted identifiers (`result.first`, `config.settings`)

**Alternative considered:** Manual migration — rejected due to scale (34 files, ~400 casts)

## Self-Check: PASSED

**Created files exist:**
- N/A (no new files created)

**Modified files exist:**
```bash
✓ backend/lib/helpers/collection_helpers.dart (exists)
✓ backend/lib/services/*.dart (all 34 files exist)
```

**Commits exist:**
```bash
✓ 22c882a refactor(02-03): migrate backend services to safe parsing helpers
```

**Verification:**
```bash
$ cd backend && dart analyze lib/services/ lib/helpers/collection_helpers.dart
No issues found!

$ dart test
+268: All tests passed!

$ grep -rn 'DateTime\.parse(' lib/services/ | wc -l
0  # ✓ Zero DateTime.parse() calls

$ grep -rn ' as String\b' lib/services/*.dart | grep -v toString | grep -v '//' | wc -l
0  # ✓ Zero unsafe String casts

$ grep -rn "import.*parsing_helpers" lib/services/*.dart | wc -l
34  # ✓ All 34 services import parsing_helpers
```

**Remaining safe casts:** 30 null-conditional casts like `(value as num?)?.toDouble()` — already safe, not blocking.

## Impact

**Type safety:** Services now use type-safe extraction with clear error messages when database returns unexpected types

**Error clarity:** FormatException with field name ("Missing required field: user_id") instead of generic cast errors

**Consistency:** All service-layer database access uses same pattern (models use fromJson with helpers, services use helpers directly on raw rows)

**Testing:** 268 tests pass (77 parsing helper tests + 191 backend roundtrip tests)

**Code coverage:** 100% of service files migrated (34/34)

## Next Steps

1. Plan 02-04: Migrate handler layer (API request/response parsing)
2. Consider migrating 30 null-conditional casts for full consistency (low priority)
3. Consider extending pattern to frontend data sources (separate phase)
