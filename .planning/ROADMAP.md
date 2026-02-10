# Roadmap: Core - Idrett

## Milestones

- ✅ **v1.0 Refactoring R2** — Phases 1-10 (shipped 2026-02-10)
- 🔄 **v1.1 CI/CD + Kvalitetsvern** — Phases 11-14 (active)

## Phases

<details>
<summary>✅ v1.0 Refactoring R2 (Phases 1-10) — SHIPPED 2026-02-10</summary>

- [x] Phase 1: Test Infrastructure (4/4 plans) — 2026-02-09
- [x] Phase 2: Type Safety & Validation (4/4 plans) — 2026-02-09
- [x] Phase 3: Backend Service Splitting (4/4 plans) — 2026-02-09
- [x] Phase 4: Backend Security & Input Validation (2/2 plans) — 2026-02-09
- [x] Phase 5: Frontend Widget Extraction (4/4 plans) — 2026-02-09
- [x] Phase 6: Feature Test Coverage (3/3 plans) — 2026-02-09
- [x] Phase 7: Code Consistency Patterns (4/4 plans) — 2026-02-09
- [x] Phase 8: Push Notification Hardening (3/3 plans) — 2026-02-10
- [x] Phase 9: Translation Completion (3/3 plans) — 2026-02-10
- [x] Phase 10: Final Quality Pass (3/3 plans) — 2026-02-10

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

### v1.1 CI/CD + Kvalitetsvern (Phases 11-14)

**Goal:** Beskytt kodekvaliteten med automatiserte sjekker og etabler full deployment pipeline.

#### Phase 11: CI Pipeline + Coverage
**Goal:** Automated testing and analysis on every PR with coverage visibility.

| Plan | Deliverable | Requirements |
|------|-------------|--------------|
| 11-01 | Backend CI workflow (`dart analyze` + `dart test --coverage`) | CI-01, COV-01 |
| 11-02 | Frontend CI workflow (`flutter analyze` + `flutter test --coverage`) | CI-02, COV-02 |
| 11-03 | Coverage upload (Codecov), branch protection, caching | CI-03, CI-04, COV-03 |

Key decisions:
- Separate workflows per stack (independent triggers, clearer logs)
- Ubuntu runners (sufficient for Dart/Flutter tests)
- Codecov for coverage (free, good PR comments)
- 5 known analyze warnings: filter with documented allowlist

- [ ] Phase 11: CI Pipeline + Coverage (0/3 plans) — **NEXT**

#### Phase 12: Pre-commit Hooks
**Goal:** Catch formatting and analysis issues locally before push.

| Plan | Deliverable | Requirements |
|------|-------------|--------------|
| 12-01 | Git hooks for format + analyze (backend + frontend) | HOOKS-02, HOOKS-03 |
| 12-02 | Setup script + team documentation | HOOKS-01 |

Key decisions:
- `.githooks/` directory (no npm/husky dependency, pure shell)
- Format check with `--set-exit-if-changed` (warn, don't auto-format)
- Skip `flutter test` in hooks (let CI handle that)

- [ ] Phase 12: Pre-commit Hooks (0/2 plans)

#### Phase 13: Backend Docker + Cloud Run
**Goal:** Containerize backend and deploy to GCP Cloud Run.

| Plan | Deliverable | Requirements |
|------|-------------|--------------|
| 13-01 | Dockerfile (multi-stage) + `.dockerignore` + health endpoint | DOCK-01, DOCK-02, DOCK-03 |
| 13-02 | GCP setup guide + Secret Manager configuration | DEPLOY-02 |
| 13-03 | CI deploy workflow (build → Artifact Registry → Cloud Run) | DEPLOY-01, DEPLOY-03 |

Key decisions:
- `dart compile exe` for native binary (smaller container, faster startup)
- Single environment (production) — staging adds complexity without enough value yet
- GCP Secret Manager for SUPABASE_SERVICE_KEY and JWT_SECRET
- Deploy on merge to main (not on PR)
- Manual steps: GCP project setup, billing, Workload Identity Federation

- [ ] Phase 13: Backend Docker + Cloud Run (0/3 plans)

#### Phase 14: Flutter Build Pipeline + Distribution
**Goal:** Automated Flutter builds for all platforms with distribution to testers.

| Plan | Deliverable | Requirements |
|------|-------------|--------------|
| 14-01 | Android signed build (APK + AAB) in GitHub Actions | BUILD-01, BUILD-04 |
| 14-02 | Web build + Firebase Hosting deployment | BUILD-02 |
| 14-03 | iOS build documentation + distribution setup | BUILD-03 |

Key decisions:
- Android keystore encrypted in GitHub Secrets (base64 → decode in CI)
- Version from pubspec.yaml, build number from `$GITHUB_RUN_NUMBER`
- Firebase Hosting for web (free tier, SPA routing, same GCP project)
- iOS: Document manual Xcode Archive + TestFlight (macOS runners ~10x cost)
- Artifacts uploaded to GitHub Releases (APK) for easy tester download

- [ ] Phase 14: Flutter Build Pipeline + Distribution (0/3 plans)

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Test Infrastructure | v1.0 | 4/4 | ✓ Complete | 2026-02-09 |
| 2. Type Safety & Validation | v1.0 | 4/4 | ✓ Complete | 2026-02-09 |
| 3. Backend Service Splitting | v1.0 | 4/4 | ✓ Complete | 2026-02-09 |
| 4. Backend Security & Input Validation | v1.0 | 2/2 | ✓ Complete | 2026-02-09 |
| 5. Frontend Widget Extraction | v1.0 | 4/4 | ✓ Complete | 2026-02-09 |
| 6. Feature Test Coverage | v1.0 | 3/3 | ✓ Complete | 2026-02-09 |
| 7. Code Consistency Patterns | v1.0 | 4/4 | ✓ Complete | 2026-02-09 |
| 8. Push Notification Hardening | v1.0 | 3/3 | ✓ Complete | 2026-02-10 |
| 9. Translation Completion | v1.0 | 3/3 | ✓ Complete | 2026-02-10 |
| 10. Final Quality Pass | v1.0 | 3/3 | ✓ Complete | 2026-02-10 |
| 11. CI Pipeline + Coverage | v1.1 | 0/3 | ⬜ Next | — |
| 12. Pre-commit Hooks | v1.1 | 0/2 | ⬜ Pending | — |
| 13. Backend Docker + Cloud Run | v1.1 | 0/3 | ⬜ Pending | — |
| 14. Flutter Build Pipeline | v1.1 | 0/3 | ⬜ Pending | — |

---
*Roadmap created: 2026-02-08*
*Last updated: 2026-02-10 (v1.1 milestone initialized)*
