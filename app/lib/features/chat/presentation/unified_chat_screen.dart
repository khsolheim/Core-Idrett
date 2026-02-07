import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/unified_chat_provider.dart';
import 'widgets/conversation_list_panel.dart';
import 'widgets/chat_panel.dart';

class UnifiedChatScreen extends ConsumerStatefulWidget {
  final String teamId;

  const UnifiedChatScreen({super.key, required this.teamId});

  @override
  ConsumerState<UnifiedChatScreen> createState() => _UnifiedChatScreenState();
}

class _UnifiedChatScreenState extends ConsumerState<UnifiedChatScreen> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;

        if (isWide) {
          return WideChatLayout(teamId: widget.teamId);
        } else {
          return NarrowChatLayout(teamId: widget.teamId);
        }
      },
    );
  }
}

/// Wide layout with split view (conversation list + chat panel)
class WideChatLayout extends ConsumerWidget {
  final String teamId;

  const WideChatLayout({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedConversationProvider);

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 320,
            child: ConversationListPanel(teamId: teamId),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selected != null
                ? ChatPanel(teamId: teamId, conversation: selected)
                : const EmptyChatPanel(),
          ),
        ],
      ),
    );
  }
}

/// Narrow layout with navigation between list and chat
class NarrowChatLayout extends ConsumerWidget {
  final String teamId;

  const NarrowChatLayout({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedConversationProvider);

    if (selected == null) {
      return ConversationListPanel(teamId: teamId, showAppBar: true);
    } else {
      return ChatPanel(
        teamId: teamId,
        conversation: selected,
        showBackButton: true,
      );
    }
  }
}
