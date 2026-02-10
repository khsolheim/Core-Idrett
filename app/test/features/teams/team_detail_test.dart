import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/teams/presentation/team_detail_screen.dart';
import 'package:core_idrett/data/models/team.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_data.dart';
import '../../helpers/mock_repositories.dart';

void main() {
  late TestScenario scenario;
  late Team testTeam;

  setUpAll(() {
    registerFallbackValues();
  });

  setUp(() {
    scenario = TestScenario();
    resetAllTestFactories();
    testTeam = TestTeamFactory.create(
      id: 'team-1',
      name: 'Test Team',
      sport: 'Fotball',
    );
  });

  group('TeamDetailScreen', () {
    testWidgets('shows team name in app bar after loading', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);

      await tester.pumpWidget(
        createTestWidget(
          const TeamDetailScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Team'), findsOneWidget);
    });

    testWidgets('shows sport when available', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);

      await tester.pumpWidget(
        createTestWidget(
          const TeamDetailScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fotball'), findsOneWidget);
    });

    testWidgets('shows bottom navigation bar', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);

      await tester.pumpWidget(
        createTestWidget(
          const TeamDetailScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Hjem'), findsOneWidget);
      expect(find.text('Aktiviteter'), findsWidgets);
      expect(find.text('Statistikk'), findsWidgets);
      expect(find.text('Bøter'), findsOneWidget);
    });

    testWidgets('shows settings icon in app bar', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);

      await tester.pumpWidget(
        createTestWidget(
          const TeamDetailScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('shows invite button for admin users', (tester) async {
      final adminTeam = TestTeamFactory.create(
        id: 'team-1',
        name: 'Admin Team',
        userIsAdmin: true,
      );
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(adminTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);

      await tester.pumpWidget(
        createTestWidget(
          const TeamDetailScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('hides invite button for non-admin users', (tester) async {
      final playerTeam = TestTeamFactory.create(
        id: 'team-1',
        name: 'Player Team',
        userIsAdmin: false,
      );
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(playerTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);

      await tester.pumpWidget(
        createTestWidget(
          const TeamDetailScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsNothing);
    });

    testWidgets('shows sport icon based on sport type', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam); // Has 'Fotball' as sport
      scenario.setupWithTeamMembers('team-1', memberCount: 2);

      await tester.pumpWidget(
        createTestWidget(
          const TeamDetailScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.sports_soccer), findsOneWidget);
    });

    testWidgets('shows error when team load fails', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.teamRepository.getTeam('team-1'))
          .thenThrow(Exception('Network error'));
      scenario.setupWithTeamMembers('team-1', memberCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const TeamDetailScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Prøv igjen'), findsOneWidget);
    });
  });
}
