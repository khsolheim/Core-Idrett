import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/teams/presentation/teams_screen.dart';

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

  group('TeamsScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(const TeamsScreen(), overrides: scenario.overrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mine lag'), findsOneWidget);
    });

    testWidgets('shows empty state when no teams', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(const TeamsScreen(), overrides: scenario.overrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ingen lag enda'), findsOneWidget);
      expect(
        find.text('Opprett et lag eller bli invitert av noen andre'),
        findsOneWidget,
      );
      expect(find.text('Opprett lag'), findsOneWidget);
    });

    testWidgets('shows team list when teams exist', (tester) async {
      final teams = [
        TestTeamFactory.create(name: 'Team Alpha', sport: 'Fotball'),
        TestTeamFactory.create(name: 'Team Beta', sport: 'Håndball'),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupTeamsList(teams);

      await tester.pumpWidget(
        createTestWidget(const TeamsScreen(), overrides: scenario.overrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('Team Alpha'), findsOneWidget);
      expect(find.text('Team Beta'), findsOneWidget);
      expect(find.text('Fotball'), findsOneWidget);
      expect(find.text('Håndball'), findsOneWidget);
    });

    testWidgets('shows sport icons correctly', (tester) async {
      final teams = [
        TestTeamFactory.create(name: 'Fotball Team', sport: 'Fotball'),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupTeamsList(teams);

      await tester.pumpWidget(
        createTestWidget(const TeamsScreen(), overrides: scenario.overrides),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
    });

    testWidgets('shows FAB to create new team', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 1);

      await tester.pumpWidget(
        createTestWidget(const TeamsScreen(), overrides: scenario.overrides),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Nytt lag'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.teamRepository.getTeams())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(const TeamsScreen(), overrides: scenario.overrides),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Prøv igjen'), findsOneWidget);
    });

    testWidgets('shows profile icon in app bar', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(const TeamsScreen(), overrides: scenario.overrides),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('shows user role badge on team card', (tester) async {
      final teams = [
        TestTeamFactory.create(
          name: 'My Team',
          userIsAdmin: true,
        ),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupTeamsList(teams);

      await tester.pumpWidget(
        createTestWidget(const TeamsScreen(), overrides: scenario.overrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('Administrator'), findsOneWidget);
    });
  });
}
