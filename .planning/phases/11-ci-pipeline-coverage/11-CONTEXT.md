# Phase 11: CI Pipeline + Coverage

## Goal

Automated testing and analysis on every PR with coverage visibility.

## Requirements

- **CI-01**: Backend tests and analysis run automatically on PR
- **CI-02**: Frontend tests and analysis run automatically on PR
- **CI-03**: PR merge is blocked when CI checks fail (branch protection)
- **CI-04**: CI uses dependency caching for fast builds
- **COV-01**: Backend test coverage is reported on each PR
- **COV-02**: Frontend test coverage is reported on each PR
- **COV-03**: Coverage trend is visible over time (badge or dashboard)

## Plans

| Plan | Deliverable | Requirements |
|------|-------------|--------------|
| 11-01 | Backend CI workflow (`dart analyze` + `dart test --coverage`) | CI-01, COV-01 |
| 11-02 | Frontend CI workflow (`flutter analyze` + `flutter test --coverage`) | CI-02, COV-02 |
| 11-03 | Coverage upload (Codecov), branch protection, caching | CI-03, CI-04, COV-03 |

## Key Decisions

- **Separate workflows**: Backend and frontend have independent triggers — a backend-only change shouldn't trigger Flutter tests
- **Ubuntu runners**: Sufficient for Dart/Flutter tests (no macOS needed until iOS builds in Phase 14)
- **Codecov**: Free for public/private repos, good PR comment integration, badge support
- **5 known warnings**: `dart analyze` and `flutter analyze` have 5 pre-existing info-level warnings (deprecated SharePlus, RadioGroup, use_build_context_synchronously) — these must not block CI

## Files to Create

- `.github/workflows/backend.yml`
- `.github/workflows/frontend.yml`
- Codecov config + branch protection via `gh api`

## Dependencies

None — this is the first phase of v1.1.

## Context from v1.0

- 268 backend tests, 274 frontend tests (542 total), all passing
- Backend: `dart test` from `/backend`, `dart analyze` from `/backend`
- Frontend: `flutter test` from `/app`, `flutter analyze` from `/app`
- 5 pre-existing deprecation warnings are info-level, not errors
