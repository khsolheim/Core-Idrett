import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core_idrett/features/fines/presentation/fines_screen.dart';
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
      userRole: TeamRole.player,
    );
  });

  group('FinesScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1');

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bøtekasse'), findsOneWidget);
    });

    testWidgets('shows settings icon in app bar', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1');

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('shows summary card with balance', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1',
        totalFines: 1000,
        totalPaid: 400,
      );

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lagkasse'), findsOneWidget);
      // Outstanding balance = 1000 - 400 = 600
      expect(find.text('600 kr'), findsOneWidget);
    });

    testWidgets('shows my fines action card', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1');

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mine bøter'), findsOneWidget);
      expect(find.text('Se dine egne bøter'), findsOneWidget);
    });

    testWidgets('shows fine rules action card', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1');

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bøteregler'), findsOneWidget);
      expect(find.text('Se alle regler'), findsOneWidget);
    });

    testWidgets('shows FAB to report fine', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1');

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Meld bøte'), findsOneWidget);
    });

    testWidgets('shows admin actions for admin users', (tester) async {
      final adminTeam = TestTeamFactory.create(
        id: 'team-1',
        name: 'Admin Team',
        userRole: TeamRole.admin,
        userIsAdmin: true,
      );
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(adminTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1');

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bøtesjef'), findsOneWidget);
      expect(find.text('Regnskap'), findsOneWidget);
    });

    testWidgets('hides admin actions for regular players', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam); // Regular player
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1');

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bøtesjef'), findsNothing);
      expect(find.text('Regnskap'), findsNothing);
    });

    testWidgets('shows actions section header', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary('team-1');

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Handlinger'), findsOneWidget);
    });
  });
}
