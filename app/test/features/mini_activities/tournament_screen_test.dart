import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/mini_activities/presentation/screens/tournament_screen.dart';
import 'package:core_idrett/features/mini_activities/providers/tournament_provider.dart';
import 'package:core_idrett/data/models/tournament.dart';

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

  group('TournamentScreen loading state', () {
    testWidgets('shows CircularProgressIndicator while tournament is loading', (tester) async {
      scenario.setupLoggedIn();

      // Setup tournament repository to return data slowly
      when(() => scenario.mocks.tournamentRepository.getTournament('tourn-1'))
          .thenAnswer((_) async {
        // Simulate async delay
        await Future.delayed(const Duration(milliseconds: 100));
        return Tournament(
          id: 'tourn-1',
          miniActivityId: 'mini-1',
          tournamentType: TournamentType.singleElimination,
          createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
        );
      });

      await tester.pumpWidget(
        createTestWidget(
          const TournamentScreen(
            tournamentId: 'tourn-1',
            miniActivityId: 'mini-1',
          ),
          overrides: scenario.overrides,
        ),
      );

      // Use pump() without duration to catch loading state
      await tester.pump();

      // Verify loading indicator is shown while data is being fetched
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the async operations
      await tester.pumpAndSettle();
    });
  });

  group('TournamentScreen with data', () {
    testWidgets('renders tournament content when data is loaded', (tester) async {
      final tournament = Tournament(
        id: 'tourn-1',
        miniActivityId: 'mini-1',
        tournamentType: TournamentType.singleElimination,
        status: TournamentStatus.inProgress,
        createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
      );

      scenario.setupLoggedIn();
      scenario.mocks.setupGetTournament(tournament);

      // Mock the rounds and matches providers to return empty lists
      when(() => scenario.mocks.tournamentRepository.getRounds('tourn-1'))
          .thenAnswer((_) async => []);
      when(() => scenario.mocks.tournamentRepository.getMatches('tourn-1', roundId: any(named: 'roundId')))
          .thenAnswer((_) async => []);
      when(() => scenario.mocks.tournamentRepository.getGroups('tourn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const TournamentScreen(
            tournamentId: 'tourn-1',
            miniActivityId: 'mini-1',
          ),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify tournament content is rendered (no loading indicator)
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Verify AppBar is shown
      expect(find.byType(AppBar), findsOneWidget);

      // Verify TabBar is shown with tabs
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Bracket'), findsOneWidget);
      expect(find.text('Kamper'), findsOneWidget);
    });

    testWidgets('shows tournament type name in AppBar', (tester) async {
      final tournament = Tournament(
        id: 'tourn-1',
        miniActivityId: 'mini-1',
        tournamentType: TournamentType.singleElimination,
        status: TournamentStatus.inProgress,
        createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
      );

      scenario.setupLoggedIn();
      scenario.mocks.setupGetTournament(tournament);

      // Mock the rounds and matches providers
      when(() => scenario.mocks.tournamentRepository.getRounds('tourn-1'))
          .thenAnswer((_) async => []);
      when(() => scenario.mocks.tournamentRepository.getMatches('tourn-1', roundId: any(named: 'roundId')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const TournamentScreen(
            tournamentId: 'tourn-1',
            miniActivityId: 'mini-1',
          ),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify tournament type display name is shown in AppBar
      expect(find.text(TournamentType.singleElimination.displayName), findsOneWidget);
    });

    testWidgets('shows settings icon in AppBar', (tester) async {
      final tournament = Tournament(
        id: 'tourn-1',
        miniActivityId: 'mini-1',
        tournamentType: TournamentType.singleElimination,
        status: TournamentStatus.inProgress,
        createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
      );

      scenario.setupLoggedIn();
      scenario.mocks.setupGetTournament(tournament);

      // Mock the rounds and matches providers
      when(() => scenario.mocks.tournamentRepository.getRounds('tourn-1'))
          .thenAnswer((_) async => []);
      when(() => scenario.mocks.tournamentRepository.getMatches('tourn-1', roundId: any(named: 'roundId')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const TournamentScreen(
            tournamentId: 'tourn-1',
            miniActivityId: 'mini-1',
          ),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify settings icon is shown
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('shows FAB for draft tournaments', (tester) async {
      final tournament = Tournament(
        id: 'tourn-1',
        miniActivityId: 'mini-1',
        tournamentType: TournamentType.singleElimination,
        status: TournamentStatus.draft,
        createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
      );

      scenario.setupLoggedIn();
      scenario.mocks.setupGetTournament(tournament);

      // Mock the rounds and matches providers
      when(() => scenario.mocks.tournamentRepository.getRounds('tourn-1'))
          .thenAnswer((_) async => []);
      when(() => scenario.mocks.tournamentRepository.getMatches('tourn-1', roundId: any(named: 'roundId')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const TournamentScreen(
            tournamentId: 'tourn-1',
            miniActivityId: 'mini-1',
          ),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify FAB is shown for draft tournaments
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Generer bracket'), findsOneWidget);
    });

    testWidgets('does not show FAB for inProgress tournaments', (tester) async {
      final tournament = Tournament(
        id: 'tourn-1',
        miniActivityId: 'mini-1',
        tournamentType: TournamentType.singleElimination,
        status: TournamentStatus.inProgress,
        createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
      );

      scenario.setupLoggedIn();
      scenario.mocks.setupGetTournament(tournament);

      // Mock the rounds and matches providers
      when(() => scenario.mocks.tournamentRepository.getRounds('tourn-1'))
          .thenAnswer((_) async => []);
      when(() => scenario.mocks.tournamentRepository.getMatches('tourn-1', roundId: any(named: 'roundId')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const TournamentScreen(
            tournamentId: 'tourn-1',
            miniActivityId: 'mini-1',
          ),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify FAB is NOT shown for inProgress tournaments
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('shows Grupper tab for group tournament types', (tester) async {
      final tournament = Tournament(
        id: 'tourn-1',
        miniActivityId: 'mini-1',
        tournamentType: TournamentType.groupPlay,
        status: TournamentStatus.inProgress,
        createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
      );

      scenario.setupLoggedIn();
      scenario.mocks.setupGetTournament(tournament);

      // Mock the rounds, matches, and groups providers
      when(() => scenario.mocks.tournamentRepository.getRounds('tourn-1'))
          .thenAnswer((_) async => []);
      when(() => scenario.mocks.tournamentRepository.getMatches('tourn-1', roundId: any(named: 'roundId')))
          .thenAnswer((_) async => []);
      when(() => scenario.mocks.tournamentRepository.getGroups('tourn-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const TournamentScreen(
            tournamentId: 'tourn-1',
            miniActivityId: 'mini-1',
          ),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Verify all three tabs are shown for group tournaments
      expect(find.text('Bracket'), findsOneWidget);
      expect(find.text('Kamper'), findsOneWidget);
      expect(find.text('Grupper'), findsOneWidget);
    });
  });
}
