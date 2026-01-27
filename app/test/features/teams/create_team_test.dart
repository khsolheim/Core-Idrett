import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/teams/presentation/create_team_screen.dart';

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

  group('CreateTeamScreen', () {
    testWidgets('renders form fields', (tester) async {
      scenario.setupLoggedIn();

      await tester.pumpWidget(
        createTestWidget(const CreateTeamScreen(), overrides: scenario.overrides),
      );

      expect(find.text('Opprett lag'), findsNWidgets(2)); // Title and button
      expect(find.text('Lagnavn'), findsOneWidget);
      expect(find.text('Idrett (valgfritt)'), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      scenario.setupLoggedIn();

      await tester.pumpWidget(
        createTestWidget(const CreateTeamScreen(), overrides: scenario.overrides),
      );

      // Tap create button without entering name
      await tester.tap(find.widgetWithText(FilledButton, 'Opprett lag'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn lagnavn'), findsOneWidget);
    });

    testWidgets('disables button while creating', (tester) async {
      scenario.setupLoggedIn();

      // Mock that takes time and then throws (to avoid navigation issues)
      when(() => scenario.mocks.teamRepository.createTeam(
            name: any(named: 'name'),
            sport: any(named: 'sport'),
          )).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw Exception('Test error');
      });

      await tester.pumpWidget(
        createTestWidget(const CreateTeamScreen(), overrides: scenario.overrides),
      );

      // Enter team name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lagnavn'),
        'New Team',
      );

      // Before tap - button should be enabled
      final buttonBefore = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buttonBefore.onPressed, isNotNull);

      // Tap create
      await tester.tap(find.widgetWithText(FilledButton, 'Opprett lag'));
      await tester.pump();

      // During loading - button should be disabled
      final buttonDuring = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(buttonDuring.onPressed, isNull);

      await tester.pumpAndSettle();
    });

    testWidgets('calls createTeam with correct data (name only)', (tester) async {
      scenario.setupLoggedIn();
      // Setup createTeam to throw to avoid navigation issues in test
      when(() => scenario.mocks.teamRepository.createTeam(
            name: any(named: 'name'),
            sport: any(named: 'sport'),
          )).thenThrow(Exception('Test - verify call'));

      await tester.pumpWidget(
        createTestWidget(const CreateTeamScreen(), overrides: scenario.overrides),
      );

      // Enter team name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lagnavn'),
        'My New Team',
      );

      // Tap create
      await tester.tap(find.widgetWithText(FilledButton, 'Opprett lag'));
      await tester.pumpAndSettle();

      verify(() => scenario.mocks.teamRepository.createTeam(
            name: 'My New Team',
            sport: null,
          )).called(1);
    });

    testWidgets('calls createTeam with sport when provided', (tester) async {
      scenario.setupLoggedIn();
      // Setup createTeam to throw to avoid navigation issues in test
      when(() => scenario.mocks.teamRepository.createTeam(
            name: any(named: 'name'),
            sport: any(named: 'sport'),
          )).thenThrow(Exception('Test - verify call'));

      await tester.pumpWidget(
        createTestWidget(const CreateTeamScreen(), overrides: scenario.overrides),
      );

      // Enter team name and sport
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lagnavn'),
        'Football Team',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Idrett (valgfritt)'),
        'Fotball',
      );

      // Tap create
      await tester.tap(find.widgetWithText(FilledButton, 'Opprett lag'));
      await tester.pumpAndSettle();

      verify(() => scenario.mocks.teamRepository.createTeam(
            name: 'Football Team',
            sport: 'Fotball',
          )).called(1);
    });

    testWidgets('shows error snackbar when creation fails', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.teamRepository.createTeam(
            name: any(named: 'name'),
            sport: any(named: 'sport'),
          )).thenThrow(Exception('Failed to create team'));

      await tester.pumpWidget(
        createTestWidget(const CreateTeamScreen(), overrides: scenario.overrides),
      );

      // Enter team name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lagnavn'),
        'Test Team',
      );

      // Tap create
      await tester.tap(find.widgetWithText(FilledButton, 'Opprett lag'));
      await tester.pumpAndSettle();

      expect(find.text('Kunne ikke opprette lag. Prøv igjen.'), findsOneWidget);
    });

    testWidgets('shows icons in form fields', (tester) async {
      scenario.setupLoggedIn();

      await tester.pumpWidget(
        createTestWidget(const CreateTeamScreen(), overrides: scenario.overrides),
      );

      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.sports), findsOneWidget);
    });
  });
}
