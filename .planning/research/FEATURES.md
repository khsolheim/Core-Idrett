# Feature Landscape

**Domain:** Dart/Flutter Code Refactoring & Quality
**Researched:** 2026-02-08
**Confidence:** MEDIUM (based on established Dart/Flutter patterns and project context)

## Table Stakes

Features users expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Type Safety** | Dart's core strength; unsafe casts undermine compiler | Medium | Replace `as Type` with type guards, pattern matching (Dart 3.0+) |
| **File Size Management** | 300-400 LOC max per file for maintainability | Low-Medium | Already partially done; remaining 700+ LOC services need splitting |
| **Widget Composition** | Flutter best practice; widgets >200 LOC become unmaintainable | Low | Extract stateless widgets, use composition over inheritance |
| **Test Coverage** | Core features must have tests; <60% coverage signals technical debt | Medium-High | Missing: export, tournaments, fines, statistics |
| **Null Safety** | Dart 3.0 requirement; sound null safety is table stakes | Low | Already enforced by compiler; validate external data boundaries |
| **Error Handling Consistency** | Predictable error patterns across app/backend | Low | Partially done; ensure all API boundaries use consistent error types |
| **Input Validation** | All external data validated before use | Medium | Backend: validate JSON fields, query params, headers |
| **Resource Cleanup** | Dispose controllers, cancel streams, close connections | Low | Use `dispose()` in StatefulWidgets, `ref.onDispose()` in providers |
| **Performance Patterns** | Const constructors, keys on dynamic lists, memoization | Low | Partially done; const widgets, ListView keys already added |
| **Code Analysis Compliance** | Zero errors, <5 warnings on `flutter/dart analyze` | Low | Currently 5 pre-existing warnings; new code should add zero |
| **Dependency Management** | Clear separation of concerns, DI pattern | Medium | Already done via constructor injection in backend |
| **Logging & Observability** | Structured logging, error tracking | Medium | Add consistent logging levels, consider error aggregation |
| **Security Basics** | Authentication, authorization, input sanitization | Medium-High | Admin dual-check needed, rate limiting missing |
| **Internationalization** | Single language source, translatable strings | Low | English→Norwegian cleanup needed |
| **API Consistency** | REST conventions, predictable responses | Low | Already consistent with resp.ok/forbidden pattern |

## Differentiators

Features that set product apart. Not expected, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Dead Code Elimination** | Proactive removal of unused code | Low-Medium | Analyze imports, unused classes/methods; reduces cognitive load |
| **Performance Profiling** | Identify N+1 queries, expensive rebuilds | Medium | Already addressed N+1; consider Flutter DevTools profiling |
| **Code Generation Leverage** | Use build_runner for boilerplate (JSON, freezed, riverpod_generator) | Medium-High | Reduces manual serialization errors; considered advanced |
| **Automated Refactoring Tools** | dart fix, IDE refactorings for safe changes | Low | Safer than manual refactoring; catches edge cases |
| **Documentation as Code** | dartdoc comments, auto-generated API docs | Low-Medium | Living documentation stays in sync with code |
| **Advanced State Management** | Optimized provider patterns, .select() usage | Medium | Already implemented; signals mature Riverpod usage |
| **Repository Pattern Optimization** | Caching strategies, optimistic updates | Medium | Repository layer already exists; add caching where beneficial |
| **Feature Flags** | Runtime feature toggles without redeployment | Medium-High | Enables gradual rollouts, A/B testing |
| **Backend OpenAPI/Swagger** | Auto-generated API documentation | Medium | Improves frontend/backend contract clarity |
| **Migration Scripts** | Versioned database + data migrations | Medium | Supabase migrations already exist; ensure rollback strategies |
| **CI/CD Integration** | Automated testing, linting, deployment | High | Catches issues before merge; speeds up development |
| **Accessibility (a11y)** | Semantic labels, screen reader support | Medium | Often overlooked; differentiates quality apps |
| **Analytics Integration** | Usage tracking, performance metrics | Medium | Informs product decisions; requires privacy considerations |
| **Offline-First Architecture** | Local-first data sync, conflict resolution | High | Complex but valuable for mobile; significant refactoring |

## Anti-Features

Features to explicitly NOT build.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Over-Abstraction** | Premature abstraction creates complexity without value | Apply DRY only after 3rd duplication; prefer explicit over clever |
| **God Objects** | Single class/service doing too much violates SRP | Split by domain boundaries; max 400 LOC guideline |
| **Premature Optimization** | Optimize before profiling wastes time | Profile first, optimize proven bottlenecks |
| **Breaking API Changes** | Backend changes break existing clients | Version APIs, deprecate gracefully, maintain compatibility |
| **Global State** | Singletons, global vars make testing impossible | Use DI, providers for state management |
| **Magic Strings/Numbers** | Hardcoded values scatter throughout code | Use constants, enums, configuration files |
| **Tight Coupling** | Direct dependencies between layers | Depend on interfaces/abstract classes, use DI |
| **Test-After Development** | Writing tests after implementation = low coverage | TDD or test-during for critical paths |
| **Silent Failures** | Catching exceptions without logging/handling | Log errors, notify users, fail fast in dev |
| **Mixed Responsibilities** | UI logic in models, business logic in widgets | Strict layer separation: UI→Provider→Repository→API |
| **Nested Ternaries** | Unreadable conditional logic | Use early returns, if/else, or pattern matching |
| **Large Diffs** | Mixing refactoring with feature work | Separate commits: refactor-only vs feature-only |
| **Ignoring Warnings** | analyzer warnings signal future problems | Fix warnings immediately; disable sparingly with justification |
| **Manual Serialization** | Hand-written fromJson/toJson = error-prone | Use json_serializable or freezed for codegen |

## Feature Dependencies

```
Type Safety → Input Validation (validation relies on type guarantees)
Input Validation → Error Handling Consistency (validated data needs consistent error responses)
Test Coverage → CI/CD Integration (tests run automatically)
Widget Composition → File Size Management (composition enables smaller files)
Code Analysis Compliance → Dead Code Elimination (analyzer detects unused code)
Dependency Management → Test Coverage (DI enables mocking for tests)
Null Safety → Type Safety (sound null safety is part of type system)
Security Basics → Input Validation (sanitization prevents injection)
Logging & Observability → Error Handling Consistency (consistent errors = consistent logs)
```

## MVP Recommendation

Prioritize (for remaining refactoring phases):

### Phase 1: Type Safety & Input Validation
1. **Type Safety Hardening** - Replace unsafe casts with type guards/pattern matching
2. **Input Validation Audit** - Validate all external data boundaries (API, DB, user input)
3. **Null Safety Audit** - Ensure sound null safety at data boundaries

**Rationale:** Foundation for all other improvements; prevents runtime errors.

### Phase 2: File Size & Organization
1. **Service File Splitting** - Split 700+ LOC services into focused modules
2. **Widget Extraction** - Extract widgets >200 LOC into composed components
3. **Dead Code Elimination** - Remove unused imports, classes, methods

**Rationale:** Improves maintainability; makes subsequent refactoring easier.

### Phase 3: Test Coverage
1. **Missing Feature Tests** - Add tests for export, tournaments, fines, statistics
2. **Test Helpers Expansion** - Extend TestScenario for new domains
3. **Repository Test Coverage** - Ensure all repositories have unit tests

**Rationale:** Safety net for future changes; catches regressions early.

### Phase 4: Security & Production Readiness
1. **Admin Role Dual-Check** - Verify admin checks at both auth and operation levels
2. **Rate Limiting** - Add rate limiting middleware to prevent abuse
3. **FCM Token Security** - Address token exposure/management issues
4. **Logging & Observability** - Structured logging across backend services

**Rationale:** Production-critical; prevents security incidents and operational issues.

### Phase 5: Polish & Consistency
1. **Internationalization Cleanup** - Replace remaining English with Norwegian
2. **Code Analysis Zero Warnings** - Address all analyzer warnings
3. **Documentation** - Add dartdoc to public APIs, update README with architecture

**Rationale:** Professional polish; improves developer experience.

## Defer

### Defer: Advanced Features
- **Offline-First Architecture** - High complexity; requires significant architectural changes
- **Feature Flags** - Not needed until multi-environment deployment
- **OpenAPI/Swagger** - Nice-to-have; API already stable and documented in CLAUDE.md
- **CI/CD Integration** - Valuable but can be added independently of refactoring
- **Code Generation Migration** - Current manual serialization works; migration is risky

**Reason:** These provide value but don't address current technical debt. Focus on foundation first.

## Complexity Assessment

| Complexity | Features | Estimated Effort |
|------------|----------|------------------|
| **Low** | Const constructors, early returns, magic number elimination, English→Norwegian | 1-2 days total |
| **Medium** | Type safety hardening, file splitting, widget extraction, test coverage, logging | 1-2 weeks total |
| **High** | Security hardening, dead code analysis, comprehensive test suite | 2-3 weeks total |
| **Very High** | Offline-first, CI/CD, code generation migration | 1-2 months total |

## Feature-Specific Notes

### Type Safety Patterns (Dart 3.0+)
```dart
// BAD: Unsafe cast
final name = data['name'] as String;

// GOOD: Type guard with pattern matching
final name = switch (data['name']) {
  String s => s,
  _ => throw ValidationException('name must be string'),
};

// GOOD: Safe cast with validation
final name = data['name'];
if (name is! String) {
  throw ValidationException('name must be string');
}
```

### Widget Composition
```dart
// BAD: 400 LOC widget
class TeamDetailScreen extends StatelessWidget {
  // Massive build method with nested widgets
}

// GOOD: Composed widgets
class TeamDetailScreen extends StatelessWidget {
  Widget build(context) => Scaffold(
    appBar: TeamDetailAppBar(...),
    body: Column([
      TeamHeaderCard(...),
      TeamMembersList(...),
      TeamActivityFeed(...),
    ]),
  );
}
```

### Test Coverage Metrics
- **Critical paths**: 90%+ (auth, team operations, activity scheduling)
- **Feature coverage**: 70%+ (all features have basic tests)
- **Integration tests**: Key user flows (signup→create team→add activity)
- **Widget tests**: All custom widgets with business logic

### Security Patterns
```dart
// Backend: Dual authorization check
Future<Response> deleteTeam(Request request, String teamId) async {
  final userId = getUserId(request);
  if (userId == null) return resp.unauthorized();

  // First check: team membership
  final member = await requireTeamMember(teamId, userId);
  if (member == null) return resp.forbidden();

  // Second check: admin role
  if (member.role != 'admin') return resp.forbidden();

  // Proceed with operation
}
```

## Sources

**Confidence: MEDIUM**

Research based on:
- Established Dart/Flutter best practices (effective Dart guide, Flutter style guide)
- Project context (CLAUDE.md, MEMORY.md, completed 22 refactoring phases)
- Clean Architecture principles (Uncle Bob)
- Riverpod patterns (Riverpod documentation)
- Shelf framework patterns (Dart shelf package documentation)

**Note:** Unable to access live documentation or Context7 due to tool restrictions. Recommendations based on training data knowledge of Dart 3.0+ and Flutter 3.10+ patterns current as of January 2025. Specific package versions and 2026 ecosystem changes not verified.

**Verification needed:**
- Current Dart/Flutter analyzer rules and recommendations (2026)
- Latest Riverpod generator patterns
- Shelf middleware ecosystem updates
- Flutter 3.x widget best practices evolution
