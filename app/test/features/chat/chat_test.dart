import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/chat/presentation/chat_screen.dart';

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

  group('ChatScreen', () {
    // Note: ChatScreen uses ConsumerStatefulWidget with complex state.
    // We test error states and basic rendering which work reliably.

    testWidgets('renders app bar with title', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getMessages(
            'team-1',
            limit: any(named: 'limit'),
            before: any(named: 'before'),
            after: any(named: 'after'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const ChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('shows refresh button in app bar', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getMessages(
            'team-1',
            limit: any(named: 'limit'),
            before: any(named: 'before'),
            after: any(named: 'after'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const ChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('shows message input field', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getMessages(
            'team-1',
            limit: any(named: 'limit'),
            before: any(named: 'before'),
            after: any(named: 'after'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const ChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Skriv en melding...'), findsOneWidget);
    });

    testWidgets('shows send button', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getMessages(
            'team-1',
            limit: any(named: 'limit'),
            before: any(named: 'before'),
            after: any(named: 'after'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const ChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getMessages(
            'team-1',
            limit: any(named: 'limit'),
            before: any(named: 'before'),
            after: any(named: 'after'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const ChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Kunne ikke laste meldinger'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getMessages(
            'team-1',
            limit: any(named: 'limit'),
            before: any(named: 'before'),
            after: any(named: 'after'),
          )).thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const ChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prov igjen'), findsOneWidget);
    });
  });
}
