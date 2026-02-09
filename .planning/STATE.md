# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-08)

**Core value:** Koden skal være lett å forstå, endre, og utvide — uten å krasje på uventede data.
**Current focus:** Phase 8 - Push Notification Hardening (in progress)

## Current Position

Phase: 8 of 10 (Push Notification Hardening)
Plan: 1 of 3 (Complete)
Status: In Progress
Last activity: 2026-02-09 — Plan 08-01 complete, installed foundation services (FCM token persistence + local notifications), Firebase config deferred

Progress: [███████████░] 92% (22 of 24 total plans across phases 01-08)

## Performance Metrics

**Velocity:**
- Total plans completed: 22
- Average duration: ~10 minutes
- Total execution time: ~3.8 hours

**By Phase:**

| Phase | Plans | Total Time | Avg/Plan |
|-------|-------|------------|----------|
| 01    | 4/4   | ~3.5h      | ~50m     |
| 02    | 4/4   | ~21m       | ~5m      |
| 03    | 4/4   | ~25m       | ~6.25m   |
| 04    | 2/2   | ~4m        | ~2m      |
| 05    | 3/4   | ~12m       | ~4m      |
| 06    | 3/3   | ~30m       | ~10m     |
| 07    | 4/4   | ~20m       | ~5m      |
| 08    | 1/3   | ~10m       | ~10m     |

**Recent Trend:**
- Plan 01-01: Backend Equatable + test infra (30 min)
- Plan 01-02: Frontend Equatable + test factories (11 min)
- Plan 01-03: Backend roundtrip tests — 191 tests (9 min + orchestrator fixes)
- Plan 01-04: Frontend roundtrip tests — 148 tests (25 min across 2 agents)
- Plan 02-01: Safe parsing helpers + LeaderboardEntry fix (4 min)
- Plan 02-03: Backend service migration (7 min, Python script automation)
- Plan 02-04: Handler layer migration (10 min, 32 handlers, ~250 casts)
- Plan 03-01: Tournament + Leaderboard service splitting (7 min, 2 services → 7 sub-services)
- Plan 03-02: Fine + Activity service splitting (6 min, 2 services → 5 sub-services)
- Plan 03-03: Export + Mini-Activity Statistics service splitting (6 min, 2 services → 5 sub-services)
- Plan 03-04: Division + Points Config service splitting (6 min, 2 services → 5 sub-services, Phase 3 complete)
- Plan 04-01: Permission consolidation (2 min, isAdmin() consolidated, isFinesManager() added, Phase 2 validation verified)
- Plan 04-02: Rate limiting middleware (2 min, shelf_limiter for auth/mutation/export endpoints, Phase 4 complete)
- Plan 05-01: Test detail widget extraction (234 min, test_detail_screen 590→211 LOC, 3 new widget files)
- Plan 05-02: Export & activity detail widget extraction (3 min, export_screen 470→219 LOC, activity_detail_screen 456→178 LOC, 3 new widget files)
- Plan 05-03: Mini-activity widget extraction (5 min, mini_activity_detail_content 436→307 LOC, stats_widgets→barrel, 5 new widget files)
- Plan 06-01: Export and statistics service tests (5 min, mocktail setup, 54 tests covering all export types + statistics edge cases)
- Plan 06-02: Tournament bracket and fine service tests (6 min, 39 tests covering bracket generation 2-16 teams + payment reconciliation)
- Plan 06-03: Export and tournament screen widget tests (19 min, 14 tests covering admin/non-admin rendering, async states, Phase 6 complete)
- Trend: Phase 6 complete — comprehensive service and widget testing with mocktail, 107 total tests across backend services and frontend screens
- Plan 07-01: Backend handler auth and error message consistency (3 min, standardized ~52 single-line auth returns to multi-line, verified Norwegian error messages)
- Plan 07-03: Frontend user feedback migration (11 min, migrated all 33 files from raw ScaffoldMessenger to ErrorDisplayService, -155 LOC, automated Python script for batch patterns)
- Plan 07-04: AppSpacing constants and EmptyStateWidget standardization (6 min, added 8px grid constants, replaced custom empty states in 5 screens, -39 net LOC)
- Trend: Phase 7 complete — code consistency patterns established across backend and frontend, -194 net LOC through standardization
- Plan 08-01: Push notification foundation services (10 min, installed flutter_local_notifications + retry + flutter_secure_storage, Firebase initialization with graceful failure, NotificationLocalDataSource for secure token persistence, ForegroundNotificationService for local notifications, Firebase config deferred by user)

*Updated 2026-02-09 after plan 08-01 complete*
| Phase 08 P01 | 10 | 2 tasks | 6 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Refactoring without new features — keeps scope focused on quality improvements
- Norwegian for all UI text — consistent user experience for Norwegian sports teams
- Code/comments in English — follows Dart/Flutter conventions
- Equatable for all backend models — enables structural equality testing (01-01)
- Manual mock instead of code generation — Supabase incompatible with mockito, manual provides better control (01-01)
- Norwegian test data — realistic Norwegian names (16+16 combinations) for test factories (01-01)
- Equatable for all frontend models — enables roundtrip equality assertions (01-02)
- Deterministic test timestamps — use fixed UTC timestamps instead of DateTime.now() (01-02)
- Date-only fields use local DateTime in tests — toJson outputs date-only strings, fromJson parses to local (01-03)
- LeaderboardEntry optedOut key mismatch FIXED in Phase 2 — fromJson now reads 'opted_out' matching toJson (02-01)
- FormatException for parsing errors — aligns with Dart core library conventions (02-01)
- Dual-type DateTime helpers — handle both DateTime objects and ISO strings from Supabase (02-01)
- Database vs JSON layer separation — DB uses leaderboard_opt_out, API JSON uses opted_out (02-01)
- Python-based automated migration — regex transformation for large-scale refactoring (02-03, 02-04)
- Null-conditional casts are safe — patterns like `(value as num?)?.toDouble()` don't need migration (02-03)
- Enum conversions kept as-is — fromString methods already validate input (02-04)
- Internal service response casts preserved — service layer returns validated data (02-04)
- DateTime.parse replaced with tryParse — safe parsing for date strings in tournament handlers (02-04)
- Service splitting with barrel exports — split large services while maintaining import paths (03-01)
- Tournament service split into 4 sub-services — CRUD, Rounds, Matches, Bracket (03-01)
- Leaderboard service split into 3 sub-services — CRUD/forwarding, Category, Ranking (03-01)
- Fine service split into 3 sub-services — Rules, CRUD+Appeals+Payments, Summaries (03-02)
- Activity service split into 2 sub-services — CRUD+Generation, Query (03-02)
- Accept slight LOC overage for complex services — FineCrudService 402 LOC (target 320), ActivityQueryService 364 LOC (target 310) maintained cohesion over strict size limits (03-02)
- Export service split into 2 sub-services — Data exports (5 methods), Utility/CSV/Logging (03-03)
- Mini-Activity Statistics service split into 3 sub-services — Player stats, H2H+History+PointSources, Aggregation+Leaderboard (03-03)
- Stats aggregation composes from other services — Avoids duplication while maintaining separation (03-03)
- Division service split into 2 sub-services — Algorithms (divideTeams, 5 methods), Management (team CRUD, handicaps) (03-04)
- Points config split into 3 sub-services — CRUD+opt-out, Attendance points, Manual adjustments (03-04)
- Phase 3 complete: 8 services → 22 sub-services — All under 400 LOC, barrel exports maintain import paths, 268 tests pass (03-04)
- Consolidated admin check — isAdmin() uses only user_is_admin flag, removed backwards-compatible user_role check (04-01)
- Permission helper pattern — permission_helpers.dart for role-based access control (isFinesManager, isCoachOrAdmin) (04-01)
- Fine creation permission — _createFine enforces isFinesManager() after team membership check (04-01)
- Deferred team-context checks — fineId-based endpoints have TODO markers for future permission enforcement (requires teamId lookup) (04-01)
- Phase 2 validation verified — 347 safe parsing helper usages, all handler inputs validated before service layer (04-01)
- Rate limiting with shelf_limiter — auth endpoints (5 req/min), mutations (10/min), exports (1/min), global fallback (30/min) (04-02)
- Selective rate limiting — Read-heavy routes (teams, activities, stats) remain unlimited for legitimate usage (04-02)
- Middleware ordering pattern — Auth routes: rate limit first; protected routes: auth first, then rate limit (04-02)
- Phase 4 complete: Permission consolidation + rate limiting — Security foundation established, 268 tests pass (04-01, 04-02)
- [Phase 05-02]: Keep tightly coupled state methods (_performExport, _shareCsv) in screen for cohesion
- [Phase 05-02]: Extract ActivityDetailContent as single 286 LOC file - keeps response/attendance/mini-activity logic together
- [Phase 05-01]: Convert message_widgets.dart to barrel file - preserves existing imports without breaking changes
- [Phase 05-01]: Make private widgets public for better composition and independent testing
- [Phase 05-03]: Dialog helpers as standalone functions with explicit parameters - improves testability and makes dependencies clear
- [Phase 05-03]: Convert stats_widgets to barrel file - preserves existing imports while enabling focused widget files
- [Phase 05-03]: Group related widgets in same file - PlayerStatsCard + CompactStatsCard stay together for cohesion
- [Phase 06-01]: Use mocktail for service mocking - provides clean mock syntax without code generation
- [Phase 06-01]: Mock Database and SupabaseClient separately - allows precise control over query responses
- [Phase 06-01]: Explicit edge case testing for zero-division - prevents NaN/Infinity bugs in attendance calculations
- [Phase 06-02]: Mocktail counter pattern for unique IDs - ensures each mock call generates unique ID (roundCounter++, matchCounter++)
- [Phase 06-02]: Test round names as implementation generates them - verifies actual behavior not expected order (insert(0) reverses)
- [Phase 06-02]: Capture pattern for update data verification - clearer than any(named:) matchers in mocktail
- [Phase 06-02]: Multi-step partial payment test - demonstrates cumulative payment logic in single test (30kr → 40kr → 30kr = paid)
- [Phase 06-03]: Initialize Norwegian locale in widget tests - ExportHistoryTile uses DateFormat('d. MMM yyyy HH:mm', 'nb_NO') requiring locale init
- [Phase 06-03]: Override family providers at call site - exportHistoryProvider(teamId) needs per-argument override, cannot use setup methods
- [Phase 06-03]: Test loading state with pump() not pumpAndSettle() - catches CircularProgressIndicator before async completes
- [Phase 07-01]: Multi-line auth pattern standardized - all 32 backend handlers use consistent multi-line format for auth checks (userId null, team null, role checks)
- [Phase 07-01]: Norwegian error messages verified - all handler error responses use Norwegian text, zero exception details leaked to users
- [Phase 07-03]: Centralized feedback pattern enforced - all 33 frontend files use ErrorDisplayService.show* methods, zero raw ScaffoldMessenger/SnackBar
- [Phase 07-03]: Automated migration with Python - regex patterns covered 91% of use cases, manual fixes for 5 edge cases with conditional logic
- [Phase 07-03]: Code reduction through centralization - 287 lines of SnackBar boilerplate → 132 lines of service calls (-155 LOC, -54%)
- [Phase 07-04]: AppSpacing constants without migration - 8px grid constants defined, 300+ hard-coded values remain for incremental future migration (low risk)
- [Phase 07-04]: EmptyStateWidget standardization - replaced custom empty states (81 lines) with centralized widget (31 uses), consistent UX across features
- [Phase 08-01]: Firebase graceful initialization - Firebase.initializeApp() wrapped in try/catch, allows app to run without Firebase config files, FCM fails gracefully until configured
- [Phase 08-01]: Secure token storage with FlutterSecureStorage - more secure than SharedPreferences for FCM tokens, encrypted iOS keychain + Android keystore
- [Phase 08-01]: 24-hour token reregistration threshold - balances server load with token freshness via timestamp tracking
- [Phase 08-01]: Firebase configuration deferred - user skipped Task 2 checkpoint, code ready for Plans 08-02/08-03, Firebase config via flutterfire CLI can happen later

### Pending Todos

None.

### Blockers/Concerns

- 8 pre-existing frontend widget test failures (error state tests) — not caused by Phase 1 changes

## Session Continuity

Last session: 2026-02-09 (Plan 08-01 execution)
Stopped at: Completed 08-01-PLAN.md — Push notification foundation services installed, Firebase config deferred, ready for Plans 08-02 and 08-03
Resume file: None
Next: Plan 08-02 (Token retry and persistence logic)
