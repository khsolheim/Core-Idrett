import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/profile/presentation/profile_screen.dart';
import 'package:core_idrett/data/models/user.dart';

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

  group('ProfileScreen', () {
    testWidgets('renders app bar with title', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Min profil'), findsOneWidget);
    });

    testWidgets('shows edit button in app bar', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('shows user name', (tester) async {
      final user = TestUserFactory.create(
        id: 'user-1',
        name: 'Test User',
        email: 'test@example.com',
      );
      scenario.setupLoggedIn(user: user);
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows user email', (tester) async {
      final user = TestUserFactory.create(
        id: 'user-1',
        name: 'Test User',
        email: 'test@example.com',
      );
      scenario.setupLoggedIn(user: user);
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('shows not logged in when unauthenticated', (tester) async {
      scenario.setupLoggedOut();

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ikke innlogget'), findsOneWidget);
    });

    testWidgets('shows information section', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Informasjon'), findsOneWidget);
    });

    testWidgets('shows my teams section', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mine lag'), findsOneWidget);
    });

    testWidgets('shows logout button', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Logg ut'), findsOneWidget);
    });

    testWidgets('shows settings button', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Innstillinger'), findsOneWidget);
    });

    testWidgets('shows team count when teams exist', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 2);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows no teams message when empty', (tester) async {
      scenario.setupLoggedIn();
      scenario.setupWithTeams(teamCount: 0);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Du er ikke medlem'), findsOneWidget);
    });
  });
}
