---
phase: 11-ci-pipeline-coverage
plan: 02
subsystem: ci-pipeline
tags: [ci, github-actions, flutter, testing, coverage, automation]
dependency_graph:
  requires:
    - pubspec.yaml (Flutter dependencies)
  provides:
    - .github/workflows/frontend.yml (Frontend CI workflow)
  affects:
    - app/** (triggers on changes to frontend code)
tech_stack:
  added:
    - GitHub Actions workflow for Flutter
    - codecov/codecov-action@v5
    - subosito/flutter-action@v2
  patterns:
    - Path-based workflow triggers
    - Built-in dependency caching
    - LCOV coverage generation
key_files:
  created:
    - .github/workflows/frontend.yml (47 lines)
  modified: []
decisions:
  - No Flutter version pinning - use latest stable (project supports 3.10+, reduces maintenance)
  - Use --no-fatal-warnings to allow 5 known info-level deprecation warnings
  - fail_ci_if_error: false on Codecov upload (coverage is informational, don't block CI if Codecov is down)
metrics:
  duration: 1m 19s
  tasks_completed: 1
  files_created: 1
  commits: 1
  completed_date: 2026-02-10
---

# Phase 11 Plan 02: Frontend CI Workflow Summary

**One-liner:** GitHub Actions workflow that runs Flutter analyze and test with LCOV coverage on PRs touching app/

## What Was Built

Created `.github/workflows/frontend.yml` - a GitHub Actions CI workflow for the Flutter frontend that:
- Triggers automatically on push/PR to main when `app/**` or the workflow file itself changes
- Runs static analysis with `flutter analyze --no-fatal-warnings` to allow 5 pre-existing info-level deprecation warnings
- Executes tests with coverage using `flutter test --coverage` (generates LCOV natively)
- Uploads coverage data to Codecov with `frontend` flag for tracking trends
- Uses `subosito/flutter-action@v2` with built-in pub dependency caching for faster runs

## Deviations from Plan

None - plan executed exactly as written.

## Key Implementation Details

**Workflow Configuration:**
- **Name:** Frontend CI
- **Triggers:** `push` and `pull_request` to `main` branch with path filters: `app/**` and `.github/workflows/frontend.yml`
- **Job:** Single `test` job on `ubuntu-latest`

**Steps:**
1. Checkout code with `actions/checkout@v4`
2. Set up Flutter with `subosito/flutter-action@v2`:
   - `channel: 'stable'` (no version pin - uses latest stable)
   - `cache: true` (enables built-in pub caching)
3. Install dependencies: `flutter pub get` in `./app`
4. Analyze code: `flutter analyze --no-fatal-warnings` in `./app`
5. Run tests with coverage: `flutter test --coverage` in `./app`
6. Upload coverage: `codecov/codecov-action@v5` with `./app/coverage/lcov.info`, `flags: frontend`, `fail_ci_if_error: false`

**Key Design Decisions:**

1. **No Flutter version pinning:** The plan explicitly stated not to pin `flutter-version`. The project's `pubspec.yaml` has `sdk: ^3.10.4`, which is well behind current stable (3.38.x as of 2026). Using latest stable reduces maintenance burden without compatibility risk.

2. **--no-fatal-warnings flag:** Per user decision (documented in research), the project has 5 known info-level warnings (SharePlus, RadioGroup, use_build_context_synchronously). Using `--no-fatal-warnings` allows these through without blocking CI. The alternative (configuring `analysis_options.yaml` to downgrade specific warnings) was explicitly rejected in favor of simplicity.

3. **fail_ci_if_error: false on Codecov:** Coverage reporting is informational. If Codecov service is down, the CI should still pass. This prevents external service outages from blocking PRs.

4. **Built-in caching vs manual actions/cache:** The plan explicitly called out using `cache: true` with `flutter-action@v2` instead of manual `actions/cache`. This leverages optimized cache keys maintained by the action maintainers.

5. **LCOV generation:** Flutter's `test --coverage` command natively outputs `coverage/lcov.info` (unlike Dart backend which outputs JSON). No conversion step is needed.

## Files Created/Modified

**Created:**
- `.github/workflows/frontend.yml` (47 lines) - Complete frontend CI workflow

**Modified:** None

## Testing & Verification

**YAML validation:**
```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/frontend.yml'))"
# Output: YAML syntax is valid
```

**Verification checklist (all passed):**
- ✓ Uses actions/checkout@v4
- ✓ Uses subosito/flutter-action@v2
- ✓ Has cache: true
- ✓ Uses stable channel
- ✓ Runs flutter pub get
- ✓ Runs analyze with --no-fatal-warnings
- ✓ Runs tests with --coverage
- ✓ Uses codecov-action@v5
- ✓ Has fail_ci_if_error: false
- ✓ Has flags: frontend
- ✓ Has app/** path filter

**Workflow will trigger on:**
- Any push to `main` that modifies files in `app/` directory
- Any pull request to `main` that modifies files in `app/` directory
- Changes to `.github/workflows/frontend.yml` itself

**Expected behavior on first run:**
1. Workflow will install Flutter stable (latest version)
2. Cache pub dependencies for subsequent runs
3. Run analyze - will complete successfully with 5 info-level warnings (allowed)
4. Run tests - will execute all tests in `app/test/` and generate coverage
5. Upload coverage to Codecov - requires `CODECOV_TOKEN` secret to be configured

**Note:** The workflow will fail until `CODECOV_TOKEN` is added to GitHub Secrets, but `fail_ci_if_error: false` means this won't block PR merges. The token setup is a manual user step documented as a blocker in STATE.md.

## Next Steps

For this workflow to be fully operational:
1. User must create Codecov account and link GitHub repository
2. User must add `CODECOV_TOKEN` to GitHub repository secrets
3. Consider setting up branch protection rules to require "Frontend CI" status check before merge

These are one-time setup steps outside the scope of this plan.

## Commits

| Task | Description | Commit | Files |
|------|-------------|--------|-------|
| 1 | Create frontend CI workflow | 7b989ea | .github/workflows/frontend.yml |

## Self-Check: PASSED

**Files exist:**
```bash
[ -f ".github/workflows/frontend.yml" ] && echo "FOUND: .github/workflows/frontend.yml"
# FOUND: .github/workflows/frontend.yml
```

**Commits exist:**
```bash
git log --oneline --all | grep -q "7b989ea"
# FOUND: 7b989ea
```

All claimed artifacts verified.
