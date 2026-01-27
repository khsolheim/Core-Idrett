import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/fines/presentation/fines_screen.dart';
import 'package:core_idrett/features/fines/presentation/fine_rules_screen.dart';
import 'package:core_idrett/data/models/team.dart';
import 'package:core_idrett/data/models/fine.dart';

import '../helpers/test_app.dart';
import '../helpers/test_data.dart';
import '../helpers/mock_repositories.dart';

/// Tests the complete fines management flow:
/// - View fines overview
/// - View fine rules
/// - Admin actions visibility
/// - Summary display
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

  group('Complete Fines Flow', () {
    testWidgets('fines screen shows overview for players', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 3);
      scenario.mocks.setupTeamFinesSummary('team-1', totalFines: 500, totalPaid: 200);

      await tester.pumpWidget(
        createTestWidget(
          const FinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Basic elements should be visible
      expect(find.text('Bøtekasse'), findsOneWidget);
      expect(find.text('Mine bøter'), findsOneWidget);
      expect(find.text('Bøteregler'), findsOneWidget);
    });

    testWidgets('fines screen shows admin actions for admins', (tester) async {
      final adminTeam = TestTeamFactory.create(
        id: 'team-1',
        name: 'Admin Team',
        userRole: TeamRole.admin,
        userIsAdmin: true,
      );
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(adminTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 3);
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

    testWidgets('fines screen hides admin actions for players', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 3);
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

    testWidgets('fine rules screen shows rules', (tester) async {
      final rules = [
        TestFineRuleFactory.create(
          id: 'rule-1',
          teamId: 'team-1',
          name: 'For sent',
          amount: 50,
        ),
        TestFineRuleFactory.create(
          id: 'rule-2',
          teamId: 'team-1',
          name: 'Glemt drikke',
          amount: 100,
        ),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupFineRules('team-1', rules);

      await tester.pumpWidget(
        createTestWidget(
          const FineRulesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bøteregler'), findsOneWidget);
      expect(find.text('For sent'), findsOneWidget);
      expect(find.text('Glemt drikke'), findsOneWidget);
      expect(find.text('50 kr'), findsOneWidget);
      expect(find.text('100 kr'), findsOneWidget);
    });

    testWidgets('fine rules screen shows empty state', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupFineRules('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const FineRulesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ingen bøteregler'), findsOneWidget);
    });

    testWidgets('fines summary shows balance', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupGetTeam(testTeam);
      scenario.setupWithTeamMembers('team-1', memberCount: 2);
      scenario.mocks.setupTeamFinesSummary(
        'team-1',
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

      // Outstanding = 1000 - 400 = 600
      expect(find.text('600 kr'), findsOneWidget);
    });

    testWidgets('fines screen has FAB to report fine', (tester) async {
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

    testWidgets('fine rules screen has FAB to add rule', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupFineRules('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const FineRulesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });
}
