# Phase 13: Backend Docker + Cloud Run

## Goal

Containerize backend and deploy to GCP Cloud Run.

## Requirements

- **DOCK-01**: Backend builds as Docker container via multi-stage build
- **DOCK-02**: Container accepts configuration via environment variables
- **DOCK-03**: Health check endpoint exists at `/health`
- **DEPLOY-01**: Backend auto-deploys to Cloud Run on merge to main
- **DEPLOY-02**: Secrets managed via GCP Secret Manager (not in repo)
- **DEPLOY-03**: Deployment status visible in GitHub

## Plans

| Plan | Deliverable | Requirements |
|------|-------------|--------------|
| 13-01 | Dockerfile (multi-stage) + `.dockerignore` + health endpoint | DOCK-01, DOCK-02, DOCK-03 |
| 13-02 | GCP setup guide + Secret Manager configuration | DEPLOY-02 |
| 13-03 | CI deploy workflow (build → Artifact Registry → Cloud Run) | DEPLOY-01, DEPLOY-03 |

## Key Decisions

- **`dart compile exe`**: Native binary for smaller container (~30MB vs ~200MB with SDK), faster startup
- **Single environment**: Production only — staging adds complexity, insufficient value at this stage
- **GCP Secret Manager**: For SUPABASE_SERVICE_KEY and JWT_SECRET — never in repo
- **Deploy on merge to main**: Not on PR — PRs only run tests
- **Workload Identity Federation**: GitHub Actions authenticates to GCP without long-lived service account keys

## Files to Create

- `backend/Dockerfile` (multi-stage: dart SDK → compile → minimal runtime)
- `backend/.dockerignore`
- `backend/lib/api/health_handler.dart`
- `.github/workflows/deploy-backend.yml`
- `docs/gcp-setup.md`

## Manual Steps Required (User)

1. Create GCP project and enable billing
2. Enable Cloud Run + Artifact Registry + Secret Manager APIs
3. Create secrets in Secret Manager (SUPABASE_URL, SUPABASE_SERVICE_KEY, JWT_SECRET)
4. Set up Workload Identity Federation for GitHub Actions → GCP auth
5. Configure GitHub repository secrets (GCP_PROJECT_ID, WIF_PROVIDER, WIF_SERVICE_ACCOUNT)

## Dependencies

- Phase 11 (CI) must exist first — deploy workflow builds on CI patterns
- Backend must have a health endpoint before containerization

## Context from v1.0

- Backend runs with `dart run bin/server.dart` (requires env vars)
- Shelf framework listens on configurable port (default 8080)
- Env vars: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_KEY, JWT_SECRET
- Server fails fast at startup if JWT_SECRET is missing
