import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:core_idrett/main.dart' as app;

/// Integration tests for the Core-Idrett app.
///
/// These tests run on a real device or emulator and test the actual app behavior.
/// They are slower than widget tests but provide end-to-end verification.
///
/// Run with: flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize locales for date formatting
    await initializeDateFormatting('nb_NO', null);
    await initializeDateFormatting('en_US', null);
  });

  group('App Integration Tests', () {
    testWidgets('app starts and shows login screen', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify we start on login screen
      expect(find.text('Logg inn'), findsOneWidget);
      expect(find.text('E-post'), findsOneWidget);
      expect(find.text('Passord'), findsOneWidget);
    });

    testWidgets('login screen has register link', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify register link exists
      expect(find.textContaining('Registrer'), findsOneWidget);
    });

    testWidgets('email field accepts input', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find email field and enter text
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Verify text was entered
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('password field accepts input', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find password field (second text field typically)
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(1), 'password123');
      await tester.pumpAndSettle();

      // Note: Password field obscures text, so we just verify no crash
      expect(fields, findsWidgets);
    });

    testWidgets('login button is present', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Logg inn'), findsOneWidget);
    });
  });
}
