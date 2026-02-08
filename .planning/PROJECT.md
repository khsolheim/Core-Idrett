# Core - Idrett: Refaktorering Runde 2

## What This Is

En systematisk refaktorering av hele Core - Idrett-appen (Flutter frontend + Dart backend). Målet er å gjøre koden vedlikeholdbar, robust, og konsistent — både i struktur, feilhåndtering, og brukeropplevelse. Alle brukersynlige tekster skal være på norsk.

## Core Value

Koden skal være lett å forstå, endre, og utvide — uten å krasje på uventede data.

## Requirements

### Validated

<!-- Eksisterende kapabiliteter som allerede fungerer. -->

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
- ✓ Auth middleware med requireAuth, response_helpers, auth_helpers — fase 1
- ✓ Service cleanup (fromRow→fromJson, DB-level filtering) — fase 2
- ✓ Backend file splitting (handlers, models, services) — fase 3, 7, 8, 9
- ✓ Frontend provider splitting og widget extraction — fase 4, 10, 21
- ✓ EmptyStateWidget, when2(), parseList() patterns — fase 5, 6, 12
- ✓ Chat dedup (shared message_widgets.dart) — fase 11
- ✓ Backend common helpers (getUserMap, getTeamMemberUserIds) — fase 13
- ✓ Auth & error consistency (401 vs 403, no $e in serverError) — fase 14
- ✓ Backend input validation (null checks, DateTime.tryParse) — fase 15
- ✓ N+1 query optimization — fase 16
- ✓ Service boundaries (DashboardService, collection_helpers) — fase 17
- ✓ Frontend error handling (ErrorDisplayService.showWarning) — fase 18
- ✓ Named routes (45 path-based→named) — fase 19
- ✓ Provider optimization (.select() on ref.watch) — fase 20
- ✓ Image caching (cached_network_image, ValueKey) — fase 22

### Active

<!-- Refaktoreringsarbeid for denne milepælen. -->

- [ ] Splitte store backend service-filer (700+ LOC: tournament, leaderboard, fine, activity, export)
- [ ] Splitte store frontend widget-filer (400+ LOC: message_widgets, test_detail, export, activity_detail, m.fl.)
- [ ] Erstatte usikre `as String`/`as int`/`as Map` casts med trygg validering i backend
- [ ] Legge til tester for export, turneringer, bøter, og statistikk
- [ ] Fikse admin-rolle dual-check (user_is_admin vs user_role)
- [ ] Implementere rate limiting på kritiske endpoints
- [ ] Fikse FCM token-håndtering (retry-logikk, persistent state)
- [ ] Fikse foreground push notification-visning
- [ ] Sikre konsistente mønstre i feilhåndtering, navngivning, og struktur overalt
- [ ] Sikre konsistent API-design (response format, statuskoder)
- [ ] Sikre konsistent UI (widgets, spacing, layout)
- [ ] Oversette alle gjenværende engelske frontend-tekster til norsk

### Out of Scope

- Nye features (offline support, audit logging, export-kryptering) — dette er ren refaktorering
- Database-migrasjoner eller skjemaendringer — kun applikasjonskode
- Ytelsesoptimalisering utover det som kommer naturlig av refaktoreringen
- Skaleringsarbeid (paginering, caching-strategier) — separat milestone

## Context

Core - Idrett er en norsk idrettslagsapp brukt av trenere, spillere og lagledere. Appen har vært gjennom 22 faser med refaktorering som ryddet opp i arkitektur, mønstre, og kodekvalitet. CONCERNS.md fra codebase-mappingen avdekket gjenværende teknisk gjeld som denne milepælen adresserer.

Kodebasen er ca. 30k+ linjer Dart fordelt på frontend og backend. Backend bruker Shelf-rammeverket med Handler→Service→Database-mønster. Frontend bruker Riverpod + Clean Architecture med feature-basert struktur.

Eksisterende mønstre som skal følges:
- Backend: `requireAuth` middleware, `response_helpers.dart`, `auth_helpers.dart`
- Frontend: `when2()`, `EmptyStateWidget`, `ErrorDisplayService.showWarning()`
- Filsplitting: barrel exports, `router.mount('/', subHandler.router.call)`

## Constraints

- **Tech stack**: Flutter 3.10+ / Dart 3.0+ — ingen rammeverksendringer
- **Bakoverkompatibilitet**: Ingen breaking changes i API — frontend og backend må fungere sammen under hele refaktoreringen
- **Språk**: Alle brukersynlige tekster på norsk; kode og kommentarer på engelsk
- **Eksisterende tester**: Alle eksisterende tester må fortsatt passere etter endringer

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Refaktorering uten nye features | Holde scope fokusert; nye features i separat milestone | — Pending |
| Norsk for all UI-tekst | Appen er for norske idrettslag; konsistent språk | — Pending |
| Kode/kommentarer på engelsk | Dart/Flutter-konvensjon; lettere å søke i | — Pending |

---
*Last updated: 2026-02-08 after initialization*
