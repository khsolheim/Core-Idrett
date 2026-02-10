# Requirements: Core - Idrett v1.1 CI/CD + Kvalitetsvern

**Defined:** 2026-02-10
**Core Value:** Beskytt kodekvaliteten med automatiserte sjekker og etabler full deployment pipeline.

## v1.1 Requirements

Requirements for the CI/CD milestone. Each maps to roadmap phases 11-14.

### Pre-commit Quality Gates (HOOKS)

- [ ] **HOOKS-01**: Developer can install pre-commit hooks with a single setup command → Phase 12
- [ ] **HOOKS-02**: Pre-commit hook blocks commits with formatting issues → Phase 12
- [ ] **HOOKS-03**: Pre-commit hook blocks commits with new analysis errors (5 known warnings allowed) → Phase 12

### Continuous Integration (CI)

- [ ] **CI-01**: Backend tests and analysis run automatically on PR → Phase 11
- [ ] **CI-02**: Frontend tests and analysis run automatically on PR → Phase 11
- [ ] **CI-03**: PR merge is blocked when CI checks fail (branch protection) → Phase 11
- [ ] **CI-04**: CI uses dependency caching for fast builds → Phase 11

### Coverage Reporting (COV)

- [ ] **COV-01**: Backend test coverage is reported on each PR → Phase 11
- [ ] **COV-02**: Frontend test coverage is reported on each PR → Phase 11
- [ ] **COV-03**: Coverage trend is visible over time (badge or dashboard) → Phase 11

### Backend Containerization (DOCK)

- [ ] **DOCK-01**: Backend builds as Docker container via multi-stage build → Phase 13
- [ ] **DOCK-02**: Container accepts configuration via environment variables → Phase 13
- [ ] **DOCK-03**: Health check endpoint exists at `/health` → Phase 13

### Cloud Deployment (DEPLOY)

- [ ] **DEPLOY-01**: Backend auto-deploys to Cloud Run on merge to main → Phase 13
- [ ] **DEPLOY-02**: Secrets managed via GCP Secret Manager (not in repo) → Phase 13
- [ ] **DEPLOY-03**: Deployment status visible in GitHub → Phase 13

### Flutter Build Pipeline (BUILD)

- [ ] **BUILD-01**: Android APK/AAB builds automatically in CI (signed) → Phase 14
- [ ] **BUILD-02**: Web app builds and deploys to Firebase Hosting → Phase 14
- [ ] **BUILD-03**: iOS build process is documented (Codemagic or manual) → Phase 14
- [ ] **BUILD-04**: Build version auto-increments from git → Phase 14

## Traceability Matrix

| Requirement | Phase | Plan | Status |
|-------------|-------|------|--------|
| HOOKS-01 | 12 | 12-02 | Pending |
| HOOKS-02 | 12 | 12-01 | Pending |
| HOOKS-03 | 12 | 12-01 | Pending |
| CI-01 | 11 | 11-01 | Pending |
| CI-02 | 11 | 11-02 | Pending |
| CI-03 | 11 | 11-03 | Pending |
| CI-04 | 11 | 11-03 | Pending |
| COV-01 | 11 | 11-01 | Pending |
| COV-02 | 11 | 11-02 | Pending |
| COV-03 | 11 | 11-03 | Pending |
| DOCK-01 | 13 | 13-01 | Pending |
| DOCK-02 | 13 | 13-01 | Pending |
| DOCK-03 | 13 | 13-01 | Pending |
| DEPLOY-01 | 13 | 13-03 | Pending |
| DEPLOY-02 | 13 | 13-02 | Pending |
| DEPLOY-03 | 13 | 13-03 | Pending |
| BUILD-01 | 14 | 14-01 | Pending |
| BUILD-02 | 14 | 14-02 | Pending |
| BUILD-03 | 14 | 14-03 | Pending |
| BUILD-04 | 14 | 14-01 | Pending |

---
*Created: 2026-02-10*
