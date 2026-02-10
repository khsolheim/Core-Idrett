# Core - Idrett

## What This Is

En norsk idrettslagsapp (Flutter frontend + Dart backend + Supabase) for trenere, spillere og lagledere. Appen håndterer lagadministrasjon, aktiviteter, turneringer, bøtesystem, chat, statistikk, dokumenter, og push-notifikasjoner. Koden er systematisk refaktorert gjennom to runder — arkitekturen er nå robust, konsistent, og godt testet.

## Core Value

Koden skal være lett å forstå, endre, og utvide — uten å krasje på uventede data.

## Requirements

### Validated

- ✓ Team management med roller (admin/coach/fine_boss/player) — existing
- ✓ Aktiviteter med recurring schedules og attendance tracking — existing
- ✓ Mini-aktiviteter med poeng/scoring — existing
- ✓ Turneringer med bracket-generering — existing
- ✓ Statistikk, leaderboards, og sesonger — existing
- ✓ Bøtesystem med regler og betalingssporing — existing
- ✓ Chat (team + direktemeldinger) med reply/edit/delete — existing
- ✓ Dokumentopplasting per lag — existing
- ✓ Fysiske tester — existing
- ✓ Achievement-system — existing
- ✓ Fraværsrapportering — existing
- ✓ Dataeksport — existing
- ✓ Push-notifikasjoner — existing
- ✓ Auth middleware med requireAuth, response_helpers, auth_helpers — R1 fase 1
- ✓ Service cleanup (fromRow→fromJson, DB-level filtering) — R1 fase 2
- ✓ Backend file splitting (handlers, models, services) — R1 fase 3, 7, 8, 9
- ✓ Frontend provider splitting og widget extraction — R1 fase 4, 10, 21
- ✓ EmptyStateWidget, when2(), parseList() patterns — R1 fase 5, 6, 12
- ✓ Chat dedup (shared message_widgets.dart) — R1 fase 11
- ✓ Backend common helpers (getUserMap, getTeamMemberUserIds) — R1 fase 13
- ✓ Auth & error consistency (401 vs 403, no $e in serverError) — R1 fase 14
- ✓ Backend input validation (null checks, DateTime.tryParse) — R1 fase 15
- ✓ N+1 query optimization — R1 fase 16
- ✓ Service boundaries (DashboardService, collection_helpers) — R1 fase 17
- ✓ Frontend error handling (ErrorDisplayService.showWarning) — R1 fase 18
- ✓ Named routes (45 path-based→named) — R1 fase 19
- ✓ Provider optimization (.select() on ref.watch) — R1 fase 20
- ✓ Image caching (cached_network_image, ValueKey) — R1 fase 22
- ✓ Equatable models med roundtrip-tester (339 tester) — v1.0 Phase 1
- ✓ Trygg type-parsing med validerte hjelpefunksjoner (347 brukssteder) — v1.0 Phase 2
- ✓ Backend service-splitting (8 store → 22 fokuserte sub-services) — v1.0 Phase 3
- ✓ Rate limiting og permission consolidation — v1.0 Phase 4
- ✓ Frontend widget extraction (8 store filer splittet) — v1.0 Phase 5
- ✓ Feature-tester (export, turneringer, bøter, statistikk) — v1.0 Phase 6
- ✓ Konsistente mønstre (auth, feilmeldinger, SnackBar, spacing) — v1.0 Phase 7
- ✓ FCM push notification hardening (retry, persistence, foreground) — v1.0 Phase 8
- ✓ Komplett norsk oversettelse — zero English i UI — v1.0 Phase 9
- ✓ Final quality pass — 542 tester grønne, clean analyse — v1.0 Phase 10

### Active — v1.1 CI/CD + Kvalitetsvern

- Pre-commit hooks for format + analyze quality gates (HOOKS-01..03)
- GitHub Actions CI for backend + frontend on PR (CI-01..04)
- Codecov coverage reporting with trend visibility (COV-01..03)
- Backend Docker container with multi-stage build (DOCK-01..03)
- Cloud Run deployment with Secret Manager (DEPLOY-01..03)
- Flutter build pipeline for Android, Web, iOS (BUILD-01..04)

Full requirements: `.planning/REQUIREMENTS.md`

### Out of Scope

- Nye features (offline support, audit logging, export-kryptering)
- Database-migrasjoner eller skjemaendringer — kun applikasjonskode
- Code generation (freezed, json_serializable, riverpod_generator)
- Skaleringsarbeid (paginering, caching-strategier) — separat milestone
- Staging environment — production only for now

## Current Milestone: v1.1 CI/CD + Kvalitetsvern

**Goal:** Beskytt kodekvaliteten med automatiserte sjekker og etabler full deployment pipeline.

**Starting state:** GitHub repo, zero CI, no Docker, no GCP, not deployed.
**Target state:** PR quality gates, coverage reporting, backend on Cloud Run, Flutter builds for Android/iOS/Web.

Phases 11-14, ~11 plans. See `.planning/ROADMAP.md` for details.

## Context

Core - Idrett er en norsk idrettslagsapp med 75k LOC Dart (47k frontend + 28k backend). Appen har vært gjennom R1 (22 faser) og R2 (10 faser, v1.0) med refaktorering. Kodebasen er nå robust med:

- **542 tester** (268 backend + 274 frontend), alle grønne
- **22 fokuserte sub-services** under 400 LOC med barrel exports
- **Konsistente mønstre** for auth, feilhåndtering, og UI
- **Validert type-parsing** — ingen usikre casts i kodebasen
- **Rate limiting** på auth, mutations, og export endpoints
- **FCM push-notifikasjoner** med retry, persistent tokens, og foreground display
- **Komplett norsk UI** — zero engelske strenger i brukergrensesnittet

Backend bruker Shelf med Handler→Service→Database-mønster. Frontend bruker Riverpod + Clean Architecture med feature-basert struktur.

Mønstre som følges:
- Backend: `requireAuth` middleware, `response_helpers.dart`, `auth_helpers.dart`, `permission_helpers.dart`
- Frontend: `when2()`, `EmptyStateWidget`, `ErrorDisplayService.showWarning()`, `AppSpacing` constants
- Filsplitting: barrel exports, `router.mount('/', subHandler.router.call)`

## Constraints

- **Tech stack**: Flutter 3.10+ / Dart 3.0+ — ingen rammeverksendringer
- **Bakoverkompatibilitet**: Ingen breaking changes i API
- **Språk**: Alle brukersynlige tekster på norsk; kode og kommentarer på engelsk
- **Tester**: 542 tester må fortsatt passere etter endringer

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Refaktorering uten nye features | Holde scope fokusert; nye features i separat milestone | ✓ Good — scope stayed clean |
| Norsk for all UI-tekst | Appen er for norske idrettslag; konsistent språk | ✓ Good — 100% norsk UI |
| Kode/kommentarer på engelsk | Dart/Flutter-konvensjon; lettere å søke i | ✓ Good — consistent |
| Equatable for all models | Structural equality for testing + value comparison | ✓ Good — enabled 339 roundtrip tests |
| Manual mocks over code generation | Supabase incompatible with mockito; better control | ✓ Good — 542 tests passing |
| Safe parsing helpers over raw casts | Fail safely with error messages instead of crashing | ✓ Good — 347 usages, zero unsafe casts |
| Service splitting with barrel exports | Split services while maintaining import paths | ✓ Good — 22 sub-services, zero broken imports |
| Rate limiting with shelf_limiter | Auth 5/min, mutations 10/min, exports 1/min | ✓ Good — production-ready |
| FCM retry with exponential backoff | 8 attempts, selective retry on transient errors | ✓ Good — reliable push delivery |
| flutter_localizations for system dialogs | MaterialApp with nb_NO locale for native Norwegian | ✓ Good — DatePicker etc. in Norwegian |
| Separate CI workflows per stack | Independent triggers, clearer logs | v1.1 — Phase 11 |
| Codecov for coverage reporting | Free, good PR comments, trend visibility | v1.1 — Phase 11 |
| `.githooks/` over husky/npm | No extra dependencies, pure shell | v1.1 — Phase 12 |
| `dart compile exe` in Docker | Smaller container, faster Cloud Run startup | v1.1 — Phase 13 |
| Single production environment | Staging adds complexity without enough value yet | v1.1 — Phase 13 |
| Firebase Hosting for web | Free tier, SPA routing, same GCP project | v1.1 — Phase 14 |

---
*Last updated: 2026-02-10 after v1.1 milestone initialization*
