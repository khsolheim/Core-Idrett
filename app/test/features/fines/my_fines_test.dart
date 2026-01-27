import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/fines/presentation/my_fines_screen.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_data.dart';
import '../../helpers/mock_repositories.dart';

void main() {
  late TestScenario scenario;

  setUpAll(() async {
    registerFallbackValues();
    await initializeTestLocales();
  });

  setUp(() {
    scenario = TestScenario();
    resetAllTestFactories();
  });

  group('MyFinesScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupFinesList('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const MyFinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mine bøter'), findsOneWidget);
    });

    testWidgets('shows empty state when no fines', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupFinesList('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const MyFinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ingen bøter!'), findsOneWidget);
      expect(find.byIcon(Icons.celebration), findsOneWidget);
    });

    testWidgets('shows not logged in message when unauthenticated', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(
          const MyFinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ikke innlogget'), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.finesRepository.getFines(
            'team-1',
            status: any(named: 'status'),
            offenderId: any(named: 'offenderId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const MyFinesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Feil'), findsOneWidget);
    });
  });
}
