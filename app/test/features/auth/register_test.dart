import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/auth/presentation/register_screen.dart';
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

  group('RegisterScreen', () {
    testWidgets('renders all required fields', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      expect(find.text('Navn'), findsOneWidget);
      expect(find.text('E-post'), findsOneWidget);
      expect(find.text('Passord'), findsOneWidget);
      expect(find.text('Bekreft passord'), findsOneWidget);
      expect(find.text('Registrer deg'), findsNWidgets(2)); // Title and button
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      // Tap register without entering anything
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn navnet ditt'), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      // Enter name only
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Navn'),
        'Test User',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn e-post'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid email', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Navn'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'invalid-email',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn en gyldig e-post'), findsOneWidget);
    });

    testWidgets('shows validation error when password is too short', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Navn'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'short',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      expect(find.text('Passordet må være minst 8 tegn'), findsOneWidget);
    });

    testWidgets('shows validation error when passwords do not match', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Navn'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bekreft passord'),
        'differentpassword',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      expect(find.text('Passordene er ikke like'), findsOneWidget);
    });

    testWidgets('disables register button while processing', (tester) async {
      final user = TestUserFactory.create();
      scenario.mocks.setupUnauthenticated();

      // Use delayed response to test loading state
      when(() => scenario.mocks.authRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            inviteCode: any(named: 'inviteCode'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return AuthResult(token: 'mock-token', user: user);
      });

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      // Fill all fields correctly
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Navn'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bekreft passord'),
        'password123',
      );

      // Before tap - button should be enabled
      final buttonBefore = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buttonBefore.onPressed, isNotNull);

      // Tap register and pump once (not settle)
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pump();

      // During loading - button should be disabled
      final buttonDuring = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buttonDuring.onPressed, isNull);

      // Let it complete
      await tester.pumpAndSettle();
    });

    testWidgets('shows error message when registration fails', (tester) async {
      scenario.mocks.setupUnauthenticated();
      when(() => scenario.mocks.authRepository.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
            inviteCode: any(named: 'inviteCode'),
          )).thenThrow(const ValidationException('Email already exists'));

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      // Fill all fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Navn'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'existing@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bekreft passord'),
        'password123',
      );

      // Tap register
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.text('Registrering feilet. Prøv igjen.'), findsOneWidget);
    });

    testWidgets('calls register with correct data', (tester) async {
      final user = TestUserFactory.create();
      scenario.mocks.setupUnauthenticated();
      scenario.mocks.setupRegisterSuccess(user: user);

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      // Fill all fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Navn'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bekreft passord'),
        'password123',
      );

      // Tap register
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      // Verify register was called with correct parameters
      verify(() => scenario.mocks.authRepository.register(
            email: 'test@test.com',
            password: 'password123',
            name: 'Test User',
            inviteCode: null,
          )).called(1);
    });

    testWidgets('shows invite banner when inviteCode is provided', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(
          const RegisterScreen(inviteCode: 'ABC123'),
          overrides: scenario.overrides,
        ),
      );

      expect(
        find.text('Du er invitert til et lag! Registrer deg for å bli med.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.group_add), findsOneWidget);
    });

    testWidgets('passes inviteCode to register method', (tester) async {
      final user = TestUserFactory.create();
      scenario.mocks.setupUnauthenticated();
      scenario.mocks.setupRegisterSuccess(user: user);

      await tester.pumpWidget(
        createTestWidget(
          const RegisterScreen(inviteCode: 'ABC123'),
          overrides: scenario.overrides,
        ),
      );

      // Fill all fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Navn'),
        'Test User',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'E-post'),
        'test@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Passord'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Bekreft passord'),
        'password123',
      );

      // Tap register
      await tester.tap(find.widgetWithText(FilledButton, 'Registrer deg'));
      await tester.pumpAndSettle();

      // Verify inviteCode was passed
      verify(() => scenario.mocks.authRepository.register(
            email: 'test@test.com',
            password: 'password123',
            name: 'Test User',
            inviteCode: 'ABC123',
          )).called(1);
    });

    testWidgets('has link to login screen', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(const RegisterScreen(), overrides: scenario.overrides),
      );

      expect(find.text('Har du allerede konto? Logg inn'), findsOneWidget);
    });

  });
}
