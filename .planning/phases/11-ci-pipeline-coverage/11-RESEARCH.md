# Phase 11: CI Pipeline + Coverage - Research

**Researched:** 2026-02-10
**Domain:** GitHub Actions CI/CD for Dart backend and Flutter frontend with Codecov coverage reporting
**Confidence:** HIGH

## Summary

This phase implements automated testing, analysis, and coverage reporting using GitHub Actions workflows. The standard approach uses separate workflows for backend (Dart) and frontend (Flutter) to enable independent triggering based on file paths, with Codecov for coverage visualization and trend tracking.

The research confirms that the tech stack is mature and well-documented. GitHub provides official `dart-lang/setup-dart@v1` and community-maintained `subosito/flutter-action@v2` actions with built-in dependency caching. Codecov v5 now supports token-free uploads for public repositories and provides comprehensive PR commenting and badge generation. The main complexity involves handling pre-existing analyzer warnings without blocking CI and configuring path-based triggers to avoid unnecessary workflow runs.

**Primary recommendation:** Use separate backend.yml and frontend.yml workflows with path-based triggers (`paths: ['backend/**']`), official setup actions with caching enabled, `--no-fatal-warnings` flag to allow info-level warnings, and Codecov v5 for coverage reporting with auto targets for baseline comparison.

## Standard Stack

### Core
| Library/Action | Version | Purpose | Why Standard |
|----------------|---------|---------|--------------|
| `dart-lang/setup-dart` | v1 (v1.7.1) | Dart SDK setup in GitHub Actions | Official action from Dart team, supports SDK channels and caching |
| `subosito/flutter-action` | v2 | Flutter SDK setup in GitHub Actions | Most popular community action (2.8k+ stars), supports pub caching |
| `codecov/codecov-action` | v5 | Coverage upload and reporting | Official Codecov action, v5 uses CLI wrapper for faster updates |
| `actions/checkout` | v4 | Clone repository code | GitHub official, required prerequisite for all workflows |

### Supporting
| Library/Action | Version | Purpose | When to Use |
|----------------|---------|---------|-------------|
| `actions/cache` | v4 | Manual dependency caching | If not using built-in caching from setup actions |
| `gh` CLI | pre-installed | Branch protection configuration | Setting up required status checks via API |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Codecov | Coveralls, CodeClimate | Codecov has better free tier, PR comments, and trend graphs |
| Separate workflows | Monolithic workflow | Separate workflows enable independent triggers, clearer logs, faster runs |
| GitHub Actions | CircleCI, Travis CI | GitHub Actions has tighter integration, free tier sufficient for this project |

**Installation:**
```bash
# No installation needed - workflows reference actions via GitHub Marketplace
# Codecov account creation: https://codecov.io (free for public/private repos)
```

## Architecture Patterns

### Recommended Project Structure
```
.github/
├── workflows/
│   ├── backend.yml        # Dart backend CI (analyze + test + coverage)
│   └── frontend.yml       # Flutter frontend CI (analyze + test + coverage)
└── codecov.yml            # Codecov configuration (optional, for customization)
```

### Pattern 1: Path-Based Workflow Triggers
**What:** Use `paths` filters to trigger workflows only when relevant files change
**When to use:** Monorepos or projects with independent backend/frontend
**Example:**
```yaml
# Source: https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions
on:
  push:
    branches: [ main ]
    paths:
      - 'backend/**'
      - '.github/workflows/backend.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'backend/**'
      - '.github/workflows/backend.yml'
```

**Key constraint:** Cannot use both `paths` and `paths-ignore` for the same event. Use `paths` with `!` prefix to exclude patterns.

### Pattern 2: Dependency Caching with Built-in Support
**What:** Use action-provided caching instead of manual `actions/cache`
**When to use:** Always - official actions have optimized caching
**Example:**
```yaml
# Source: https://github.com/subosito/flutter-action
- uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.10.4'
    channel: 'stable'
    cache: true
    pub-cache-key: 'flutter-pub-:os:-:channel:-:version:-:arch:-:hash:'
```

**Dart setup-dart action** has automatic caching - no configuration needed (as of v1.7.1).

### Pattern 3: Coverage Generation and Upload
**What:** Run tests with `--coverage` flag, then upload LCOV file to Codecov
**When to use:** Every CI run to track coverage trends
**Example:**
```yaml
# Source: https://github.com/codecov/codecov-action
- name: Run tests with coverage
  run: dart test --coverage=coverage
  working-directory: ./backend

- name: Upload coverage to Codecov
  uses: codecov/codecov-action@v5
  with:
    files: ./backend/coverage/lcov.info
    flags: backend
    fail_ci_if_error: true
```

**Flutter equivalent:**
```yaml
- run: flutter test --coverage
  working-directory: ./app

- uses: codecov/codecov-action@v5
  with:
    files: ./app/coverage/lcov.info
    flags: frontend
```

### Pattern 4: Handling Pre-existing Warnings
**What:** Use `--no-fatal-warnings` to allow info-level warnings without blocking CI
**When to use:** When you have known deprecation warnings that don't affect functionality
**Example:**
```yaml
# Source: https://dart.dev/tools/dart-analyze
- name: Analyze backend
  run: dart analyze --no-fatal-warnings
  working-directory: ./backend
```

**Alternative approach:** Configure `analysis_options.yaml` to set specific warnings to `ignore` or `info` level:
```yaml
# Source: https://dart.dev/tools/analysis
analyzer:
  errors:
    deprecated_member_use: info  # Downgrade to info (doesn't block CI)
```

### Anti-Patterns to Avoid
- **Running all tests on every change:** Use path filters to avoid running backend tests when only frontend changes
- **Hardcoding tokens in workflows:** Always use GitHub Secrets (`${{ secrets.CODECOV_TOKEN }}`)
- **Using `paths-ignore` alone:** Prefer `paths` with explicit includes for clarity
- **Skipping coverage on PRs:** Coverage comments on PRs are valuable for review

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Coverage visualization | Custom HTML parser + hosting | Codecov | Handles LCOV parsing, trend graphs, PR comments, badges automatically |
| Dependency caching | Manual `actions/cache` with custom keys | Built-in caching in `setup-dart`/`flutter-action` | Official actions have optimized cache keys and invalidation |
| Branch protection | Manual GitHub UI configuration | `gh api` calls in script | Reproducible, version-controlled, automatable |
| SDK installation | Custom Docker images | Official `setup-dart`/`flutter-action` | Supports all platforms, channels, versions; maintained by teams |

**Key insight:** GitHub Actions ecosystem is mature - community has solved common problems like caching, coverage upload, and SDK setup. Custom solutions add maintenance burden without benefit.

## Common Pitfalls

### Pitfall 1: Branch Protection with `paths-ignore`
**What goes wrong:** Workflows with `paths-ignore` are skipped, but GitHub doesn't mark them as "success" - they're absent, blocking PR merge
**Why it happens:** GitHub requires all status checks to report, but filtered workflows never run
**How to avoid:** Use `paths` (positive filter) instead of `paths-ignore`, or don't require skippable workflows as branch protection checks
**Warning signs:** PR shows "Waiting for status to be reported" indefinitely

### Pitfall 2: Coverage Path Mapping
**What goes wrong:** Codecov shows "Files not found" or maps coverage to wrong files
**Why it happens:** CI runs in `/home/runner/work/repo/repo` but paths in LCOV are relative; Codecov can't match to Git structure
**How to avoid:** Ensure coverage files use relative paths from repository root. Use `working-directory` consistently.
**Warning signs:** Codecov dashboard shows 0% coverage despite successful upload

### Pitfall 3: Dart Test Coverage Output Location
**What goes wrong:** Assuming `dart test --coverage` creates `coverage/lcov.info` like Flutter
**Why it happens:** Dart's `--coverage` flag requires a directory argument and outputs JSON, not LCOV
**How to avoid:** For Dart backend, use `dart test --coverage=coverage` then convert with `format_coverage` from `package:coverage`, OR use a test script that handles LCOV generation
**Warning signs:** Codecov upload fails with "coverage file not found"

**Resolution for this project:** Use `test_cov_console` package or custom script to generate LCOV from Dart tests.

### Pitfall 4: Token Requirements for Private Repos
**What goes wrong:** Codecov upload fails with authentication error on private repos
**Why it happens:** v5 made tokens optional for public repos, but private repos still require `CODECOV_TOKEN`
**How to avoid:** Always add `CODECOV_TOKEN` to repository secrets, even if repo is public (for future privacy changes)
**Warning signs:** Codecov action fails with "Missing repository token"

### Pitfall 5: Flutter Cache Miss on Windows
**What goes wrong:** Windows runners fail to cache Flutter dependencies
**Why it happens:** `flutter-action` required `yq` for `flutter-version-file` parsing, not pre-installed on Windows
**How to avoid:** Use `flutter-action@v2.18.0+` which auto-installs `yq`, or specify `flutter-version` directly
**Warning signs:** Workflow logs show "yq: command not found" on Windows runners

### Pitfall 6: Combining `paths` and `paths-ignore`
**What goes wrong:** Workflow syntax error or unexpected trigger behavior
**Why it happens:** GitHub doesn't allow both filters for the same event
**How to avoid:** Use only `paths` with `!` prefix for exclusions: `paths: ['!.github/workflows/*.md']`
**Warning signs:** Workflow validation error or triggers on excluded files

## Code Examples

Verified patterns from official sources:

### Backend Workflow (Dart)
```yaml
# Source: https://github.com/dart-lang/setup-dart
name: Backend CI

on:
  push:
    branches: [ main ]
    paths:
      - 'backend/**'
      - '.github/workflows/backend.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'backend/**'
      - '.github/workflows/backend.yml'

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: 'stable'

      - name: Install dependencies
        run: dart pub get
        working-directory: ./backend

      - name: Analyze code
        run: dart analyze --no-fatal-warnings
        working-directory: ./backend

      - name: Run tests with coverage
        run: dart test --coverage=coverage
        working-directory: ./backend

      # Note: Dart outputs JSON, need to convert to LCOV
      # Use package:coverage or test_cov_console
```

### Frontend Workflow (Flutter)
```yaml
# Source: https://github.com/subosito/flutter-action
name: Frontend CI

on:
  push:
    branches: [ main ]
    paths:
      - 'app/**'
      - '.github/workflows/frontend.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'app/**'
      - '.github/workflows/frontend.yml'

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.4'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get
        working-directory: ./app

      - name: Analyze code
        run: flutter analyze --no-fatal-warnings
        working-directory: ./app

      - name: Run tests with coverage
        run: flutter test --coverage
        working-directory: ./app

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v5
        with:
          files: ./app/coverage/lcov.info
          flags: frontend
          fail_ci_if_error: true
```

### Codecov Configuration (codecov.yml)
```yaml
# Source: https://docs.codecov.com/docs/codecov-yaml
coverage:
  status:
    project:
      default:
        target: auto          # Compare against base branch coverage
        threshold: 1%         # Allow 1% drop
    patch:
      default:
        target: 80%           # New code should have 80%+ coverage
        threshold: 5%

ignore:
  - "**/*.g.dart"             # Ignore generated files
  - "**/*.freezed.dart"
  - "**/*.mocks.dart"

flags:
  backend:
    paths:
      - backend/
  frontend:
    paths:
      - app/
```

### Branch Protection via gh CLI
```bash
# Source: https://docs.github.com/en/rest/branches/branch-protection
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  repos/OWNER/REPO/branches/main/protection \
  -f required_status_checks='{"strict":true,"contexts":["Backend CI","Frontend CI"]}' \
  -f enforce_admins=true \
  -f required_pull_request_reviews='{"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"required_approving_review_count":1}'
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `actions/cache@v2` with manual keys | Built-in caching in setup actions | ~2023 (setup-dart v1.6+, flutter-action v2.18+) | Faster setup, fewer lines of YAML |
| Codecov v3 with token required | Codecov v5 with optional token for public repos | Jan 2024 | Simpler public repo setup, faster updates via CLI wrapper |
| `dart format` as separate command | `dart format` integrated into `dart analyze` | Dart 3.0+ (2023) | One less CI step needed |
| Travis CI, CircleCI dominance | GitHub Actions as default | ~2020-2021 | Tighter GitHub integration, free minutes for public/private repos |

**Deprecated/outdated:**
- **`flutter format`**: Deprecated in favor of `dart format` (still works but shows warning)
- **Codecov v3**: v5 released with better performance and OIDC support
- **Manual `lcov` installation on macOS**: Modern Flutter/Dart tooling includes coverage tools

## Open Questions

1. **Backend LCOV generation approach**
   - What we know: `dart test --coverage` outputs JSON in `coverage/` directory, not LCOV
   - What's unclear: Best approach for this project - use `package:coverage` with `format_coverage`, or `test_cov_console` package?
   - Recommendation: Try `test_cov_console` first (simpler), fall back to `format_coverage` script if needed. Document the chosen approach in backend CI workflow.

2. **Codecov token necessity for this project**
   - What we know: Public repos can use tokenless upload in v5; private repos need token
   - What's unclear: Is "Core - Idrett" repository public or private?
   - Recommendation: Set up `CODECOV_TOKEN` secret regardless - it works for both and future-proofs against visibility changes.

3. **Handling the 5 known warnings**
   - What we know: Project has 5 info-level deprecation warnings that shouldn't block CI
   - What's unclear: Should we use `--no-fatal-warnings` (allows all warnings) or configure `analysis_options.yaml` to downgrade specific warnings?
   - Recommendation: Start with `--no-fatal-warnings` for simplicity. If new warnings creep in, switch to explicit `analysis_options.yaml` configuration to only allow the 5 known warnings.

## Sources

### Primary (HIGH confidence)
- [dart-lang/setup-dart v1.7.1](https://github.com/dart-lang/setup-dart) - Official Dart setup action
- [subosito/flutter-action v2](https://github.com/subosito/flutter-action) - Flutter setup action with caching
- [codecov/codecov-action v5](https://github.com/codecov/codecov-action) - Official Codecov upload action
- [dart analyze documentation](https://dart.dev/tools/dart-analyze) - Exit codes and flags
- [GitHub branch protection docs](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/managing-a-branch-protection-rule) - Status check requirements
- [Codecov YAML reference](https://docs.codecov.com/docs/codecov-yaml) - Configuration options
- [GitHub workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions) - Path triggers

### Secondary (MEDIUM confidence)
- [Testing Dart packages with GitHub Actions](https://medium.com/flutter-community/testing-dart-packages-with-github-actions-4c2c671b1e34) - Community patterns
- [Flutter CI/CD with GitHub Actions](https://medium.com/@akashvyasce/automate-your-flutter-builds-with-ci-cd-using-github-actions-55a7790c3f74) - Coverage enforcement patterns (Jul 2025)
- [Run Flutter tests with GitHub Actions](https://damienaicheh.github.io/flutter/github/actions/2021/05/06/flutter-tests-github-actions-codecov-en.html) - Codecov integration
- [How to Generate Flutter Test Coverage](https://codewithandrea.com/articles/flutter-test-coverage/) - LCOV output paths

### Tertiary (LOW confidence - needs validation)
- Community discussions on path-ignore branch protection issues (marked for validation during implementation)
- Coverage path mapping troubleshooting (verify against actual project structure)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official actions from GitHub and Dart/Flutter teams with extensive documentation
- Architecture: HIGH - Patterns verified in official docs and community practice for monorepos
- Pitfalls: MEDIUM-HIGH - Most verified in official docs, some from community experience (needs validation)

**Research date:** 2026-02-10
**Valid until:** ~2026-04-10 (60 days for stable ecosystem)
