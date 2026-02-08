# Phase 1: Test Infrastructure - Research

**Researched:** 2026-02-08
**Domain:** Dart testing infrastructure, model serialization, test data patterns
**Confidence:** HIGH

## Summary

Phase 1 establishes comprehensive test infrastructure for both backend (Dart/Shelf) and frontend (Flutter) to enable safe refactoring in subsequent phases. The codebase has 27 backend models and 33 frontend models requiring roundtrip tests, test data factories, and mock infrastructure. The frontend already uses Mocktail with established patterns in `test/helpers/`, while the backend has zero test infrastructure currently. The decision to use Mockito (with @GenerateMocks) for backend creates a split-library approach that aligns with Dart ecosystem norms: Mockito for backend/server testing, Mocktail for Flutter widget testing.

**Key finding:** Backend models use `DateTime` directly from Supabase (PostgreSQL timestamps), while frontend models parse ISO 8601 strings—this asymmetry requires careful roundtrip test design.

**Primary recommendation:** Implement simple factory functions (not builders) for test data, use Equatable for model equality, organize backend tests to mirror lib/ structure exactly, and create mock Supabase client wrapper for service-level backend tests.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Test Data Strategy**
  - Factories cover ALL core models from day one: User, Team, TeamMember, Activity, MiniActivity, Fine, Message, Tournament, Achievement (and sub-models)
  - Test data uses realistic Norwegian names and data (e.g., 'Ola Nordmann', 'ola@example.no') — not obvious test markers
  - Mocking library: Mockito (package:mockito) with @GenerateMocks

- **Model Roundtrip Scope**
  - Roundtrip tests cover BOTH backend and frontend models
  - Roundtrip = structural equality: `fromJson(toJson(model)) == model`
  - Models get == operator and hashCode implementation (equatable or manual) to enable clean assertions
  - Each model tested with TWO variants: all optional fields null, and all fields populated

- **Test Organization & Naming**
  - Shared test helpers centralized: `test/helpers/` for backend, `test/helpers/` for frontend
  - Test file names mirror source file names: `user_service_test.dart` for `user_service.dart`
  - Test directory structure mirrors `lib/` exactly: `test/services/team_service_test.dart` for `lib/services/team_service.dart`
  - Test descriptions (group/test names) in Norwegian: `group('Brukerservice')`, `test('returnerer bruker fra id')`

### Claude's Discretion
- Factory pattern: simple functions vs builder pattern — pick what fits the codebase best
- Valid-only factories vs including invalid-state helpers — determine based on test suite needs
- Mock database approach: stubbed responses vs in-memory fake — pick what catches real bugs
- Service test isolation level: full isolation vs allowing integration between services
- Auth mock infrastructure: whether to include auth middleware test helpers or test auth separately

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope

</user_constraints>

## Standard Stack

### Core Testing Libraries

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| test | ^1.25.0 | Dart test framework | Official Dart team package, universal for Dart testing |
| flutter_test | SDK | Flutter widget testing | Bundled with Flutter SDK, required for widget tests |
| mockito | ^5.4.4 | Backend mocking (code-gen) | Official Dart team package, mature code generation support |
| mocktail | ^1.0.0 | Frontend mocking (no code-gen) | Already in use, null-safe by design, zero-config approach |
| equatable | ^2.0.5 | Model equality | De facto standard for value equality in Dart/Flutter |
| build_runner | ^2.4.0 | Code generation runner | Required for Mockito @GenerateMocks code generation |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| clock | ^1.1.1 | Time mocking | For testing time-dependent code (statistics, instances) |
| fake_async | ^1.3.1 | Async time control | For testing async code with time dependencies |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Mockito (backend) | Mocktail | Mockito requires build_runner but provides better IDE support for generated mocks; Mocktail is simpler but manual mock class declarations |
| Equatable | Manual == and hashCode | Equatable eliminates boilerplate and prevents equality bugs; manual implementation gives more control but is error-prone |
| Simple factories | Builder pattern | Builders allow chaining and complex customization but add cognitive overhead; simple factories are sufficient for this codebase's model complexity |

**Installation:**

Backend (add to `backend/pubspec.yaml`):
```yaml
dev_dependencies:
  test: ^1.25.0
  mockito: ^5.4.4
  build_runner: ^2.4.0
  equatable: ^2.0.5
  clock: ^1.1.1
```

Frontend (already has flutter_test, mocktail; add):
```yaml
dependencies:
  equatable: ^2.0.5  # Move from dev to main for model classes
dev_dependencies:
  clock: ^1.1.1
```

## Architecture Patterns

### Recommended Backend Test Structure

```
backend/
├── lib/
│   ├── models/
│   ├── services/
│   └── api/
└── test/
    ├── helpers/
    │   ├── test_data.dart         # All test data factories
    │   ├── mock_supabase.dart     # Mock Supabase client
    │   └── test_helpers.dart      # Common test utilities
    ├── models/
    │   ├── user_test.dart         # Model roundtrip tests
    │   ├── team_test.dart
    │   └── ...                    # One per model file
    ├── services/
    │   ├── user_service_test.dart
    │   ├── team_service_test.dart
    │   └── ...
    └── api/
        └── (handlers tested via integration tests in Phase 3+)
```

### Frontend Test Structure (Already Established)

```
app/
├── lib/
│   ├── data/models/
│   ├── features/
│   └── core/
└── test/
    ├── helpers/
    │   ├── test_data.dart         # Already exists, expand factories
    │   ├── mock_repositories.dart # Already exists
    │   ├── test_app.dart          # Already exists
    │   └── test_scenario.dart     # Already exists (part of test_app.dart)
    ├── models/                    # NEW: Add roundtrip tests
    │   ├── user_test.dart
    │   ├── team_test.dart
    │   └── ...
    └── features/                  # Already exists
```

### Pattern 1: Test Data Factories (Simple Functions)

**What:** Static factory functions with default valid values and optional parameter overrides
**When to use:** For creating test instances of models with realistic data
**Why not builders:** Models in this codebase are relatively flat; builder pattern adds unnecessary complexity

**Example (Backend):**
```dart
// backend/test/helpers/test_data.dart
import 'package:backend/models/user.dart';

class TestUserFactory {
  static int _counter = 0;

  static User create({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    _counter++;
    return User(
      id: id ?? 'user-$_counter',
      email: email ?? 'ola.nordmann$_counter@example.no',
      name: name ?? 'Ola Nordmann $_counter',
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  static void reset() => _counter = 0;
}

// Call resetAllTestFactories() in setUp()
void resetAllTestFactories() {
  TestUserFactory.reset();
  TestTeamFactory.reset();
  // ... all factories
}
```

### Pattern 2: Model Roundtrip Tests with Equatable

**What:** Test that `fromJson(toJson(model)) == model` for structural equality
**When to use:** For every model class in both backend and frontend
**Why Equatable:** Eliminates manual == and hashCode implementation, prevents equality bugs

**Example:**
```dart
// Source: https://github.com/felangel/equatable/blob/master/README.md
import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, createdAt];

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Test file: backend/test/models/user_test.dart
void main() {
  group('User', () {
    test('roundtrip med alle felt populert', () {
      final original = User(
        id: 'user-1',
        email: 'ola@example.no',
        name: 'Ola Nordmann',
        avatarUrl: 'https://example.com/avatar.jpg',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = original.toJson();
      final decoded = User.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = User(
        id: 'user-2',
        email: 'test@example.no',
        name: 'Test Bruker',
        avatarUrl: null, // Optional field
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = original.toJson();
      final decoded = User.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
```

### Pattern 3: Mock Supabase Client (Backend)

**What:** Mock wrapper around Supabase client for service-level testing
**When to use:** For testing backend services without real database connection
**Why needed:** Backend services receive SupabaseClient in constructor, need to stub `.from()`, `.select()`, `.insert()`, etc.

**Example:**
```dart
// Source: https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md
// backend/test/helpers/mock_supabase.dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase/supabase.dart';

@GenerateMocks([SupabaseClient, SupabaseQueryBuilder, PostgrestFilterBuilder])
import 'mock_supabase.mocks.dart';

// Helper to set up common query stubs
class MockSupabaseHelper {
  final MockSupabaseClient client;
  final Map<String, MockSupabaseQueryBuilder> _builders = {};

  MockSupabaseHelper(this.client);

  void setupTable(String table, List<Map<String, dynamic>> rows) {
    final builder = _builders[table] ?? MockSupabaseQueryBuilder();
    _builders[table] = builder;

    when(client.from(table)).thenReturn(builder);

    final filter = MockPostgrestFilterBuilder();
    when(builder.select(any)).thenReturn(filter);
    when(filter.eq(any, any)).thenReturn(filter);

    // Stub the actual data fetch
    when(filter.then(any)).thenAnswer((_) async => rows);
  }
}

// Usage in test:
// var mockClient = MockSupabaseClient();
// var helper = MockSupabaseHelper(mockClient);
// helper.setupTable('users', [{'id': 'user-1', 'name': 'Ola'}]);
```

### Pattern 4: Frontend Mock Repositories (Already Established)

**What:** Mocktail-based mocks for repositories with helper setup methods
**When to use:** Already used extensively in frontend widget tests
**Why keep it:** Frontend already uses Mocktail, established patterns work well

**Example from existing codebase:**
```dart
// app/test/helpers/mock_repositories.dart (already exists)
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProviders {
  final MockAuthRepository authRepository;

  MockProviders() : authRepository = MockAuthRepository();

  void setupAuthenticatedUser(User user) {
    when(() => authRepository.getCurrentUser())
        .thenAnswer((_) async => user);
  }

  List<Object> get overrides => [
    authRepositoryProvider.overrideWithValue(authRepository),
  ];
}
```

### Anti-Patterns to Avoid

- **DateTime.now() in production code:** Untestable; use `clock.now()` from `package:clock` instead (Source: [Controlling time in Dart unit tests](https://iiro.dev/controlling-time-with-package-clock/))
- **Assuming system timezone:** Backend receives DateTime from Postgres, frontend parses ISO strings—different contexts require explicit handling (Source: [Supabase DateTime handling](https://github.com/supabase/supabase-flutter/issues/845))
- **Mixing Mockito and Mocktail in same project:** Creates confusion; keep Mockito in backend, Mocktail in frontend
- **Not resetting factory counters:** Leads to flaky tests; always call `resetAllTestFactories()` in `setUp()`
- **Manual == without @override:** Easy to forget nullable fields; use Equatable or be extremely careful

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Model equality | Manual `==` and `hashCode` | `package:equatable` | Handles nullables, lists, nested objects correctly; prevents subtle equality bugs |
| Time mocking | Custom clock wrapper | `package:clock` | Official Dart team package, integrates with fake_async, battle-tested |
| Mock generation | Manual mock classes | `@GenerateMocks` (backend) or Mocktail (frontend) | Code generation eliminates boilerplate, catches signature changes at compile-time |
| Test data builders | Complex builder classes | Simple factory functions | This codebase's models are flat enough that builders add unnecessary complexity |
| Supabase query mocking | Full in-memory database | Stubbed query responses | Backend services are thin wrappers around DB calls; stub the responses, not the entire DB |

**Key insight:** Test infrastructure is where "don't reinvent the wheel" matters most—Dart ecosystem has mature, battle-tested solutions for all common testing problems.

## Common Pitfalls

### Pitfall 1: DateTime Serialization Asymmetry (Backend vs Frontend)

**What goes wrong:** Backend receives `DateTime` objects directly from Supabase (PostgreSQL driver parses timestamps), but frontend models parse ISO 8601 strings from JSON API responses. Roundtrip tests fail due to timezone or precision differences.

**Why it happens:** PostgreSQL `TIMESTAMPTZ` columns return `DateTime` objects in backend Dart code, but API responses serialize to ISO 8601 strings that frontend parses.

**How to avoid:**
- Backend models: Accept `DateTime` from `fromJson` but also handle string fallback:
  ```dart
  createdAt: row['created_at'] is DateTime
      ? row['created_at']
      : DateTime.parse(row['created_at'].toString())
  ```
- Frontend models: Always parse from string: `DateTime.parse(json['created_at'] as String)`
- Roundtrip tests: Use UTC timestamps only, avoid local time in test data
- Source: [Supabase DateTime discussion](https://github.com/supabase/supabase-flutter/issues/845)

**Warning signs:**
- Tests fail with "Expected: 2024-01-15T10:30:00.000Z, Actual: 2024-01-15T11:30:00.000"
- Roundtrip tests pass on macOS, fail in CI (different timezones)

### Pitfall 2: DST Transitions Breaking Time-Dependent Tests

**What goes wrong:** Tests that calculate time differences (e.g., "activities in next 24 hours") fail around Daylight Saving Time transitions because `Duration(hours: 24)` doesn't equal "tomorrow at same time" on DST days.

**Why it happens:** Norwegian timezone (Europe/Oslo) observes DST; DateTime.now() + Duration(hours: 24) yields only 23 or 25 real hours depending on DST transition direction.

**How to avoid:**
- Use `clock.now()` from package:clock instead of DateTime.now() so tests can mock time
- In tests, use fixed UTC timestamps: `DateTime.utc(2024, 6, 15)` (avoid March/October DST boundaries)
- For "relative to now" tests, use `withClock()` from package:clock to freeze time
- Source: [DST Dart and DateTime](https://csdcorp.com/blog/coding/dst-dart-and-datetime/)

**Warning signs:**
- Tests pass in summer, fail in winter (or vice versa)
- CI builds in UTC timezone pass, local macOS builds fail
- Intermittent failures on specific dates (last Sunday of March/October)

### Pitfall 3: Mockito Build Runner Not Generating Mocks

**What goes wrong:** After adding `@GenerateMocks([ClassName])`, running `dart run build_runner build` produces no `.mocks.dart` file or silently fails.

**Why it happens:**
- Annotation must be on an `import` statement, not standalone: `@GenerateMocks([Foo]) import 'foo.mocks.dart';`
- build_runner doesn't watch test files by default
- Conflicting builder versions in dependency tree

**How to avoid:**
- Correct annotation syntax: `@GenerateMocks([UserService]) import 'user_service_test.mocks.dart';`
- Run with explicit test path: `dart run build_runner build --build-filter="test/**"`
- Clean before build: `dart run build_runner clean && dart run build_runner build`
- Check build_runner version compatibility with mockito version
- Source: [Mockito NULL_SAFETY_README](https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md)

**Warning signs:**
- Import of `.mocks.dart` shows red in IDE
- No generated files in project after build_runner completes
- Build completes instantly (< 1 second) with no output

### Pitfall 4: Equatable Props Missing Nullable Fields

**What goes wrong:** Two model instances that should be equal fail equality check because nullable fields weren't included in `props` getter.

**Why it happens:** Developer forgets to add newly added nullable field to `props` list, or assumes nulls don't matter for equality.

**How to avoid:**
- Use `List<Object?>` (with question mark) for props when model has nullable fields
- Include ALL fields in props, even nullable ones: `@override List<Object?> get props => [id, name, avatarUrl];`
- Write roundtrip tests with BOTH variants (all null, all populated) to catch this
- Source: [Equatable with nullable properties](https://github.com/felangel/equatable/blob/master/README.md)

**Warning signs:**
- Roundtrip test passes with all fields populated, fails with nulls
- Test failure message shows "Expected: User(..., avatarUrl: null), Actual: User(..., avatarUrl: null)" but still not equal
- HashCode differs even though all visible fields match

### Pitfall 5: Factory Counter Bleed Between Tests

**What goes wrong:** Second test in suite gets `user-4` when expecting `user-1` because previous test incremented the factory counter.

**Why it happens:** Factory classes use static counters to ensure unique IDs, but counters aren't reset between tests.

**How to avoid:**
- Call `resetAllTestFactories()` in `setUp()` for every test file
- Create centralized reset function that resets ALL factory counters
- Frontend already has this pattern: `resetAllTestFactories()` in `test/helpers/test_data.dart`
- Source: Existing frontend codebase pattern

**Warning signs:**
- First test passes, subsequent tests fail with "Expected user-1, got user-5"
- Tests pass individually, fail when run as suite
- Tests pass in one order, fail when reordered

## Code Examples

Verified patterns from official sources:

### Generate Mockito Mocks for Backend Service Testing

```dart
// Source: https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md
// backend/test/services/user_service_test.dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:backend/services/user_service.dart';
import 'package:supabase/supabase.dart';

@GenerateMocks([SupabaseClient])
import 'user_service_test.mocks.dart';

void main() {
  late MockSupabaseClient mockClient;
  late UserService service;

  setUp(() {
    mockClient = MockSupabaseClient();
    service = UserService(mockClient);
  });

  group('UserService', () {
    test('getUserById returnerer bruker fra database', () async {
      // Arrange
      final mockData = {'id': 'user-1', 'name': 'Ola Nordmann'};
      when(mockClient.from('users').select().eq('id', 'user-1'))
          .thenAnswer((_) async => [mockData]);

      // Act
      final user = await service.getUserById('user-1');

      // Assert
      expect(user.name, equals('Ola Nordmann'));
      verify(mockClient.from('users').select().eq('id', 'user-1')).called(1);
    });
  });
}
```

### Model with Equatable for Easy Equality Testing

```dart
// Source: https://github.com/felangel/equatable/blob/master/README.md
import 'package:equatable/equatable.dart';

class Team extends Equatable {
  final String id;
  final String name;
  final String? sport;
  final String? inviteCode;
  final DateTime createdAt;

  const Team({
    required this.id,
    required this.name,
    this.sport,
    this.inviteCode,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, sport, inviteCode, createdAt];

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] as String,
      name: json['name'] as String,
      sport: json['sport'] as String?,
      inviteCode: json['invite_code'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sport': sport,
      'invite_code': inviteCode,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

### Test Data Factory with Norwegian Realistic Data

```dart
// backend/test/helpers/test_data.dart
class TestTeamFactory {
  static int _counter = 0;

  static Team create({
    String? id,
    String? name,
    String? sport,
    String? inviteCode,
    DateTime? createdAt,
  }) {
    _counter++;
    return Team(
      id: id ?? 'team-$_counter',
      name: name ?? 'Åsen Fotballklubb $_counter',
      sport: sport ?? 'Fotball',
      inviteCode: inviteCode ?? 'ASENFK$_counter',
      createdAt: createdAt ?? DateTime.parse('2024-01-15T10:00:00Z'),
    );
  }

  static void reset() => _counter = 0;
}

class TestTeamMemberFactory {
  static int _counter = 0;

  static final List<String> norwegianNames = [
    'Ola Nordmann',
    'Kari Hansen',
    'Per Olsen',
    'Lise Andersen',
    'Erik Johansen',
    'Maria Nilsen',
  ];

  static TeamMember create({
    String? id,
    String? userId,
    String? teamId,
    String? userName,
    bool isAdmin = false,
    bool isCoach = false,
    bool isFineBoss = false,
    DateTime? joinedAt,
  }) {
    _counter++;
    return TeamMember(
      id: id ?? 'member-$_counter',
      userId: userId ?? 'user-$_counter',
      teamId: teamId ?? 'team-1',
      userName: userName ?? norwegianNames[_counter % norwegianNames.length],
      isAdmin: isAdmin,
      isCoach: isCoach,
      isFineBoss: isFineBoss,
      joinedAt: joinedAt ?? DateTime.parse('2024-01-15T10:00:00Z'),
    );
  }

  static void reset() => _counter = 0;
}
```

### Roundtrip Test Template

```dart
// backend/test/models/team_test.dart
import 'package:test/test.dart';
import 'package:backend/models/team.dart';

void main() {
  group('Team', () {
    test('roundtrip med alle felt populert', () {
      final original = Team(
        id: 'team-1',
        name: 'Åsen FK',
        sport: 'Fotball',
        inviteCode: 'ASENFK2024',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = original.toJson();
      final decoded = Team.fromJson(json);

      expect(decoded, equals(original));
    });

    test('roundtrip med alle valgfrie felt null', () {
      final original = Team(
        id: 'team-2',
        name: 'Test Lag',
        sport: null,          // Optional
        inviteCode: null,     // Optional
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = original.toJson();
      final decoded = Team.fromJson(json);

      expect(decoded, equals(original));
    });
  });
}
```

### Using Clock Package for Time-Dependent Tests

```dart
// Source: https://iiro.dev/controlling-time-with-package-clock/
import 'package:clock/clock.dart';
import 'package:test/test.dart';

void main() {
  test('aktiviteter innen 24 timer', () {
    // Freeze time to avoid DST and timezone issues
    final fixedTime = DateTime.utc(2024, 6, 15, 12, 0, 0);

    withClock(Clock.fixed(fixedTime), () {
      // Now clock.now() returns fixedTime
      final now = clock.now();
      final tomorrow = now.add(Duration(hours: 24));

      expect(tomorrow.difference(now).inHours, equals(24));
      // Test code that uses clock.now() instead of DateTime.now()
    });
  });
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Mockito without null safety | @GenerateNiceMocks | Dart 2.12+ (2021) | Nice mocks return safe defaults instead of throwing on unstubbed calls |
| Manual mock classes | Code generation with @GenerateMocks | Mockito 5.0+ (2021) | Eliminates boilerplate, catches signature changes at compile-time |
| DateTime.now() everywhere | package:clock | Dart 2.12+ ecosystem standard | Makes time-dependent code testable |
| Manual == and hashCode | package:equatable | Flutter community standard (2019+) | Prevents equality bugs, especially with nullable fields |
| build_runner watch | build_runner build | Dart 2.17+ recommendation | Watch mode has flaky behavior on macOS; explicit build is more reliable |

**Deprecated/outdated:**
- **Mockito without null safety:** Pre-Dart 2.12 syntax used `@GenerateMocks` without nice mocks; now @GenerateNiceMocks is standard (Source: [Mockito NULL_SAFETY_README](https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md))
- **DateTime.now() in testable code:** Ecosystem moved to `package:clock` (Source: [Controlling time in Dart tests](https://iiro.dev/controlling-time-with-package-clock/))
- **json_serializable for simple models:** Over-engineering for this codebase; manual fromJson/toJson is sufficient and more maintainable (Source: [Flutter JSON serialization guide](https://docs.flutter.dev/data-and-backend/serialization/json))

## Open Questions

1. **Backend Supabase Mock Depth**
   - What we know: Supabase client returns `PostgrestResponse` objects, services call `.from()`, `.select()`, `.eq()`, `.insert()`, etc.
   - What's unclear: Should we mock the entire query chain (client.from().select().eq()) or create a simpler MockSupabaseHelper that stubs table responses?
   - Recommendation: Start with simplified MockSupabaseHelper (stub table → rows mapping), add query chain mocking only if needed for complex tests

2. **Model Equality: Equatable vs Manual**
   - What we know: Equatable eliminates boilerplate but adds dependency; manual gives control but is error-prone
   - What's unclear: Should ALL models use Equatable, or only models used in tests?
   - Recommendation: Use Equatable for ALL models to prevent future bugs; the dependency is lightweight and universally accepted in Dart/Flutter

3. **Test Coverage for Sub-Models**
   - What we know: Models like Activity have nested classes (ActivityInstance, ActivityResponse); similar for Tournament, MiniActivity
   - What's unclear: Do sub-models need separate roundtrip tests, or test them only via parent model?
   - Recommendation: Test sub-models separately—they have independent serialization logic that can fail independently

4. **Auth Middleware Test Helpers**
   - What we know: Backend has auth middleware (`requireAuth`) used by all handlers
   - What's unclear: Should Phase 1 include auth test helpers, or defer until handler testing in Phase 3+?
   - Recommendation: Defer to Phase 3—Phase 1 focuses on models and data layer, not HTTP middleware

## Sources

### Primary (HIGH confidence)
- [Dart Mockito library](https://github.com/dart-lang/mockito) - Official Dart team package, @GenerateMocks patterns
- [Mockito NULL_SAFETY_README](https://github.com/dart-lang/mockito/blob/master/NULL_SAFETY_README.md) - Code generation workflow
- [Equatable package](https://github.com/felangel/equatable) - Value equality patterns
- [Dart testing documentation](https://dart.dev/tools/testing) - Official testing guide
- [build_runner package](https://pub.dev/packages/build_runner) - Code generation runner

### Secondary (MEDIUM confidence)
- [Mocktail vs Mockito comparison](https://github.com/felangel/mocktail) - Null-safe mocking approaches
- [Flutter JSON serialization guide](https://docs.flutter.dev/data-and-backend/serialization/json) - Serialization patterns
- [Controlling time in Dart tests](https://iiro.dev/controlling-time-with-package-clock/) - Clock package usage
- [Supabase DateTime handling](https://github.com/supabase/supabase-flutter/issues/845) - PostgreSQL timestamp parsing
- [DST and DateTime testing](https://csdcorp.com/blog/coding/dst-dart-and-datetime/) - Timezone pitfalls

### Tertiary (LOW confidence, marked for validation)
- [Test Data Factory patterns](https://eliasnogueira.com/test-data-factory-why-and-how-to-use/) - General test data guidance (not Dart-specific)
- [Builder vs Factory patterns](http://www.natpryce.com/articles/000714.html) - Pattern comparison (not Dart-specific)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All packages are official Dart team or universally accepted in Flutter ecosystem
- Architecture: HIGH - Frontend patterns already established, backend mirrors standard Dart project structure
- Pitfalls: HIGH - Verified with Context7, official docs, and community-known issues

**Codebase context:**
- Backend: 27 model files, 34 service files, 38 handler files
- Frontend: 33 model files, existing test infrastructure with Mocktail
- Current state: Backend has ZERO tests; frontend has widget tests but no model roundtrip tests
- Models to cover: User, Team, TeamMember, TrainerType, Activity, ActivityInstance, ActivityResponse, MiniActivity (10+ sub-models), Fine, FineRule, Message, Tournament (6+ sub-models), Achievement (4+ sub-models), Document, Absence, Notification, PointsConfig, Season, Statistics, Stopwatch, Test

**Research date:** 2026-02-08
**Valid until:** 2026-03-08 (30 days - stable ecosystem)
