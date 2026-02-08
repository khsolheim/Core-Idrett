# Project Research Summary

**Project:** Core - Idrett Refactoring & Quality Improvement
**Domain:** Dart/Flutter Sports Team Management App Refactoring
**Researched:** 2026-02-08
**Confidence:** MEDIUM-HIGH

## Executive Summary

Core - Idrett is a mature Norwegian sports team management application with 46K LOC Flutter frontend and 26K LOC Dart backend. After completing 22 refactoring phases, the codebase needs strategic quality improvements focusing on test coverage, type safety, large file splitting, and security hardening. The recommended approach emphasizes test-first refactoring with incremental changes to minimize risk, particularly around API contract coordination between frontend and backend.

The research reveals three critical success factors: First, establish comprehensive test infrastructure before touching untested features (export, tournaments, statistics currently have zero coverage). Second, address type safety systematically using code generation (freezed, json_serializable) to eliminate unsafe casts that pose runtime risks. Third, coordinate backend service splitting with frontend changes to avoid breaking API contracts during incremental refactoring. The project's unique risk factors include a file path with spaces (causing git corruption under concurrent operations) and tight frontend-backend coupling requiring careful coordination.

Key risks center on provider invalidation chain breakage during state management refactoring, hot reload failures from widget constructor changes, and null safety violations from unsafe cast replacement. Mitigation relies on dependency mapping before splitting, test-first validation workflows, and sequential git operations. With proper discipline around testing and incremental changes, the roadmap can safely deliver production-ready quality improvements over 8-10 weeks.

## Key Findings

### Recommended Stack

The refactoring stack prioritizes built-in Dart/Flutter tools over new dependencies, focusing on static analysis and code generation for safety gains. No runtime framework changes required.

**Core technologies:**
- **flutter_lints / lints**: Official lint rules (already installed) — foundation for code quality
- **riverpod_lint / custom_lint**: Riverpod-specific safety checks — detects state management anti-patterns
- **freezed + json_serializable**: Type-safe data classes — eliminates unsafe casts, replaces manual JSON parsing
- **validators**: Lightweight string validation — email, UUID, URL checks without regex soup
- **coverage**: Test coverage reporting — tracks refactoring progress and untested code
- **shelf_rate_limit**: Rate limiting middleware — protects auth endpoints (currently missing)
- **dart_code_metrics**: Code metrics analysis — identifies file splitting candidates by LOC and complexity

**Critical principle:** Add code generation for safety (freezed/json_serializable), not for convenience. Current code has pervasive unsafe casts that cause runtime failures.

### Expected Features

Refactoring quality work has well-established expectations that users (developers and end users) implicitly demand.

**Must have (table stakes):**
- **Type Safety**: Sound null safety, no unsafe casts — Dart's core strength
- **Test Coverage**: 70%+ backend, 80%+ frontend — critical features must have tests
- **Input Validation**: All external data validated at boundaries — prevents injection and crashes
- **File Size Management**: 300-400 LOC max per file — maintainability requirement
- **Security Basics**: Auth/authz, rate limiting, role checks — production readiness
- **Error Handling Consistency**: Predictable error patterns — user-facing Norwegian messages
- **Code Analysis Compliance**: Zero errors, minimal warnings — professional quality signal

**Should have (competitive differentiators):**
- **Code Generation Leverage**: freezed/json_serializable for boilerplate — signals advanced maturity
- **Dead Code Elimination**: Proactive cleanup — reduces cognitive load
- **Performance Profiling**: Identify N+1 queries and expensive rebuilds — already addressed N+1, need widget profiling
- **Documentation as Code**: dartdoc comments — living API documentation
- **Advanced State Management**: Provider .select() optimization — signals mature Riverpod usage (Phase 20 completed)

**Defer (v2+):**
- **Offline-First Architecture**: High complexity, significant refactoring
- **CI/CD Integration**: Valuable but independent of code quality work
- **Code Generation Migration**: Risky at scale, manual serialization currently works
- **Feature Flags**: Not needed until multi-environment deployment

### Architecture Approach

The codebase follows Clean Architecture with Flutter frontend (Riverpod state management) communicating with Dart backend (Shelf framework) via REST. Data flows through clearly defined layers: UI → Providers → Repositories → API Client → Backend Handlers → Services → Database. Both frontend and backend use feature-based structure with completed barrel export patterns from 22 prior refactoring phases.

**Major components:**
1. **Frontend Providers** (20 files, some 400+ LOC) — State management with AsyncNotifierProvider, needs splitting for read/write separation
2. **Backend Services** (35 files, 8 files 700+ LOC) — Business logic layer, needs vertical slice splitting by domain feature
3. **Models** (shared structure) — Data classes with unsafe casts, requires freezed migration for type safety
4. **API Client** (frontend) — HTTP communication with error mapping, stable foundation for refactoring
5. **Handlers** (backend, ~30 files) — HTTP routing layer, mostly split after Phase 7, needs input validation audit

**Key pattern:** Refactor bottom-up (models → services → handlers → providers → widgets) to avoid breaking dependencies. Use barrel exports to hide internal structure changes. Critical path: Model validation must complete before service splitting.

### Critical Pitfalls

The research identified six critical pitfalls that can derail refactoring work, ranked by impact and likelihood:

1. **Breaking API Contract During Incremental Refactoring** — Backend handler changes alter response shape or field names without coordination. Frontend continues using old structure. Silent production failures. **Prevent:** Contract-first refactoring, integration tests across API boundary, version headers, parallel endpoints during transition.

2. **Riverpod Invalidation Cascade Failures** — Provider splitting breaks dependency chains. Provider A depends on B but doesn't invalidate when B changes. Stale UI state. **Prevent:** Document provider dependency graph before splitting, preserve ref.watch() for reactive dependencies, explicit ref.invalidate() calls, integration tests for invalidation chains.

3. **Unsafe Cast Null Pointer Explosions** — Replacing `as Type` with `as Type?` seems safe but downstream code assumes non-null. Production crashes. **Prevent:** Trace all call sites when making casts nullable, validation at deserialization boundary, test with missing JSON fields, staged rollout.

4. **Performance Regression Through Widget Rebuilds** — Widget extraction creates new boundaries, entire tree rebuilds instead of subtrees. Janky animations. **Prevent:** Preserve const constructors, use .select() for providers, maintain keys, record rebuild count baselines with debugPrintRebuildDirtyWidgets.

5. **Git Index Corruption with Concurrent Operations** — Path with space + concurrent git operations = corrupted .git/index. **Prevent:** Sequential git operations only, proper quoting in shell commands, recovery script documented.

6. **Test Coverage False Positives** — Refactoring passes existing tests, production breaks because tests only cover happy paths. **Prevent:** Add edge case tests before refactoring, test with null/empty/error cases, use production data replay.

## Implications for Roadmap

Based on research, suggested phase structure follows dependency order and risk management principles:

### Phase 1: Test Infrastructure Foundation
**Rationale:** Must establish safety net before touching untested code. Backend has 0% coverage, frontend ~30%. Cannot safely refactor without tests.
**Delivers:** Backend test helpers, repository mocks, model serialization tests, test data factories, coverage reporting setup
**Addresses:** Test Coverage (table stakes), Foundation for all subsequent phases
**Avoids:** Test Coverage False Positives (Pitfall #6) — establishes baseline before refactoring
**Duration:** 1-2 weeks
**Research flag:** Standard patterns, skip deeper research

### Phase 2: Type Safety & Model Validation
**Rationale:** Foundation for everything else. Unsafe casts in models affect all layers. Easier to test than services. Low risk, high value.
**Delivers:** Validation helpers (validateString, validateInt), safe JSON parsing with tryParse(), model unit tests, freezed/json_serializable setup
**Addresses:** Type Safety (table stakes), Input Validation (table stakes), Code Generation (differentiator)
**Uses:** freezed, json_serializable, validators from STACK.md
**Avoids:** Unsafe Cast Null Pointer Explosions (Pitfall #3) — catches errors at deserialization boundary
**Duration:** 2-3 weeks
**Research flag:** Freezed migration pattern needs research-phase (conversion strategy for 50+ models)

### Phase 3: Backend Service Splitting
**Rationale:** Services are dependency middle layer. Must split before handlers depend on new structure. 8 services exceed 700 LOC.
**Delivers:** Split tournament_service (757 LOC), leaderboard_service (701 LOC), fine_service (614 LOC), activity_service (576 LOC), export_service (540 LOC), mini_activity services (533/525 LOC), points_config_service (488 LOC)
**Addresses:** File Size Management (table stakes), Service Boundaries
**Implements:** Vertical slice splitting with barrel exports (ARCHITECTURE.md Pattern 1)
**Avoids:** Service Boundary Confusion (Pitfall #8) — document responsibility model before splitting
**Duration:** 3-4 weeks (parallel work on independent services possible)
**Research flag:** Standard splitting pattern, skip research

### Phase 4: Backend Input Validation & Security
**Rationale:** Services are stable from Phase 3. Handlers are thin layer. High security priority before frontend work.
**Delivers:** Request validation before unsafe casts, query parameter validation, 401 vs 403 consistency, rate limiting on auth endpoints, admin role dual-check audit
**Addresses:** Security Basics (table stakes), Input Validation (table stakes)
**Uses:** shelf_rate_limit from STACK.md
**Avoids:** Breaking API Contract (Pitfall #1) — validate inputs before they reach services
**Duration:** 2 weeks
**Research flag:** shelf_rate_limit API needs verification (MEDIUM confidence in STACK.md)

### Phase 5: Frontend Provider Refactoring
**Rationale:** Backend stable from Phases 2-4. Can now safely refactor frontend state without backend coordination risk.
**Delivers:** Split stopwatch_provider (401 LOC), tournament_notifiers (376 LOC), points_provider (374 LOC), mini_activity_operations_notifier (378 LOC) into read/write separation
**Addresses:** File Size Management (table stakes), Advanced State Management (differentiator)
**Implements:** Read/write separation pattern (ARCHITECTURE.md Provider Splitting)
**Avoids:** Invalidation Cascade Failures (Pitfall #2) — map dependencies before splitting, test invalidation chains
**Duration:** 2-3 weeks
**Research flag:** Provider dependency mapping needs research-phase (complex invalidation chains)

### Phase 6: Frontend Widget Extraction
**Rationale:** Mostly presentational, lowest risk. Providers are stable from Phase 5. Can defer if timeline pressure.
**Delivers:** Split activity model (486 LOC), message_widgets (482 LOC), test_detail_screen (476 LOC), export_screen (470 LOC), tournament models (470 LOC), stopwatch model (458 LOC), activity_detail_screen (456 LOC)
**Addresses:** File Size Management (table stakes), Widget Composition (table stakes)
**Implements:** Composition pattern with focused widgets (ARCHITECTURE.md Widget Splitting)
**Avoids:** Hot Reload Breakage (Pitfall #2), Performance Regression (Pitfall #4) — incremental extraction, performance baseline
**Duration:** 3-4 weeks (low priority, can parallelize with Phase 7)
**Research flag:** Standard widget extraction, skip research

### Phase 7: Missing Feature Test Coverage
**Rationale:** Export, tournaments, statistics, absences currently untested. Must test before any refactoring of these features.
**Delivers:** Tests for export feature, tournament brackets, statistics calculations, absence reporting
**Addresses:** Test Coverage (table stakes) for untested features
**Avoids:** Test Coverage False Positives (Pitfall #6) — catches edge cases before refactoring
**Duration:** 2-3 weeks
**Research flag:** Tournament bracket logic needs research-phase (complex algorithm, needs verification)

### Phase 8: Security Audit & Hardening
**Rationale:** Cross-cutting concern. Code is stable from all prior phases. High priority for production.
**Delivers:** Auth check audit (401 vs 403), role-based permission verification, SQL injection review, file upload security, token expiration handling, FCM token security
**Addresses:** Security Basics (table stakes), Rate Limiting (from Phase 4 validated here)
**Avoids:** Multiple security pitfalls, production vulnerabilities
**Duration:** 1-2 weeks
**Research flag:** Security best practices need research-phase (2026 standards verification)

### Phase 9: Translation & Polish
**Rationale:** No architectural impact. All code stable. Can be done last or deferred entirely.
**Delivers:** Find remaining English strings, translate to Norwegian, consistency check with existing translations
**Addresses:** Internationalization (table stakes)
**Avoids:** Translation Brittleness (Pitfall #9) — audit logic vs UI text separation first
**Duration:** 1 week
**Research flag:** Standard translation work, skip research

### Phase Ordering Rationale

**Dependency-driven sequencing:** Phase 2 (models) is critical path blocking everything. Backend work (Phases 3-4) must complete before frontend provider refactoring (Phase 5) to avoid API contract breakage. Widget extraction (Phase 6) depends on provider stability. Testing (Phases 1, 7) bracket refactoring work to establish safety.

**Risk management:** High-risk phases (Provider Refactoring, Security Audit) come after foundation is solid and test coverage exists. Low-risk phases (Widget Extraction, Translation) can defer under timeline pressure. Test Infrastructure (Phase 1) front-loads safety investment.

**Parallelization opportunities:** Backend team can work Phases 3-4 while frontend prepares infrastructure. Phase 6 (widgets) and Phase 7 (tests) can overlap. Eight services in Phase 3 can split independently. This enables 2-3 person team parallelization.

**Avoids critical pitfalls:** Sequential phasing prevents git corruption (Pitfall #5). Test-first approach prevents false positive coverage (Pitfall #6). Phases grouped to avoid breaking API contracts during transitions (Pitfall #1). Model validation before service work prevents unsafe cast explosions (Pitfall #3).

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 2 (Model Validation):** Freezed migration strategy for 50+ models — need conversion workflow, code generation setup verification
- **Phase 4 (Security):** shelf_rate_limit exact API verification — STACK.md has MEDIUM confidence on this package
- **Phase 5 (Provider Refactoring):** Provider dependency mapping for invalidation chains — complex cross-feature dependencies need analysis
- **Phase 7 (Testing):** Tournament bracket algorithm verification — complex logic needs test strategy research
- **Phase 8 (Security Audit):** Current 2026 security best practices — verify against official Dart/Flutter security guidelines

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Test Infrastructure):** Well-documented testing patterns, existing Flutter test infrastructure to extend
- **Phase 3 (Service Splitting):** Vertical slice pattern established in Phase 7/9, barrel exports proven
- **Phase 6 (Widget Extraction):** Composition pattern established in Phase 10/21, 9 widgets already split
- **Phase 9 (Translation):** Standard i18n work, grep and replace with validation

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | flutter_lints/freezed/json_serializable HIGH (industry standard), shelf_rate_limit MEDIUM (exists but API unverified), dart_code_metrics LOW (may be deprecated/renamed in 2026) |
| Features | HIGH | Based on established Dart/Flutter best practices and 22 completed phases showing what patterns work |
| Architecture | HIGH | Current project structure well-documented, patterns validated by completed refactoring work |
| Pitfalls | MEDIUM | Flutter-specific pitfalls HIGH confidence (training data), project-specific pitfalls MEDIUM (based on MEMORY.md), production frequency unknown |

**Overall confidence:** MEDIUM-HIGH

Research is grounded in strong project context (46K frontend LOC, 26K backend LOC, 22 phases documented) and established Dart/Flutter patterns. Main uncertainty is 2026 ecosystem changes (package versions, deprecations) and production error data.

### Gaps to Address

**Stack verification needed:**
- **shelf_rate_limit**: Verify package exists and check exact middleware API before Phase 4 starts
- **dart_code_metrics**: Verify current status (may be renamed or deprecated), have fallback (manual LOC counting)
- **Package versions**: Check pub.dev for current versions of freezed, json_serializable, validators before Phase 2

**Architecture questions:**
- **Freezed migration scope**: 50+ models across frontend and backend — need accurate count and conversion priority order
- **Provider dependency graph**: Map complete invalidation chains before Phase 5 — complex cross-feature dependencies need visualization
- **Test data strategy**: Production data replay mentioned in PITFALLS.md — establish anonymization and storage strategy

**Pitfall validation:**
- **Git corruption frequency**: Test git corruption scenario in isolated environment — document exact recovery process
- **API contract coordination**: Establish integration test strategy for cross-boundary changes — need shared test data between frontend/backend
- **Performance baselines**: Record current rebuild counts and build times before refactoring — enable regression detection

**Timeline assumptions:**
- Effort estimates assume 1-2 developers working full-time — adjust for actual team size and availability
- Testing phases may take longer if untested features more complex than expected
- Security audit duration depends on findings — may need follow-up phase for remediation

## Sources

### Primary (HIGH confidence)
- Project codebase analysis: 46K LOC frontend (`/app`), 26K LOC backend (`/backend`)
- `/Users/karsten/NextCore/Core - Idrett/CLAUDE.md` — Architecture, patterns, commands
- `/Users/karsten/.claude/projects/-Users-karsten-NextCore-Core---Idrett/memory/MEMORY.md` — 22 completed phases, established patterns
- `/Users/karsten/NextCore/Core - Idrett/app/pubspec.yaml` — Current frontend dependencies
- `/Users/karsten/NextCore/Core - Idrett/backend/pubspec.yaml` — Current backend dependencies
- `/Users/karsten/NextCore/Core - Idrett/app/test/` — Existing test infrastructure (TestScenario, MockProviders)

### Secondary (MEDIUM confidence)
- Flutter/Dart best practices (training data, January 2025 cutoff)
- Riverpod patterns (training data, official docs patterns)
- Shelf framework patterns (training data, Dart shelf package documentation)
- freezed/json_serializable (de facto standard for Dart data classes, widely adopted)
- Clean Architecture principles (Robert C. Martin)
- Test-driven development methodology (industry standard)

### Tertiary (LOW confidence)
- shelf_rate_limit API (training data suggests exists, exact API unverified)
- dart_code_metrics current status (may have changed in 2026)
- Specific package versions (may have updated since January 2025)
- Production error frequencies (no access to logs)

### Verification Recommendations
Before implementation:
1. Check pub.dev for current versions: `dart pub search validators`, `dart pub search shelf_rate_limit`, `dart pub global search dart_code_metrics`
2. Review official Flutter refactoring guide (if exists in 2026)
3. Verify Riverpod invalidation best practices against current documentation
4. Test git corruption scenario in isolated environment with space in path

---
*Research completed: 2026-02-08*
*Ready for roadmap: yes*
