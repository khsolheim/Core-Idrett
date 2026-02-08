# Domain Pitfalls: Dart/Flutter App Refactoring

**Domain:** Dart backend + Flutter frontend refactoring
**Researched:** 2026-02-08
**Confidence:** MEDIUM (based on training data + project context analysis)

## Executive Summary

Refactoring existing Dart/Flutter applications introduces unique risks distinct from greenfield development. Critical mistakes include breaking API contracts between frontend and backend during incremental changes, creating hot reload failures through widget constructor changes, breaking provider dependency chains, introducing null safety violations through unsafe casts, and creating performance regressions through excessive widget rebuilds.

This project has specific high-risk factors:
- **Path with space** (git corruption with concurrent operations)
- **No test coverage** for several features (blind refactoring risk)
- **Frontend + backend coordination** (API compatibility requirements)
- **22 completed phases** (refactoring fatigue, pattern drift)

## Critical Pitfalls

### Pitfall 1: Breaking API Contract During Incremental Refactoring
**What goes wrong:** Backend handler refactoring changes response shape or field names. Frontend continues using old structure. Silent failures in production because tests don't catch cross-boundary issues.

**Why it happens:**
- Backend and frontend developed/tested in isolation
- JSON field renames (e.g., `user_name` → `userName`) not coordinated
- Handler splitting moves fields between endpoints
- Service layer changes propagate to API without version checking

**Consequences:**
- Deserialization failures in production
- Silent null values (Dart's `fromJson` doesn't fail on missing fields)
- Partial data loss (some fields work, others don't)
- User-facing errors with no stack trace

**Prevention:**
1. **Contract-first refactoring:** Document API changes in shared schema before implementation
2. **Integration tests:** Test full frontend→backend flow (not just unit tests)
3. **JSON validation:** Add runtime assertions in `fromJson` methods during refactoring phase
4. **Parallel deployment:** Keep both old and new endpoints during transition
5. **Version headers:** Backend checks `X-API-Version` header, frontend sends current version

**Detection:**
- Warning sign: Handler changes include model field additions/removals
- Warning sign: `fromJson` methods modified in same PR as handler changes
- Warning sign: Test coverage only on one side of API boundary

**Phase mapping:** Phases focusing on service/handler splitting (large file splitting) must include integration test verification

### Pitfall 2: Hot Reload Breakage Through Widget Constructor Changes
**What goes wrong:** Widget refactoring changes constructor parameters. During development, hot reload fails or shows stale state. Developer loses 5-10 minutes per failure restarting app.

**Why it happens:**
- Widget extraction adds required parameters
- Changing parameter order or types
- Converting StatelessWidget → StatefulWidget
- Adding keys to widget constructors

**Consequences:**
- Developer productivity loss (2+ hours/day on large refactorings)
- Incomplete testing (developers skip edge cases to avoid restarts)
- Bugs introduced because changes not properly verified

**Prevention:**
1. **Optional parameters first:** Make new parameters optional with defaults during refactoring
2. **Incremental extraction:** Split widget in multiple steps (extract, then add parameters)
3. **Full restart protocol:** Document when full restart required (State changes, key changes)
4. **Const constructors:** Preserve `const` constructors where possible (better hot reload)

**Detection:**
- Warning sign: `The getter 'widget' was called on null` during hot reload
- Warning sign: UI not updating after hot reload
- Warning sign: Multiple StatelessWidget → StatefulWidget conversions in same PR

**Phase mapping:** Widget extraction phases (400+ LOC widget splitting) need strict hot reload testing protocol

### Pitfall 3: Riverpod Invalidation Cascade Failures
**What goes wrong:** Provider refactoring breaks dependency chain. Provider A depends on Provider B. After refactoring, A doesn't invalidate when B changes. Stale UI state. Silent bugs.

**Why it happens:**
- Provider splitting separates dependencies
- Changing `ref.watch()` to `ref.read()` (removes reactive dependency)
- Provider family parameters change
- Moving state between providers loses invalidation calls

**Consequences:**
- UI shows stale data after mutations
- Inconsistent state across features
- Race conditions in async operations
- Hard-to-reproduce bugs (timing-dependent)

**Prevention:**
1. **Dependency mapping:** Document provider dependency graph before splitting
2. **Invalidation audit:** Every mutation must list which providers to invalidate
3. **ref.watch() preservation:** Keep `ref.watch()` for reactive dependencies even if seems unnecessary
4. **Integration tests:** Test provider invalidation chains (not just individual providers)
5. **Explicit invalidation:** Use `ref.invalidate()` liberally during refactoring (optimize later)

**Detection:**
- Warning sign: Provider splitting moves `ref.watch()` calls
- Warning sign: `ref.read()` used where reactive updates needed
- Warning sign: Manual `setState()` or `notifyListeners()` added after provider refactoring
- Test: After mutation, check if UI rebuilds (use `debugPrintRebuildDirtyWidgets = true`)

**Phase mapping:** Provider splitting phases must include invalidation chain verification

### Pitfall 4: Unsafe Cast Null Pointer Explosions
**What goes wrong:** Replacing `as Type` with `as Type?` seems safe. But downstream code assumes non-null. NullPointerException in production.

**Why it happens:**
- Type system doesn't track nullable types through layers
- `data['field'] as Map<String, dynamic>` → `data['field'] as Map<String, dynamic>?` but caller doesn't handle null
- Dart analyzer doesn't warn about potential null in conditional paths
- Optional fields in JSON treated as required

**Consequences:**
- Production crashes with no local reproduction
- Error messages don't show root cause (NPE in unrelated code)
- Silent data corruption (null treated as empty/default)

**Prevention:**
1. **Null propagation:** If making cast nullable, trace all call sites and add null checks
2. **Validation at boundary:** Add runtime checks at deserialization layer (fail fast)
3. **Explicit defaults:** Use `??` operator to provide defaults immediately after cast
4. **Test with missing fields:** Integration tests should include API responses with optional fields missing
5. **Staged rollout:** Change `as Type` → `as Type?` in separate PR from null handling changes

**Detection:**
- Warning sign: Cast changed from `as Type` to `as Type?` without corresponding null checks
- Warning sign: Analyzer warnings suppressed (`// ignore: cast_nullable_to_non_nullable`)
- Warning sign: Null checks only in immediate function, not call sites
- Test: Remove optional fields from test JSON, verify graceful handling

**Phase mapping:** Unsafe cast replacement phase is HIGH RISK - requires extensive integration testing

### Pitfall 5: Performance Regression Through Widget Rebuilds
**What goes wrong:** Widget extraction creates new widget boundaries. Looks cleaner. But now entire widget tree rebuilds on every state change instead of small subtree.

**Why it happens:**
- Extracted widget uses `ref.watch()` on frequently-changing provider
- Missing `const` constructors after extraction
- Widget keys not preserved during extraction
- Provider `.select()` optimization lost during refactoring

**Consequences:**
- Janky animations (60fps → 30fps)
- Battery drain on mobile
- Delayed UI responses
- ListView scroll stuttering

**Prevention:**
1. **Preserve const:** If parent was `const`, child must be `const`
2. **Selective watching:** Use `.select()` for providers in extracted widgets
3. **Memoization:** Use `useMemoized()` from flutter_hooks if appropriate
4. **Keys preservation:** Keep ValueKey/ObjectKey during extraction
5. **Performance baseline:** Record build counts before refactoring (use `debugPrintRebuildDirtyWidgets`)

**Detection:**
- Warning sign: `ref.watch()` in extracted widget listens to large provider
- Warning sign: Lost `const` keyword during extraction
- Warning sign: New `setState()` calls in extracted StatefulWidget
- Test: Use Flutter DevTools performance overlay, compare rebuild counts before/after
- Test: Check `flutter run --profile` frame times

**Phase mapping:** Large widget file splitting (400+ LOC) needs performance testing

### Pitfall 6: Git Index Corruption with Concurrent Operations
**What goes wrong:** Multiple agents or developers work concurrently. Path has space. Git operations interleave. `.git/index` corrupts. All git commands fail.

**Why it happens:**
- Path: `/Users/karsten/NextCore/Core - Idrett` (space in directory name)
- Concurrent git operations (status, diff, add) without locking
- Shell command splitting on space instead of proper quoting
- Git's index file locking insufficient for concurrent access

**Consequences:**
- Lost work (commits fail, can't stage changes)
- Workflow blockage (all git commands fail)
- Confusion (error messages unclear)
- Time waste (30+ minutes debugging git state)

**Prevention:**
1. **Sequential operations:** Never run parallel git commands in phases
2. **Atomic commits:** Each phase completes all git operations before next starts
3. **Proper quoting:** Always quote paths in shell commands: `"$PATH"`
4. **Recovery script:** `rm -f .git/index && git reset` (documented in MEMORY.md)
5. **Pre-commit verification:** Check `.git/index` readable before operations

**Detection:**
- Warning sign: `error: bad signature 0x00000000` from git commands
- Warning sign: `fatal: index file corrupt`
- Warning sign: Concurrent agent workflows triggered in same repo
- Test: Run `git status` before and after refactoring operations

**Phase mapping:** ALL phases - orchestrator must serialize git operations

## Moderate Pitfalls

### Pitfall 7: Test Coverage False Positives
**What goes wrong:** Refactoring passes all existing tests. Deploy. Production breaks. Why? Tests only cover happy path. Refactoring broke edge cases.

**Why it happens:**
- Tests use mock data without null/empty/error cases
- Integration tests missing for untested features
- Test data always valid (no malformed JSON)
- Tests don't verify error handling paths

**Prevention:**
1. **Edge case audit:** Before refactoring untested feature, add negative tests
2. **Test coverage report:** Run `flutter test --coverage` and check coverage delta
3. **Null case testing:** Test every `fromJson` with missing fields
4. **Error injection:** Test with 400/500 responses from backend
5. **Production data replay:** Use anonymized production data in tests

**Detection:**
- Warning sign: Refactoring feature with <50% test coverage
- Warning sign: All tests use same mock data
- Warning sign: No tests for error handling after refactoring

**Phase mapping:** Test coverage phase must precede refactoring of untested features

### Pitfall 8: Service Boundary Confusion After Splitting
**What goes wrong:** Service split into multiple files. Unclear which service owns which responsibility. Circular dependencies. Duplicate logic.

**Why it happens:**
- Split based on line count, not responsibility
- No clear ownership model after split
- Shared logic extracted to both services
- Dependencies between split services not managed

**Prevention:**
1. **Responsibility documentation:** Each service documents its bounded context
2. **Dependency direction:** Services only depend on more fundamental services (no cycles)
3. **Shared logic extraction:** Common helpers go to separate utility service
4. **Facade pattern:** Original service becomes coordinator for sub-services
5. **Barrel exports:** Use `services.dart` to control public API

**Detection:**
- Warning sign: Import cycles between split services
- Warning sign: Similar method names in multiple split services
- Warning sign: Service splitting PR doesn't update documentation

**Phase mapping:** Large service file splitting (700+ LOC) needs architectural planning

### Pitfall 9: Translation Brittleness
**What goes wrong:** English UI text moved to Norwegian. But text used in logic (string matching, validation). Logic breaks.

**Why it happens:**
- Hardcoded strings used for business logic
- Enum-like string constants user-facing text
- Error messages parsed by code
- Text used as keys in maps/lookups

**Prevention:**
1. **Text audit:** Grep for string literals, identify which are UI vs logic
2. **Constants separation:** Keep internal constants (English) separate from display text
3. **i18n boundaries:** Translation layer separate from business logic
4. **Key-based errors:** Error codes not error messages in logic
5. **Staged translation:** Translate UI first, verify logic unchanged

**Detection:**
- Warning sign: String literals in business logic (services, repositories)
- Warning sign: String comparison in conditional logic
- Warning sign: Error handling code parses error messages
- Test: Change translated strings, verify logic still works

**Phase mapping:** Translation phase (English → Norwegian) needs logic/UI separation audit

### Pitfall 10: Async State Race Conditions
**What goes wrong:** Refactoring changes async operation order. Race condition appears. Sometimes A finishes before B, sometimes opposite. Intermittent failures.

**Why it happens:**
- Provider refactoring changes when async operations trigger
- Parallel operations that should be sequential
- Missing `await` after refactoring
- State updates during async gaps

**Prevention:**
1. **Async audit:** Map all async operations and dependencies
2. **Sequential by default:** Use `await` unless parallelism explicitly needed
3. **State versioning:** Track operation version to ignore stale updates
4. **Cancellation tokens:** Use `ref.watch()` disposal to cancel in-flight operations
5. **Deterministic testing:** Integration tests with controlled timing

**Detection:**
- Warning sign: Removed `await` during refactoring
- Warning sign: Converted sequential operations to parallel (`Future.wait`)
- Warning sign: Intermittent test failures (timing-dependent)
- Test: Add delays in async operations, verify behavior consistent

**Phase mapping:** Provider refactoring and service splitting phases need async flow analysis

## Minor Pitfalls

### Pitfall 11: Import Organization Drift
**What goes wrong:** File splitting creates many new imports. Import organization inconsistent. Linter warnings multiply. Code review noise.

**Prevention:**
- Run `dart fix --apply` after each refactoring step
- Use IDE auto-organize imports (CMD+Option+O in VS Code)
- Pre-commit hook runs `flutter analyze`

**Detection:**
- Many linter warnings about import ordering
- Mix of relative and absolute imports

### Pitfall 12: Barrel Export Bloat
**What goes wrong:** Create `widgets.dart` barrel export. Include everything. Now importing one widget imports 50 files. Slow compilation.

**Prevention:**
- Selective exports (only public API)
- Document why each export exists
- Avoid re-exporting re-exports (max 1 level)

**Detection:**
- Barrel files >50 lines
- Compile times increase after barrel creation
- Analyzer warnings about unused imports

### Pitfall 13: Documentation Staleness
**What goes wrong:** Refactor handler structure. `CLAUDE.md` still lists old structure. Next developer confused.

**Prevention:**
- Update `CLAUDE.md` in same PR as structural changes
- Update API endpoint table when handlers split
- Update architecture section when patterns change

**Detection:**
- Documentation references files that don't exist
- New patterns not in `CLAUDE.md`

### Pitfall 14: Over-Extraction
**What goes wrong:** Split widget into 10 tiny files. Now simple change requires editing 5 files. Readability worse than before.

**Prevention:**
- Only extract when widget >400 LOC or reused 3+ times
- Keep related logic together (don't split logic by type)
- Co-locate files (same directory)

**Detection:**
- Files <50 LOC that aren't reused
- Need to edit 4+ files for simple feature

### Pitfall 15: Type Inference Loss
**What goes wrong:** Refactoring changes explicit types to `var`/`dynamic`. Lose type safety. Analyzer can't catch errors.

**Prevention:**
- Preserve explicit types during refactoring
- Run `dart analyze` after each step
- Avoid `dynamic` unless necessary

**Detection:**
- Increased `as` casts after refactoring
- Runtime type errors in tests

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Large service splitting (700+ LOC) | Service boundary confusion (#8) | Document responsibility model before splitting |
| Large widget splitting (400+ LOC) | Hot reload breakage (#2), performance regression (#5) | Incremental extraction, performance baseline |
| Unsafe cast replacement | Null pointer explosions (#4) | Integration tests with missing fields, staged rollout |
| Test coverage addition | Test coverage false positives (#7) | Add edge case tests first, then refactor |
| Provider refactoring | Invalidation cascade failures (#3), async race conditions (#10) | Dependency mapping, explicit invalidation |
| Handler/endpoint changes | Breaking API contract (#1) | Integration tests, parallel endpoints |
| Translation (EN → NO) | Translation brittleness (#9) | Separate UI text from logic constants |
| Any git operations | Git index corruption (#6) | Sequential operations, proper quoting |

## Confidence Assessment

**Overall confidence:** MEDIUM

**Reasoning:**
- HIGH confidence on Flutter-specific pitfalls (widget rebuilds, hot reload, Riverpod patterns) - well-documented in training data
- MEDIUM confidence on project-specific pitfalls (git corruption, API coordination) - based on MEMORY.md and CLAUDE.md analysis
- LOW confidence on exact frequencies/impact - no access to real-world data on this specific project

**Verification sources:**
- Project documentation (CLAUDE.md, MEMORY.md)
- Training data on Dart/Flutter refactoring patterns
- Standard refactoring anti-patterns (Martin Fowler, etc.)

**Gaps:**
- No access to current project error logs (would show real production failures)
- No access to recent Dart/Flutter community discussions (2026)
- No verification against official Dart/Flutter refactoring guides (latest)

**Recommendations:**
1. Verify critical pitfalls #1-6 against official Flutter documentation
2. Test git corruption scenario (#6) in isolated environment before production refactoring
3. Measure baseline metrics before refactoring (test coverage %, build times, rebuild counts)
4. Create runbook for each critical pitfall with specific detection/recovery steps
