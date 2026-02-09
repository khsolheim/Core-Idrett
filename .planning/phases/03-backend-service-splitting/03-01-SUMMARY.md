---
phase: 03-backend-service-splitting
plan: 01
subsystem: backend-services
tags: [refactoring, architecture, splitting]
dependency-graph:
  requires: [phase-02]
  provides: [tournament-sub-services, leaderboard-sub-services]
  affects: [backend-handlers, service-layer]
tech-stack:
  added: []
  patterns: [service-splitting, barrel-exports, dependency-injection]
key-files:
  created:
    - backend/lib/services/tournament/tournament_crud_service.dart
    - backend/lib/services/tournament/tournament_rounds_service.dart
    - backend/lib/services/tournament/tournament_matches_service.dart
    - backend/lib/services/tournament/tournament_bracket_service.dart
    - backend/lib/services/leaderboard/leaderboard_crud_service.dart
    - backend/lib/services/leaderboard/leaderboard_category_service.dart
    - backend/lib/services/leaderboard/leaderboard_ranking_service.dart
  modified:
    - backend/lib/services/tournament_service.dart (758→7 LOC, barrel)
    - backend/lib/services/leaderboard_service.dart (702→6 LOC, barrel)
    - backend/lib/api/router.dart (service instantiation)
    - backend/lib/api/tournaments_handler.dart (uses sub-services)
    - backend/lib/api/tournament_rounds_handler.dart (uses sub-services)
    - backend/lib/api/tournament_matches_handler.dart (uses sub-services)
    - backend/lib/api/tournament_groups_handler.dart (uses sub-services)
    - backend/lib/api/leaderboards_handler.dart (uses sub-services)
    - backend/lib/api/leaderboard_entries_handler.dart (uses sub-services)
    - backend/lib/services/activity_instance_service.dart (uses LeaderboardCrudService)
    - backend/lib/services/mini_activity_result_service.dart (uses LeaderboardCrudService)
decisions:
  - decision: Split tournament into 4 focused sub-services
    rationale: 758 LOC too large, clear separation of concerns (CRUD, rounds, matches, bracket generation)
    impact: Improved readability, testability, and maintainability
  - decision: Split leaderboard into 3 focused sub-services
    rationale: 702 LOC too large, distinct responsibilities (CRUD/forwarding, categories, ranking/stats)
    impact: Clearer boundaries, easier to understand and extend
  - decision: Barrel exports maintain existing import paths
    rationale: Zero breaking changes for consumers, seamless migration
    impact: All handlers continue using same import statement
  - decision: LeaderboardCategoryService has no dependency on LeaderboardCrudService
    rationale: Category operations are independent, only need database access
    impact: Cleaner dependency graph, fewer service dependencies
  - decision: Sub-handlers receive only needed sub-services
    rationale: Explicit dependencies, clear which operations each handler performs
    impact: Better understanding of handler responsibilities
metrics:
  duration: 7 minutes
  completed: 2026-02-09
  tasks: 2
  files-created: 7
  files-modified: 11
  lines-split: 1460 (758 tournament + 702 leaderboard)
  new-loc: 1536 (806 tournament + 730 leaderboard)
  tests-passing: 268
---

# Phase 03 Plan 01: Tournament and Leaderboard Service Splitting Summary

Split the two largest backend service files into focused sub-services with barrel exports, improving code organization while maintaining backward compatibility.

## Changes Made

### Tournament Service Split (758 LOC → 4 sub-services)

**1. TournamentCrudService (134 LOC)**
- Tournament CRUD operations: create, read, update, delete
- Team ID lookup methods for authorization
- Clean, focused responsibility

**2. TournamentRoundsService (85 LOC)**
- Round creation and management
- Round status updates
- Simplest of the sub-services

**3. TournamentMatchesService (352 LOC)**
- Match operations: create, update, start, complete
- Match result recording with bracket advancement
- Walkover declaration
- Match games (best-of series): create, record, update
- Largest sub-service due to match complexity

**4. TournamentBracketService (228 LOC)**
- Single elimination bracket generation
- Tournament detail assembly (rounds, matches, groups)
- Depends on: CrudService, RoundsService, MatchesService, GroupService
- High-level orchestration service

**Barrel Export**: `tournament_service.dart` (7 LOC) exports all sub-services

### Leaderboard Service Split (702 LOC → 3 sub-services)

**1. LeaderboardCrudService (258 LOC)**
- Leaderboard CRUD operations
- Forwarding methods to LeaderboardEntryService (getEntries, upsertEntry, etc.)
- Point config management
- Team ID lookup for authorization
- Central hub for leaderboard data access

**2. LeaderboardCategoryService (97 LOC)**
- Category-based leaderboard lookup
- Auto-creation of category leaderboards
- Category leaderboard map retrieval
- No dependency on CrudService (direct DB access for creation)

**3. LeaderboardRankingService (375 LOC)**
- Ranked entries with avatar lookup
- User position retrieval
- Monthly trends integration
- Weighted total calculation (training/match/social/competition weights)
- Total leaderboard synchronization (batch-optimized)
- Monthly stats retrieval
- Depends on: CrudService, CategoryService, TeamService
- Most complex sub-service with statistical operations

**Barrel Export**: `leaderboard_service.dart` (6 LOC) exports all sub-services

### Router and Handler Updates

**Router.dart Changes:**
- Tournament: 1 service → 4 sub-services instantiated
- Leaderboard: 1 service → 3 sub-services instantiated
- Updated handler constructors to pass sub-services
- Updated service consumer constructors (ActivityInstanceService, MiniActivityResultService)

**Handler Updates:**
- `tournaments_handler.dart`: Receives all 4 tournament sub-services
- `tournament_rounds_handler.dart`: Receives CrudService + RoundsService
- `tournament_matches_handler.dart`: Receives CrudService + MatchesService
- `tournament_groups_handler.dart`: Receives CrudService (for team lookup)
- `leaderboards_handler.dart`: Receives CrudService + RankingService (no CategoryService needed directly)
- `leaderboard_entries_handler.dart`: Receives CrudService

**Service Consumer Updates:**
- `activity_instance_service.dart`: Uses LeaderboardCrudService (attendance points)
- `mini_activity_result_service.dart`: Uses LeaderboardCrudService (mini-activity points)

## Deviations from Plan

None - plan executed exactly as written.

## Technical Details

### Dependency Injection Pattern

Tournament services form a dependency chain:
```
TournamentCrudService (base)
TournamentRoundsService (base)
TournamentMatchesService (base)
TournamentBracketService (depends on: crud, rounds, matches, group)
```

Leaderboard services:
```
LeaderboardCrudService (base, wraps EntryService)
LeaderboardCategoryService (base, independent)
LeaderboardRankingService (depends on: crud, category, team)
```

### Barrel Export Pattern

Both services use barrel exports to maintain existing import paths:
```dart
// Consumers continue using:
import '../services/tournament_service.dart';
import '../services/leaderboard_service.dart';

// But now resolve to multiple classes via barrel exports
```

### Authorization Pattern

Both CRUD services provide team ID lookup methods used by handlers for authorization checks:
- `TournamentCrudService.getTeamIdForTournament()`
- `TournamentCrudService.getTeamIdForMiniActivity()`
- `LeaderboardCrudService.getTeamIdForLeaderboard()`

## Testing

All 268 backend tests pass:
- Model roundtrip tests (191 tests)
- Parsing helpers tests (77 tests)
- Zero new errors or warnings
- Zero breaking changes

## Files Changed

**Created (7 files):**
- 4 tournament sub-services (806 LOC total)
- 3 leaderboard sub-services (730 LOC total)

**Modified (11 files):**
- 2 barrel exports (tournament_service.dart, leaderboard_service.dart)
- 1 router (service instantiation)
- 6 handlers (tournament, leaderboard)
- 2 service consumers (activity_instance, mini_activity_result)

## Impact

### Before
- `tournament_service.dart`: 758 LOC, all concerns mixed
- `leaderboard_service.dart`: 702 LOC, CRUD + ranking + categories + stats mixed

### After
- Tournament: 4 focused services, largest 352 LOC (matches)
- Leaderboard: 3 focused services, largest 375 LOC (ranking)
- Clear separation: CRUD, domain operations, orchestration
- Explicit dependencies between sub-services
- Zero breaking changes for consumers

### Benefits
1. **Readability**: Each service has single, clear responsibility
2. **Testability**: Smaller units easier to test in isolation
3. **Maintainability**: Changes affect fewer lines, clearer impact
4. **Extensibility**: New features fit into clear service boundaries
5. **Discoverability**: Service name indicates exact purpose

## Self-Check: PASSED

**Created files verified:**
- [x] backend/lib/services/tournament/tournament_crud_service.dart
- [x] backend/lib/services/tournament/tournament_rounds_service.dart
- [x] backend/lib/services/tournament/tournament_matches_service.dart
- [x] backend/lib/services/tournament/tournament_bracket_service.dart
- [x] backend/lib/services/leaderboard/leaderboard_crud_service.dart
- [x] backend/lib/services/leaderboard/leaderboard_category_service.dart
- [x] backend/lib/services/leaderboard/leaderboard_ranking_service.dart

**Commits verified:**
- [x] 7090c46: Tournament service split (feat(03-01): split tournament service into 4 sub-services)
- [x] 0d19c8e: Leaderboard service split (feat(03-01): split leaderboard service into 3 sub-services)

**Tests verified:**
- [x] dart analyze: No issues found
- [x] dart test: 268 tests passed
- [x] No direct sub-service imports in handlers (grep verified)
