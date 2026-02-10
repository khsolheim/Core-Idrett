# Phase 10: Final Quality Pass - Research

**Researched:** 2026-02-10
**Domain:** Software Quality Assurance, Static Analysis, Test Coverage, Cross-Phase Validation
**Confidence:** HIGH

## Summary

Phase 10 is a validation phase that ensures all quality goals from Phases 1-9 are achieved before declaring the refactoring complete. This phase differs from traditional development phases—it's about verification, measurement, and gap closure rather than new feature delivery.

The research reveals that the codebase is in excellent shape after 9 completed phases, but several gaps must be addressed before final sign-off:

1. **Widget File Splitting (Phase 5)**: Already completed and verified. All 8 FSPLIT requirements are satisfied. The only files mentioned in requirements (FSPLIT-01 through FSPLIT-08) have been successfully split or no longer exist as large files.

2. **Test Coverage (Phase 6)**: Partially complete. Backend has 361 passing tests with 100% pass rate. Frontend has 262 tests with 12 failures (4.6% failure rate). Requirements TEST-03 through TEST-08 remain pending.

3. **Static Analysis**: Backend shows 1 warning (unused import). Frontend shows 67 issues (2 duplicate imports, 5 unused imports/fields, 5 pre-existing deprecation warnings, 55 info-level const constructor suggestions).

4. **Manual Smoke Testing**: No systematic smoke test checklist exists. This is a critical gap for cross-cutting validation.

**Primary recommendation:** Create a 4-plan phase focusing on (1) fixing frontend test failures, (2) completing missing backend test coverage, (3) cleaning static analysis warnings, and (4) executing manual smoke tests with documented evidence.

## Standard Stack

### Core Tools (Already in Use)

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `flutter analyze` | Built-in | Frontend static analysis | Official Flutter tool, uses analyzer package with flutter_lints rules |
| `dart analyze` | Built-in | Backend static analysis | Official Dart tool, same analyzer package as Flutter |
| `flutter test --coverage` | Built-in | Frontend test execution + coverage | Generates LCOV reports, industry standard for Flutter |
| `dart test` | Built-in | Backend test execution | Official Dart test runner |
| `lcov` / `genhtml` | Via brew | Coverage visualization | Industry standard for LCOV → HTML conversion |

### Supporting Tools

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| `test` package | ^1.25.0 | Dart test framework | Already used in backend/pubspec.yaml |
| `flutter_test` | SDK | Flutter widget testing | Already used in app/pubspec.yaml |
| `mocktail` | ^1.0.0 | Test mocking | Already used in both frontend and backend |
| `coverage` package | Latest | Advanced coverage reports | Optional—for generating coverage from JSON to LCOV |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual smoke testing | Integration test automation | Integration tests are ideal long-term but require significant setup; manual testing is faster for this milestone |
| flutter_lints | custom_lint / DCM | Custom linters offer more control but add complexity; flutter_lints is sufficient for this phase |
| Manual LCOV viewing | SonarQube Cloud | SonarQube offers CI/CD integration and trends, but adds infrastructure; local lcov is simpler for one-time validation |

**Installation:**

```bash
# macOS: Install lcov for coverage HTML generation
brew install lcov

# Generate frontend coverage
cd app
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Generate backend coverage (requires coverage package)
cd backend
dart pub global activate coverage
dart pub global run coverage:test_with_coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Architecture Patterns

### Quality Pass Structure

Quality validation phases should follow this layered approach:

```
Phase 10 Structure:
├── 10-01-PLAN.md          # Frontend test fixing (12 failing tests)
├── 10-02-PLAN.md          # Backend test coverage (TEST-03 through TEST-06)
├── 10-03-PLAN.md          # Static analysis cleanup (backend + frontend warnings)
└── 10-04-PLAN.md          # Manual smoke testing with evidence checklist
```

### Pattern 1: Test Failure Triage

**What:** Systematic approach to addressing test failures
**When to use:** When test suite has failures that need prioritization

**Example:**

```markdown
1. **Classify failures by root cause:**
   - Widget not found (test expectations outdated)
   - Provider state issues (mock setup incomplete)
   - Async timing issues (missing pumpAndSettle)

2. **Prioritize by impact:**
   - Blocking failures (indicate broken functionality)
   - Flaky failures (timing or state issues)
   - Outdated assertions (implementation changed correctly)

3. **Fix or disable:**
   - Fix if test reveals actual bug
   - Update if implementation evolved correctly
   - Skip (with TODO) if blocked by missing infrastructure
```

### Pattern 2: Coverage Gap Analysis

**What:** Identify untested critical paths
**When to use:** When coverage metrics show gaps in important services

**Example from this project:**

```markdown
Backend Coverage Gaps (from requirements):
- TEST-03: Export service (7 export types untested)
- TEST-04: Tournament bracket generation (bracket logic untested)
- TEST-05: Fine payment reconciliation (edge cases untested)
- TEST-06: Statistics edge cases (zero attendance, season boundaries)

Frontend Coverage Gaps:
- TEST-07: Export screen widget tests (UI coverage missing)
- TEST-08: Tournament screen widget tests (UI coverage missing)
```

### Pattern 3: Manual Smoke Test Checklist

**What:** Structured manual testing to validate cross-cutting concerns
**When to use:** Before final release to catch integration issues automated tests miss

**Example structure:**

```markdown
## Authentication Flow
- [ ] Register new user with valid credentials
- [ ] Login with registered credentials
- [ ] Logout successfully
- [ ] Attempt login with invalid credentials (should fail gracefully)

## Team Management
- [ ] Create new team
- [ ] View team dashboard
- [ ] Invite member to team
- [ ] Accept invite as invited user
- [ ] Remove member from team

## Critical Paths Per Feature
[One section per major feature from project overview]
```

### Anti-Patterns to Avoid

- **Skipping manual testing:** Automated tests cannot catch all integration issues, UX problems, or visual regressions
- **Ignoring pre-existing warnings:** "It was already broken" normalizes technical debt and makes future issues harder to spot
- **Coverage theater:** Chasing 100% coverage with meaningless tests instead of testing critical paths
- **Test-fix whack-a-mole:** Fixing test failures without understanding root cause leads to fragile tests

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Test coverage reports | Custom parser for test output | `flutter test --coverage` + `genhtml` | LCOV format is industry standard; custom parsing is fragile and misses edge cases |
| Static analysis rules | Custom linter from scratch | `flutter_lints` / `package:lints` | Curated rulesets by Flutter team cover 90% of common issues; custom rules add maintenance burden |
| Test data factories | Manual construction in every test | Centralized factory pattern (already exists in `test/helpers/test_data.dart`) | DRY principle; factory ensures consistent, valid test data |
| Smoke test automation | Custom Selenium/Appium scripts | Manual checklist for milestone validation | Integration test infrastructure is a separate project; manual validation is faster for one-time use |

**Key insight:** Quality validation tools are mature and standardized. The value is in *systematic application* and *gap closure*, not in building custom tooling.

## Common Pitfalls

### Pitfall 1: Treating Quality Pass as Optional

**What goes wrong:** Teams skip final validation, assuming passing tests = ready to ship. This misses cross-cutting issues like UX regressions, accessibility problems, or incomplete translations.

**Why it happens:** Pressure to "finish" the milestone, fatigue after 9 phases of work.

**How to avoid:** Make quality pass non-negotiable. Define explicit success criteria before starting the phase. Treat it as a gate, not a formality.

**Warning signs:** Phrases like "we'll fix it later" or "it's good enough" during quality review discussions.

### Pitfall 2: Ignoring Pre-Existing Test Failures

**What goes wrong:** Test suite has 12 failures, but team assumes "they were already broken" and ships anyway. This normalizes failure and prevents catching new regressions.

**Why it happens:** Unclear baseline (what was broken before vs. what broke during this milestone).

**How to avoid:** Document baseline at phase start. Fix pre-existing failures or explicitly skip them with TODO comments explaining why they're deferred.

**Warning signs:** Test suite shows failures for weeks/months with no action taken.

### Pitfall 3: Coverage Metrics Without Context

**What goes wrong:** Chasing "70% backend coverage" by adding trivial tests for getters/setters instead of testing critical business logic.

**Why it happens:** Coverage percentage becomes a goal instead of a tool.

**How to avoid:** Define coverage requirements by *what* must be tested (export types, bracket generation, payment reconciliation) rather than *how much* code is executed.

**Warning signs:** Coverage increases but no new critical paths are validated.

### Pitfall 4: Static Analysis Whack-A-Mole

**What goes wrong:** Developers suppress warnings with `// ignore` comments instead of fixing root cause. Analysis becomes useless as noise-to-signal ratio increases.

**Why it happens:** Warnings feel like distractions when trying to "finish" the milestone.

**How to avoid:** Treat each warning category systematically. Fix or suppress with *documented* justification. Never suppress without understanding the warning.

**Warning signs:** Growing list of `// ignore` comments, especially without explanatory comments.

### Pitfall 5: Manual Testing Without Documentation

**What goes wrong:** Manual smoke testing happens, tester says "looks good," but no record exists of what was tested or what passed/failed.

**Why it happens:** Manual testing feels informal; documenting feels like overhead.

**How to avoid:** Create a checklist with checkboxes. Record results in a VERIFICATION.md file. Include screenshots or logs for critical flows.

**Warning signs:** Questions like "did we test X?" cannot be answered definitively.

## Code Examples

### Example 1: Running Test Coverage (Frontend)

```bash
# Source: Official Flutter docs
cd /Users/karsten/NextCore/Core\ -\ Idrett/app
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

### Example 2: Running Test Coverage (Backend)

```bash
# Source: Dart test package documentation
cd /Users/karsten/NextCore/Core\ -\ Idrett/backend

# Option 1: Manual coverage collection
dart pub global activate coverage
dart pub global run coverage:test_with_coverage

# Option 2: Using dart test (requires coverage package)
dart test --coverage=coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# View report
open coverage/html/index.html
```

### Example 3: Fixing a Failing Widget Test

```dart
// Source: Flutter testing best practices
// BEFORE: Failing test - widget not found
testWidgets('shows error state with retry button', (tester) async {
  await tester.pumpWidget(TestApp(child: MyScreen()));

  // This fails because async state hasn't loaded
  expect(find.byIcon(Icons.error), findsOneWidget);
});

// AFTER: Fixed test - wait for async state
testWidgets('shows error state with retry button', (tester) async {
  await tester.pumpWidget(TestApp(child: MyScreen()));

  // Wait for async state updates
  await tester.pumpAndSettle();

  // Now error icon should be visible
  expect(find.byIcon(Icons.error), findsOneWidget);
});
```

### Example 4: Manual Smoke Test Checklist Template

```markdown
# Manual Smoke Test - Core - Idrett
**Tested by:** [Name]
**Date:** 2026-02-10
**Build:** Phase 10 completion candidate
**Device:** iPhone 15 Pro (iOS 18.2) / Pixel 8 (Android 15)

## Authentication
- [ ] PASS: Register new user with email/password
- [ ] PASS: Login with registered credentials
- [ ] PASS: Logout and verify return to login screen
- [ ] PASS: Invalid credentials show Norwegian error message

## Team Management
- [ ] PASS: Create new team with Norwegian name
- [ ] PASS: View team dashboard (leaderboard, messages, fines, quick links visible)
- [ ] PASS: Generate invite code
- [ ] PASS: Join team using invite code (from second device/user)
- [ ] PASS: Assign coach role to member
- [ ] PASS: Remove member from team

## Activities
- [ ] PASS: Create training activity with future date
- [ ] PASS: Respond to activity (going/not going/maybe)
- [ ] PASS: View activity details
- [ ] PASS: Activity shows correct attendance count

## Mini-Activities
- [ ] PASS: Create mini-activity within activity instance
- [ ] PASS: Record match result (player vs player)
- [ ] PASS: View mini-activity statistics
- [ ] PASS: Tournament bracket generates correctly (8 participants)

## Fines
- [ ] PASS: fine_boss creates fine for player
- [ ] PASS: Player views fine in their list
- [ ] PASS: Record payment for fine
- [ ] PASS: Fine status updates to "paid" when amount >= fine total

## Chat
- [ ] PASS: Send team message
- [ ] PASS: Message appears for all team members
- [ ] PASS: Reply to message
- [ ] PASS: Send direct message to team member
- [ ] PASS: Edit sent message

## Export
- [ ] PASS: Export team data (CSV)
- [ ] PASS: Export file downloads successfully
- [ ] PASS: Export history shows completed export

## Notifications
- [ ] PASS: Receive push notification when app in background
- [ ] PASS: Receive foreground notification when app is open
- [ ] PASS: Tap notification navigates to relevant screen

## UI/UX Validation
- [ ] PASS: All text in Norwegian (no English labels remaining)
- [ ] PASS: Empty states show EmptyStateWidget with Norwegian message
- [ ] PASS: Error messages show in Norwegian via ErrorDisplayService
- [ ] PASS: Loading states show CircularProgressIndicator consistently
- [ ] PASS: Navigation works across all screens (no dead ends)

## Edge Cases
- [ ] PASS: Offline mode shows connectivity error
- [ ] PASS: Invalid date input handled gracefully
- [ ] PASS: Empty team (no members) doesn't crash dashboard
- [ ] PASS: Zero attendance rate displays "0%" not "NaN"

**Result:** ✅ PASS / ❌ FAIL / ⚠️ PARTIAL
**Blockers:** [List any issues that prevent release]
**Notes:** [Additional observations]
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual test execution only | `flutter test --coverage` with automated coverage reports | Flutter 1.x → 2.x | Shifted from "we think we tested enough" to measurable coverage metrics |
| Custom lint rules per project | `flutter_lints` / `package:lints` curated packages | Dart 2.12+ | Reduced setup complexity and ensured consistency across Flutter projects |
| `dart analyze` without configuration | `analysis_options.yaml` with include directives | Dart 2.0+ | Centralized team-wide analysis rules |
| SonarQube as only coverage tool | Local LCOV + genhtml for rapid feedback | 2020+ | Faster iteration without CI/CD dependency |

**Deprecated/outdated:**

- **Ignoring info-level lints:** Modern best practice treats info lints (like `prefer_const_constructors_in_immutables`) as actionable, not noise. The project has 55 such warnings that should be addressed.
- **Skipping manual smoke tests:** 2026 best practices emphasize that automated tests alone cannot catch all issues. Manual validation with documented evidence is standard before releases.

## Current State Assessment

### Backend Status

**Static Analysis:**
- 1 warning: Unused import in `test/services/fine_service_test.dart`
- 0 errors
- ✅ Goal of "zero errors and zero warnings" is achievable with minimal work

**Test Status:**
- 361 tests passing (100% pass rate)
- Coverage: Unknown (needs measurement)
- Gap: Requirements TEST-03 through TEST-06 incomplete (export, tournament, fine, statistics service tests)

### Frontend Status

**Static Analysis:**
- 67 issues total:
  - 3 duplicate imports (warnings)
  - 5 unused imports/fields (warnings)
  - 5 pre-existing deprecation warnings (known, documented in CLAUDE.md)
  - 54 `prefer_const_constructors_in_immutables` (info-level, fixable with auto-fix)
- 0 errors
- ⚠️ Goal of "zero errors and only accepted warnings" requires cleanup, but is achievable

**Test Status:**
- 262 tests total
- 250 passing, 12 failing (4.6% failure rate)
- Failures concentrated in 2 files:
  - `activities_list_test.dart`: Error state retry button not found
  - `activity_detail_test.dart`: Error state icon not found
- Gap: Requirements TEST-07 and TEST-08 incomplete (export screen and tournament screen widget tests)

### Widget File Splitting Status

**Assessment:** ✅ **COMPLETE** (verified 2026-02-09)

All 8 FSPLIT requirements (FSPLIT-01 through FSPLIT-08) are **satisfied**:

- **FSPLIT-01 (message_widgets.dart):** ✅ Split into 4 files via barrel export (message_bubble, message_input_widgets, new_conversation_sheet, message_helpers)
- **FSPLIT-02 (test_detail_screen.dart):** ✅ Reduced from 476 → 121 LOC, 3 widget files extracted
- **FSPLIT-03 (export_screen.dart):** ✅ Reduced from 470 → 206 LOC, 3 widget files extracted
- **FSPLIT-04 (activity_detail_screen.dart):** ✅ Split into screen + content widget (178 + 286 LOC)
- **FSPLIT-05 (mini_activity_detail_content.dart):** ✅ Reduced to 307 LOC (under 350 target)
- **FSPLIT-06 (stats_widgets.dart):** ✅ Converted to barrel with 3 focused files
- **FSPLIT-07 (edit_team_members_tab.dart):** ✅ Reduced from 423 → 88 LOC
- **FSPLIT-08 (dashboard_info_widgets.dart):** ✅ Converted to barrel with 4 focused files

**Evidence:** Phase 5 verification report (`05-VERIFICATION.md`) confirms all 6 success criteria met, all 22 artifacts exist and wired, all 11 key links verified, and flutter analyze shows only 5 pre-existing warnings with zero new errors.

**Note:** The files listed in requirements no longer exist as large monolithic files—they have been successfully decomposed. This is the *desired end state*, not a problem to fix.

### Requirements Coverage

From `.planning/REQUIREMENTS.md`:

**Completed (v1):**
- TEST-01 ✅ (Phase 1)
- TEST-02 ✅ (Phase 1)
- TYPE-01 through TYPE-06 ✅ (Phase 2)
- BSPLIT-01 through BSPLIT-08 ✅ (Phase 3)
- **FSPLIT-01 through FSPLIT-08 ✅ (Phase 5)** ← Confirmed complete

**Pending (for Phase 10):**
- TEST-03: Backend export service tests
- TEST-04: Backend tournament service tests
- TEST-05: Backend fine service tests
- TEST-06: Backend statistics service tests
- TEST-07: Frontend export screen widget tests
- TEST-08: Frontend tournament screen widget tests
- SEC-01: Admin role check consolidation (Phase 4, not started)
- SEC-02: Rate limiting auth endpoints (Phase 4, not started)
- SEC-03: Rate limiting mutation endpoints (Phase 4, not started)
- SEC-07: fine_boss permission checks (Phase 4, not started)
- CONS-01 through CONS-06 (Phase 7, not started)
- I18N-01 through I18N-03 (Phase 9, completed per git log)

**Total v1 requirements:** 45
**Completed:** 30 (66.7%)
**Remaining:** 15 (33.3%)

## Open Questions

1. **Should Phase 10 include Phase 4, 6, and 7 work?**
   - What we know: Roadmap shows Phases 4, 6, 7 as separate phases with their own plans
   - What's unclear: Whether "Final Quality Pass" means executing those phases or validating they're complete
   - Recommendation: Phase 10 should validate that *planned* work is complete. If Phases 4, 6, 7 were never executed, they should be executed as separate phases, not rolled into Phase 10. Phase 10 focuses on *verification* and *gap closure*, not executing deferred work.

2. **What coverage percentage is "enough"?**
   - What we know: Requirements specify "above 70% backend, above 80% frontend"
   - What's unclear: Whether this is line coverage, branch coverage, or function coverage
   - Recommendation: Use line coverage (simplest to measure with LCOV). Focus on critical path coverage (TEST-03 through TEST-08) rather than chasing arbitrary percentages.

3. **Should pre-existing test failures be fixed or documented?**
   - What we know: 12 frontend tests fail, concentrated in 2 files (activities tests)
   - What's unclear: Whether these failures existed before Phase 1 or were introduced during refactoring
   - Recommendation: Fix if they're regressions from refactoring. Document and skip with `// TODO:` if they reveal deeper issues requiring infrastructure work. Do not ship with active failures—either fix or explicitly defer.

4. **What constitutes "evidence" for manual smoke testing?**
   - What we know: Success criteria states "manual smoke test of all features reveals no regressions"
   - What's unclear: What level of documentation is required (checklist only vs. screenshots vs. video)
   - Recommendation: Checklist with checkboxes and brief notes per feature. Screenshots for critical flows (auth, payment, notifications). No need for video unless demonstrating a specific bug.

## Sources

### Primary (HIGH confidence)

- **Flutter Testing Documentation:** [https://docs.flutter.dev/testing](https://docs.flutter.dev/testing) - Official testing guide
- **Dart Static Analysis:** [https://dart.dev/tools/analysis](https://dart.dev/tools/analysis) - Customizing static analysis
- **Dart Analyze Command:** [https://dart.dev/tools/dart-analyze](https://dart.dev/tools/dart-analyze) - Official dart analyze documentation
- **Coverage Package:** [https://pub.dev/packages/coverage](https://pub.dev/packages/coverage) - Official Dart coverage tool
- **Code with Andrea - Flutter Test Coverage:** [https://codewithandrea.com/articles/flutter-test-coverage/](https://codewithandrea.com/articles/flutter-test-coverage/) - Practical Flutter coverage guide
- **SonarQube Dart Coverage:** [https://docs.sonarsource.com/sonarqube-cloud/enriching/test-coverage/dart-test-coverage](https://docs.sonarsource.com/sonarqube-cloud/enriching/test-coverage/dart-test-coverage) - LCOV format documentation

### Secondary (MEDIUM confidence)

- **BrowserStack Smoke Testing Guide:** [https://www.browserstack.com/guide/smoke-testing](https://www.browserstack.com/guide/smoke-testing) - What is smoke testing in 2026
- **TestGrid Smoke Testing Guide:** [https://testgrid.io/blog/smoke-testing-everything-you-need-to-know/](https://testgrid.io/blog/smoke-testing-everything-you-need-to-know/) - Comprehensive smoke testing guide
- **QA Source QA Checklist:** [https://blog.qasource.com/resources/the-ultimate-qa-checklist-for-software-development](https://blog.qasource.com/resources/the-ultimate-qa-checklist-for-software-development) - Ultimate QA testing checklist
- **QA Source Smoke Testing 2026:** [https://blog.qasource.com/a-complete-guide-to-smoke-testing-in-software-qa](https://blog.qasource.com/a-complete-guide-to-smoke-testing-in-software-qa) - Essential QA guide for software teams
- **Monday.com SQA Best Practices:** [https://monday.com/blog/rnd/software-quality-assurance/](https://monday.com/blog/rnd/software-quality-assurance/) - Software quality assurance best practices for 2026
- **Flutter Community - Widget Splitting:** [https://medium.com/flutter-community/improve-your-flutter-app-performance-split-your-widgets-935f97e93f7d](https://medium.com/flutter-community/improve-your-flutter-app-performance-split-your-widgets-935f97e93f7d) - Performance best practices for widget splitting
- **Flutter Best Practices - Widget Separation:** [https://medium.com/@umkithya/flutter-best-practices-part-1-f0ebb0a4b167](https://medium.com/@umkithya/flutter-best-practices-part-1-f0ebb0a4b167) - UI separation guide
- **DHiWise Flutter Analyzer Guide:** [https://www.dhiwise.com/post/flutter-analyzer-a-guide-to-static-analysis-in-flutter](https://www.dhiwise.com/post/flutter-analyzer-a-guide-to-static-analysis-in-flutter) - Mastering static analysis

### Tertiary (LOW confidence)

- **QAwerk Mobile Testing Checklist:** [https://qawerk.com/blog/mobile-app-testing-checklist/](https://qawerk.com/blog/mobile-app-testing-checklist/) - Mobile app testing checklist
- **Ranger QA Release Checklist:** [https://www.ranger.net/post/qa-checklist-8-steps-before-every-release](https://www.ranger.net/post/qa-checklist-8-steps-before-every-release) - 8 steps before every release
- **Sauce Labs QA Trends:** [https://saucelabs.com/resources/blog/beyond-pass-fail-3-strategic-trends-that-will-define-qa-in-2026](https://saucelabs.com/resources/blog/beyond-pass-fail-3-strategic-trends-that-will-define-qa-in-2026) - Strategic trends for QA in 2026

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All tools are official Flutter/Dart tooling, well-documented and stable
- Architecture patterns: HIGH - Based on official documentation and verified project state
- Current state assessment: HIGH - Based on direct analysis of test output and static analysis results
- Widget file splitting status: HIGH - Verified via Phase 5 completion report (05-VERIFICATION.md)
- Manual smoke testing: MEDIUM - Based on general QA best practices, not Flutter-specific

**Research date:** 2026-02-10
**Valid until:** 60 days (stable tooling and patterns, low churn expected)
