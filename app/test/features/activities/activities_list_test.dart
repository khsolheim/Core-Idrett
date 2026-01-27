import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/activities/presentation/activities_screen.dart';
import 'package:core_idrett/data/models/activity.dart';

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

  group('ActivitiesScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithActivities('team-1', activityCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ActivitiesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aktiviteter'), findsOneWidget);
    });

    testWidgets('shows calendar icon in app bar', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithActivities('team-1', activityCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ActivitiesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_month), findsOneWidget);
    });

    testWidgets('shows empty state when no activities', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithActivities('team-1', activityCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ActivitiesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ingen kommende aktiviteter'), findsOneWidget);
      expect(find.byIcon(Icons.event_busy), findsOneWidget);
    });

    testWidgets('shows activity list when activities exist', (tester) async {
      final activities = [
        TestActivityInstanceFactory.create(
          title: 'Trening mandag',
          type: ActivityType.training,
          teamId: 'team-1',
        ),
        TestActivityInstanceFactory.create(
          title: 'Kamp lørdag',
          type: ActivityType.match,
          teamId: 'team-1',
        ),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupActivityInstances('team-1', activities);

      await tester.pumpWidget(
        createTestWidget(
          const ActivitiesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trening mandag'), findsOneWidget);
      expect(find.text('Kamp lørdag'), findsOneWidget);
    });

    testWidgets('shows FAB to create new activity', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithActivities('team-1', activityCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ActivitiesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Ny aktivitet'), findsOneWidget);
    });

    testWidgets('shows error state with retry button', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.activityRepository.getUpcomingInstances(
            'team-1',
            limit: any(named: 'limit'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const ActivitiesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Prøv igjen'), findsOneWidget);
    });

    testWidgets('shows activity type icons correctly', (tester) async {
      final activities = [
        TestActivityInstanceFactory.create(
          title: 'Training Session',
          type: ActivityType.training,
          teamId: 'team-1',
        ),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupActivityInstances('team-1', activities);

      await tester.pumpWidget(
        createTestWidget(
          const ActivitiesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
    });

    testWidgets('renders activity card with response info', (tester) async {
      final activities = [
        TestActivityInstanceFactory.create(
          title: 'Team Event',
          type: ActivityType.social,
          teamId: 'team-1',
          yesCount: 5,
          noCount: 2,
          maybeCount: 3,
        ),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupActivityInstances('team-1', activities);

      await tester.pumpWidget(
        createTestWidget(
          const ActivitiesScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify activity card is rendered with title
      expect(find.text('Team Event'), findsOneWidget);
    });
  });
}
