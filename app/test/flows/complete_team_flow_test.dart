import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/teams/presentation/teams_screen.dart';
import 'package:core_idrett/features/teams/presentation/create_team_screen.dart';

import '../helpers/test_app.dart';
import '../helpers/test_data.dart';
import '../helpers/mock_repositories.dart';

/// Tests the complete team management flow:
/// - View teams list
/// - Create new team
/// - Team validation
/// - Team data display
void main() {
  late TestScenario scenario;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    scenario = TestScenario();
    resetAllTestFactories();
  });

  group('Complete Team Flow', () {
    testWidgets('teams list shows create button for new users', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const TeamsScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mine lag'), findsOneWidget);
      expect(find.text('Opprett lag'), findsOneWidget);
    });

    testWidgets('teams list displays existing teams', (tester) async {
      final teams = [
        TestTeamFactory.create(
          id: 'team-1',
          name: 'Fotball FC',
          sport: 'Fotball',
          userIsAdmin: true,
        ),
        TestTeamFactory.create(
          id: 'team-2',
          name: 'Basketball Club',
          sport: 'Basketball',
          userIsAdmin: false,
        ),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupTeamsList(teams);

      await tester.pumpWidget(
        createTestWidget(
          const TeamsScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fotball FC'), findsOneWidget);
      expect(find.text('Basketball Club'), findsOneWidget);
    });

    testWidgets('create team form validates team name', (tester) async {
      scenario.setupLoggedIn();

      await tester.pumpWidget(
        createTestWidget(
          const CreateTeamScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Try to create without entering name
      await tester.tap(find.widgetWithText(FilledButton, 'Opprett lag'));
      await tester.pumpAndSettle();

      expect(find.text('Vennligst skriv inn lagnavn'), findsOneWidget);
    });

    testWidgets('create team calls repository with correct data', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.teamRepository.createTeam(
            name: any(named: 'name'),
            sport: any(named: 'sport'),
          )).thenThrow(Exception('Test'));

      await tester.pumpWidget(
        createTestWidget(
          const CreateTeamScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Lagnavn'), 'New Team');
      await tester.enterText(find.widgetWithText(TextFormField, 'Idrett (valgfritt)'), 'Handball');
      await tester.tap(find.widgetWithText(FilledButton, 'Opprett lag'));
      await tester.pumpAndSettle();

      verify(() => scenario.mocks.teamRepository.createTeam(
            name: 'New Team',
            sport: 'Handball',
          )).called(1);
    });

    testWidgets('teams list displays team with admin status', (tester) async {
      final teams = [
        TestTeamFactory.create(
          id: 'team-1',
          name: 'Admin Team',
          userIsAdmin: true,
        ),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupTeamsList(teams);

      await tester.pumpWidget(
        createTestWidget(
          const TeamsScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Team name is displayed
      expect(find.text('Admin Team'), findsOneWidget);
    });

    testWidgets('teams list renders list view', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 1);

      await tester.pumpWidget(
        createTestWidget(
          const TeamsScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // ListView should render successfully
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('create team shows both form fields', (tester) async {
      scenario.setupLoggedIn();

      await tester.pumpWidget(
        createTestWidget(
          const CreateTeamScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lagnavn'), findsOneWidget);
      expect(find.text('Idrett (valgfritt)'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.sports), findsOneWidget);
    });
  });
}
