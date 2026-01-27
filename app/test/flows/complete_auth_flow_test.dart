import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/auth/presentation/login_screen.dart';
import 'package:core_idrett/features/auth/presentation/register_screen.dart';

import '../helpers/test_app.dart';
import '../helpers/test_data.dart';
import '../helpers/mock_repositories.dart';

/// Tests the complete authentication flow:
/// - Login screen rendering
/// - Register screen rendering
/// - Form validation
/// - State management during auth operations
void main() {
  late TestScenario scenario;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    scenario = TestScenario();
    resetAllTestFactories();
  });

  group('Complete Auth Flow', () {
    testWidgets('login screen shows all required elements', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(
          const LoginScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify all login elements are present
      expect(find.text('Logg inn'), findsWidgets); // Title and/or button
      expect(find.text('E-post'), findsOneWidget);
      expect(find.text('Passord'), findsOneWidget);
      expect(find.textContaining('Registrer'), findsOneWidget);
    });

    testWidgets('register screen shows all required elements', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(
          const RegisterScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify all registration elements are present
      expect(find.text('Registrer deg'), findsWidgets); // Title and button
      expect(find.text('Navn'), findsOneWidget);
      expect(find.text('E-post'), findsOneWidget);
      expect(find.text('Passord'), findsOneWidget);
      expect(find.text('Bekreft passord'), findsOneWidget);
    });

    testWidgets('login validates empty email', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(
          const LoginScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Try to login without entering email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Logg inn'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn e-post'), findsOneWidget);
    });

    testWidgets('register validates empty fields', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(
          const RegisterScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Try to register without entering any fields
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.textContaining('Vennligst'), findsWidgets);
    });

    testWidgets('register validates password match', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(
          const RegisterScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      await tester.enterText(find.widgetWithText(TextFormField, 'Navn'), 'Test User');
      await tester.enterText(find.widgetWithText(TextFormField, 'E-post'), 'test@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Passord'), 'password123');
      await tester.enterText(find.widgetWithText(TextFormField, 'Bekreft passord'), 'different');

      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      expect(find.text('Passordene er ikke like'), findsOneWidget);
    });

    testWidgets('login calls auth repository with credentials', (tester) async {
      scenario.setupLoggedOut();
      // Setup login to throw to avoid navigation issues in test
      when(() => scenario.mocks.authRepository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('Test'));

      await tester.pumpWidget(
        createTestWidget(
          const LoginScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'E-post'), 'user@example.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Passord'), 'password');
      await tester.tap(find.widgetWithText(FilledButton, 'Logg inn'));
      await tester.pumpAndSettle();

      verify(() => scenario.mocks.authRepository.login(
            email: 'user@example.com',
            password: 'password',
          )).called(1);
    });
  });
}
