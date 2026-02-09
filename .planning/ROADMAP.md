# Roadmap: Core - Idrett Refactoring R2

## Overview

This roadmap transforms Core - Idrett from a working but fragile codebase into a robust, maintainable, and production-ready application. The journey spans 10 phases covering test infrastructure, type safety hardening, systematic file splitting, security improvements, consistency enforcement, and Norwegian translation. Each phase builds on prior work to minimize risk while delivering measurable quality improvements.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Test Infrastructure** - Foundation for safe refactoring ✓ (2026-02-09)
- [x] **Phase 2: Type Safety & Validation** - Eliminate unsafe casts and parsing ✓ (2026-02-09)
- [x] **Phase 3: Backend Service Splitting** - Break down large service files ✓ (2026-02-09)
- [ ] **Phase 4: Backend Security & Input Validation** - Harden API endpoints
- [ ] **Phase 5: Frontend Widget Extraction** - Split large widget files
- [ ] **Phase 6: Feature Test Coverage** - Test untested critical features
- [ ] **Phase 7: Code Consistency Patterns** - Enforce consistent patterns everywhere
- [ ] **Phase 8: Push Notification Hardening** - Fix FCM token and foreground issues
- [ ] **Phase 9: Translation Completion** - Complete Norwegian translation
- [ ] **Phase 10: Final Quality Pass** - Cross-cutting validation and polish

## Phase Details

### Phase 1: Test Infrastructure
**Goal**: Establish comprehensive test foundation enabling safe refactoring of untested code
**Depends on**: Nothing (first phase)
**Requirements**: TEST-01, TEST-02
**Success Criteria** (what must be TRUE):
  1. Backend test helpers exist for mocking database responses and creating test data
  2. All backend models successfully roundtrip through fromJson/toJson without data loss
  3. Test data factories generate valid model instances for all core entities
  4. Mock database infrastructure enables service testing without real Supabase connection
**Plans:** 4 plans

Plans:
- [ ] 01-01-PLAN.md — Backend dependencies, Equatable migration, test data factories, mock SupabaseClient
- [ ] 01-02-PLAN.md — Frontend Equatable migration, test data factory expansion with Norwegian names
- [ ] 01-03-PLAN.md — Backend model roundtrip tests (all ~62 classes)
- [ ] 01-04-PLAN.md — Frontend model roundtrip tests (all ~64 classes)

### Phase 2: Type Safety & Validation
**Goal**: Eliminate all unsafe type casts and establish validated parsing at deserialization boundaries
**Depends on**: Phase 1
**Requirements**: TYPE-01, TYPE-02, TYPE-03, TYPE-04, TYPE-05, TYPE-06
**Success Criteria** (what must be TRUE):
  1. Zero unsafe `as String`, `as int`, `as Map` casts remain in backend codebase
  2. All JSON deserialization uses validation helpers that fail safely with error messages
  3. All DateTime parsing uses tryParse() with null fallback handling
  4. All query result access checks emptiness or uses firstOrNull to avoid exceptions
  5. Backend analyze shows zero type safety warnings in services and handlers
**Plans:** 4 plans

Plans:
- [ ] 02-01-PLAN.md — Create parsing_helpers.dart (TDD) + fix LeaderboardEntry key mismatch
- [ ] 02-02-PLAN.md — Migrate all 24 model fromJson to safe parsing helpers
- [ ] 02-03-PLAN.md — Migrate all 34 service files to safe casts + guard .first accesses
- [ ] 02-04-PLAN.md — Migrate all 32 handler files to safe casts + final verification

### Phase 3: Backend Service Splitting
**Goal**: Break down large backend service files into focused sub-services with clear boundaries
**Depends on**: Phase 2
**Requirements**: BSPLIT-01, BSPLIT-02, BSPLIT-03, BSPLIT-04, BSPLIT-05, BSPLIT-06, BSPLIT-07, BSPLIT-08
**Success Criteria** (what must be TRUE):
  1. All backend service files under 400 LOC with focused responsibility
  2. Tournament, leaderboard, fine, activity, export services split into vertical slices
  3. Mini-activity statistics and division services decomposed by feature area
  4. Points config service extracted into separate concern
  5. All split services use barrel exports maintaining existing import paths
  6. Existing backend tests continue passing after splitting
**Plans:** 4 plans

Plans:
- [ ] 03-01-PLAN.md — Split tournament_service (758 LOC → 4) and leaderboard_service (702 LOC → 3)
- [ ] 03-02-PLAN.md — Split fine_service (615 LOC → 3) and activity_service (577 LOC → 2)
- [ ] 03-03-PLAN.md — Split export_service (541 LOC → 2) and mini_activity_statistics_service (534 LOC → 3)
- [ ] 03-04-PLAN.md — Split mini_activity_division_service (526 LOC → 2) and points_config_service (489 LOC → 3) + final verification

### Phase 4: Backend Security & Input Validation
**Goal**: Harden API security with consolidated auth checks, rate limiting, and validated inputs
**Depends on**: Phase 3
**Requirements**: SEC-01, SEC-02, SEC-03, SEC-07
**Success Criteria** (what must be TRUE):
  1. Admin role checks use single authoritative source (no dual-check inconsistency)
  2. Auth endpoints (login, register, password reset) protected by rate limiting
  3. Data mutation endpoints (message send, fine create, export) protected by rate limiting
  4. All fine mutation endpoints enforce fine_boss permission check
  5. All handler inputs validated before reaching service layer
  6. Backend analyze shows zero security warnings
**Plans:** 2 plans

Plans:
- [ ] 04-01-PLAN.md — Consolidate admin role check + create permission helpers + enforce fine_boss on _createFine + verify Phase 2 input validation coverage
- [ ] 04-02-PLAN.md — Add shelf_limiter rate limiting to auth, message/fine mutation, and export endpoints

### Phase 5: Frontend Widget Extraction
**Goal**: Break down large frontend widget files into focused, composable components
**Depends on**: Phase 4 (backend stable, safe to refactor frontend)
**Requirements**: FSPLIT-01, FSPLIT-02, FSPLIT-03, FSPLIT-04, FSPLIT-05, FSPLIT-06, FSPLIT-07, FSPLIT-08
**Success Criteria** (what must be TRUE):
  1. All frontend widget files under 350 LOC with focused presentation logic
  2. Message widgets, test detail, export, activity detail screens split into components
  3. Mini-activity detail content, stats widgets, edit members tab decomposed
  4. Dashboard info widgets extracted into separate files
  5. All split widgets maintain existing functionality and hot reload works
  6. Existing frontend tests continue passing after extraction
**Plans**: TBD

Plans:
- [ ] 05-01: [Plan details TBD during planning]

### Phase 6: Feature Test Coverage
**Goal**: Achieve comprehensive test coverage for untested critical features
**Depends on**: Phase 5 (widgets stable for UI testing)
**Requirements**: TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-08
**Success Criteria** (what must be TRUE):
  1. Export service has tests for all 7 export types with data validation
  2. Tournament service has tests for bracket generation (single-elim, round-robin, 3/5/8/16 participants)
  3. Fine service has tests for payment reconciliation, idempotency, balance calculations
  4. Statistics service has tests for edge cases (zero attendance, empty scores, season boundaries)
  5. Frontend export and tournament screens have widget tests covering key interactions
  6. Coverage report shows 70%+ backend, 80%+ frontend test coverage
**Plans**: TBD

Plans:
- [ ] 06-01: [Plan details TBD during planning]

### Phase 7: Code Consistency Patterns
**Goal**: Enforce consistent patterns across all handlers, error responses, and UI components
**Depends on**: Phase 6 (all code stable and tested)
**Requirements**: CONS-01, CONS-02, CONS-03, CONS-04, CONS-05, CONS-06
**Success Criteria** (what must be TRUE):
  1. All backend handlers follow identical auth pattern (getUserId → null check → requireTeamMember → role check)
  2. All backend error responses use Norwegian messages via response_helpers
  3. All frontend screens with async data use when2() + EmptyStateWidget consistently
  4. All frontend error feedback uses ErrorDisplayService.showWarning() without raw SnackBars
  5. All API endpoints return consistent response shapes with data envelope and error codes
  6. All frontend widgets follow consistent spacing and padding from theme
**Plans**: TBD

Plans:
- [ ] 07-01: [Plan details TBD during planning]

### Phase 8: Push Notification Hardening
**Goal**: Fix FCM token management and foreground notification display
**Depends on**: Phase 7 (consistent patterns established)
**Requirements**: SEC-04, SEC-05, SEC-06
**Success Criteria** (what must be TRUE):
  1. FCM token registration retries with exponential backoff on failure
  2. FCM token persisted with last-sync timestamp enabling recovery after app restart
  3. Foreground push notifications display via local notification or in-app banner
  4. Token registration errors logged and reported to error tracking
  5. Users receive notifications reliably in all app states (foreground, background, terminated)
**Plans**: TBD

Plans:
- [ ] 08-01: [Plan details TBD during planning]

### Phase 9: Translation Completion
**Goal**: Complete Norwegian translation of all remaining English text in user interface
**Depends on**: Phase 8 (all features stable)
**Requirements**: I18N-01, I18N-02, I18N-03
**Success Criteria** (what must be TRUE):
  1. All UI labels, buttons, and headers display in Norwegian
  2. All error messages and feedback text appear in Norwegian
  3. All placeholder text and input hints show Norwegian text
  4. Manual UI walkthrough finds zero English strings in user-facing flows
  5. Grep search for common English UI words returns zero results in lib/features
**Plans**: TBD

Plans:
- [ ] 09-01: [Plan details TBD during planning]

### Phase 10: Final Quality Pass
**Goal**: Cross-cutting validation ensuring all quality goals achieved
**Depends on**: Phase 9 (all individual work complete)
**Requirements**: None (validation phase)
**Success Criteria** (what must be TRUE):
  1. Flutter analyze shows zero errors and only accepted warnings (5 known)
  2. Dart analyze backend shows zero errors and zero warnings
  3. All backend tests pass with coverage above 70%
  4. All frontend tests pass with coverage above 80%
  5. Manual smoke test of all features reveals no regressions
  6. All 45 v1 requirements marked complete with evidence
**Plans**: TBD

Plans:
- [ ] 10-01: [Plan details TBD during planning]

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Test Infrastructure | 4/4 | ✓ Complete | 2026-02-09 |
| 2. Type Safety & Validation | 4/4 | ✓ Complete | 2026-02-09 |
| 3. Backend Service Splitting | 4/4 | ✓ Complete | 2026-02-09 |
| 4. Backend Security & Input Validation | 0/0 | Not started | - |
| 5. Frontend Widget Extraction | 0/0 | Not started | - |
| 6. Feature Test Coverage | 0/0 | Not started | - |
| 7. Code Consistency Patterns | 0/0 | Not started | - |
| 8. Push Notification Hardening | 0/0 | Not started | - |
| 9. Translation Completion | 0/0 | Not started | - |
| 10. Final Quality Pass | 0/0 | Not started | - |

---
*Roadmap created: 2026-02-08*
*Last updated: 2026-02-08*
