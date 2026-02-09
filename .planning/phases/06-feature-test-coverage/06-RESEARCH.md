# Phase 6: Feature Test Coverage - Research

**Researched:** 2026-02-09
**Domain:** Dart/Flutter Testing for Backend Services and Frontend Widgets
**Confidence:** HIGH

## Summary

Phase 6 focuses on achieving comprehensive test coverage for untested critical features: export service (7 export types), tournament service (bracket generation algorithms), fine service (payment reconciliation with idempotency), and statistics service (edge cases). The project already has strong testing foundations in place—manual mocks using mocktail, test helpers for both backend and frontend, and Norwegian test data factories—following prior decision 01-01 to avoid code generation. The backend uses standard Dart `test` package with manual Supabase mocking, while frontend uses `flutter_test` with Riverpod provider overrides.

The key challenge is that Supabase lacks official mock support, requiring manual HTTP client mocking via `mock_supabase_http_client` for integration-style tests, though the project has chosen a simpler approach of direct service testing with mocked dependencies. Export service must validate 7 data transformation pipelines (leaderboard, attendance, fines, activities, members, plus 2 undocumented types). Tournament bracket generation has complex algorithms (single-elimination with 3/5/8/16 participants, round-robin, bronze finals). Fine service requires rigorous payment reconciliation tests to prevent double-payment bugs. Statistics service must handle edge cases like zero attendance, empty score arrays, and season boundary conditions that could cause division-by-zero or null reference errors.

**Primary recommendation:** Write focused service-level unit tests for backend business logic, widget tests for frontend screens using existing TestScenario patterns, and achieve 70%+ backend/80%+ frontend coverage using `flutter test --coverage` with LCOV reporting.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| test | 1.24+ | Dart backend testing | Official Dart test framework, universal for Dart projects |
| flutter_test | (SDK) | Flutter widget testing | Bundled with Flutter SDK, official testing framework |
| mocktail | 1.0+ | Test mocking | Preferred over mockito—no code generation, better null-safety support |
| riverpod_test | 2.0+ | Riverpod testing helpers | Official Riverpod testing utilities, simplifies provider mocking |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mock_supabase_http_client | 0.3+ | Mock Supabase client | Backend integration tests (NOT current approach) |
| coverage | 1.7+ | LCOV coverage generation | CI/CD coverage reporting |
| test_cov_console | Latest | Console coverage display | Local coverage verification |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mocktail | mockito | Mockito requires code generation (@GenerateMocks), conflicts with 01-01 decision |
| Manual mocks | mock_supabase_http_client | More realistic but slower; project uses direct service mocking for speed |
| Unit tests | Integration tests | Integration tests require Supabase CLI setup; unit tests faster and isolated |

**Installation:**
```bash
# Backend (already installed)
cd backend && dart pub add --dev test mocktail

# Frontend (already installed)
cd app && flutter pub add --dev flutter_test mocktail riverpod_test
```

## Architecture Patterns

### Recommended Project Structure
```
backend/test/
├── services/               # Service-level unit tests (NEW)
│   ├── export_service_test.dart
│   ├── tournament_bracket_test.dart
│   ├── fine_summary_test.dart
│   └── statistics_service_test.dart
├── models/                 # Model serialization tests (EXISTS)
└── helpers/                # Test utilities (EXISTS)

app/test/
├── features/               # Feature widget tests (EXISTS)
│   ├── export/             # NEW
│   │   └── export_screen_test.dart
│   └── mini_activities/    # NEW
│       └── tournament_screen_test.dart
├── models/                 # Model tests (EXISTS)
└── helpers/                # TestScenario, mocks (EXISTS)
```

### Pattern 1: Backend Service Unit Testing
**What:** Test services by mocking Database client, not Supabase directly
**When to use:** All backend service tests (export, tournament, fine, statistics)
**Example:**
```dart
// Source: Existing pattern from backend/test/helpers/test_helpers.dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabase extends Mock implements Database {}
class MockClient extends Mock implements SupabaseClient {}

void main() {
  late MockDatabase db;
  late MockClient client;
  late ExportDataService service;

  setUp(() {
    db = MockDatabase();
    client = MockClient();
    when(() => db.client).thenReturn(client);
    service = ExportDataService(db);
  });

  group('ExportDataService', () {
    test('exportLeaderboard returns correct structure', () async {
      // Arrange: Mock database response
      when(() => client.select('leaderboard_entries',
        filters: any(named: 'filters'),
        order: any(named: 'order'),
      )).thenAnswer((_) async => [
        {'user_id': 'user-1', 'points': 100},
      ]);

      // Act
      final result = await service.exportLeaderboard('team-1');

      // Assert
      expect(result['type'], 'leaderboard');
      expect(result['columns'], ['Plass', 'Bruker', 'Poeng']);
      expect(result['data'], isNotEmpty);
    });
  });
}
```

### Pattern 2: Frontend Widget Testing with Riverpod
**What:** Use TestScenario for provider overrides, pump widgets with test data
**When to use:** All frontend screen/widget tests (export, tournament)
**Example:**
```dart
// Source: https://riverpod.dev/docs/how_to/testing
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_app.dart';

void main() {
  late TestScenario scenario;

  setUp(() {
    scenario = TestScenario();
  });

  testWidgets('ExportScreen shows 7 export options', (tester) async {
    scenario.setupLoggedIn();
    scenario.mocks.setupGetTeam(testTeam);

    await tester.pumpWidget(
      createTestWidget(
        const ExportScreen(teamId: 'team-1'),
        overrides: scenario.overrides,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eksporter data'), findsOneWidget);
    expect(find.byType(ExportOptionCard), findsNWidgets(7));
  });
}
```

### Pattern 3: Edge Case Testing for Statistics
**What:** Test boundary conditions that could cause crashes (empty arrays, zero division)
**When to use:** Statistics service tests covering edge cases
**Example:**
```dart
// Pattern for edge case testing
test('getLeaderboard handles team with zero members', () async {
  when(() => teamService.getTeamMemberUserIds('team-1'))
      .thenAnswer((_) async => []); // Empty team

  final result = await service.getLeaderboard('team-1');

  expect(result, isEmpty);
});

test('getTeamAttendance handles zero activities', () async {
  when(() => client.select('activities', filters: any(named: 'filters')))
      .thenAnswer((_) async => []); // No activities

  final result = await service.getTeamAttendance('team-1');

  expect(result.every((r) => r.percentage == 0.0), isTrue);
});
```

### Pattern 4: Tournament Bracket Generation Testing
**What:** Parameterized tests for different participant counts and tournament types
**When to use:** Tournament bracket generation algorithm tests
**Example:**
```dart
// Test tournament bracket algorithms with various participant counts
group('generateSingleEliminationBracket', () {
  for (final numTeams in [3, 5, 8, 16]) {
    test('generates correct bracket for $numTeams teams', () async {
      final teamIds = List.generate(numTeams, (i) => 'team-$i');

      final matches = await service.generateSingleEliminationBracket(
        tournamentId: 'tourn-1',
        teamIds: teamIds,
      );

      // Calculate expected matches: sum of rounds (n-1) + (n-2) + ... + 1
      final expectedRounds = (log(numTeams) / log(2)).ceil();
      expect(matches.length, greaterThan(0));

      // Verify all teams placed
      final uniqueTeams = matches
          .map((m) => [m.teamAId, m.teamBId])
          .expand((e) => e)
          .where((id) => id != null)
          .toSet();
      expect(uniqueTeams.length, numTeams);
    });
  }
});
```

### Pattern 5: Fine Payment Idempotency Testing
**What:** Ensure payment operations can be retried without double-charging
**When to use:** Fine service payment reconciliation tests
**Example:**
```dart
test('recordPayment is idempotent (prevents double-payment)', () async {
  // Arrange: Record initial payment
  await service.recordPayment(
    fineId: 'fine-1',
    amount: 50.0,
    registeredBy: 'admin-1',
  );

  // Act: Attempt duplicate payment with same parameters
  await service.recordPayment(
    fineId: 'fine-1',
    amount: 50.0,
    registeredBy: 'admin-1',
  );

  // Assert: Only one payment recorded
  final payments = await service.getPaymentsForFine('fine-1');
  expect(payments.length, 1);
  expect(payments.first.amount, 50.0);
});

test('balance calculation after partial payments', () async {
  // Arrange: Fine of 100 kr
  final fine = TestFineFactory.create(amount: 100.0);

  // Act: Make two partial payments
  await service.recordPayment(fineId: fine.id, amount: 30.0);
  await service.recordPayment(fineId: fine.id, amount: 40.0);

  // Assert: Balance is 30 kr (100 - 70)
  final summary = await service.getUserSummary('team-1', fine.offenderId);
  expect(summary.outstandingBalance, 30.0);
});
```

### Anti-Patterns to Avoid
- **Testing implementation details:** Don't test internal service methods; test public API behavior
- **Over-mocking:** Don't mock simple value objects (models); only mock I/O boundaries (Database)
- **Brittle assertions:** Use `contains()` and `isA<Type>()` instead of exact string matches for error messages
- **Shared mutable state:** Reset test factories between tests (`resetAllTestFactories()` in setUp)
- **Missing edge cases:** Don't only test happy path; tournament with 0 participants, negative fine amounts, etc.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Supabase mocking | Custom HTTP interceptor | Manual mocks or mock_supabase_http_client | Official mock client handles auth, retries, error codes |
| Test data generation | Random values | Test factories with counters | Deterministic tests are reproducible; Norwegian names provide realism |
| Coverage reporting | Custom coverage parser | `flutter test --coverage` + lcov | LCOV is industry standard, integrates with SonarQube/Codecov |
| Widget assertion helpers | Custom find.byX extensions | flutter_test finders | Built-in finders cover 99% of cases |
| Async testing | Manual Future.delayed() | pumpAndSettle() | Handles all pending timers, animations, and futures automatically |
| Date/time testing | DateTime.now() | Fixed timestamps in test factories | Eliminates timing-dependent test flakes |
| Golden test diffing | Manual image comparison | flutter_test matchesGoldenFile | Handles pixel ratios, platform differences, CI compatibility |

**Key insight:** Flutter/Dart testing ecosystem is mature; custom solutions rarely improve on official tools and introduce maintenance burden.

## Common Pitfalls

### Pitfall 1: Flaky Tests from Unmocked External Dependencies
**What goes wrong:** Tests fail intermittently because they call real Supabase or depend on network
**Why it happens:** Forgetting to mock Database client or using Supabase client directly in tests
**How to avoid:** Always inject Database dependency, mock in setUp(), verify mock calls with `verify()`
**Warning signs:** Tests pass locally but fail in CI, random timeout failures

### Pitfall 2: Division-by-Zero in Statistics Calculations
**What goes wrong:** Statistics service crashes when calculating percentages for teams with no activities
**Why it happens:** Code like `attended / total * 100` without checking `total > 0`
**How to avoid:** Test edge cases: zero activities, zero attendance, zero members
**Warning signs:** Exception in production for new teams, crashes when filtering empty date ranges

### Pitfall 3: Test Data Pollution Between Tests
**What goes wrong:** Test passes when run alone, fails when run with others
**Why it happens:** Test factories use static counters that aren't reset; IDs collide between tests
**How to avoid:** Call `resetAllTestFactories()` in setUp() or use unique IDs per test
**Warning signs:** Tests fail only when run in specific order, "already exists" errors

### Pitfall 4: Over-Reliance on pumpAndSettle
**What goes wrong:** Tests hang indefinitely or timeout waiting for animations
**Why it happens:** Infinite animations (indeterminate progress indicators) never settle
**How to avoid:** Use `pump(duration)` for specific animation frames, `pumpAndSettle()` for finite UI updates
**Warning signs:** Tests take >5 seconds, "timed out waiting for animation" errors

### Pitfall 5: Testing Serialization Instead of Logic
**What goes wrong:** 100% test coverage but no actual business logic tested
**Why it happens:** Only testing model toJson/fromJson, not service algorithms
**How to avoid:** Model tests are quick wins; focus on service tests (export transformations, bracket generation, payment reconciliation)
**Warning signs:** High coverage number but bugs in production, tests don't catch calculation errors

### Pitfall 6: Hard-Coded Norwegian Text Assertions
**What goes wrong:** Tests break when UI text changes (internationalization, copywriting)
**Why it happens:** Using `expect(find.text('Eksporter data'), findsOneWidget)` for non-critical text
**How to avoid:** Test by widget type or key for structure, only assert critical text (headers, buttons)
**Warning signs:** Test failures on translation updates, brittleness on minor UI tweaks

### Pitfall 7: Missing Bronze Final Edge Cases in Tournament
**What goes wrong:** Tournament bracket fails to generate when `bronzeFinal=true` but only 2 teams
**Why it happens:** Bronze final requires semi-finals (4+ teams); code doesn't validate
**How to avoid:** Test all tournament parameter combinations: 3/5/8/16 teams × with/without bronze × single-elim/round-robin
**Warning signs:** Exception when user enables bronze final option, crashes on small tournaments

## Code Examples

Verified patterns from existing codebase and official sources:

### Backend Service Test Setup
```dart
// Source: Project pattern from backend/test/models/fine_test.dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core_idrett_backend/services/export_service.dart';
import 'package:core_idrett_backend/db/database.dart';

class MockDatabase extends Mock implements Database {}
class MockClient extends Mock implements SupabaseClient {}
class MockUserService extends Mock implements UserService {}

void main() {
  late MockDatabase db;
  late MockClient client;
  late MockUserService userService;
  late ExportDataService service;

  setUp(() {
    db = MockDatabase();
    client = MockClient();
    userService = MockUserService();
    when(() => db.client).thenReturn(client);
    service = ExportDataService(db);
  });

  tearDown(() {
    reset(db);
    reset(client);
    reset(userService);
  });

  // Tests here...
}
```

### Export Service Data Validation Test
```dart
// Testing export data structure and content
test('exportFines includes summary with totals', () async {
  when(() => client.select('fines',
    filters: {'team_id': 'eq.team-1', 'status': 'eq.approved'},
    order: any(named: 'order'),
  )).thenAnswer((_) async => [
    {
      'id': 'fine-1',
      'user_id': 'user-1',
      'amount': 100,
      'paid_at': null,
      'created_at': '2024-01-01T10:00:00Z',
    },
    {
      'id': 'fine-2',
      'user_id': 'user-2',
      'amount': 50,
      'paid_at': '2024-01-15T14:00:00Z',
      'created_at': '2024-01-01T11:00:00Z',
    },
  ]);

  final result = await service.exportFines('team-1');

  expect(result['type'], 'fines');
  expect(result['data'], hasLength(2));
  expect(result['summary']['total_amount'], 150);
  expect(result['summary']['paid_amount'], 50);
  expect(result['summary']['unpaid_amount'], 100);
});
```

### Frontend Widget Test with Provider Overrides
```dart
// Source: Project pattern from app/test/features/fines/fines_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_data.dart';

void main() {
  late TestScenario scenario;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    scenario = TestScenario();
    resetAllTestFactories();
  });

  testWidgets('ExportScreen shows all export types for admin', (tester) async {
    final adminTeam = TestTeamFactory.create(
      id: 'team-1',
      userIsAdmin: true,
    );

    scenario.setupLoggedIn();
    scenario.mocks.setupGetTeam(adminTeam);

    await tester.pumpWidget(
      createTestWidget(
        const ExportScreen(teamId: 'team-1', isAdmin: true),
        overrides: scenario.overrides,
      ),
    );
    await tester.pumpAndSettle();

    // Verify all 7 export types visible
    expect(find.byType(ExportOptionCard), findsNWidgets(7));
    expect(find.text('Leaderboard'), findsOneWidget);
    expect(find.text('Oppmøte'), findsOneWidget);
    expect(find.text('Bøter'), findsOneWidget);
  });
}
```

### Tournament Bracket Algorithm Test
```dart
// Testing complex bracket generation logic
test('single-elimination with bronze final creates correct structure', () async {
  final teamIds = ['team-1', 'team-2', 'team-3', 'team-4'];

  when(() => roundsService.createRound(
    tournamentId: any(named: 'tournamentId'),
    roundNumber: any(named: 'roundNumber'),
    roundName: any(named: 'roundName'),
    roundType: any(named: 'roundType'),
  )).thenAnswer((_) async => TournamentRound(
    id: 'round-${_counter++}',
    tournamentId: 'tourn-1',
    roundNumber: 1,
    roundName: 'Round 1',
    roundType: RoundType.winners,
  ));

  final matches = await service.generateSingleEliminationBracket(
    tournamentId: 'tourn-1',
    teamIds: teamIds,
    bronzeFinal: true,
  );

  // 4 teams = 2 semi + 1 final + 1 bronze = 4 matches
  expect(matches, hasLength(4));

  // Verify bronze match exists
  final bronzeMatches = matches.where((m) =>
    m.roundType == RoundType.bronze
  ).toList();
  expect(bronzeMatches, hasLength(1));
});
```

### Statistics Edge Case Test
```dart
// Testing division-by-zero prevention
test('attendance calculation handles zero total activities', () async {
  when(() => teamService.getTeamMemberUserIds('team-1'))
      .thenAnswer((_) async => ['user-1', 'user-2']);
  when(() => userService.getUserMap(['user-1', 'user-2']))
      .thenAnswer((_) async => {
        'user-1': {'id': 'user-1', 'name': 'User 1'},
        'user-2': {'id': 'user-2', 'name': 'User 2'},
      });
  when(() => client.select('activities',
    select: any(named: 'select'),
    filters: {'team_id': 'eq.team-1'},
  )).thenAnswer((_) async => []); // No activities

  final result = await service.getTeamAttendance('team-1');

  expect(result, hasLength(2));
  expect(result[0].totalActivities, 0);
  expect(result[0].percentage, 0.0); // Should be 0, not NaN
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| mockito with code generation | mocktail for manual mocks | 2023 (Dart 3.0) | Simpler setup, no build_runner, better null-safety |
| flutter_driver | integration_test package | 2021 | Official integration testing, better CI support |
| ProviderScope with overrides | ProviderContainer.test() | Riverpod 3.0 (2024) | Cleaner test syntax, better error messages |
| Manual golden comparisons | Alchemist package | 2024 | Consistent device sizes, reduced CI flakes |
| HTML coverage reports only | LCOV + Codecov/SonarQube | Standard (2023+) | Better visualization, PR comments, trends |

**Deprecated/outdated:**
- **flutter_driver:** Replaced by integration_test package (still works but not recommended)
- **mockito's @GenerateMocks:** Still works but mocktail preferred for new projects
- **flutter test --coverage with manual filtering:** Use test_cov_console or IDE plugins

## Open Questions

1. **Should we test all 7 export types individually or group them?**
   - What we know: Export service has 5 documented types (leaderboard, attendance, fines, activities, members)
   - What's unclear: Requirements mention 7 types but only 5 are in code
   - Recommendation: Test 5 existing types thoroughly, add placeholder tests for 2 future types if identified

2. **What is the expected behavior for tournament brackets with odd participants?**
   - What we know: Code generates brackets for 3/5/8/16 teams, uses "byes" for odd numbers
   - What's unclear: Should bye teams advance automatically or wait for opponent?
   - Recommendation: Test current behavior (code shows auto-advance with walkover), document in test names

3. **How should fine payment idempotency be enforced—database constraints or application logic?**
   - What we know: Code records payments in fine_payments table, calculates totals
   - What's unclear: Are there DB unique constraints preventing duplicate payment_id?
   - Recommendation: Test application-level idempotency with same parameters, verify duplicate detection

4. **What constitutes "season boundary" for statistics edge cases?**
   - What we know: Statistics service filters by season_year (int), uses DateTime.now().year
   - What's unclear: Year-end transition behavior (Dec 31 → Jan 1)
   - Recommendation: Test with mock dates on year boundaries (Dec 31, Jan 1), verify correct season_year

## Sources

### Primary (HIGH confidence)
- [Flutter Official Testing Docs](https://docs.flutter.dev/cookbook/testing/unit/introduction) - Testing fundamentals
- [Dart Testing Guide](https://dart.dev/tools/testing) - Official Dart test package documentation
- [Riverpod Testing Documentation](https://riverpod.dev/docs/how_to/testing) - Provider mocking patterns
- Project codebase: `/backend/test/helpers/test_helpers.dart`, `/app/test/helpers/test_app.dart` - Existing test patterns
- Project codebase: `/backend/lib/services/` - Service implementations to test

### Secondary (MEDIUM confidence)
- [Code With Andrea: Flutter Test Coverage](https://codewithandrea.com/articles/flutter-test-coverage/) - Coverage setup and LCOV
- [Very Good Ventures: Guide to Flutter Testing](https://www.verygood.ventures/blog/guide-to-flutter-testing) - Industry best practices
- [Testing Riverpod Providers: Complete Guide](https://article.temiajiboye.com/comprehensive-guide-to-testing-riverpod-providers) - Provider testing patterns
- [mock_supabase_http_client package](https://pub.dev/packages/mock_supabase_http_client) - Supabase mocking alternative

### Tertiary (LOW confidence)
- [Walturn: Best Practices for Testing Flutter Applications](https://www.walturn.com/insights/best-practices-for-testing-flutter-applications) - General guidance
- [Bacancy Technology: Flutter Unit Testing 2026](https://www.bacancytechnology.com/blog/flutter-unit-testing) - Current year patterns (verify dates)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official packages, verified in existing codebase
- Architecture: HIGH - Patterns extracted from existing tests, proven in production
- Pitfalls: MEDIUM-HIGH - Combination of web search findings and common Dart/Flutter issues
- Export/Tournament algorithms: MEDIUM - Based on code inspection, needs validation with domain experts

**Research date:** 2026-02-09
**Valid until:** 2026-04-09 (60 days; testing best practices are stable)

**Coverage notes:**
- Backend has 25 existing model tests, 0 service tests → Phase 6 adds 4+ service test files
- Frontend has 16 widget tests, 36 model tests → Phase 6 adds 2 screen test files
- Project uses `flutter_test` and `test` packages already installed → No new dependencies required
