# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-08)

**Core value:** Koden skal være lett å forstå, endre, og utvide — uten å krasje på uventede data.
**Current focus:** Phase 3 - Backend Service Splitting (in progress)

## Current Position

Phase: 3 of 10 (Backend Service Splitting)
Plan: 1 of 4 (Tournament and Leaderboard services split)
Status: In progress
Last activity: 2026-02-09 — Plan 03-01 complete, split 2 largest services (tournament 758→4 services, leaderboard 702→3 services)

Progress: [████████░░] 50% (8 of 16 total plans across all phases)

## Performance Metrics

**Velocity:**
- Total plans completed: 8
- Average duration: ~18 minutes
- Total execution time: ~2.6 hours

**By Phase:**

| Phase | Plans | Total Time | Avg/Plan |
|-------|-------|------------|----------|
| 01    | 4/4   | ~3.5h      | ~50m     |
| 02    | 4/4   | ~21m       | ~5m      |
| 03    | 1/4   | ~7m        | ~7m      |

**Recent Trend:**
- Plan 01-01: Backend Equatable + test infra (30 min)
- Plan 01-02: Frontend Equatable + test factories (11 min)
- Plan 01-03: Backend roundtrip tests — 191 tests (9 min + orchestrator fixes)
- Plan 01-04: Frontend roundtrip tests — 148 tests (25 min across 2 agents)
- Plan 02-01: Safe parsing helpers + LeaderboardEntry fix (4 min)
- Plan 02-03: Backend service migration (7 min, Python script automation)
- Plan 02-04: Handler layer migration (10 min, 32 handlers, ~250 casts)
- Plan 03-01: Tournament + Leaderboard service splitting (7 min, 2 services → 7 sub-services)
- Trend: TDD execution very fast; automated migrations and refactorings consistently fast

*Updated 2026-02-09 after plan 03-01 complete*

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

### Pending Todos

None.

### Blockers/Concerns

- 8 pre-existing frontend widget test failures (error state tests) — not caused by Phase 1 changes

## Session Continuity

Last session: 2026-02-09 (Plan 03-01 execution)
Stopped at: Plan 03-01 complete — Tournament + Leaderboard services split, 268 tests passing
Resume file: None
Next: Plan 03-02 execution → /gsd:execute-plan 03-02
