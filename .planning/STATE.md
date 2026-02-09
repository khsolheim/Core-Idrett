# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-08)

**Core value:** Koden skal være lett å forstå, endre, og utvide — uten å krasje på uventede data.
**Current focus:** Phase 5 - Frontend Widget Extraction (in progress)

## Current Position

Phase: 5 of 10 (Frontend Widget Extraction)
Plan: 2 of 4 (export & activity detail screens split)
Status: In Progress
Last activity: 2026-02-09 — Plan 05-02 complete, split export_screen (470→219 LOC) and activity_detail_screen (456→178 LOC)

Progress: [█████████░] 87% (14 of 16 total plans across all phases)

## Performance Metrics

**Velocity:**
- Total plans completed: 14
- Average duration: ~10 minutes
- Total execution time: ~3 hours

**By Phase:**

| Phase | Plans | Total Time | Avg/Plan |
|-------|-------|------------|----------|
| 01    | 4/4   | ~3.5h      | ~50m     |
| 02    | 4/4   | ~21m       | ~5m      |
| 03    | 4/4   | ~25m       | ~6.25m   |
| 04    | 2/2   | ~4m        | ~2m      |
| 05    | 2/4   | ~3m        | ~3m      |

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
- Plan 05-02: Export & activity detail widget extraction (3 min, export_screen 470→219 LOC, activity_detail_screen 456→178 LOC, 4 new widget files)
- Trend: Phase 5 widget extraction fast (~3 min), clean splits maintaining functionality

*Updated 2026-02-09 after plan 05-02 complete*

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

### Pending Todos

None.

### Blockers/Concerns

- 8 pre-existing frontend widget test failures (error state tests) — not caused by Phase 1 changes

## Session Continuity

Last session: 2026-02-09 (Plan 05-02 execution)
Stopped at: Completed 05-02-PLAN.md — export_screen and activity_detail_screen split complete
Resume file: None
Next: Phase 5 Plan 03 (tournament and statistics screen splitting)
