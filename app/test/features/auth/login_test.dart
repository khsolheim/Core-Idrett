import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/auth/presentation/login_screen.dart';
import 'package:core_idrett/features/auth/data/auth_repository.dart';
import 'package:core_idrett/core/errors/app_exceptions.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_data.dart';
import '../../helpers/mock_repositories.dart';

void main() {
  late TestScenario scenario;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    scenario = TestScenario();
    resetAllTestFactories();
  });

  group('LoginScreen', () {
    testWidgets('renders email and password fields', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      expect(find.text('E-post'), findsOneWidget);
      expect(find.text('Passord'), findsOneWidget);
      expect(find.text('Logg inn'), findsOneWidget);
    });

    testWidgets('renders app title and icon', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      expect(find.text('Core - Idrett'), findsOneWidget);
      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      // Tap login without entering anything
      await tester.tap(find.text('Logg inn'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn e-post'), findsOneWidget);
    });

    testWidgets('shows validation error when password is empty', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      // Enter email but not password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.tap(find.text('Logg inn'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn passord'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email format', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      // Enter invalid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'invalid-email',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );
      await tester.tap(find.text('Logg inn'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn en gyldig e-post'), findsOneWidget);
    });

    testWidgets('disables login button while processing', (tester) async {
      final user = TestUserFactory.create();
      scenario.mocks.setupUnauthenticated();

      // Use a completer to control when the login completes
      when(() => scenario.mocks.authRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {
        // Delay to allow testing loading state
        await Future.delayed(const Duration(milliseconds: 100));
        return AuthResult(token: 'mock-token', user: user);
      });

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      // Enter valid credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );

      // Before tap - button should be enabled
      final buttonBefore = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buttonBefore.onPressed, isNotNull);

      // Tap login and pump once (not settle) to see loading state
      await tester.tap(find.text('Logg inn'));
      await tester.pump();

      // During loading - button should be disabled
      final buttonDuring = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buttonDuring.onPressed, isNull);

      // Let it complete
      await tester.pumpAndSettle();
    });

    testWidgets('shows error message when login fails', (tester) async {
      scenario.mocks.setupUnauthenticated();
      scenario.mocks.setupLoginFailure(const InvalidCredentialsException());

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      // Enter valid credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'wrongpassword',
      );

      // Tap login
      await tester.tap(find.text('Logg inn'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Innlogging feilet. Sjekk e-post og passord.'), findsOneWidget);
    });

    testWidgets('calls login with correct credentials', (tester) async {
      final user = TestUserFactory.create();
      scenario.mocks.setupUnauthenticated();
      scenario.mocks.setupLoginSuccess(user: user);

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      // Enter credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );

      // Tap login
      await tester.tap(find.text('Logg inn'));
      await tester.pumpAndSettle();

      // Verify login was called
      verify(() => scenario.mocks.authRepository.login(
            email: 'test@test.com',
            password: 'password123',
          )).called(1);
    });

    testWidgets('has link to register screen', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const LoginScreen(), overrides: scenario.overrides),
      );

      expect(find.text('Har du ikke konto? Registrer deg'), findsOneWidget);
    });

  });
}
