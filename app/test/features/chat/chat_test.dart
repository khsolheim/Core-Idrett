import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:core_idrett/features/chat/presentation/unified_chat_screen.dart';
import 'package:core_idrett/data/models/conversation.dart';

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

  group('UnifiedChatScreen', () {
    // Note: UnifiedChatScreen uses ConsumerStatefulWidget with complex state.
    // We test error states and basic rendering which work reliably.

    testWidgets('renders app bar with title on narrow screen', (tester) async {
      // Set narrow screen size for mobile layout
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getAllConversations('team-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const UnifiedChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      // Narrow layout shows AppBar with title 'Meldinger'
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Meldinger'), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getAllConversations('team-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const UnifiedChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('shows error state when loading fails', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getAllConversations('team-1'))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const UnifiedChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(find.text('Prøv igjen'), findsOneWidget);
    });

    testWidgets('shows retry button on error', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getAllConversations('team-1'))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(
        createTestWidget(
          const UnifiedChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Prøv igjen'), findsOneWidget);
    });

    testWidgets('shows FAB for new conversation', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getAllConversations('team-1'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          const UnifiedChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows conversation list when data loads', (tester) async {
      scenario.setupLoggedIn();
      when(() => scenario.mocks.chatRepository.getAllConversations('team-1'))
          .thenAnswer((_) async => [
                ChatConversation(
                  type: ConversationType.team,
                  teamId: 'team-1',
                  name: 'Lag-chat',
                  unreadCount: 2,
                  lastMessage: 'Hei alle sammen!',
                  lastMessageAt: DateTime.now(),
                ),
              ]);

      await tester.pumpWidget(
        createTestWidget(
          const UnifiedChatScreen(teamId: 'team-1'),
          overrides: scenario.overrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lag-chat'), findsOneWidget);
      expect(find.text('Hei alle sammen!'), findsOneWidget);
    });
  });
}
