---
phase: 03-backend-service-splitting
plan: 03
subsystem: backend-services
tags: [refactoring, service-splitting, export, mini-activity-statistics]
dependency_graph:
  requires: [03-02]
  provides: [export-services, mini-activity-statistics-services]
  affects: [exports-handler, mini-activity-handlers]
tech_stack:
  added: []
  patterns: [barrel-exports, service-composition, dependency-injection]
key_files:
  created:
    - backend/lib/services/export/export_data_service.dart
    - backend/lib/services/export/export_utility_service.dart
    - backend/lib/services/mini_activity_statistics/player_stats_service.dart
    - backend/lib/services/mini_activity_statistics/head_to_head_service.dart
    - backend/lib/services/mini_activity_statistics/stats_aggregation_service.dart
  modified:
    - backend/lib/services/export_service.dart
    - backend/lib/services/mini_activity_statistics_service.dart
    - backend/lib/api/router.dart
    - backend/lib/api/exports_handler.dart
    - backend/lib/api/mini_activity_statistics_handler.dart
    - backend/lib/api/mini_activities_handler.dart
    - backend/lib/api/mini_activity_scoring_handler.dart
decisions:
  - summary: "ExportService split into 2 focused services"
    rationale: "5 data export methods cohesive at 455 LOC; CSV generation + logging separate at 94 LOC"
  - summary: "MiniActivityStatisticsService split into 3 services"
    rationale: "Player stats (175 LOC), head-to-head + history + point sources (220 LOC), aggregation + leaderboard (164 LOC) provides clear separation of concerns"
  - summary: "Stats aggregation service depends on player and H2H services"
    rationale: "Aggregation composes data from both sub-services, avoiding duplication"
metrics:
  duration_minutes: 6
  tasks_completed: 2
  files_created: 5
  files_modified: 7
  tests_passing: 268
  lines_refactored: 1075
---

# Phase 03 Plan 03: Export and Mini-Activity Statistics Service Splitting Summary

**One-liner:** Split ExportService (541 LOC) into 2 sub-services and MiniActivityStatisticsService (534 LOC) into 3 sub-services with barrel exports

**Completed:** 2026-02-09

## Overview

Executed plan 03-03 to split two large service files into focused sub-services. ExportService split into data retrieval (455 LOC) and utility/CSV/logging (94 LOC). MiniActivityStatisticsService split into player stats (175 LOC), head-to-head + history + point sources (220 LOC), and aggregation + leaderboard (164 LOC). All services use barrel exports to maintain existing import paths.

## Tasks Completed

### Task 1: Split ExportService into 2 sub-services
- **Commit:** 7a34b39
- **Files:**
  - Created `export/export_data_service.dart` (455 LOC): 5 data export operations (leaderboard, attendance, fines, members, activities)
  - Created `export/export_utility_service.dart` (94 LOC): CSV generation, export logging, history retrieval
  - Updated `export_service.dart` to barrel export
  - Updated `router.dart`: instantiate both sub-services
  - Updated `exports_handler.dart`: use ExportDataService for data ops, ExportUtilityService for CSV/logging
- **Verification:** dart analyze clean, 268 tests passing
- **Deviations:** None

### Task 2: Split MiniActivityStatisticsService into 3 sub-services
- **Commit:** 8688dea
- **Files:**
  - Created `mini_activity_statistics/player_stats_service.dart` (175 LOC): CRUD, team stats, updatePlayerStats with streak calculation
  - Created `mini_activity_statistics/head_to_head_service.dart` (220 LOC): H2H CRUD, team history, point sources
  - Created `mini_activity_statistics/stats_aggregation_service.dart` (164 LOC): aggregated stats, leaderboard integration, batch processing
  - Updated `mini_activity_statistics_service.dart` to barrel export
  - Updated `router.dart`: instantiate 3 sub-services with dependency injection
  - Updated `mini_activity_statistics_handler.dart`: use all 3 sub-services
  - Updated `mini_activities_handler.dart` + `mini_activity_scoring_handler.dart`: use aggregation service
- **Verification:** dart analyze clean, 268 tests passing
- **Deviations:** None

## Deviations from Plan

None - plan executed exactly as written.

## Key Decisions Made

1. **Export data service kept at 455 LOC**: The 5 export methods (leaderboard, attendance, fines, members, activities) are cohesive - each follows the same pattern (fetch data, enrich with user info, return structured map). Splitting them further would create artificial boundaries. Acceptable slight overage from target 400 LOC.

2. **Head-to-head service includes team history and point sources**: These features are logically related to H2H tracking and share similar data access patterns. Grouping them together at 220 LOC maintains cohesion.

3. **Aggregation service composes from other services**: StatsAggregationService depends on PlayerStatsService and HeadToHeadService, calling their methods to build aggregate views. This avoids code duplication while maintaining clear separation.

4. **Handlers receive only needed services**: MiniActivityScoringHandler only needs aggregation service (for leaderboard), so it receives just that one. MiniActivityStatisticsHandler receives all three for its broader functionality.

## Verification Results

### Analysis
```
dart analyze
No issues found!
```

### Tests
```
dart test
00:00 +268: All tests passed!
```

All 268 backend tests passing - no regressions.

### File Size Verification
```
Export services:
  export/export_data_service.dart: 455 LOC
  export/export_utility_service.dart: 94 LOC

Mini-Activity Statistics services:
  mini_activity_statistics/player_stats_service.dart: 175 LOC
  mini_activity_statistics/head_to_head_service.dart: 220 LOC
  mini_activity_statistics/stats_aggregation_service.dart: 164 LOC
```

All services well-sized for maintainability.

## Technical Implementation

### Export Service Architecture
```
ExportDataService (455 LOC)
├── exportLeaderboard()
├── exportAttendance()
├── exportFines()
├── exportMembers()
└── exportActivities()

ExportUtilityService (94 LOC)
├── generateCsv()
├── logExport()
└── getExportHistory()
```

ExportsHandler receives both services, routes data export endpoints to ExportDataService, CSV generation and logging to ExportUtilityService.

### Mini-Activity Statistics Architecture
```
MiniActivityPlayerStatsService (175 LOC)
├── getPlayerStats()
├── getOrCreatePlayerStats()
├── getTeamPlayerStats()
└── updatePlayerStats() [includes streak logic]

MiniActivityHeadToHeadService (220 LOC)
├── getHeadToHead()
├── getOrCreateHeadToHead()
├── recordHeadToHeadResult()
├── getHeadToHeadForUser()
├── recordTeamHistory()
├── getTeamHistoryForUser()
├── recordPointSource()
├── getPointSourcesForUser()
└── getPointSourcesForEntry()

MiniActivityStatsAggregationService (164 LOC)
├── getPlayerStatsAggregate() → calls PlayerStats + HeadToHead
├── getMiniActivityLeaderboard() → calls PlayerStats + UserService
└── processMiniActivityResults() → calls PlayerStats + HeadToHead
```

Dependency injection in router.dart:
```dart
final miniActivityPlayerStatsService = MiniActivityPlayerStatsService(db);
final miniActivityHeadToHeadService = MiniActivityHeadToHeadService(db);
final miniActivityStatsAggregationService = MiniActivityStatsAggregationService(
  db, miniActivityPlayerStatsService, miniActivityHeadToHeadService, userService,
);
```

### Barrel Exports
Both services maintain existing import paths via barrel exports:
```dart
// export_service.dart
export 'export/export_data_service.dart';
export 'export/export_utility_service.dart';

// mini_activity_statistics_service.dart
export 'mini_activity_statistics/player_stats_service.dart';
export 'mini_activity_statistics/head_to_head_service.dart';
export 'mini_activity_statistics/stats_aggregation_service.dart';
```

No consumer code needed to change imports.

## Self-Check: PASSED

### Created files exist:
```
✓ backend/lib/services/export/export_data_service.dart
✓ backend/lib/services/export/export_utility_service.dart
✓ backend/lib/services/mini_activity_statistics/player_stats_service.dart
✓ backend/lib/services/mini_activity_statistics/head_to_head_service.dart
✓ backend/lib/services/mini_activity_statistics/stats_aggregation_service.dart
```

### Commits exist:
```
✓ 7a34b39: refactor(03-03): split ExportService into 2 sub-services
✓ 8688dea: refactor(03-03): split MiniActivityStatisticsService into 3 sub-services
```

## Impact

### Services Split
- ExportService (541 LOC) → 2 services (455 + 94 LOC)
- MiniActivityStatisticsService (534 LOC) → 3 services (175 + 220 + 164 LOC)

### Handler Updates
- ExportsHandler: receives 2 services instead of 1
- MiniActivityStatisticsHandler: receives 3 services instead of 1
- MiniActivitiesHandler: receives aggregation service
- MiniActivityScoringHandler: receives aggregation service

### Code Organization
- Clear separation of data retrieval vs utility functions in export services
- Player stats separated from head-to-head tracking
- Aggregation logic isolated from raw data access
- Barrel exports maintain backward compatibility

## Next Steps

Proceed to plan 03-04: Split UserService and DashboardService (final services in phase).
