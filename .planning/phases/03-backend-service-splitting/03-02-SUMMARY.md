---
phase: 03-backend-service-splitting
plan: 02
subsystem: backend-services
tags: [refactoring, service-splitting, fine-system, activities]
dependency-graph:
  requires: ["03-01"]
  provides: ["fine-service-split", "activity-service-split"]
  affects: ["fines-handler", "activities-handler", "activity-instances-handler"]
tech-stack:
  added: []
  patterns: ["barrel-exports", "dependency-injection"]
key-files:
  created:
    - backend/lib/services/fine/fine_rule_service.dart
    - backend/lib/services/fine/fine_crud_service.dart
    - backend/lib/services/fine/fine_summary_service.dart
    - backend/lib/services/activity/activity_crud_service.dart
    - backend/lib/services/activity/activity_query_service.dart
  modified:
    - backend/lib/services/fine_service.dart (barrel export)
    - backend/lib/services/activity_service.dart (barrel export)
    - backend/lib/api/fines_handler.dart
    - backend/lib/api/activities_handler.dart
    - backend/lib/api/activity_instances_handler.dart
    - backend/lib/api/router.dart
decisions:
  - summary: "Split FineService into 3 sub-services by responsibility"
    rationale: "Original service mixed rule management, fine lifecycle, and summary calculations"
    alternatives: ["Keep monolithic", "Split into 2 services"]
    chosen: "3-way split for clear separation of concerns"
  - summary: "Split ActivityService into 2 sub-services by operation type"
    rationale: "Service mixed CRUD/generation with complex query logic"
    alternatives: ["Keep monolithic", "Split by entity type"]
    chosen: "Split by operation type (CRUD vs Query)"
  - summary: "ActivityQueryService slightly exceeds target LOC (364 vs 310)"
    rationale: "Query methods have significant complexity with instance overrides, response counting, and user enrichment"
    alternatives: ["Further split query types", "Extract helper methods"]
    chosen: "Accept slight overage - methods are cohesive and logically grouped"
metrics:
  duration_minutes: 6
  tasks_completed: 2
  files_created: 7
  files_modified: 6
  tests_passing: 268
  completed_date: 2026-02-09
---

# Phase 03 Plan 02: Fine and Activity Service Splitting Summary

**One-liner:** Split FineService into 3 focused sub-services (Rules, CRUD+Appeals, Summaries) and ActivityService into 2 sub-services (CRUD+Generation, Queries) with barrel exports maintaining import compatibility.

## Objective

Split fine_service.dart (615 LOC) into 3 focused sub-services and activity_service.dart (577 LOC) into 2 focused sub-services. Both get barrel exports maintaining existing import paths.

**Why this matters:** Fine service mixed rule management, fine lifecycle, and summary calculations. Activity service mixed CRUD/generation with complex query logic. Splitting improves single-responsibility adherence and maintainability.

## What Was Built

### Task 1: Fine Service Split

**Created 3 sub-services:**

1. **FineRuleService (82 LOC)** - Fine rule CRUD operations
   - `getFineRules`, `createFineRule`, `updateFineRule`, `deleteFineRule`
   - Clean separation of rule management from fine lifecycle

2. **FineCrudService (402 LOC)** - Fine CRUD, appeals, and payments
   - Fine operations: `getFines`, `getFine`, `createFine`, `approveFine`, `rejectFine`
   - Appeal operations: `createAppeal`, `resolveAppeal`, `getPendingAppeals`
   - Payment operations: `recordPayment` (with auto-status update to 'paid')
   - Batch fetching: users, rules, and payment totals in `getFines`
   - Appeal resolution logic: update fine status and amount based on accepted/rejected

3. **FineSummaryService (149 LOC)** - Team and user fine summaries
   - `getTeamSummary`: aggregate statistics for team
   - `getUserSummaries`: per-user fine and payment data
   - Includes `_UserFineData` private helper class

**Integration:**
- Barrel export at `backend/lib/services/fine_service.dart`
- FinesHandler updated to accept 3 sub-services (rule, crud, summary)
- router.dart DI updated with sub-service instantiation

**Commit:** `3e3b3f7` - All 268 tests passing

### Task 2: Activity Service Split

**Created 2 sub-services:**

1. **ActivityCrudService (221 LOC)** - Activity CRUD and instance generation
   - `createActivity`: creates activity + generates instances via recurrence rules
   - `_generateInstances`: private method for instance creation
   - `_createDefaultResponses`: opt-out activity default responses (batch insert)
   - `_calculateDates`: recurrence calculation (once, weekly, biweekly, monthly)
   - `updateActivity`, `deleteActivity`, `getTeamIdForActivity`, `getTeamMemberIds`

2. **ActivityQueryService (364 LOC)** - Activity listing and querying
   - `getActivitiesForTeam`: activities with instance counts
   - `getUpcomingInstances`: upcoming instances with response counts
   - `getInstanceWithResponses`: detailed instance view with user-enriched responses
   - `getInstancesByDateRange`: calendar-style queries with user response filtering
   - Uses `collection_helpers.groupByCount` for efficient aggregation
   - Uses `UserService.getUserMap` for batch user enrichment

**Integration:**
- Barrel export at `backend/lib/services/activity_service.dart`
- ActivitiesHandler updated to accept 2 sub-services (crud, query)
- ActivityInstancesHandler updated to use query service
- router.dart DI updated with sub-service instantiation

**Commit:** `414ef47` - All 268 tests passing

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

✅ **dart analyze:** No issues found (fixed 2 unused imports during execution)
✅ **dart test:** All 268 tests passing
✅ **Line counts:**
- FineRuleService: 82 LOC (target ~90) ✅
- FineCrudService: 402 LOC (target ~320, acceptable given complexity) ✅
- FineSummaryService: 149 LOC (target ~140) ✅
- ActivityCrudService: 221 LOC (target ~220) ✅
- ActivityQueryService: 364 LOC (target ~310, acceptable given query complexity) ✅

## Key Decisions

**1. Three-way split for FineService**
- Rule CRUD, Fine lifecycle (CRUD+appeals+payments), Summaries
- Clear separation of concerns vs. potential over-engineering
- **Chosen:** 3-way split - each service has distinct responsibility

**2. CRUD vs Query split for ActivityService**
- Could have split by entity type (activities vs instances)
- Could have kept monolithic
- **Chosen:** Operation-type split - CRUD/generation separate from querying

**3. Accept slight LOC overage for query services**
- FineCrudService: 402 vs 320 target (fine lifecycle complexity)
- ActivityQueryService: 364 vs 310 target (query method complexity)
- **Rationale:** Methods are cohesive, further splitting would break logical grouping
- **Decision:** Accept overage - services are still focused and maintainable

## Technical Highlights

### Barrel Export Pattern
Both services use barrel exports to maintain import compatibility:
```dart
// Fine Services - Barrel export
export 'fine/fine_rule_service.dart';
export 'fine/fine_crud_service.dart';
export 'fine/fine_summary_service.dart';
```

### Dependency Injection
router.dart instantiates sub-services with proper dependencies:
```dart
final fineRuleService = FineRuleService(db);
final fineCrudService = FineCrudService(db, userService);
final fineSummaryService = FineSummaryService(db, userService, teamService);

final finesHandler = FinesHandler(
  fineRuleService, fineCrudService, fineSummaryService, teamService
);
```

### Batch Fetching Preservation
Complex batch-fetching logic preserved in sub-services:
- `FineCrudService.getFines`: users + rules + payments in parallel
- `ActivityQueryService.getInstanceWithResponses`: responses + users batch-fetched

### Appeal Resolution Logic
`FineCrudService.resolveAppeal` maintains complex business logic:
- Accepted: set fine status to 'rejected'
- Rejected: set fine status to 'approved', optionally add extra fee
- Update appeal status and timestamps

## Impact

**Before:**
- `FineService`: 615 LOC, 3 concerns mixed
- `ActivityService`: 577 LOC, CRUD and queries interleaved

**After:**
- Fine: 3 focused services (82, 402, 149 LOC)
- Activity: 2 focused services (221, 364 LOC)
- Barrel exports maintain import compatibility
- Zero test failures, zero analyze issues

**Benefits:**
- Clearer separation of concerns
- Easier to understand each service's responsibility
- Simpler testing (can mock sub-services independently)
- Better maintainability (changes isolated to specific responsibilities)

## Self-Check: PASSED

**Created files verified:**
- ✅ `/Users/karsten/NextCore/Core - Idrett/backend/lib/services/fine/fine_rule_service.dart` (82 LOC)
- ✅ `/Users/karsten/NextCore/Core - Idrett/backend/lib/services/fine/fine_crud_service.dart` (402 LOC)
- ✅ `/Users/karsten/NextCore/Core - Idrett/backend/lib/services/fine/fine_summary_service.dart` (149 LOC)
- ✅ `/Users/karsten/NextCore/Core - Idrett/backend/lib/services/activity/activity_crud_service.dart` (221 LOC)
- ✅ `/Users/karsten/NextCore/Core - Idrett/backend/lib/services/activity/activity_query_service.dart` (364 LOC)

**Commits verified:**
- ✅ `3e3b3f7`: refactor(03-02): split FineService into 3 sub-services
- ✅ `414ef47`: refactor(03-02): split ActivityService into 2 sub-services

**Tests verified:**
- ✅ All 268 backend tests passing after both splits

## What's Next

**Phase 03 continuation:**
- Plan 03-03: Split mini-activity services (template, division, result, statistics)
- Plan 03-04: Split message, team, and user services

**Dependencies unlocked:**
None - this was a focused refactoring with no downstream blockers.

---

*Completed: 2026-02-09 | Duration: ~6 minutes | Status: ✅ Success*
