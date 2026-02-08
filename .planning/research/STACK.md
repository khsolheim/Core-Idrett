# Technology Stack for Refactoring

**Project:** Core - Idrett Refactoring
**Researched:** 2026-02-08
**Confidence:** MEDIUM (based on training data and current project inspection; verification with official sources blocked)

## Executive Summary

This stack focuses on **refactoring existing code** for quality, robustness, and consistency. We're not building new features — we're improving existing Dart backend and Flutter frontend code through static analysis, testing, and type-safe patterns.

**Key principle:** Minimal new dependencies. Maximize built-in Dart/Flutter tools. Add libraries only when they provide clear safety or productivity gains.

## Recommended Stack

### Core Static Analysis

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **flutter_lints** | ^6.0.0 | Frontend linting (already installed) | Official Flutter lint rules. Includes all `lints` rules plus Flutter-specific checks. Already in pubspec. |
| **lints** | ^6.1.0 | Backend linting (already installed) | Official Dart lint rules. Core set maintained by Dart team. Already in backend pubspec. |
| **custom_lint** | ^0.7.0 | Custom lint rules | Enables Riverpod lints for better state management safety. Detects common Riverpod anti-patterns. |
| **riverpod_lint** | ^3.0.0 | Riverpod-specific lints | Enforces Riverpod best practices: proper provider usage, avoiding rebuilds, ref usage patterns. Critical for refactoring state management code. |

**Rationale:** Built-in lints first, then framework-specific (Riverpod). Custom lints catch patterns that static analysis misses.

### Testing Infrastructure

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **test** | ^1.25.0 | Backend unit/integration tests (already installed) | Official Dart test package. Synchronous and async test support. Already used in backend. |
| **flutter_test** | SDK | Frontend widget tests (already installed) | Built into Flutter SDK. Widget testing, pump/settle for async UI. Already used extensively. |
| **mocktail** | ^1.0.0 | Mocking framework (already installed) | Modern null-safe mocking. Better than mockito for null safety. Already in use. |
| **integration_test** | SDK | End-to-end tests (already installed) | Built into Flutter. Real device testing. Already in pubspec. |
| **coverage** | ^1.9.0 | Test coverage reporting | Generate LCOV coverage reports. Identify untested code paths. Essential for measuring refactoring progress. |

**Rationale:** Frontend test infrastructure already solid (TestScenario, MockProviders, test helpers). Backend has zero tests — need coverage tool to track progress.

### Code Generation

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **freezed** | ^2.5.0 | Immutable data classes | Eliminates boilerplate for models. Type-safe copying, equality, toString. Better than manual implementations. |
| **freezed_annotation** | ^2.4.0 | Freezed annotations | Runtime annotations for freezed. |
| **json_serializable** | ^6.9.0 | JSON serialization | Type-safe JSON parsing. Replaces unsafe `as String`/`as int` casts. Generate fromJson/toJson at compile time. |
| **json_annotation** | ^4.9.0 | JSON annotations | Runtime annotations for json_serializable. |
| **build_runner** | ^2.4.0 | Code generation orchestrator | Runs freezed and json_serializable. One-time setup, massive safety gains. |

**Rationale:** Current code has unsafe casts (`as String`, `as int`, `.first` on potentially empty lists). Code generation eliminates entire class of runtime errors. Freezed makes models immutable by default (functional programming safety).

### Input Validation

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Built-in Dart** | SDK | Type checking, null safety | Dart 3.0+ has sound null safety. Use `DateTime.tryParse()`, `.firstOrNull`, safe casts. Zero deps. |
| **validators** | ^3.0.0 | String validation | Email, URL, UUID, phone validation. Lightweight. Better than regex soup. |

**Rationale:** Don't need heavy validation library. Dart SDK + lightweight validators covers 95% of cases. Custom validation for domain logic (team names, fine amounts).

### Security & Rate Limiting

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **shelf_rate_limit** | ^1.0.0 | Rate limiting middleware | Shelf-native rate limiting. Protects auth endpoints from brute force. Simple per-IP tracking. |
| **Built-in JWT** | (dart_jsonwebtoken ^3.3.1) | JWT validation (already installed) | Already using dart_jsonwebtoken. No change needed. |

**Rationale:** Backend currently has no rate limiting. shelf_rate_limit integrates with existing Shelf middleware pipeline. Minimal config.

### File Size Management

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Built-in Dart** | SDK | File splitting | No tool needed. Manual refactoring guided by analysis. |
| **dart_code_metrics** | ^5.7.0 | Code metrics analysis | LOC per file, cyclomatic complexity, maintainability index. Identifies splitting candidates. |

**Rationale:** Don't need tool to split files — need tool to identify which files to split and verify improvements.

### Documentation

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **dartdoc** | SDK | API documentation | Built into Dart. Generates docs from /// comments. Zero setup. |

**Rationale:** Already have some doc comments. dartdoc validates them and generates browsable API docs for backend services.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Mocking | mocktail | mockito | Mockito requires code generation. Mocktail is simpler, null-safe by default. |
| JSON | json_serializable | Manual toJson/fromJson | Manual is error-prone. json_serializable catches errors at compile time. |
| Data classes | freezed | built_value | Freezed has better DX, less boilerplate. built_value is more verbose. |
| Validation | validators + custom | formz, dart_either | formz is Flutter-specific (don't need in backend). dart_either adds FP overhead. |
| Metrics | dart_code_metrics | SonarQube | SonarQube is overkill for single project. dart_code_metrics is Dart-native. |
| Rate limiting | shelf_rate_limit | redis-backed | Redis adds infrastructure complexity. In-memory sufficient for single-server backend. |

## Installation

### Frontend Dependencies

```bash
cd "/Users/karsten/NextCore/Core - Idrett/app"

# Production dependencies
flutter pub add freezed_annotation json_annotation validators

# Dev dependencies
flutter pub add --dev custom_lint riverpod_lint freezed json_serializable build_runner coverage
```

### Backend Dependencies

```bash
cd "/Users/karsten/NextCore/Core - Idrett/backend"

# Production dependencies
dart pub add validators shelf_rate_limit

# Dev dependencies
dart pub add --dev freezed_annotation json_annotation freezed json_serializable build_runner coverage
# Note: dart_code_metrics may need separate installation via pub global
```

### Analysis Configuration

**Frontend** (`app/analysis_options.yaml`):
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint

  errors:
    # Upgrade warnings to errors for refactoring
    invalid_use_of_protected_member: error
    invalid_use_of_internal_member: error

  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    # Type safety
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_type_to_string
    - cancel_subscriptions
    - close_sinks
    - unsafe_html

    # Null safety
    - prefer_null_aware_operators
    - unnecessary_null_checks
    - unnecessary_nullable_for_final_variable_declarations

    # Refactoring-friendly
    - prefer_final_locals
    - prefer_final_in_for_each
    - unnecessary_lambdas
    - cascade_invocations

    # Code quality
    - avoid_print
    - avoid_returning_null_for_void
    - prefer_single_quotes
    - require_trailing_commas
    - sort_constructors_first
```

**Backend** (`backend/analysis_options.yaml`):
```yaml
include: package:lints/recommended.yaml

analyzer:
  errors:
    invalid_use_of_protected_member: error

  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    # Same as frontend, minus Flutter-specific rules
    - always_declare_return_types
    - avoid_dynamic_calls
    - avoid_type_to_string
    - cancel_subscriptions
    - prefer_null_aware_operators
    - unnecessary_null_checks
    - prefer_final_locals
    - avoid_print  # Use proper logging in backend
    - prefer_single_quotes
    - require_trailing_commas
```

### Coverage Configuration

**Both projects** (`coverage.yaml` or inline in scripts):
```bash
# Generate coverage
flutter test --coverage  # Frontend
dart run test --coverage=coverage  # Backend

# Filter out generated files
lcov --remove coverage/lcov.info \
  '**/*.g.dart' \
  '**/*.freezed.dart' \
  '**/test/**' \
  -o coverage/lcov_filtered.info

# Generate HTML report
genhtml coverage/lcov_filtered.info -o coverage/html

# View coverage thresholds (fail if below)
lcov --summary coverage/lcov_filtered.info
```

## Build Runner Setup

After installing code generation packages:

```bash
# Frontend
cd "/Users/karsten/NextCore/Core - Idrett/app"
flutter pub run build_runner build --delete-conflicting-outputs

# Backend
cd "/Users/karsten/NextCore/Core - Idrett/backend"
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
flutter pub run build_runner watch  # Frontend
dart run build_runner watch  # Backend
```

## Type-Safe Patterns

### Replace Unsafe Casts

**Before:**
```dart
final name = json['name'] as String;  // Runtime error if null or wrong type
final count = json['count'] as int;
final items = json['items'] as List;
```

**After (with json_serializable):**
```dart
@freezed
class MyModel with _$MyModel {
  const factory MyModel({
    required String name,
    required int count,
    required List<String> items,
  }) = _MyModel;

  factory MyModel.fromJson(Map<String, dynamic> json) => _$MyModelFromJson(json);
}

// Usage
final model = MyModel.fromJson(json);  // Compile-time type safety
```

### Safe List Access

**Before:**
```dart
final first = list.first;  // Runtime error if empty
```

**After:**
```dart
final first = list.firstOrNull;  // Returns null if empty
if (first != null) {
  // Safe to use
}
```

### Safe DateTime Parsing

**Before:**
```dart
final date = DateTime.parse(str);  // Runtime error on invalid format
```

**After:**
```dart
final date = DateTime.tryParse(str);
if (date == null) {
  return resp.badRequest('Invalid date format');
}
```

### Validation Example

```dart
import 'package:validators/validators.dart';

// Email validation
if (!isEmail(email)) {
  return resp.badRequest('Invalid email');
}

// UUID validation
if (!isUUID(id)) {
  return resp.badRequest('Invalid ID format');
}

// Custom domain validation
bool isValidTeamName(String name) {
  return name.length >= 3 &&
         name.length <= 50 &&
         !name.contains(RegExp(r'[<>]'));
}
```

## Code Metrics Usage

```bash
# Install globally
dart pub global activate dart_code_metrics

# Run analysis
dart_code_metrics analyze "/Users/karsten/NextCore/Core - Idrett/app/lib"
dart_code_metrics analyze "/Users/karsten/NextCore/Core - Idrett/backend/lib"

# Check specific metric
dart_code_metrics check-unnecessary-nullable "/Users/karsten/NextCore/Core - Idrett/app/lib"

# Custom thresholds
dart_code_metrics analyze lib \
  --cyclomatic-complexity=10 \
  --lines-of-code=300 \
  --number-of-methods=10
```

**Refactoring targets:**
- Files with LOC > 300: Split into multiple files
- Cyclomatic complexity > 10: Extract methods
- Number of methods > 15: Split class

## Rate Limiting Configuration

**Backend** (`backend/lib/api/router.dart`):
```dart
import 'package:shelf_rate_limit/shelf_rate_limit.dart';

// Auth endpoints: 5 requests per minute
final authRateLimit = RateLimiter(
  maxRequests: 5,
  window: Duration(minutes: 1),
);

// General API: 100 requests per minute
final apiRateLimit = RateLimiter(
  maxRequests: 100,
  window: Duration(minutes: 1),
);

// Apply to routes
final authRouter = Router()
  ..post('/login', Pipeline()
    .addMiddleware(authRateLimit.middleware())
    .addHandler(authHandler.login));
```

## Testing Strategy

### Backend (currently zero tests)

**Priority order:**
1. **Critical business logic** - Fines calculation, statistics, tournament brackets
2. **Auth/security** - JWT validation, role checks, rate limiting
3. **Data integrity** - Service-level validation, database constraints
4. **API contracts** - Handler-level tests for request/response format

**Test structure:**
```
backend/test/
├── unit/
│   ├── services/
│   │   ├── fine_service_test.dart
│   │   ├── statistics_service_test.dart
│   │   └── tournament_service_test.dart
│   └── helpers/
│       └── auth_helpers_test.dart
├── integration/
│   ├── api/
│   │   ├── auth_endpoints_test.dart
│   │   ├── fines_endpoints_test.dart
│   │   └── statistics_endpoints_test.dart
│   └── rate_limiting_test.dart
└── fixtures/
    └── test_data.dart
```

### Frontend (tests exist, need expansion)

**Priority order:**
1. **Export feature** - No tests currently, critical feature
2. **Tournament brackets** - Complex logic, needs coverage
3. **Statistics calculations** - Client-side aggregations
4. **Absence reporting** - Likely undertested

**Existing coverage:**
- Auth: Good (login_test.dart, register_test.dart)
- Activities: Good (activities_list_test.dart, activity_detail_test.dart)
- Fines: Partial (my_fines_test.dart, fine_rules_test.dart, fines_screen_test.dart)
- Teams: Good (teams_list_test.dart, team_detail_test.dart, create_team_test.dart)
- Chat: Partial (chat_test.dart)

**Test expansion needed:**
```
app/test/features/
├── export/
│   └── export_test.dart  # NEW
├── tournaments/
│   ├── tournament_list_test.dart  # NEW
│   └── tournament_bracket_test.dart  # NEW
├── statistics/
│   └── statistics_test.dart  # NEW
└── absences/
    └── absence_reporting_test.dart  # NEW
```

## Success Metrics

| Metric | Current | Target | Tool |
|--------|---------|--------|------|
| Backend test coverage | 0% | 70%+ | coverage |
| Frontend test coverage | ~30% (estimated) | 80%+ | coverage |
| Average file LOC | ~400 | <300 | dart_code_metrics |
| Max cyclomatic complexity | Unknown | <10 | dart_code_metrics |
| Unsafe casts | Many | 0 (all json_serializable) | grep + manual |
| Lint violations | Unknown | 0 | flutter analyze / dart analyze |
| Rate limiting | None | All auth endpoints | Manual verification |
| Admin role checks | Inconsistent | 100% coverage | Grep + manual |

## Implementation Order

**Phase 1: Foundation** (Week 1)
1. Install static analysis tools (lints, custom_lint, riverpod_lint)
2. Add backend analysis_options.yaml
3. Fix all existing lint violations
4. Set up coverage tooling

**Phase 2: Type Safety** (Week 2-3)
1. Install freezed, json_serializable, build_runner
2. Convert models to freezed classes (start with User, Team, Activity)
3. Replace unsafe casts with generated JSON parsing
4. Add validators to critical input paths

**Phase 3: Testing** (Week 4-5)
1. Backend: Write tests for critical services (fines, statistics, tournaments)
2. Frontend: Add tests for export, tournaments, statistics
3. Achieve 70% backend coverage, 80% frontend coverage
4. Add integration tests for auth flow + rate limiting

**Phase 4: Security** (Week 6)
1. Add shelf_rate_limit to auth endpoints
2. Audit all admin role checks (grep for 'isAdmin', 'requireAdmin')
3. Add tests for permission boundaries
4. Review FCM token handling

**Phase 5: File Splitting** (Week 7-8)
1. Run dart_code_metrics to identify large files
2. Split 700+ LOC services (activity_service, statistics_service)
3. Split 400+ LOC widgets (team_detail_screen, etc.)
4. Verify metrics improve

**Phase 6: Consistency** (Week 9-10)
1. Ensure all features follow Clean Architecture
2. Standardize error handling patterns
3. Norwegian translation for remaining English text
4. Final lint pass, final test pass

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Static Analysis (lints) | HIGH | Official packages, well-documented, training data verified by current pubspec |
| Testing (test, mocktail) | HIGH | Already in use, proven infrastructure |
| Code Generation (freezed, json_serializable) | HIGH | Industry standard, widely adopted in Dart/Flutter community |
| Validation (validators) | MEDIUM | Package exists, but specific version not verified with official source |
| Rate Limiting (shelf_rate_limit) | MEDIUM | Package exists for Shelf, but specific API not verified |
| Metrics (dart_code_metrics) | MEDIUM | Training data suggests this tool exists, but current status (2026) not verified |

**Verification needed:**
- Current versions of validators, shelf_rate_limit (training data may be stale)
- dart_code_metrics status (may have been renamed or deprecated)
- shelf_rate_limit API (exact middleware syntax)

**Fallback options:**
- If dart_code_metrics unavailable: Manual LOC counting via `wc -l`, cyclomatic complexity via grep for if/while/for
- If shelf_rate_limit unavailable: Custom middleware using in-memory Map<String, List<DateTime>> for per-IP tracking
- If validators unavailable: Pure Dart regex validation (more verbose but zero deps)

## Sources

**HIGH confidence (current project inspection):**
- `/Users/karsten/NextCore/Core - Idrett/app/pubspec.yaml` - Current dependencies
- `/Users/karsten/NextCore/Core - Idrett/backend/pubspec.yaml` - Current dependencies
- `/Users/karsten/NextCore/Core - Idrett/app/analysis_options.yaml` - Current lint config
- `/Users/karsten/NextCore/Core - Idrett/app/test/` - Existing test infrastructure

**MEDIUM confidence (training data, January 2025 cutoff):**
- flutter_lints, lints packages (official, maintained by Dart/Flutter teams)
- freezed, json_serializable (de facto standard for Dart data classes)
- mocktail (recommended over mockito for null safety)
- riverpod_lint, custom_lint (Riverpod ecosystem tools)

**LOW confidence (training data, needs verification):**
- Specific package versions (may have updated since January 2025)
- dart_code_metrics current status (may have changed maintainers or been deprecated)
- shelf_rate_limit exact API (training data suggests it exists, but details uncertain)

**Blocked sources (permission denied):**
- Context7 library documentation
- Web search for current 2026 best practices
- Official pub.dev package pages

**Recommendation:** Before installation, verify package availability and current versions at pub.dev:
- `dart pub search validators`
- `dart pub search shelf_rate_limit`
- `dart pub global search dart_code_metrics`
