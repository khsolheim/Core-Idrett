# Phase 12: Pre-commit Hooks

## Goal

Catch formatting and analysis issues locally before push.

## Requirements

- **HOOKS-01**: Developer can install pre-commit hooks with a single setup command
- **HOOKS-02**: Pre-commit hook blocks commits with formatting issues
- **HOOKS-03**: Pre-commit hook blocks commits with new analysis errors (5 known warnings allowed)

## Plans

| Plan | Deliverable | Requirements |
|------|-------------|--------------|
| 12-01 | Git hooks for format + analyze (backend + frontend) | HOOKS-02, HOOKS-03 |
| 12-02 | Setup script + team documentation | HOOKS-01 |

## Key Decisions

- **`.githooks/` directory**: No npm/husky dependency — pure shell scripts, version-controlled
- **Format check only**: Use `--set-exit-if-changed` flag to detect formatting issues without auto-formatting
- **No tests in hooks**: `flutter test` is too slow for pre-commit; CI handles that
- **Allowlist for known warnings**: 5 pre-existing analyze warnings are filtered so they don't block commits

## Files to Create

- `.githooks/pre-commit` (shell script)
- `scripts/setup-hooks.sh` (one-time setup: `git config core.hooksPath .githooks`)

## Dependencies

- Phase 11 (CI) should be done first so developers can verify their hooks match CI behavior

## Context from v1.0

- `dart format` and `flutter format` (now `dart format`) check formatting
- `dart analyze` and `flutter analyze` check for analysis issues
- Both backend and frontend need to be checked on every commit
