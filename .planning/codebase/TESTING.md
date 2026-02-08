# Testing Patterns

**Analysis Date:** 2026-02-08

## Test Framework

**Runner:**
- Frontend: `flutter_test` (from Flutter SDK)
- Backend: `test` v1.25.0 (not currently in use — no tests found)
- Config: Frontend tests in `app/test/`; backend has no test directory

**Assertion Library:**
- Frontend: Flutter's `expect()` from `flutter_test`
- Mocking: `mocktail` v1.0.0 for mocking repositories and services

**Run Commands:**
```bash
# Frontend: Run all tests
flutter test

# Frontend: Watch mode (rebuilds and retests on file changes)
flutter test --watch

# Frontend: Coverage report
flutter test --coverage

# Frontend: Run specific test file
flutter test test/features/auth/login_test.dart

# Frontend: Run tests for specific feature
flutter test test/features/teams/

# Frontend: Integration tests
flutter test integration_test/app_test.dart
```

## Test File Organization

**Location:**
- Tests co-located with source in `app/test/` mirror directory
- Test files parallel source structure: `app/lib/features/auth/` → `app/test/features/auth/`
- Test helpers in `app/test/helpers/` (shared test infrastructure)
- Integration tests in `app/integration_test/`

**Naming:**
- Widget/feature tests: `{feature_name}_test.dart` (e.g., `login_test.dart`, `teams_list_test.dart`)
- Flow tests: `complete_{flow_name}_test.dart` (e.g., `complete_auth_flow_test.dart`)
- Single test file per feature/screen (comprehensive with multiple test groups inside)

**Structure:**
```
app/test/
├── helpers/                          # Shared test infrastructure
│   ├── test_app.dart                # TestApp wrapper, TestScenario, extensions
│   ├── mock_repositories.dart       # Mock classes and MockProviders setup
│   ├── test_data.dart               # Factory classes for test data
│   └── mock_api_client.dart         # API client mocks
├── features/
│   ├── auth/
│   │   ├── login_test.dart
│   │   └── register_test.dart
│   ├── teams/
│   │   ├── teams_list_test.dart
│   │   ├── team_detail_test.dart
│   │   └── create_team_test.dart
│   └── [feature]/
│       └── {feature}_test.dart
├── flows/
│   ├── complete_auth_flow_test.dart
│   ├── complete_team_flow_test.dart
│   └── complete_fines_flow_test.dart
└── widget_test.dart                 # Smoke test
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  late TestScenario scenario;

  setUpAll(() {
    registerFallbackValues();  // Register mock fallback values once
  });

  setUp(() {
    scenario = TestScenario();  // Create fresh scenario per test
    resetAllTestFactories();    // Reset auto-incrementing counters
  });

  group('ScreenName', () {
    testWidgets('description of what test does', (tester) async {
      scenario.setupLoggedOut();  // Set up initial state

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      expect(find.text('Some Text'), findsOneWidget);
      // ... more assertions
    });
  });
}
```

**Patterns:**

1. **Setup Pattern:**
   - `setUpAll()`: Register fallback values once for all tests (mocktail requirement)
   - `setUp()`: Create new `TestScenario` and reset factories before each test
   - `tearDown()`: Optional cleanup (not always needed)

2. **Scenario Setup Pattern:**
   ```dart
   scenario.setupLoggedOut();              // Anonymous user
   scenario.setupLoggedIn();               // Authenticated user
   scenario.setupWithTeams(teamCount: 2);  // Add teams to authenticated user
   scenario.setupWithFines(teamId, fineCount: 3);  // Add fines for team
   ```

3. **Widget Testing Pattern:**
   ```dart
   await tester.pumpWidget(
     createTestWidget(const MyScreen(), overrides: scenario.overrides),
   );
   // ... find and interact
   await tester.tap(find.text('Button'));
   await tester.pumpAndSettle();  // Wait for all animations/transitions
   ```

4. **Assertion Pattern:**
   ```dart
   expect(find.text('Expected Text'), findsOneWidget);
   expect(find.byType(CircularProgressIndicator), findsNothing);
   expect(find.byKey(const Key('my_key')), findsOneWidget);
   ```

## Mocking

**Framework:** `mocktail` v1.0.0

**Patterns:**

1. **Mock Class Definition:**
   ```dart
   class MockAuthRepository extends Mock implements AuthRepository {}
   class MockTeamRepository extends Mock implements TeamRepository {}
   ```

2. **Mock Setup in MockProviders:**
   ```dart
   class MockProviders {
     final MockAuthRepository authRepository = MockAuthRepository();

     List<Object> get overrides => [
       authRepositoryProvider.overrideWithValue(authRepository),
     ];

     void setupAuthenticatedUser(User user) {
       when(() => authRepository.getCurrentUser())
           .thenAnswer((_) async => user);
     }
   }
   ```

3. **Mocking Async Methods:**
   ```dart
   when(() => authRepository.login(
         email: any(named: 'email'),
         password: any(named: 'password'),
       )).thenAnswer((_) async => AuthResult(token: 'token', user: user));
   ```

4. **Mocking with Delay (for loading state testing):**
   ```dart
   when(() => authRepository.login(...))
       .thenAnswer((_) async {
     await Future.delayed(const Duration(milliseconds: 100));
     return AuthResult(...);
   });
   ```

5. **Mocking Failures:**
   ```dart
   when(() => authRepository.login(...))
       .thenThrow(const InvalidCredentialsException());
   ```

6. **Verify Mock Was Called:**
   ```dart
   verify(() => authRepository.login(
         email: 'test@test.com',
         password: 'password123',
       )).called(1);
   ```

**What to Mock:**
- All repositories (data access layer)
- API client (network operations)
- Services (when testing in isolation)
- Do NOT mock Riverpod providers directly; override via `ProviderScope(overrides: [...])`

**What NOT to Mock:**
- Models and data classes (use factories instead)
- UI widgets (test the real implementation)
- Navigation (use real GoRouter in tests)
- Theme and styling classes

## Fixtures and Factories

**Test Data:**

Factory pattern with auto-incrementing IDs:
```dart
class TestUserFactory {
  static int _counter = 0;

  static User create({
    String? id,
    String? email,
    String? name,
  }) {
    _counter++;
    return User(
      id: id ?? 'user-$_counter',
      email: email ?? 'user$_counter@test.com',
      name: name ?? 'Test User $_counter',
    );
  }

  static void reset() => _counter = 0;
}
```

**Usage:**
```dart
final user = TestUserFactory.create(email: 'custom@test.com');
final user2 = TestUserFactory.create();  // Gets id 'user-2'

// In setUp: reset counters for clean IDs per test
setUp(() {
  resetAllTestFactories();
});
```

**Location:**
- All factories in `app/test/helpers/test_data.dart`
- Factory classes: `TestUserFactory`, `TestTeamFactory`, `TestActivityInstanceFactory`, `TestFineFactory`, etc.
- Call `resetAllTestFactories()` in setUp to ensure predictable IDs

**Available Factories:**
- `TestUserFactory`: Users with customizable email, name, avatar
- `TestTeamFactory`: Teams with sport, invite code, user role flags
- `TestTeamMemberFactory`: Team members with permissions and roles
- `TestActivityFactory`: Activities with type, recurrence, response settings
- `TestActivityInstanceFactory`: Scheduled activity instances with responses
- `TestFineFactory`: Fines with status, amount, evidence
- `TestFineRuleFactory`: Fine rules with amounts
- `TestMessageFactory`: Team chat messages with replies

## Coverage

**Requirements:** Not enforced; no coverage thresholds configured

**View Coverage:**
```bash
flutter test --coverage
# Generated: coverage/lcov.info
# To view in browser:
genhtml coverage/lcov.info -o coverage/html && open coverage/html/index.html
```

## Test Types

**Unit Tests:**
- Not explicitly separated; widget tests cover UI + state management
- Test individual functions/methods in isolation (rare — focus is on widget/integration)
- Mock all dependencies

**Widget Tests:**
- Test screens and custom widgets in isolation
- Run in-process, fast
- Use `tester.pumpWidget()` to render widget tree
- Use `find.*()` to locate elements
- Use `tester.tap()`, `tester.enterText()` for interactions
- Use `pumpAndSettle()` to wait for animations
- Scope: One screen/feature per test file

**Integration Tests:**
- File: `app/integration_test/app_test.dart`
- Test complete user flows (e.g., launch app → navigate → interact)
- Use real backend when available
- Much slower than widget tests

**Test Groups:**
- Organize multiple test cases per widget with `group('WidgetName', () { ... })`
- Group name should match screen/widget being tested
- Multiple groups per test file (e.g., login_test.dart has groups for form validation, error states, success flows)

## Common Patterns

**Async Testing:**
```dart
testWidgets('shows loading during operation', (tester) async {
  scenario.setupUnauthenticated();

  when(() => scenario.mocks.authRepository.login(...))
      .thenAnswer((_) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return AuthResult(...);
  });

  await tester.pumpWidget(createTestWidget(...));

  // Tap to start async operation
  await tester.tap(find.text('Login'));
  await tester.pump();  // Pump once to see loading state (NOT pumpAndSettle)

  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  await tester.pumpAndSettle();  // Wait for completion
});
```

**Error Testing:**
```dart
testWidgets('shows error message when login fails', (tester) async {
  scenario.setupUnauthenticated();
  scenario.mocks.setupLoginFailure(const InvalidCredentialsException());

  await tester.pumpWidget(createTestWidget(const LoginScreen(), overrides: scenario.overrides));

  await tester.enterText(find.widgetWithText(TextFormField, 'E-post'), 'test@test.com');
  await tester.enterText(find.widgetWithText(TextFormField, 'Passord'), 'wrong');

  await tester.tap(find.text('Logg inn'));
  await tester.pumpAndSettle();

  expect(find.text('Innlogging feilet. Sjekk e-post og passord.'), findsOneWidget);
});
```

**Form Validation Testing:**
```dart
testWidgets('shows validation error when field is empty', (tester) async {
  scenario.setupLoggedOut();

  await tester.pumpWidget(createTestWidget(const LoginScreen(), overrides: scenario.overrides));

  // Tap button without filling form
  await tester.tap(find.text('Logg inn'));
  await tester.pumpAndSettle();

  expect(find.text('Vennligst skriv inn e-post'), findsOneWidget);
});
```

**State Change Testing (Verify Mock Called):**
```dart
testWidgets('calls login with correct credentials', (tester) async {
  scenario.setupUnauthenticated();
  scenario.mocks.setupLoginSuccess(user: TestUserFactory.create());

  await tester.pumpWidget(createTestWidget(...));

  await tester.enterText(..., 'test@test.com');
  await tester.enterText(..., 'password123');
  await tester.tap(find.text('Logg inn'));
  await tester.pumpAndSettle();

  // Verify the mock was called with these exact arguments
  verify(() => scenario.mocks.authRepository.login(
    email: 'test@test.com',
    password: 'password123',
  )).called(1);
});
```

**Navigation Testing:**
```dart
testWidgets('navigates to register when link tapped', (tester) async {
  scenario.setupLoggedOut();

  await tester.pumpWidget(createRoutedTestWidget(
    overrides: scenario.overrides,
    initialLocation: '/login',
  ));

  await tester.tap(find.text('Registrer deg'));
  await tester.pumpAndSettle();

  expect(find.text('Registrer deg'), findsWidgets);  // New screen title
});
```

**Using AppFinders Helper:**
```dart
testWidgets('uses predefined finders', (tester) async {
  await tester.pumpWidget(createTestWidget(...));

  await tester.tap(AppFinders.loginButton);
  expect(find.byKey(AppFinders.emailField.evaluate().first.widget.key), findsOneWidget);
  await tester.scrollUntilVisible(AppFinders.registerButton);
});
```

**WidgetTester Extensions (Custom):**
```dart
// Available in all tests via WidgetTesterExtensions
await tester.tapByKey(const Key('submit'));
await tester.tapByText('Submit');
await tester.enterTextByKey(const Key('name_field'), 'John');
await tester.enterTextByHint('E-post', 'test@test.com');
await tester.scrollUntilVisible(find.text('Bottom Item'));
```

## Test Helpers Summary

**From `test_app.dart`:**
- `TestApp`: Basic widget wrapper with provider overrides
- `TestAppWithRouter`: Full router support for navigation tests
- `createTestWidget()`: Quickly wrap a widget with theme + providers
- `createRoutedTestWidget()`: Quickly create app with routing
- `TestScenario`: Builder for common test states (logged in, teams, activities, etc.)
- `initializeTestLocales()`: Call in setUpAll for date formatting tests
- `WidgetTesterExtensions`: Helper methods like `tapByKey()`, `enterTextByHint()`
- `AppFinders`: Predefined finders for common UI elements

**From `mock_repositories.dart`:**
- `MockProviders`: Container for all mocks with setup methods
- Setup methods: `setupAuthenticatedUser()`, `setupTeamsList()`, `setupActivityInstances()`, etc.
- `registerFallbackValues()`: Register enum values for mocktail (call in setUpAll)
- `MockProvidersTestExtensions`: Verification helpers like `verifyLoginCalled()`

**From `test_data.dart`:**
- All `TestXxxFactory` classes for creating domain models
- `resetAllTestFactories()`: Reset counters before each test

## Test Best Practices

1. **One assertion concern per test** - Each test should verify one behavior
2. **Use meaningful test names** - Describe what is being tested and expected outcome
3. **Follow AAA pattern** - Arrange (setup), Act (interact), Assert (verify)
4. **Reset state between tests** - Always reset factories in setUp
5. **Mock at the repository level** - Don't mock providers; override them in ProviderScope
6. **Use expect() for all verifications** - Consistent assertion syntax
7. **Test user-visible behavior** - Focus on what the user sees, not internal implementation
8. **Group related tests** - Use `group()` to organize test cases by feature
9. **Don't test framework behavior** - Assume Flutter/Riverpod work; test your code
10. **Test error paths** - Include tests for failure scenarios and validation errors

---

*Testing analysis: 2026-02-08*
