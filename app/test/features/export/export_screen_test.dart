import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/export/presentation/export_screen.dart';
import 'package:core_idrett/features/export/presentation/widgets/widgets.dart';
import 'package:core_idrett/features/export/providers/export_provider.dart';
import 'package:core_idrett/data/models/export_log.dart';

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

  group('ExportScreen rendering', () {
    testWidgets('renders app bar with title', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupExportHistory('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const ExportScreen(teamId: 'team-1', isAdmin: true),
          overrides: [
            ...scenario.overrides,
            exportHistoryProvider('team-1').overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Eksporter data'), findsOneWidget);
    });

    testWidgets('admin user sees all 5 ExportOptionCard widgets', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupExportHistory('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const ExportScreen(teamId: 'team-1', isAdmin: true),
          overrides: [
            ...scenario.overrides,
            exportHistoryProvider('team-1').overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 5 export option cards are rendered
      expect(find.byType(ExportOptionCard), findsNWidgets(5));

      // Verify specific export types are shown
      expect(find.text('Poengtabell'), findsOneWidget);
      expect(find.text('Oppmote'), findsOneWidget);
      expect(find.text('Boter'), findsOneWidget);
      expect(find.text('Aktiviteter'), findsOneWidget);
      expect(find.text('Medlemmer'), findsOneWidget);
    });

    testWidgets('non-admin user sees 4 ExportOptionCard widgets (members hidden)', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupExportHistory('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const ExportScreen(teamId: 'team-1', isAdmin: false),
          overrides: [
            ...scenario.overrides,
            exportHistoryProvider('team-1').overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify only 4 export option cards are rendered
      expect(find.byType(ExportOptionCard), findsNWidgets(4));

      // Verify members export is NOT shown
      expect(find.text('Medlemmer'), findsNothing);

      // Verify other export types are still shown
      expect(find.text('Poengtabell'), findsOneWidget);
      expect(find.text('Oppmote'), findsOneWidget);
      expect(find.text('Boter'), findsOneWidget);
      expect(find.text('Aktiviteter'), findsOneWidget);
    });

    testWidgets('shows section header for export options', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupExportHistory('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const ExportScreen(teamId: 'team-1', isAdmin: true),
          overrides: [
            ...scenario.overrides,
            exportHistoryProvider('team-1').overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Velg hva du vil eksportere'), findsOneWidget);
    });

    testWidgets('shows section header for export history', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupExportHistory('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const ExportScreen(teamId: 'team-1', isAdmin: true),
          overrides: [
            ...scenario.overrides,
            exportHistoryProvider('team-1').overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Eksporthistorikk'), findsOneWidget);
    });
  });

  group('ExportScreen with export history', () {
    testWidgets('empty history shows empty state', (tester) async {
      scenario.setupLoggedIn();
      scenario.mocks.setupExportHistory('team-1', []);

      await tester.pumpWidget(
        createTestWidget(
          const ExportScreen(teamId: 'team-1', isAdmin: true),
          overrides: [
            ...scenario.overrides,
            exportHistoryProvider('team-1').overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify history section is rendered but no ExportHistoryTile widgets
      expect(find.text('Eksporthistorikk'), findsOneWidget);
      expect(find.byType(ExportHistoryTile), findsNothing);
    });

    testWidgets('history with entries shows history section', (tester) async {
      final exportLogs = [
        ExportLog(
          id: 'log-1',
          teamId: 'team-1',
          userId: 'user-1',
          exportType: 'leaderboard',
          fileFormat: 'csv',
          createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
          userName: 'Ola Nordmann',
        ),
      ];
      scenario.setupLoggedIn();
      scenario.mocks.setupExportHistory('team-1', exportLogs);

      await tester.pumpWidget(
        createTestWidget(
          const ExportScreen(teamId: 'team-1', isAdmin: true),
          overrides: [
            ...scenario.overrides,
            exportHistoryProvider('team-1').overrideWith((ref) async => exportLogs),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify history section header is shown
      expect(find.text('Eksporthistorikk'), findsOneWidget);

      // Verify at least one Card widget exists (history is rendered in a Card)
      expect(find.byType(Card), findsWidgets);
    });
  });
}
