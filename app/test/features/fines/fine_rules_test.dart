import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/fines/presentation/fine_rules_screen.dart';

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

  group('FineRulesScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithFineRules('team-1', ruleCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const FineRulesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bøteregler'), findsOneWidget);
    });

    testWidgets('shows FAB to create new rule', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithFineRules('team-1', ruleCount: 0);

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

    testWidgets('shows empty state when no rules', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithFineRules('team-1', ruleCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const FineRulesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ingen bøteregler'), findsOneWidget);
    });

    testWidgets('shows rules list when rules exist', (tester) async {
      final rules = [
        TestFineRuleFactory.create(
          id: 'rule-1',
          teamId: 'team-1',
          name: 'For sent på trening',
          amount: 50,
          active: true,
        ),
        TestFineRuleFactory.create(
          id: 'rule-2',
          teamId: 'team-1',
          name: 'Glemt utstyr',
          amount: 100,
          active: true,
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

      expect(find.text('For sent på trening'), findsOneWidget);
      expect(find.text('Glemt utstyr'), findsOneWidget);
      expect(find.text('50 kr'), findsOneWidget);
      expect(find.text('100 kr'), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.finesRepository.getFineRules(
            'team-1',
            activeOnly: any(named: 'activeOnly'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const FineRulesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Prøv igjen'), findsOneWidget);
    });

    testWidgets('shows popup menu for rule actions', (tester) async {
      final rules = [
        TestFineRuleFactory.create(
          id: 'rule-1',
          teamId: 'team-1',
          name: 'Test Rule',
          amount: 50,
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

      // Find and tap popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Rediger'), findsOneWidget);
      expect(find.text('Slett'), findsOneWidget);
    });
  });
}
