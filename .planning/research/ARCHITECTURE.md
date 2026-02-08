# Architecture Patterns: Flutter + Dart Backend Refactoring

**Domain:** Sports team management app refactoring
**Researched:** 2026-02-08
**Confidence:** HIGH (based on established patterns from 22 completed phases + Flutter/Dart best practices)

## Recommended Architecture for Refactoring

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter Frontend                        │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐             │
│  │    UI    │───▶│ Riverpod │───▶│Repository│───┐         │
│  │  Widgets │◀───│ Providers│◀───│   Layer  │   │         │
│  └──────────┘    └──────────┘    └──────────┘   │         │
│                                                   │         │
│  ┌──────────────────────────────────────────┐   │         │
│  │    Core Layer (Services, Router, Theme)   │   │         │
│  └──────────────────────────────────────────┘   │         │
└─────────────────────────────────────────────────┼─────────┘
                                                   │
                                                   │ HTTP/REST
                                                   │
┌─────────────────────────────────────────────────┼─────────┐
│                    Dart Backend                  │         │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐  │         │
│  │ Handlers │───▶│ Services │───▶│ Database │◀─┘         │
│  │  (HTTP)  │◀───│(Business)│◀───│ (Supabase│            │
│  └──────────┘    └──────────┘    └──────────┘            │
│                                                            │
│  ┌──────────────────────────────────────────┐            │
│  │    Middleware (Auth, CORS, Logging)       │            │
│  └──────────────────────────────────────────┘            │
└────────────────────────────────────────────────────────────┘
```

### Component Boundaries

| Component | Responsibility | Communicates With | File Count | Current State |
|-----------|---------------|-------------------|------------|---------------|
| **Frontend UI** | User interface, local state | Providers | ~90 screens/widgets | Some 400+ LOC files |
| **Riverpod Providers** | State management, async data | Repositories, UI | ~20 provider files | Some split, some need work |
| **Frontend Repositories** | API calls, data transformation | API Client, Models | ~15 repositories | Mostly clean |
| **API Client** | HTTP communication, token mgmt | Backend handlers | 1 file | Clean |
| **Backend Handlers** | HTTP routing, request validation | Services, Middleware | ~30 handlers | Mostly split after Phase 7 |
| **Backend Services** | Business logic, data operations | Database, Models | ~35 services | 8 files 700+ LOC |
| **Database Layer** | Supabase client wrapper | PostgreSQL | 1 wrapper | Clean |
| **Models** | Data structures, serialization | All layers | ~25 models/layer | Some complex, need splitting |

### Data Flow

**Read Operations:**
```
User Action → UI Widget → Provider.watch() → Repository.fetch()
  → ApiClient.get() → Backend Handler → Service.query()
  → Database.select() → Model.fromJson() → Service → Handler
  → ApiClient → Repository → Provider → UI (AsyncValue)
```

**Write Operations:**
```
User Action → UI Widget → Provider.method() → Repository.create/update()
  → ApiClient.post/put() → Backend Handler (validation) → Service.insert/update()
  → Database.insert/update() → ref.invalidate() → Triggers re-fetch
```

**Error Flow:**
```
Exception → ApiClient (maps to AppException) → ErrorDisplayService.showError()
  → Feature-specific error handler → User-friendly Norwegian message → SnackBar
```

## Refactoring Architecture Patterns

### Pattern 1: Vertical Slice Splitting (Large Files)

**What:** Split files by feature/responsibility while maintaining cohesion
**When:** Files exceed 400 LOC (widgets) or 700 LOC (services)
**Risk Level:** MEDIUM

**Strategy:**
```
Before:
  tournament_service.dart (757 LOC)
    - Group management
    - Round management
    - Match management
    - Bracket generation

After:
  tournament/
    ├── tournament_service.dart (core operations)
    ├── tournament_group_service.dart (group logic)
    ├── tournament_bracket_service.dart (bracket logic)
    └── services.dart (barrel export)
```

**Dependencies:**
- Service → Database (remains unchanged)
- Handler → Service (import path changes)
- Tests → Service (import path updates)

**Example from completed work:**
```dart
// Phase 7: Backend handler splitting
// handlers/activities_handler.dart →
//   handlers/activities/activities_handler.dart
//   handlers/activities/activity_instances_handler.dart

// Phase 8: Backend model splitting
// models/tournament.dart →
//   models/tournament/tournament_core.dart
//   models/tournament/tournament_round.dart
//   models/tournament/tournament_match.dart
//   models/tournament/tournament_group.dart
//   models/tournament/tournament.dart (barrel)
```

### Pattern 2: Test-First Validation Refactoring

**What:** Add tests before changing unsafe code patterns
**When:** Replacing unsafe casts, nullable field access, unvalidated parsing
**Risk Level:** HIGH (breaking production code)

**Strategy:**
```
1. Identify unsafe pattern (e.g., map['field'] as String)
2. Write test covering current behavior (even if wrong)
3. Add validation (validateString(), DateTime.tryParse())
4. Update test to expect safe behavior
5. Run full test suite
```

**Example patterns to replace:**
```dart
// UNSAFE (current code):
final id = json['id'] as String;  // Throws if null
final date = DateTime.parse(json['date']);  // Throws on invalid

// SAFE (refactored):
final id = validateString(json['id'], 'id');  // Returns String, throws ValidationException
final date = DateTime.tryParse(json['date'] ?? '') ?? DateTime.now();  // Fallback
```

**Testing priority order:**
1. Models (JSON serialization) - LOW RISK, high value
2. Services (business logic) - HIGH RISK, critical
3. Providers (state management) - MEDIUM RISK, user-facing
4. Handlers (HTTP routing) - LOW RISK, thin layer

### Pattern 3: Dependency-Aware Splitting

**What:** Split files in dependency order (leaf → root)
**When:** Files have complex interdependencies
**Risk Level:** LOW (if order followed)

**Dependency layers (bottom-up):**
```
Layer 0: Models, Constants, Enums
  ↓
Layer 1: Database Client, Helpers
  ↓
Layer 2: Services (business logic)
  ↓
Layer 3: Handlers (HTTP routing)
  ↓
Layer 4: Router (composition)
```

**Frontend equivalent:**
```
Layer 0: Models, Constants, Theme
  ↓
Layer 1: API Client, Repositories
  ↓
Layer 2: Providers (state)
  ↓
Layer 3: Widgets (reusable)
  ↓
Layer 4: Screens (composition)
  ↓
Layer 5: Router (navigation)
```

**Splitting order:**
1. Start at leaves (models, helpers) - no dependencies
2. Move to services - depend on models
3. Then handlers - depend on services
4. Update router last - depends on handlers

### Pattern 4: Provider Invalidation Chain

**What:** Ensure state updates propagate correctly after mutations
**When:** Splitting providers or changing state structure
**Risk Level:** MEDIUM (stale data bugs)

**Invalidation patterns:**
```dart
// After mutation, invalidate related providers
Future<void> deleteFine(String fineId) async {
  await repository.deleteFine(fineId);

  // Invalidate affected state
  ref.invalidate(finesListProvider);
  ref.invalidate(teamStatisticsProvider);  // Fines affect stats
  ref.invalidate(leaderboardProvider);     // Points may change
}
```

**Dependency graph example:**
```
teamMembersProvider
  ├─▶ dashboardProvider
  ├─▶ statisticsProvider
  └─▶ leaderboardProvider

finesProvider
  ├─▶ teamAccountingProvider
  ├─▶ statisticsProvider (shared)
  └─▶ leaderboardProvider (shared)
```

### Pattern 5: Barrel Export Encapsulation

**What:** Use barrel exports to hide internal structure changes
**When:** Splitting any multi-file component
**Risk Level:** LOW

**Structure:**
```
feature/
  ├── internal_file_1.dart
  ├── internal_file_2.dart
  └── feature.dart  // Barrel export

// feature.dart
export 'internal_file_1.dart';
export 'internal_file_2.dart';
```

**Benefits:**
- Consumers import from barrel: `import 'feature/feature.dart'`
- Internal refactoring doesn't break imports
- Clear public API surface

**Completed examples:**
- `models/tournament/tournament.dart` (Phase 8)
- `services/achievement/achievement.dart` (Phase 9)
- `providers/fines_providers.dart` (Phase 4)

## Anti-Patterns to Avoid

### Anti-Pattern 1: Big Bang Refactoring

**What:** Refactoring entire codebase at once
**Why bad:**
- Impossible to test incrementally
- Merge conflicts across features
- Hard to isolate bugs
- High rollback cost

**Instead:**
- Refactor one feature/component at a time
- Use feature flags if needed
- Deploy incrementally

### Anti-Pattern 2: Test-Last Validation Changes

**What:** Changing unsafe casts without tests
**Why bad:**
- No safety net for regressions
- Can't verify current behavior
- Breaking changes ship to production

**Instead:**
- Write tests first (even for bad behavior)
- Change implementation
- Update tests to expect correct behavior

### Anti-Pattern 3: Circular Dependencies

**What:** Service A depends on Service B, B depends on A
**Why bad:**
- Impossible to split cleanly
- Tight coupling
- Hard to test in isolation

**Instead:**
- Extract shared logic to new service
- Use dependency injection
- Follow layered architecture

**Example:**
```dart
// BAD: Circular
class FineService {
  final StatisticsService stats;
  calculateFine() => stats.getPlayerPoints();
}

class StatisticsService {
  final FineService fines;
  getTeamBalance() => fines.getTotalFines();
}

// GOOD: Extracted
class TeamFinancialService {
  final FineService fines;
  final StatisticsService stats;

  getFullReport() {
    // Combines both services
  }
}
```

### Anti-Pattern 4: Over-Splitting

**What:** Creating too many tiny files (< 50 LOC)
**Why bad:**
- Cognitive overhead navigating files
- Import explosion
- No clear boundaries

**Instead:**
- Split at logical boundaries (features, responsibilities)
- Aim for 150-400 LOC per file
- Group related functionality

### Anti-Pattern 5: Breaking Import Paths Without Barrel Exports

**What:** Splitting files and updating all imports manually
**Why bad:**
- Error-prone
- Large git diffs
- Breaks in-progress branches

**Instead:**
- Add barrel export first
- Update internal structure
- Imports remain unchanged

## Scalability Considerations

| Concern | Current (15 features) | At 30 features | At 50 features |
|---------|----------------------|----------------|----------------|
| **File navigation** | Manageable with feature folders | Needs consistent structure | Consider domain grouping |
| **Build time** | ~30s Flutter, ~5s Dart | ~60s Flutter, ~10s Dart | Modularization required |
| **Test execution** | 20 tests, <5s | 100+ tests, ~20s | Parallel test execution |
| **Provider count** | ~20 providers | ~50 providers | Provider organization layer |
| **Service dependencies** | 35 services, manageable DI | Need dependency graph docs | Consider service locator |
| **Code size** | 46K LOC frontend, 26K backend | 90K+ LOC | Monorepo vs packages |

## Refactoring Build Order

### Phase Structure Recommendation

Based on dependency analysis and risk assessment:

#### **Phase 1: Foundation - Test Infrastructure** (LOW RISK)
**Why first:** Enable safe refactoring of everything else

**Targets:**
- Set up test helpers for services
- Add repository mocks
- Create test data factories
- Add model serialization tests

**Duration:** 1-2 weeks
**Dependencies:** None
**Validates:** All subsequent phases

#### **Phase 2: Models - Safe Validation** (LOW-MEDIUM RISK)
**Why early:** Foundation for everything, easier to test

**Targets:**
- Add validation helpers (validateString, validateInt, etc.)
- Replace unsafe casts in fromJson()
- Add tryParse() for dates/numbers
- Add model tests

**Duration:** 1-2 weeks
**Dependencies:** Phase 1 (test infrastructure)
**Affects:** All layers using models

#### **Phase 3: Backend Services - Large File Splitting** (MEDIUM RISK)
**Why before handlers:** Handlers depend on services

**Targets (by LOC):**
1. tournament_service.dart (757 LOC) → 3-4 services
2. leaderboard_service.dart (701 LOC) → 2-3 services
3. fine_service.dart (614 LOC) → 2 services
4. activity_service.dart (576 LOC) → existing pattern
5. export_service.dart (540 LOC) → 2-3 services
6. mini_activity_statistics_service.dart (533 LOC) → 2 services
7. mini_activity_division_service.dart (525 LOC) → 2 services
8. points_config_service.dart (488 LOC) → 2 services

**Duration:** 3-4 weeks (1 service/week, parallel work possible)
**Dependencies:** Phase 2 (validated models)
**Pattern:** Vertical slice + barrel exports

#### **Phase 4: Backend Handlers - Input Validation** (LOW-MEDIUM RISK)
**Why after services:** Services are stable, handlers are thin

**Targets:**
- Add request validation before unsafe casts
- Validate query parameters
- Add error handling tests
- Ensure 401 vs 403 consistency

**Duration:** 1-2 weeks
**Dependencies:** Phase 2-3
**Pattern:** Test-first validation

#### **Phase 5: Frontend Providers - Large File Splitting** (MEDIUM RISK)
**Why mid-way:** Affects UI but repositories are stable

**Targets (by complexity):**
1. stopwatch_provider.dart (401 LOC) - complex state
2. tournament_notifiers.dart (376 LOC) - multiple notifiers
3. points_provider.dart (374 LOC) - mutation-heavy
4. mini_activity_operations_notifier.dart (378 LOC) - complex

**Duration:** 2-3 weeks
**Dependencies:** Backend stable (Phase 2-4)
**Risk:** State bugs, invalidation issues

#### **Phase 6: Frontend Widgets - Screen Splitting** (LOW-MEDIUM RISK)
**Why late:** Mostly presentational, providers are stable

**Targets (by LOC):**
1. activity.dart model (486 LOC) - complex nested structure
2. message_widgets.dart (482 LOC) - after Phase 12 consolidation
3. test_detail_screen.dart (476 LOC)
4. export_screen.dart (470 LOC)
5. tournament_group_models.dart (470 LOC)
6. stopwatch.dart model (458 LOC)
7. activity_detail_screen.dart (456 LOC)
8. mini_activity_detail_content.dart (436 LOC)

**Duration:** 3-4 weeks (low priority, low risk)
**Dependencies:** Provider stability (Phase 5)
**Pattern:** Widget extraction + composition

#### **Phase 7: Security Audit** (HIGH PRIORITY)
**Why standalone:** Cross-cutting concern

**Targets:**
- Review all auth checks (401 vs 403)
- Audit role-based permissions
- Check for SQL injection risks (parameterized queries)
- Validate file upload security
- Review token expiration handling

**Duration:** 1 week
**Dependencies:** Code stability (Phase 1-6)
**Outcome:** Security issues list + fixes

#### **Phase 8: Translation & UI Polish** (LOW RISK)
**Why last:** No architectural impact

**Targets:**
- Find remaining English strings
- Translate to Norwegian
- Ensure consistency with existing translations

**Duration:** 1 week
**Dependencies:** UI stability (Phase 6)
**Pattern:** Search & replace with context

### Critical Path

```
Phase 1 (Test Infrastructure)
  ↓
Phase 2 (Model Validation) ← CRITICAL: Blocks everything
  ↓
┌─────────────┴─────────────┐
│                           │
Phase 3 (Backend Services)  Phase 5 (Frontend Providers) ← Can run parallel
  ↓                           ↓
Phase 4 (Backend Handlers)  Phase 6 (Frontend Widgets)   ← Low priority
  └─────────────┬─────────────┘
                ↓
Phase 7 (Security Audit) ← HIGH PRIORITY
                ↓
Phase 8 (Translation) ← Can defer
```

### Parallelization Opportunities

**Backend Team:**
- Phase 3 services can split independently (8 services)
- Each service is isolated work
- Can proceed while frontend works on Phase 5

**Frontend Team:**
- Phase 5 providers can split after backend stable
- Phase 6 widgets mostly independent
- Low risk, can defer if needed

**Shared:**
- Phase 2 models affect both (requires coordination)
- Phase 7 security audit (one-time effort)

## Component-Specific Patterns

### Backend Service Splitting

**Pattern:** Feature-based vertical slicing

```dart
// Before: tournament_service.dart (757 LOC)
class TournamentService {
  // Group operations (200 LOC)
  Future<TournamentGroup> createGroup(...);
  Future<void> updateGroupStandings(...);

  // Round/Match operations (250 LOC)
  Future<TournamentRound> createRound(...);
  Future<void> updateMatchResult(...);

  // Bracket generation (300 LOC)
  List<TournamentMatch> generateBracket(...);
  void seedTeams(...);
}

// After: Split into 3 services
// tournament/tournament_group_service.dart (220 LOC)
class TournamentGroupService {
  final SupabaseClient db;
  // Group operations only
}

// tournament/tournament_bracket_service.dart (250 LOC)
class TournamentBracketService {
  final SupabaseClient db;
  // Bracket generation logic
}

// tournament/tournament_service.dart (300 LOC)
class TournamentService {
  final SupabaseClient db;
  final TournamentGroupService groupService;
  final TournamentBracketService bracketService;

  // Delegates to specialized services
  Future<Tournament> createTournament(...) {
    // Use groupService and bracketService
  }
}

// tournament/services.dart (barrel)
export 'tournament_service.dart';
export 'tournament_group_service.dart';
export 'tournament_bracket_service.dart';
```

**Handler updates:**
```dart
// Before:
import '../services/tournament_service.dart';

// After (unchanged due to barrel export):
import '../services/tournament/services.dart';
```

### Frontend Provider Splitting

**Pattern:** Separate read/write operations

```dart
// Before: Large provider with mixed concerns
@riverpod
class StopwatchNotifier extends _$StopwatchNotifier {
  // Reading state (100 LOC)
  Future<Stopwatch> fetch();

  // Creating/updating (150 LOC)
  Future<void> create();
  Future<void> updateSettings();

  // Timer operations (150 LOC)
  void start();
  void stop();
  void recordLap();
}

// After: Split by responsibility
// stopwatch_provider.dart (read)
@riverpod
class StopwatchNotifier extends _$StopwatchNotifier {
  Future<Stopwatch> build(String id) async {
    return ref.read(stopwatchRepositoryProvider).getStopwatch(id);
  }
}

// stopwatch_operations_notifier.dart (write)
@riverpod
class StopwatchOperationsNotifier extends _$StopwatchOperationsNotifier {
  Future<void> create(StopwatchConfig config) async {
    await ref.read(stopwatchRepositoryProvider).create(config);
    ref.invalidate(stopwatchListProvider);
  }

  Future<void> updateSettings(String id, StopwatchConfig config) async {
    await ref.read(stopwatchRepositoryProvider).update(id, config);
    ref.invalidate(stopwatchProvider(id));
  }
}

// stopwatch_timer_notifier.dart (local state)
@riverpod
class StopwatchTimerNotifier extends _$StopwatchTimerNotifier {
  Duration build() => Duration.zero;

  void start() { /* timer logic */ }
  void stop() { /* timer logic */ }
  void recordLap() {
    // Persist to repository
    ref.read(stopwatchOperationsNotifierProvider).recordLap();
  }
}

// stopwatch_providers.dart (barrel)
export 'stopwatch_provider.dart';
export 'stopwatch_operations_notifier.dart';
export 'stopwatch_timer_notifier.dart';
```

### Frontend Widget Splitting

**Pattern:** Composition with focused widgets

```dart
// Before: Large screen (476 LOC)
class TestDetailScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(...),  // 50 LOC
      body: Column(
        children: [
          // Test info section (100 LOC)
          // Results chart (150 LOC)
          // History list (150 LOC)
        ],
      ),
    );
  }
}

// After: Extracted widgets
// test_detail_screen.dart (150 LOC)
class TestDetailScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testAsync = ref.watch(testProvider(testId));

    return testAsync.when2(
      data: (test) => Scaffold(
        appBar: TestDetailAppBar(test: test),
        body: TestDetailContent(test: test),
      ),
    );
  }
}

// widgets/test_detail_app_bar.dart (60 LOC)
class TestDetailAppBar extends StatelessWidget {
  final Test test;
  // Focused AppBar logic
}

// widgets/test_detail_content.dart (200 LOC)
class TestDetailContent extends ConsumerWidget {
  final Test test;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TestInfoSection(test: test),
        TestResultsChart(test: test),
        TestHistoryList(test: test),
      ],
    );
  }
}

// widgets/test_info_section.dart (80 LOC)
// widgets/test_results_chart.dart (120 LOC)
// widgets/test_history_list.dart (120 LOC)
```

## Risk Assessment Matrix

| Refactoring Type | Risk Level | Complexity | Test Coverage Needed | Rollback Cost |
|------------------|------------|------------|---------------------|---------------|
| Model validation | LOW | Low | Unit tests (100%) | Low (isolated) |
| Service splitting | MEDIUM | Medium | Unit + integration (80%) | Medium (DI updates) |
| Handler validation | LOW | Low | Integration tests (60%) | Low (thin layer) |
| Provider splitting | MEDIUM | High | Widget tests (70%) | High (state bugs) |
| Widget splitting | LOW | Low | Widget tests (50%) | Low (presentation) |
| Security fixes | HIGH | Variable | Security tests (100%) | Very High (auth) |
| Translation | VERY LOW | Low | Manual QA | Very Low (copy) |

### Risk Mitigation

**For MEDIUM/HIGH risk changes:**
1. Feature flag if possible
2. Deploy to staging first
3. Monitor error rates post-deploy
4. Have rollback plan ready
5. Incremental rollout (10% → 50% → 100%)

**For Backend service splitting:**
- Keep old imports working via barrel exports
- Add logging to verify correct service called
- Run shadow mode (old + new, compare results)

**For Provider splitting:**
- Add extensive widget tests first
- Use provider debugging (`ProviderObserver`)
- Test invalidation chains manually
- Check for stale data in production monitoring

## File Size Guidelines

Based on analysis of current codebase:

| File Type | Target Range | Split Threshold | Completed Pattern |
|-----------|--------------|-----------------|-------------------|
| Backend Service | 200-400 LOC | 700+ LOC | Phase 9: 3 services split |
| Backend Handler | 100-300 LOC | 400+ LOC | Phase 7: 7 handlers split |
| Backend Model | 100-200 LOC | 300+ LOC | Phase 8: 3 models split |
| Frontend Provider | 150-300 LOC | 400+ LOC | Phase 4: 3 providers split |
| Frontend Screen | 200-400 LOC | 500+ LOC | Phase 21: 5 screens split |
| Frontend Widget | 100-250 LOC | 400+ LOC | Phase 10: 10 widgets split |
| Frontend Model | 150-300 LOC | 400+ LOC | Tournament models need work |

**When NOT to split:**
- File is cohesive (single clear responsibility)
- Splitting would create circular dependencies
- No clear boundary emerges
- Too many shared private methods

## Testing Strategy

### Test Pyramid for Refactoring

```
         /\
        /  \  E2E Tests (5%)
       /    \  - Critical user flows
      /______\  - Smoke tests only
     /        \
    /          \ Integration Tests (25%)
   /            \ - API contracts
  /              \ - Service layer
 /________________\
/                  \ Unit Tests (70%)
/____________________\ - Models (serialization)
                       - Helpers/utilities
                       - Business logic
```

### Test Coverage Targets by Component

| Component | Current Coverage | Target Coverage | Priority |
|-----------|-----------------|-----------------|----------|
| Models (backend) | 0% | 90% | HIGH |
| Models (frontend) | 0% | 90% | HIGH |
| Services (backend) | 0% | 70% | HIGH |
| Handlers (backend) | 0% | 50% | MEDIUM |
| Repositories (frontend) | 20% (mocked) | 60% | MEDIUM |
| Providers (frontend) | 30% (20 tests) | 70% | MEDIUM |
| Widgets (frontend) | 10% | 50% | LOW |

### Test-First Refactoring Workflow

```
1. Identify refactoring target (e.g., unsafe cast)
2. Write failing test showing current behavior
3. Make test pass (document current state)
4. Refactor (add validation)
5. Update test to expect safe behavior
6. Ensure test still passes
7. Run full suite
8. Commit with test + implementation
```

**Example:**
```dart
// Step 2-3: Document current (unsafe) behavior
test('fromJson throws on null id', () {
  expect(
    () => User.fromJson({'name': 'Test'}),
    throwsA(isA<TypeError>()),
  );
});

// Step 4-5: Refactor + update test
test('fromJson throws ValidationException on null id', () {
  expect(
    () => User.fromJson({'name': 'Test'}),
    throwsA(isA<ValidationException>().having(
      (e) => e.field, 'field', 'id',
    )),
  );
});
```

## Dependency Injection Patterns

### Backend DI (router.dart)

**Current pattern (from Phase 9):**
```dart
// bin/server.dart → api/router.dart
Future<Handler> createRouter(SupabaseClient supabase) async {
  // Instantiate all services
  final userService = UserService(supabase);
  final teamService = TeamService(supabase);
  final activityService = ActivityService(supabase);
  // ... 35 services

  // Inject into handlers
  final authHandler = AuthHandler(userService, teamService);
  final activitiesHandler = ActivitiesHandler(activityService, teamService);
  // ... 30 handlers

  // Compose router
  final router = Router();
  router.mount('/auth', authHandler.router);
  router.mount('/activities', activitiesHandler.router);
  // ...

  return Pipeline()
    .addMiddleware(auth)
    .addHandler(router.call);
}
```

**After service splitting:**
```dart
// Service composition pattern
final tournamentGroupService = TournamentGroupService(supabase);
final tournamentBracketService = TournamentBracketService(supabase);
final tournamentService = TournamentService(
  supabase,
  groupService: tournamentGroupService,
  bracketService: tournamentBracketService,
);

// Handler gets composed service
final tournamentsHandler = TournamentsHandler(tournamentService);
```

**Key insight:** Handlers always get high-level service, services compose internally.

### Frontend DI (Riverpod)

**Current pattern:**
```dart
// Repository providers
@riverpod
ActivityRepository activityRepository(ActivityRepositoryRef ref) {
  return ActivityRepository(
    apiClient: ref.read(apiClientProvider),
  );
}

// Data providers (read)
@riverpod
class ActivityNotifier extends _$ActivityNotifier {
  Future<Activity> build(String id) async {
    return ref.read(activityRepositoryProvider).getActivity(id);
  }
}

// Mutation providers (write)
@riverpod
class ActivityMutationNotifier extends _$ActivityMutationNotifier {
  Future<void> create(Activity activity) async {
    await ref.read(activityRepositoryProvider).create(activity);
    ref.invalidate(activityListProvider);
  }
}
```

**After provider splitting:**
- Keep provider granularity (read vs write)
- Use `ref.read()` for cross-provider dependencies
- Invalidate affected providers after mutations
- Use `.select()` for fine-grained reactivity (Phase 20)

## Migration Checklist Template

For each refactoring phase:

### Pre-Migration
- [ ] Identify all affected files
- [ ] Document current behavior
- [ ] Write tests for current behavior
- [ ] Create feature branch
- [ ] Review with team

### During Migration
- [ ] Make changes incrementally
- [ ] Add barrel exports first
- [ ] Update internal structure
- [ ] Keep imports working
- [ ] Run tests after each change
- [ ] Update docs inline

### Post-Migration
- [ ] Full test suite passes
- [ ] Manual testing of affected features
- [ ] Code review
- [ ] Update import paths (if needed)
- [ ] Deploy to staging
- [ ] Monitor for errors
- [ ] Merge to main

### Rollback Plan
- [ ] Document rollback steps
- [ ] Keep old code for 1 sprint
- [ ] Monitor error rates
- [ ] Have hotfix ready

## Confidence Assessment

| Pattern | Confidence | Source |
|---------|------------|--------|
| File splitting strategy | HIGH | 22 completed phases, established patterns |
| Test-first validation | HIGH | Standard TDD practice, Flutter best practices |
| Provider splitting | HIGH | Riverpod documentation, Phase 4 completion |
| Service dependency order | HIGH | Clean Architecture, Phase 9 DI pattern |
| Risk assessment | MEDIUM | Based on codebase analysis, not production data |
| Build time projections | MEDIUM | Estimates based on current growth, not measured |
| Test coverage targets | HIGH | Industry standards + Flutter recommendations |

## Sources

**Confidence: HIGH** - Based on:
1. Project codebase analysis (46K LOC frontend, 26K backend)
2. Completed 22 refactoring phases documented in MEMORY.md
3. Established patterns from Phase 1-22
4. Flutter/Dart best practices (training data, January 2025)
5. Clean Architecture principles (Robert C. Martin)
6. Riverpod documentation patterns
7. Test-driven development methodology

**Note:** This research leverages extensive project-specific context. External source verification would increase confidence in scalability projections and test coverage targets, but architectural patterns are validated by completed work.
