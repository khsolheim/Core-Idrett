# Phase 5: Frontend Widget Extraction - Research

**Researched:** 2026-02-09
**Domain:** Flutter widget composition, refactoring patterns, performance optimization
**Confidence:** HIGH

## Summary

Phase 5 focuses on extracting large widget files (8 files totaling 3,592 LOC) into smaller, composable components under 350 LOC each. The project has successfully completed two prior widget extraction phases (Fase 10 and Fase 21), establishing proven patterns: extract StatelessWidget/StatefulWidget components (not helper methods), maintain barrel exports for clean imports, preserve hot reload functionality, and ensure existing tests continue passing.

Flutter's official guidance strongly recommends widget composition over helper methods for performance: extracted widgets enable Flutter to rebuild only what changes, while const constructors allow aggressive caching. The project already follows clean architecture with feature-based structure, making extraction straightforward. Primary risks are BuildContext dependencies when extracting nested widgets and ensuring tests remain valid after extraction.

**Primary recommendation:** Follow established project patterns from prior extractions - extract cohesive UI sections into separate widget files, maintain barrel exports, prefer StatelessWidget with const constructors, and run existing widget tests after each file split to ensure functionality preservation.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter | 3.10+ | UI framework | Project requirement, widget system foundation |
| flutter_riverpod | ^2.4.0 | State management | Project's state management solution, ConsumerWidget base |
| go_router | latest | Navigation | Project routing, context-dependent navigation |
| intl | latest | Internationalization | Date formatting, Norwegian locale support |
| cached_network_image | latest | Image loading | Already used across project for avatars/images |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_test | SDK | Widget testing | Validate extracted widgets maintain functionality |
| path_provider | latest | File system access | Export screen file operations |
| share_plus | latest | File sharing | Export screen CSV sharing |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| StatelessWidget | Helper methods | Helper methods prevent Flutter rebuild optimization and const caching |
| Barrel exports | Direct imports | Direct imports create import path coupling when refactoring |
| Widget per file | Multiple widgets per file | Multiple widgets per file makes navigation harder, violates 350 LOC target |

**Installation:**
No new dependencies required - all libraries already in project.

## Architecture Patterns

### Recommended Project Structure
```
features/
├── feature_name/
│   └── presentation/
│       ├── screens/
│       │   └── feature_screen.dart      # Main screen, <350 LOC
│       └── widgets/
│           ├── widgets.dart             # Barrel export
│           ├── component_a.dart         # Extracted widget
│           ├── component_b.dart         # Extracted widget
│           └── private_component.dart   # Widget with _underscore prefix
```

### Pattern 1: Extract Cohesive UI Sections into StatelessWidget
**What:** Identify logical UI sections (cards, forms, dialogs, list items) and extract to separate StatelessWidget files
**When to use:** Any UI section that forms a logical unit or is 50+ lines
**Example:**
```dart
// Source: Project's existing activity_detail_screen.dart
// BEFORE: Inline widget in build method
Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Responses', style: theme.textTheme.titleMedium),
        ResponseSummary(...),
        ...instance.responses!.map((response) => ResponseListItem(response: response)),
      ],
    ),
  ),
)

// AFTER: Extracted to separate file responses_card.dart
class ResponsesCard extends StatelessWidget {
  final ActivityInstance instance;

  const ResponsesCard({super.key, required this.instance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Svar', style: theme.textTheme.titleMedium),
            ResponseSummary(
              yesCount: instance.yesCount ?? 0,
              noCount: instance.noCount ?? 0,
              maybeCount: instance.maybeCount ?? 0,
            ),
            if (instance.responses?.isEmpty ?? true)
              Text('Ingen har svart ennå', style: theme.textTheme.bodyMedium)
            else
              ...instance.responses!.map((r) => ResponseListItem(response: r)),
          ],
        ),
      ),
    );
  }
}
```

### Pattern 2: Use Private Widgets for Screen-Specific Components
**What:** Prefix widget class names with underscore (_) when they're only used within one screen file
**When to use:** Tabs, sheets, dialogs that are tightly coupled to a single screen
**Example:**
```dart
// Source: Project's existing test_detail_screen.dart
// Private widgets used only within test_detail_screen.dart
class _RankingTab extends StatelessWidget { ... }
class _ResultsTab extends StatelessWidget { ... }
class _RecordResultSheet extends ConsumerStatefulWidget { ... }

// Main screen imports these implicitly, no export needed
class TestDetailScreen extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return TabBarView(
      children: [
        _RankingTab(ranking: state.ranking),
        _ResultsTab(results: state.results),
      ],
    );
  }
}
```

### Pattern 3: Create Barrel Exports for Clean Imports
**What:** Create widgets.dart barrel file that exports all public widgets from the folder
**When to use:** Every widgets/ folder with 2+ extracted files
**Example:**
```dart
// Source: Project's existing activities/presentation/widgets/widgets.dart
// Barrel file widgets.dart
export 'absence_button.dart';
export 'activity_info_widgets.dart';
export 'activity_response_widgets.dart';
export 'admin_actions_section.dart';
export 'mini_activities_section.dart';
// Note: Private widgets NOT exported

// Other files can now import all widgets with single import
import '../widgets/widgets.dart';
```

### Pattern 4: Pass Dependencies Through Constructors
**What:** Pass required data and callbacks explicitly through widget constructors, avoid relying on implicit BuildContext dependencies
**When to use:** Every extracted widget
**Example:**
```dart
// GOOD: Explicit dependencies
class ExportOptionCard extends StatelessWidget {
  final ExportType type;
  final bool isExporting;
  final VoidCallback onExport;

  const ExportOptionCard({
    super.key,
    required this.type,
    required this.isExporting,
    required this.onExport,
  });
}

// AVOID: Hidden BuildContext dependencies without Builder
class BadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This context might not have access to parent InheritedWidgets
    final theme = Theme.of(context); // May fail if extracted incorrectly
  }
}
```

### Pattern 5: Preserve Riverpod Integration
**What:** Use ConsumerWidget/ConsumerStatefulWidget for widgets that need ref, StatelessWidget for pure presentation
**When to use:** Extracted widgets that read providers or call notifier methods
**Example:**
```dart
// Source: Project's existing message_widgets.dart
class NewConversationSheet extends ConsumerWidget {
  final String teamId;

  const NewConversationSheet({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final currentUserId = ref.watch(authStateProvider.select((a) => a.value?.id));

    return membersAsync.when2(
      onRetry: () => ref.invalidate(teamMembersProvider(teamId)),
      data: (members) => ListView.builder(...),
    );
  }
}
```

### Anti-Patterns to Avoid
- **Helper Methods Instead of Widgets:** `Widget _buildHeader() { return ... }` prevents Flutter rebuild optimization and const caching
- **God Widgets:** Single widget file over 350 LOC with multiple responsibilities
- **BuildContext Misuse:** Passing context to async methods or using context after await without mounted check
- **Breaking Barrel Exports:** Moving widgets without updating barrel file breaks imports across codebase
- **Over-Extraction:** Creating single-use 10-line widgets adds navigation overhead without clarity benefit

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Import management | Manual import updates after extraction | Barrel exports (widgets.dart) | IDE auto-import breaks with file moves, barrel exports maintain stable import paths |
| Widget rebuild optimization | Helper method extraction | StatelessWidget/StatefulWidget extraction | Flutter can't optimize helper method rebuilds, widgets enable element tree caching |
| Const widget caching | Mutable widget constructors | const constructors with final fields | Flutter aggressively caches const widgets, reducing rebuild work |
| BuildContext scope | Implicit context passing | Explicit constructor parameters or Builder widget | Context scope changes during extraction cause InheritedWidget lookup failures |
| Test fixtures | New test setup after extraction | Existing TestApp/TestScenario helpers | Project has test helpers in app/test/helpers/ for widget testing |

**Key insight:** Flutter's widget system is designed for composition - extracting widgets isn't just about code organization, it's about enabling performance optimizations through const caching and selective rebuilds. Helper methods look similar but bypass these optimizations.

## Common Pitfalls

### Pitfall 1: BuildContext Scope Changes After Extraction
**What goes wrong:** Widget accesses Theme.of(context) or Navigator.of(context), but extracted widget's context doesn't have access to the InheritedWidget ancestor
**Why it happens:** Every widget build creates a new BuildContext - extracting a widget changes which context is used for lookups
**How to avoid:**
- Pass BuildContext explicitly if widget needs it: `final theme = Theme.of(context);` then pass `theme` to extracted widget
- Use Builder widget to create new context scope: `Builder(builder: (context) => ExtractedWidget())`
- For navigation, pass callback instead of relying on context: `final VoidCallback onTap;`
**Warning signs:** Tests fail with "Theme.of() called with context that doesn't contain ancestor", Navigator.of() returns null

### Pitfall 2: Breaking Imports When Moving Widgets
**What goes wrong:** Move widget to new file, other files importing it break with "Undefined name"
**Why it happens:** Import paths hardcoded to old location, barrel export not updated
**How to avoid:**
1. Create/update barrel export first
2. Move widget to new file
3. Export from barrel file
4. Update old file to import from barrel
5. Run flutter analyze to find broken imports
**Warning signs:** flutter analyze shows import errors, hot reload fails with compilation errors

### Pitfall 3: Losing Const Optimization
**What goes wrong:** Extracted widget rebuilds unnecessarily, performance degrades
**Why it happens:** Forgot const constructor or used non-final fields
**How to avoid:**
- Always add const constructor: `const MyWidget({super.key, required this.data});`
- Make all fields final: `final String data;`
- Use const when instantiating: `const MyWidget(data: 'static')`
**Warning signs:** Performance profiler shows widget rebuilding when parent rebuilds, hot reload slow

### Pitfall 4: Over-Extracting Private Implementation Details
**What goes wrong:** Extract every 20-line section, end up with 20+ widget files, navigation becomes difficult
**Why it happens:** Misunderstanding "small widgets" guidance - it means logical units, not arbitrary line counts
**How to avoid:**
- Extract cohesive UI sections: cards, forms, dialogs, complex list items
- Keep helper widgets private (_MyHelper) in same file if only used once
- Target 50-200 LOC per extracted widget, not 20-30
**Warning signs:** More than 15 files in widgets/ folder, difficulty finding widgets, widgets only used once

### Pitfall 5: Breaking Widget Tests After Extraction
**What goes wrong:** Existing widget tests fail because widget tree structure changed
**Why it happens:** Tests use find.byType() or find.byKey() that expect old widget structure
**How to avoid:**
- Run existing tests after each extraction: `flutter test test/features/[feature]/`
- Preserve Widget Keys on important elements for testing
- Update finders to match new structure if needed
- Use semantic finders (find.text(), find.byIcon()) over structural finders when possible
**Warning signs:** Widget tests that passed before fail after extraction, find.byType() returns zero widgets

### Pitfall 6: Losing StatefulWidget State After Extraction
**What goes wrong:** Extract StatefulWidget section, state resets on every parent rebuild
**Why it happens:** Flutter's element tree identity based on widget Type and position - moving widget changes identity
**How to avoid:**
- Preserve GlobalKey if state must survive: `final GlobalKey<MyWidgetState> myKey = GlobalKey();`
- Consider whether state should live in parent or provider instead
- For forms, keep TextEditingController in parent or provider
**Warning signs:** Form fields reset, scroll position lost, animation restarts unexpectedly

## Code Examples

Verified patterns from project's existing extractions:

### Extracting Dialog/Sheet Widgets
```dart
// Source: Project's message_widgets.dart
// Extracted sheet with DraggableScrollableSheet pattern
class NewConversationSheet extends ConsumerWidget {
  final String teamId;

  const NewConversationSheet({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Ny samtale', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: membersAsync.when2(
                onRetry: () => ref.invalidate(teamMembersProvider(teamId)),
                data: (members) => ListView.builder(
                  controller: scrollController,
                  itemCount: members.length,
                  itemBuilder: (context, index) => ListTile(...),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

### Extracting List Item Widgets
```dart
// Source: Project's dashboard_info_widgets.dart
// Extracted reusable list item with CachedNetworkImage
class DashboardLeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const DashboardLeaderboardRow({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: DashboardRankBadge(rank: entry.rank),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 16,
            backgroundImage: entry.avatarUrl != null
                ? CachedNetworkImageProvider(entry.avatarUrl!)
                : null,
            child: entry.avatarUrl == null
                ? Text(entry.userName.substring(0, 1).toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(entry.userName, style: theme.textTheme.bodyMedium),
          ),
          Text(
            '${entry.totalPoints}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
```

### Extracting Card Widgets with Actions
```dart
// Source: Project's export_screen.dart pattern
// Extracted card with loading state and callbacks
class ExportOptionCard extends StatelessWidget {
  final ExportType type;
  final bool isExporting;
  final VoidCallback onExport;

  const ExportOptionCard({
    super.key,
    required this.type,
    required this.isExporting,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(_getIcon(), color: theme.colorScheme.primary),
        ),
        title: Text(type.displayName),
        subtitle: Text(type.description),
        trailing: isExporting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.download),
                onPressed: onExport,
              ),
        onTap: isExporting ? null : onExport,
      ),
    );
  }

  IconData _getIcon() {
    switch (type) {
      case ExportType.leaderboard: return Icons.leaderboard;
      case ExportType.attendance: return Icons.how_to_reg;
      case ExportType.fines: return Icons.receipt_long;
      case ExportType.activities: return Icons.event;
      case ExportType.members: return Icons.people;
    }
  }
}
```

### Extracting Form/Input Sections
```dart
// Source: Project's test_detail_screen.dart pattern
// Extracted form sheet with validation
class _RecordResultSheet extends ConsumerStatefulWidget {
  final String teamId;
  final TestTemplate template;
  final Function(String userId, double value, String? notes) onSave;

  const _RecordResultSheet({
    required this.teamId,
    required this.template,
    required this.onSave,
  });

  @override
  ConsumerState<_RecordResultSheet> createState() => _RecordResultSheetState();
}

class _RecordResultSheetState extends ConsumerState<_RecordResultSheet> {
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedUserId;

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSave {
    return _selectedUserId != null &&
        _valueController.text.isNotEmpty &&
        double.tryParse(_valueController.text.replaceAll(',', '.')) != null;
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(teamMembersProvider(widget.teamId));
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Registrer resultat', style: theme.textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Form fields
          membersAsync.when2(
            onRetry: () => ref.invalidate(teamMembersProvider(widget.teamId)),
            data: (members) => DropdownButtonFormField<String>(
              value: _selectedUserId,
              decoration: const InputDecoration(
                labelText: 'Velg spiller *',
                border: OutlineInputBorder(),
              ),
              items: members.map((m) => DropdownMenuItem(
                value: m.userId,
                child: Text(m.userName),
              )).toList(),
              onChanged: (value) => setState(() => _selectedUserId = value),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: 'Resultat (${widget.template.unit}) *',
              border: const OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _canSave ? _save : null,
            child: const Text('Lagre'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final value = double.parse(_valueController.text.replaceAll(',', '.'));
    widget.onSave(_selectedUserId!, value, _notesController.text.trim().isEmpty ? null : _notesController.text.trim());
  }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Helper methods (_buildWidget) | StatelessWidget extraction | Flutter 1.0+ best practice | Enables rebuild optimization and const caching |
| Manual imports | Barrel exports | Dart best practice | Stable import paths during refactoring |
| God widgets (1000+ LOC) | Focused widgets (<350 LOC) | Ongoing refactoring | Improved maintainability and hot reload speed |
| Direct file imports | Feature-scoped barrel files | Project Fase 10/21 | Cleaner imports, easier refactoring |

**Deprecated/outdated:**
- **Widget helper methods:** Still functional but bypasses Flutter's rebuild optimization and const caching - use StatelessWidget instead
- **Multiple exports per feature:** Old approach had no barrel files - now use widgets.dart barrel pattern established in Fase 10/21

## Open Questions

1. **Should all 8 files be split simultaneously or sequentially?**
   - What we know: Phase 4 (backend stable) is prerequisite, suggests backend won't interfere
   - What's unclear: Risk of merge conflicts if splitting all files in parallel
   - Recommendation: Sequential approach with 2-3 files per plan, allows testing between batches

2. **What's the appropriate granularity for extraction?**
   - What we know: Project targets <350 LOC per file, existing extractions show 50-200 LOC widgets
   - What's unclear: Minimum size threshold - avoid over-extraction
   - Recommendation: Extract sections 50+ LOC that form logical UI units (cards, forms, dialogs), keep single-use helpers private

3. **How to handle widgets with complex state interactions?**
   - What we know: Some widgets (edit_team_members_tab.dart) manage multiple state variables
   - What's unclear: Whether to keep state in parent or move to provider
   - Recommendation: Preserve existing state management approach during extraction, don't combine extraction with state refactoring

4. **Are there performance benchmarks to validate extraction success?**
   - What we know: Flutter DevTools can profile widget rebuild times
   - What's unclear: Project doesn't have documented baseline metrics
   - Recommendation: Use hot reload speed and widget test execution time as pragmatic success indicators

## Sources

### Primary (HIGH confidence)
- [Flutter Performance Best Practices](https://docs.flutter.dev/perf/best-practices) - Official Flutter documentation on widget composition and splitting
- [Flutter Hot Reload](https://docs.flutter.dev/tools/hot-reload) - Official documentation on hot reload behavior with widget extraction
- [StatelessWidget API](https://api.flutter.dev/flutter/widgets/StatelessWidget-class.html) - Official API documentation
- Project codebase - Existing widget extraction patterns from Fase 10 and Fase 21, barrel exports in all feature/presentation/widgets/ folders

### Secondary (MEDIUM confidence)
- [How to Split Big Widget Files into Smaller Parts in Flutter](https://www.logique.co.id/blog/en/2025/08/21/how-to-split-big-widget-files/) - Practical extraction patterns and common pitfalls
- [Why Splitting Widgets Into Methods is Actually a Bad Habit](https://medium.com/@vortj/flutter-daily-why-splitting-widgets-into-methods-is-actually-a-bad-habit-dad3edc3eead) - Performance implications of helper methods vs widgets
- [What's new in Flutter 3.35](https://blog.flutter.dev/whats-new-in-flutter-3-35-c58ef72e3766) - Hot reload improvements and widget preview tools
- [Barrel Files in Dart and Flutter](https://medium.com/@ugamakelechi501/barrel-files-in-dart-and-flutter-a-guide-to-simplifying-imports-9b245dbe516a) - Barrel export pattern and benefits
- [Flutter Widget Testing Guide](https://docs.flutter.dev/cookbook/testing/widget/introduction) - Official widget testing documentation
- [Navigating the Hard Parts of Testing in Flutter](https://dcm.dev/blog/2025/07/30/navigating-hard-parts-testing-flutter-developers) - Testing considerations during refactoring

### Tertiary (LOW confidence)
- [Why Every Flutter Dev Should Care About BuildContext](https://getstream.io/blog/flutter-buildcontext/) - BuildContext scope issues, not Flutter-official but widely referenced
- [Flutter Naming Conventions](https://medium.com/@irfandev/best-naming-conventions-for-flutter-projects-ca681268ad78) - Community conventions for private widget naming

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All libraries already in project, verified in pubspec.yaml and codebase
- Architecture: HIGH - Patterns extracted from project's existing Fase 10/21 widget extractions, verified in codebase
- Pitfalls: HIGH - Based on Flutter official docs + project's actual file structure showing barrel exports and widget organization

**Research date:** 2026-02-09
**Valid until:** 30 days (2026-03-11) - Flutter stable ecosystem, widget composition patterns unlikely to change
