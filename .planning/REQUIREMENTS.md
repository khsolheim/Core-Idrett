# Requirements: Core - Idrett Refaktorering R2

**Defined:** 2026-02-08
**Core Value:** Koden skal være lett å forstå, endre, og utvide — uten å krasje på uventede data.

## v1 Requirements

Requirements for this refactoring milestone. Each maps to roadmap phases.

### Type Safety & Validation

- [x] **TYPE-01**: All backend unsafe `as String` casts replaced with validated parsing helpers ✓ Phase 2
- [x] **TYPE-02**: All backend unsafe `as int`/`as num` casts replaced with validated parsing helpers ✓ Phase 2
- [x] **TYPE-03**: All backend unsafe `as Map` casts replaced with validated parsing helpers ✓ Phase 2
- [x] **TYPE-04**: Safe JSON field extraction helper created and used at all deserialization boundaries ✓ Phase 2
- [x] **TYPE-05**: All `.first` calls on query results guarded with emptiness checks or `.firstOrNull` ✓ Phase 2
- [x] **TYPE-06**: All `DateTime.parse()` calls replaced with `DateTime.tryParse()` with fallback handling ✓ Phase 2

### File Splitting — Backend Services

- [ ] **BSPLIT-01**: tournament_service.dart (757 LOC) split into focused sub-services with barrel export
- [ ] **BSPLIT-02**: leaderboard_service.dart (701 LOC) split into focused sub-services with barrel export
- [ ] **BSPLIT-03**: fine_service.dart (614 LOC) split into focused sub-services with barrel export
- [ ] **BSPLIT-04**: activity_service.dart (576 LOC) split into focused sub-services with barrel export
- [ ] **BSPLIT-05**: export_service.dart (540 LOC) split into focused sub-services with barrel export
- [ ] **BSPLIT-06**: mini_activity_statistics_service.dart (533 LOC) split into focused sub-services
- [ ] **BSPLIT-07**: mini_activity_division_service.dart (525 LOC) split into focused sub-services
- [ ] **BSPLIT-08**: points_config_service.dart (488 LOC) split into focused sub-services

### File Splitting — Frontend Widgets

- [ ] **FSPLIT-01**: message_widgets.dart (482 LOC) split into focused widget files
- [ ] **FSPLIT-02**: test_detail_screen.dart (476 LOC) split into screen + extracted widgets
- [ ] **FSPLIT-03**: export_screen.dart (470 LOC) split into screen + extracted widgets
- [ ] **FSPLIT-04**: activity_detail_screen.dart (456 LOC) split into screen + extracted widgets
- [ ] **FSPLIT-05**: mini_activity_detail_content.dart (436 LOC) split into focused widget files
- [ ] **FSPLIT-06**: stats_widgets.dart (429 LOC) split into focused widget files
- [ ] **FSPLIT-07**: edit_team_members_tab.dart (423 LOC) split into focused widget files
- [ ] **FSPLIT-08**: dashboard_info_widgets.dart (420 LOC) split into focused widget files

### Test Coverage

- [x] **TEST-01**: Backend test infrastructure created (test helpers, mock database, test data factories) ✓ Phase 1
- [x] **TEST-02**: Backend model serialization tests for all models (fromJson/toJson roundtrip) ✓ Phase 1
- [ ] **TEST-03**: Backend export service tests covering all 7 export types
- [ ] **TEST-04**: Backend tournament service tests covering bracket generation (single-elim, round-robin, 3/5/8/16 participants)
- [ ] **TEST-05**: Backend fine service tests covering payment reconciliation, idempotency, balance calculations
- [ ] **TEST-06**: Backend statistics service tests covering edge cases (zero attendance, empty scores, season boundaries)
- [ ] **TEST-07**: Frontend export screen widget tests
- [ ] **TEST-08**: Frontend tournament screen widget tests

### Security & Bug Fixes

- [ ] **SEC-01**: Admin role check consolidated — remove dual-check (user_is_admin vs user_role), use single authoritative source
- [ ] **SEC-02**: Rate limiting added to auth endpoints (login, register, password reset)
- [ ] **SEC-03**: Rate limiting added to data mutation endpoints (message send, fine create, export)
- [ ] **SEC-04**: FCM token registration retry logic with exponential backoff
- [ ] **SEC-05**: FCM token persisted with last-sync timestamp for reliable recovery
- [ ] **SEC-06**: Foreground push notification display implemented (local notification or in-app banner)
- [ ] **SEC-07**: fine_boss permission checks added to all fine mutation endpoints

### Consistency — Code Patterns

- [ ] **CONS-01**: All backend handlers follow identical auth check pattern (getUserId → null check → requireTeamMember → role check)
- [ ] **CONS-02**: All backend error responses use consistent Norwegian messages via response_helpers
- [ ] **CONS-03**: All frontend screens with async data use when2() + EmptyStateWidget consistently
- [ ] **CONS-04**: All frontend error feedback uses ErrorDisplayService.showWarning() — no raw SnackBars
- [ ] **CONS-05**: All API endpoints return consistent response shapes (data envelope, error codes)
- [ ] **CONS-06**: All frontend widgets follow consistent spacing/padding patterns from theme

### Translation

- [ ] **I18N-01**: All remaining English UI labels, buttons, and headers translated to Norwegian
- [ ] **I18N-02**: All remaining English error messages and feedback text translated to Norwegian
- [ ] **I18N-03**: All remaining English placeholder text and hints translated to Norwegian

## v2 Requirements

Deferred to future milestone. Tracked but not in current roadmap.

### Code Generation

- **CODEGEN-01**: Migrate models to freezed for immutable data classes with equality
- **CODEGEN-02**: Migrate JSON serialization to json_serializable for compile-time safety
- **CODEGEN-03**: Add riverpod_generator for type-safe provider generation

### Infrastructure

- **INFRA-01**: CI/CD pipeline with automated testing and linting
- **INFRA-02**: Coverage reporting integrated in CI
- **INFRA-03**: dart_code_metrics for ongoing complexity monitoring

### Advanced

- **ADV-01**: Offline-first architecture with local cache and sync
- **ADV-02**: Audit logging for sensitive operations
- **ADV-03**: Export data encryption

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| New user-facing features | This is pure refactoring — no new functionality |
| Database schema changes | Only application code; schema is stable |
| Performance optimization beyond natural gains | Separate milestone if needed |
| Scaling work (pagination, caching strategies) | Separate milestone |
| Mobile-specific optimizations (iOS/Android) | Not the focus of this milestone |
| freezed/json_serializable migration | High complexity, deferred to v2 after manual validation foundation |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| TEST-01 | Phase 1 | ✓ Complete |
| TEST-02 | Phase 1 | ✓ Complete |
| TYPE-01 | Phase 2 | ✓ Complete |
| TYPE-02 | Phase 2 | ✓ Complete |
| TYPE-03 | Phase 2 | ✓ Complete |
| TYPE-04 | Phase 2 | ✓ Complete |
| TYPE-05 | Phase 2 | ✓ Complete |
| TYPE-06 | Phase 2 | ✓ Complete |
| BSPLIT-01 | Phase 3 | Pending |
| BSPLIT-02 | Phase 3 | Pending |
| BSPLIT-03 | Phase 3 | Pending |
| BSPLIT-04 | Phase 3 | Pending |
| BSPLIT-05 | Phase 3 | Pending |
| BSPLIT-06 | Phase 3 | Pending |
| BSPLIT-07 | Phase 3 | Pending |
| BSPLIT-08 | Phase 3 | Pending |
| SEC-01 | Phase 4 | Pending |
| SEC-02 | Phase 4 | Pending |
| SEC-03 | Phase 4 | Pending |
| SEC-07 | Phase 4 | Pending |
| FSPLIT-01 | Phase 5 | Pending |
| FSPLIT-02 | Phase 5 | Pending |
| FSPLIT-03 | Phase 5 | Pending |
| FSPLIT-04 | Phase 5 | Pending |
| FSPLIT-05 | Phase 5 | Pending |
| FSPLIT-06 | Phase 5 | Pending |
| FSPLIT-07 | Phase 5 | Pending |
| FSPLIT-08 | Phase 5 | Pending |
| TEST-03 | Phase 6 | Pending |
| TEST-04 | Phase 6 | Pending |
| TEST-05 | Phase 6 | Pending |
| TEST-06 | Phase 6 | Pending |
| TEST-07 | Phase 6 | Pending |
| TEST-08 | Phase 6 | Pending |
| CONS-01 | Phase 7 | Pending |
| CONS-02 | Phase 7 | Pending |
| CONS-03 | Phase 7 | Pending |
| CONS-04 | Phase 7 | Pending |
| CONS-05 | Phase 7 | Pending |
| CONS-06 | Phase 7 | Pending |
| SEC-04 | Phase 8 | Pending |
| SEC-05 | Phase 8 | Pending |
| SEC-06 | Phase 8 | Pending |
| I18N-01 | Phase 9 | Pending |
| I18N-02 | Phase 9 | Pending |
| I18N-03 | Phase 9 | Pending |

**Coverage:**
- v1 requirements: 45 total
- Mapped to phases: 45
- Unmapped: 0 (100% coverage)

---
*Requirements defined: 2026-02-08*
*Last updated: 2026-02-08 after roadmap creation*
