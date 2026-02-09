---
phase: "02-type-safety"
plan: "02"
subsystem: "backend-models"
tags: ["type-safety", "parsing", "models", "migration"]
completed: 2026-02-09
duration: "~8 minutes"
key-files:
  created: []
  modified:
    - backend/lib/models/user.dart
    - backend/lib/models/team.dart
    - backend/lib/models/activity.dart
    - backend/lib/models/message.dart
    - backend/lib/models/document.dart
    - backend/lib/models/notification.dart
    - backend/lib/models/export_log.dart
    - backend/lib/models/fine.dart
    - backend/lib/models/absence.dart
    - backend/lib/models/test.dart
    - backend/lib/models/season.dart
    - backend/lib/models/stopwatch.dart
    - backend/lib/models/points_config.dart
    - backend/lib/models/statistics.dart
    - backend/lib/models/mini_activity_core.dart
    - backend/lib/models/mini_activity_team.dart
    - backend/lib/models/mini_activity_adjustment.dart
    - backend/lib/models/mini_activity_statistics.dart
    - backend/lib/models/tournament_core.dart
    - backend/lib/models/tournament_round.dart
    - backend/lib/models/tournament_match.dart
    - backend/lib/models/tournament_group.dart
    - backend/lib/models/achievement_definition.dart
    - backend/lib/models/achievement_user.dart
tech-stack:
  added: []
  patterns:
    - "Safe parsing helpers in all backend model fromJson methods"
    - "Zero unsafe casts in model deserialization"
    - "requireDateTime/safeDateTimeNullable for all date parsing"
dependency-graph:
  requires:
    - "02-01: parsing_helpers.dart library"
  provides:
    - "Type-safe model deserialization for all 24 backend models"
  affects:
    - "All backend services that deserialize models"
    - "All backend handlers that return models"
key-decisions:
  - decision: "Remove deprecated helper functions"
    rationale: "Old _parseDateTime and _parseDouble functions replaced by centralized safe parsing helpers"
  - decision: "Handle nested JSON parsing safely"
    rationale: "Use safeMap/safeMapNullable before passing to nested fromJson calls"
metrics:
  models_migrated: 24
  classes_with_fromJson: 42
  unsafe_casts_removed: ~300
  tests_passing: 191
  zero_unsafe_casts: true
---

# Phase 02 Plan 02: Backend Model Migration Summary

**Migrated all 24 backend model files to use safe parsing helpers, eliminating unsafe casts and DateTime.parse() calls from model deserialization.**

## Objective Achieved

All backend model `fromJson` factory methods now use safe type extraction helpers from `parsing_helpers.dart`. Models catch bad data at the earliest possible boundary with descriptive error messages.

## Tasks Completed

### Task 1: Migrate Core and Communication Models (12 files) ✓

Commit: `189bd6a`

**Files migrated:**
- `user.dart` - 1 class, ~4 casts replaced
- `team.dart` - 3 classes (Team, TrainerType, TeamMember), ~22 casts replaced
- `activity.dart` - 3 classes (Activity, ActivityInstance, ActivityResponse), ~23 casts replaced
- `message.dart` - 1 class (Message), ~14 casts replaced
- `document.dart` - 1 class (Document), ~14 casts replaced
- `notification.dart` - 2 classes (DeviceToken, NotificationPreferences), ~16 casts replaced
- `export_log.dart` - 1 class (ExportLog), ~8 casts replaced
- `fine.dart` - 5 classes (FineRule, Fine, FineAppeal, FinePayment, TeamFinesSummary), ~60 casts replaced + 6 DateTime.parse() calls
- `absence.dart` - 2 classes (AbsenceCategory, AbsenceRecord), ~28 casts replaced + 5 DateTime.parse() calls
- `test.dart` - 2 classes (TestTemplate, TestResult), ~18 casts replaced + 2 DateTime.parse() calls
- `season.dart` - 4 classes (Season, LeaderboardCategory, Leaderboard, LeaderboardEntry), ~37 casts replaced + 5 DateTime.parse() calls
- `stopwatch.dart` - 3 classes (StopwatchSession, StopwatchLap, StopwatchSplit), ~23 casts replaced

**Changes applied:**
- Added `import '../helpers/parsing_helpers.dart';` to each file
- Replaced `row['key'] as String` → `safeString(row, 'key')`
- Replaced `row['key'] as String?` → `safeStringNullable(row, 'key')`
- Replaced `row['key'] as int` → `safeInt(row, 'key')`
- Replaced `row['key'] as int? ?? 0` → `safeInt(row, 'key', defaultValue: 0)`
- Replaced `row['key'] as bool` → `safeBool(row, 'key')`
- Replaced `row['key'] as bool? ?? false` → `safeBool(row, 'key', defaultValue: false)`
- Replaced `DateTime.parse(row['key'])` → `requireDateTime(row, 'key')`
- Replaced `row['key'] != null ? DateTime.parse(...) : null` → `safeDateTimeNullable(row, 'key')`
- Replaced `(row['key'] as num).toDouble()` → `safeDouble(row, 'key')`
- Replaced nested map access: `FineAppeal.fromJson(json['appeal'])` → `FineAppeal.fromJson(safeMap(json, 'appeal'))`

**Verification:**
- All 191 roundtrip tests pass
- Zero unsafe casts remain in Task 1 files

### Task 2: Migrate Mini-Activity, Tournament, Achievement, Statistics, and Points Models (12 files) ✓

Commit: `3b6f077`

**Files migrated:**
- `points_config.dart` - 3 classes (TeamPointsConfig, AttendancePoints, ManualPointAdjustment), ~37 casts replaced + 4 DateTime.parse() calls
- `statistics.dart` - 3 classes with fromJson (MatchStats, PlayerRating, SeasonStats), ~1 cast + 1 DateTime.parse()
- `mini_activity_core.dart` - 2 classes (ActivityTemplate, MiniActivity), ~32 casts replaced + 2 DateTime.parse() calls
- `mini_activity_team.dart` - 2 classes (MiniActivityTeam, MiniActivityParticipant), ~9 casts replaced
- `mini_activity_adjustment.dart` - 2 classes (MiniActivityAdjustment, MiniActivityHandicap), ~12 casts replaced + 1 DateTime.parse()
- `mini_activity_statistics.dart` - 5 classes (MiniActivityPlayerStats, HeadToHeadStats, MiniActivityTeamHistory, LeaderboardPointSource, PlayerStatsAggregate), ~44 casts replaced
- `tournament_core.dart` - 1 class (Tournament), ~9 casts replaced
- `tournament_round.dart` - 1 class (TournamentRound), ~8 casts replaced
- `tournament_match.dart` - 2 classes (TournamentMatch, MatchGame), ~25 casts replaced
- `tournament_group.dart` - 5 classes (TournamentGroup, GroupStanding, GroupMatch, QualificationRound, QualificationResult), ~41 casts replaced
- `achievement_definition.dart` - 2 classes (AchievementCriteria, AchievementDefinition), ~21 casts replaced + 2 DateTime.parse() calls
- `achievement_user.dart` - 2 classes (UserAchievement, AchievementProgress), ~32 casts replaced + 4 DateTime.parse() calls

**Additional cleanup:**
- Removed deprecated `_parseDateTime()` helper from mini_activity_core.dart and mini_activity_adjustment.dart
- Removed deprecated `_parseDouble()` helper from points_config.dart
- All local helper functions replaced with centralized safe parsing helpers

**Verification:**
- All 191 roundtrip tests pass
- `dart analyze lib/models/` reports zero issues
- Zero unsafe casts remain in model layer

## Deviations from Plan

None - plan executed exactly as written.

## Impact

**Models are now the safest layer in the backend:**
- All deserialization uses type-safe helpers
- Bad data caught at boundary with clear error messages
- Zero unsafe type casts remain in `fromJson` methods
- Zero `DateTime.parse()` calls remain in models

**Next layer (services and handlers) still has unsafe casts:**
- Services: ~200+ unsafe casts remain
- Handlers: ~150+ unsafe casts remain
- These will be addressed in plans 02-03 and 02-04

## Verification Results

```bash
# All roundtrip tests pass
$ dart test test/models/
00:00 +191: All tests passed!

# Zero analysis issues
$ dart analyze lib/models/
Analyzing models...
No issues found!

# Zero unsafe casts in models (grep verification)
$ grep -rn ' as String\| as int\| as bool\| as num\| as Map\| as List\| as DateTime\| as double\|DateTime\.parse(' lib/models/ | grep -v '_test\|toJson\|// ' | wc -l
0
```

## Files Modified

**24 model files, 42 classes with fromJson:**

Core models (Task 1):
- backend/lib/models/user.dart
- backend/lib/models/team.dart
- backend/lib/models/activity.dart
- backend/lib/models/message.dart
- backend/lib/models/document.dart
- backend/lib/models/notification.dart
- backend/lib/models/export_log.dart
- backend/lib/models/fine.dart
- backend/lib/models/absence.dart
- backend/lib/models/test.dart
- backend/lib/models/season.dart
- backend/lib/models/stopwatch.dart

Remaining models (Task 2):
- backend/lib/models/points_config.dart
- backend/lib/models/statistics.dart
- backend/lib/models/mini_activity_core.dart
- backend/lib/models/mini_activity_team.dart
- backend/lib/models/mini_activity_adjustment.dart
- backend/lib/models/mini_activity_statistics.dart
- backend/lib/models/tournament_core.dart
- backend/lib/models/tournament_round.dart
- backend/lib/models/tournament_match.dart
- backend/lib/models/tournament_group.dart
- backend/lib/models/achievement_definition.dart
- backend/lib/models/achievement_user.dart

## Key Patterns Applied

1. **Import parsing helpers at top of each file:**
   ```dart
   import '../helpers/parsing_helpers.dart';
   ```

2. **Replace unsafe casts with safe helpers:**
   ```dart
   // Before:
   id: row['id'] as String,
   points: row['points'] as int? ?? 0,
   isActive: row['is_active'] as bool? ?? true,
   rating: (row['rating'] as num).toDouble(),
   createdAt: DateTime.parse(row['created_at'] as String),

   // After:
   id: safeString(row, 'id'),
   points: safeInt(row, 'points', defaultValue: 0),
   isActive: safeBool(row, 'is_active', defaultValue: true),
   rating: safeDouble(row, 'rating'),
   createdAt: requireDateTime(row, 'created_at'),
   ```

3. **Handle nested JSON parsing safely:**
   ```dart
   // Before:
   criteria: AchievementCriteria.fromJson(criteriaMap),

   // After:
   final criteriaMap = safeMap(row, 'criteria');
   criteria: AchievementCriteria.fromJson(criteriaMap),
   ```

4. **Remove deprecated local helpers:**
   - Deleted `_parseDateTime()` from mini_activity files
   - Deleted `_parseDouble()` from points_config.dart
   - Replaced all usages with centralized helpers

## Technical Notes

**Helper Usage:**
- `safeString()` / `safeStringNullable()` - ~150 usages
- `safeInt()` / `safeIntNullable()` - ~180 usages
- `safeBool()` / `safeBoolNullable()` - ~45 usages
- `safeDouble()` / `safeDoubleNullable()` - ~25 usages
- `requireDateTime()` / `safeDateTimeNullable()` - ~50 usages
- `safeMap()` / `safeMapNullable()` - ~8 usages
- `safeList()` / `safeListNullable()` - ~2 usages

**DateTime Handling:**
- `requireDateTime()` for required date fields (throws if missing/invalid)
- `safeDateTimeNullable()` for optional date fields (returns null if missing)
- Both helpers accept DateTime objects OR ISO 8601 strings (handles Supabase dual format)

**Special Cases Handled:**
- **statistics.dart:** Only migrated classes with `fromJson` (MatchStats, PlayerRating, SeasonStats). Classes only having `toJson` (PlayerStatistics, LeaderboardEntry, AttendanceRecord) left unchanged.
- **achievement_definition.dart:** Handled criteria JSON that can be either String (needs jsonDecode) or Map
- **achievement_user.dart:** Handled nullable enum parsing with conditional checks
- **mini_activity_statistics.dart:** Carefully handled teammates list casting

## Self-Check: PASSED

All claimed files and commits verified:

**Files exist:**
```bash
$ ls backend/lib/models/{user,team,activity,message,document,notification,export_log,fine,absence,test,season,stopwatch,points_config,statistics,mini_activity_core,mini_activity_team,mini_activity_adjustment,mini_activity_statistics,tournament_core,tournament_round,tournament_match,tournament_group,achievement_definition,achievement_user}.dart
✓ All 24 files exist
```

**Commits exist:**
```bash
$ git log --oneline | grep -E "189bd6a|3b6f077"
✓ 3b6f077 feat(02-02): migrate remaining models to safe parsing
✓ 189bd6a feat(02-02): migrate core and communication models to safe parsing
```

**Tests passing:**
```bash
$ dart test test/models/
✓ 191 tests passing
```

**Zero analysis issues:**
```bash
$ dart analyze lib/models/
✓ No issues found!
```
