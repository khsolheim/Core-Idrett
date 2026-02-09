# Phase 7: Code Consistency Patterns - Research

**Researched:** 2026-02-09
**Domain:** Code style consistency, pattern enforcement, architectural standardization
**Confidence:** HIGH

## Summary

Phase 7 addresses consistency across backend handlers, API responses, frontend UI patterns, and error handling. The codebase already has established patterns from Fase 1-22 refactoring, but inconsistencies remain in formatting (single-line vs multi-line returns), API response envelopes (raw data vs `{success: true}` wrappers), and UI spacing/padding values.

The research reveals that **the patterns themselves are already defined and working** - this phase is about **enforcement and elimination of variations**. Prior phases established: auth_helpers.dart (Fase 1), response_helpers.dart (Fase 1), when2() extension (Fase 6), EmptyStateWidget (Fase 6), ErrorDisplayService (Fase 18). The work is identifying and standardizing the variations.

**Primary recommendation:** Create linting rules where possible, document patterns explicitly, and systematically audit/fix variations. Focus on automated detection over manual review.

## Current State Analysis

### Backend Handlers (32 total)

**Auth Pattern Compliance:**
- ✅ All 32 handlers import `response_helpers.dart`
- ✅ 251 `getUserId()` calls across handlers (consistent usage)
- ✅ 116 `requireTeamMember()` calls (team membership checks)
- ✅ 62 `isAdmin()` calls for role authorization
- ⚠️ **Inconsistency:** Single-line vs multi-line return statements

**Examples:**
```dart
// Pattern A (teams_handler): Multi-line
if (userId == null) {
  return resp.unauthorized();
}

// Pattern B (fines_handler): Single-line
if (userId == null) return resp.unauthorized();
```

**API Response Patterns:**
- ✅ All handlers use `resp.ok()` from response_helpers
- ⚠️ **Inconsistency:** Response envelopes vary
  - `resp.ok(teams)` - raw array
  - `resp.ok(team.toJson())` - raw object
  - `resp.ok({'success': true})` - wrapper object
  - `resp.ok({'rules': rules.map((r) => r.toJson()).toList()})` - named envelope

### Frontend Screens (38 total)

**AsyncValue Pattern Compliance:**
- ✅ 71 `when2()` usages across 54 files
- ✅ 26 `EmptyStateWidget` usages across 22 files
- ⚠️ **Gap:** 16 screens still don't use EmptyStateWidget pattern
- ⚠️ **Gap:** Some screens use `.isLoading` checks instead of when2()

**Error Handling Compliance:**
- ✅ 82 `ErrorDisplayService.show*()` calls across 18 files
- ⚠️ **Inconsistency:** 34 files still use raw `SnackBar()` and `ScaffoldMessenger.of(context)`
- ⚠️ **Inconsistency:** Direct error string construction instead of ErrorDisplayService

**Spacing/Padding Patterns:**
Analysis of EdgeInsets usage across features:
- `EdgeInsets.all(16)`: 118 occurrences (most common)
- `EdgeInsets.all(12)`: 27 occurrences
- `EdgeInsets.all(8)`: 10 occurrences
- `EdgeInsets.symmetric(horizontal: 16)`: 22 occurrences
- `EdgeInsets.symmetric(horizontal: 8)`: 26 occurrences
- **Finding:** Wide variety (16 different padding patterns), no clear standard

SizedBox height spacing:
- `height: 16`: 166 occurrences (most common)
- `height: 8`: 128 occurrences (second most)
- `height: 12`: 49 occurrences
- `height: 24`: 46 occurrences
- **Finding:** 4-8-12-16-24 scale exists but not consistently applied

Theme defines border radius (12px) but no spacing constants.

## Standard Patterns (Established)

### Backend: Handler Auth Flow

**Source:** `/backend/lib/api/helpers/auth_helpers.dart` (Fase 1)

```dart
// Step 1: Extract userId
final userId = getUserId(request);

// Step 2: Null check (401 if not authenticated)
if (userId == null) {
  return resp.unauthorized();
}

// Step 3: Team membership check (403 if not member)
final team = await requireTeamMember(_teamService, teamId, userId);
if (team == null) {
  return resp.forbidden('Ingen tilgang til dette laget');
}

// Step 4: Role check (403 if insufficient permission)
if (!isAdmin(team)) {
  return resp.forbidden('Kun administratorer kan utføre denne handlingen');
}

// Step 5: Business logic
```

**Rationale:** Clear separation of concerns. 401 = not authenticated, 403 = authenticated but insufficient permission.

### Backend: Response Helpers

**Source:** `/backend/lib/api/helpers/response_helpers.dart` (Fase 1)

All handlers must use:
- `resp.ok(data)` - 200 with JSON
- `resp.unauthorized([msg])` - 401 with optional message
- `resp.forbidden([msg])` - 403 with optional message
- `resp.badRequest(msg)` - 400 with required message
- `resp.notFound([msg])` - 404 with optional message
- `resp.serverError([msg])` - 500 with optional message

**Norwegian messages:** All error messages in Norwegian (Fase 14)
**No raw errors:** Never include `$e` in error responses (Fase 14)

### Backend: Permission Helpers

**Source:** `/backend/lib/api/helpers/permission_helpers.dart`

```dart
/// Check if user can manage fines (admin or fine_boss)
bool isFinesManager(Map<String, dynamic> team) {
  return team['user_is_admin'] == true || team['user_is_fine_boss'] == true;
}

/// Check if user is a coach or admin
bool isCoachOrAdmin(Map<String, dynamic> team) {
  return team['user_is_admin'] == true || team['user_is_coach'] == true;
}
```

**Used by:** Only fines_handler currently. Could be applied to other handlers.

### Frontend: AsyncValue Handling

**Source:** `/app/lib/core/extensions/async_value_extensions.dart` (Fase 6)

```dart
// Standard pattern for async data
final dataAsync = ref.watch(someProvider);

return dataAsync.when2(
  onRetry: () => ref.invalidate(someProvider),
  data: (data) {
    if (data.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inbox_outlined,
        title: 'Ingen data',
        subtitle: 'Det er ingen data å vise',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, index) => _buildItem(data[index]),
    );
  },
);
```

**Benefits:**
- Automatic loading state
- Automatic error handling with retry
- Type-safe data access
- Consistent error UI via AppErrorWidget

### Frontend: Empty States

**Source:** `/app/lib/shared/widgets/empty_state_widget.dart` (Fase 6)

```dart
EmptyStateWidget(
  icon: Icons.icon_name,
  title: 'Norwegian title',
  subtitle: 'Norwegian explanation', // Optional
  action: FilledButton(...), // Optional action
)
```

**Used in:** 22 files, should be in all list screens with empty states.

### Frontend: Error Display

**Source:** `/app/lib/core/services/error_display_service.dart` (Fase 18)

```dart
// Success feedback
ErrorDisplayService.showSuccess('Operasjon fullført');

// Warning feedback (non-critical)
ErrorDisplayService.showWarning('Dette feltet er påkrevd');

// Error feedback (with optional retry)
ErrorDisplayService.showError(
  AppException('Noe gikk galt'),
  onRetry: () => performAction(),
);

// Info feedback
ErrorDisplayService.showInfo('Dataene er oppdatert');
```

**Anti-pattern:** Raw SnackBar usage
```dart
// DON'T DO THIS
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Message')),
);
```

### Frontend: Spacing Constants

**Source:** `/app/lib/core/theme.dart`

Theme defines:
- Border radius: 12px (cards, buttons, inputs)
- Button padding: horizontal 24, vertical 14
- Input padding: horizontal 16, vertical 14
- Card elevation: 1 (light), 2 (dark)

**Missing:** Explicit spacing constants (8, 12, 16, 24, 32)

**De facto standards from usage analysis:**
- List padding: `EdgeInsets.all(16)`
- Item spacing: `SizedBox(height: 8)` or `SizedBox(height: 16)`
- Section spacing: `SizedBox(height: 24)`
- Card content padding: `EdgeInsets.all(12)` or `EdgeInsets.all(16)`
- Horizontal item spacing: `EdgeInsets.symmetric(horizontal: 8)`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Custom lint rules for auth patterns | Grep scripts, manual audits | `custom_lint` package | Automated, runs in IDE and CI |
| Manual API response validation | Postman tests, manual checking | OpenAPI/Swagger spec | Machine-readable contract |
| Custom spacing constants | Hard-coded values everywhere | Theme extension with spacing scale | Single source of truth |
| Manual pattern enforcement | Code review comments | Documented patterns + automated linting | Scales better, catches issues earlier |

## Common Patterns to Enforce

### CONS-01: Backend Auth Flow

**Current inconsistencies:**
1. Single-line vs multi-line return statements
2. Inconsistent error messages
3. Some handlers check team membership, some don't
4. Role checks sometimes inline, sometimes use helpers

**Target pattern:**
```dart
Future<Response> _handlerName(Request request, String teamId) async {
  try {
    // 1. Get userId
    final userId = getUserId(request);
    if (userId == null) {
      return resp.unauthorized();
    }

    // 2. Check team membership (if team-scoped endpoint)
    final team = await requireTeamMember(_teamService, teamId, userId);
    if (team == null) {
      return resp.forbidden('Ingen tilgang til dette laget');
    }

    // 3. Check role (if restricted endpoint)
    if (!isAdmin(team)) {
      return resp.forbidden('Kun administratorer kan utføre denne handlingen');
    }

    // 4. Business logic
    final result = await _service.doSomething();

    // 5. Return response
    return resp.ok(result);
  } catch (e) {
    return resp.serverError('Kunne ikke utføre handlingen');
  }
}
```

**Standardization:**
- Multi-line returns (easier to read)
- Explicit error messages in Norwegian
- Consistent try-catch at handler level
- Always null-check before requireTeamMember call

### CONS-02: Backend Error Responses

**Current state:** All handlers use response_helpers (✓), but messages vary.

**Target:**
- Generic Norwegian messages for common errors
- Specific Norwegian messages for domain errors
- Never include exception details (`$e`)
- Consistent message format

**Example standardization:**
```dart
// Authentication
resp.unauthorized() // "Ikke autentisert"
resp.forbidden('Ingen tilgang til dette laget')
resp.forbidden('Kun administratorer kan utføre denne handlingen')
resp.forbidden('Kun bøtesjef eller admin kan utføre denne handlingen')

// Validation
resp.badRequest('Påkrevd felt mangler')
resp.badRequest('Ugyldig dato format')
resp.badRequest('Ugyldig verdi')

// Not found
resp.notFound('Lag ikke funnet')
resp.notFound('Bruker ikke funnet')
resp.notFound('Aktivitet ikke funnet')

// Server errors (never include $e)
resp.serverError('En feil oppstod')
resp.serverError('Kunne ikke hente data')
resp.serverError('Kunne ikke lagre endringer')
```

### CONS-03: Frontend AsyncValue + EmptyState

**Current gaps:**
- 16 screens don't use EmptyStateWidget
- Some screens use manual `.isLoading` checks
- Inconsistent retry patterns

**Target pattern:**
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final dataAsync = ref.watch(dataProvider);

  return Scaffold(
    appBar: AppBar(title: const Text('Screen Title')),
    body: dataAsync.when2(
      onRetry: () => ref.invalidate(dataProvider),
      data: (data) {
        if (data.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.appropriate_icon,
            title: 'Norwegian title',
            subtitle: 'Norwegian explanation',
            action: _buildAction(), // Optional
          );
        }

        return _buildContent(data);
      },
    ),
  );
}
```

**Applies to all screens that:**
- Display lists or collections
- Fetch async data
- Have empty states
- Need loading indicators

### CONS-04: Frontend Error Feedback

**Current gaps:**
- 34 files still use raw SnackBar
- Direct ScaffoldMessenger.of(context) calls
- Inconsistent error message formatting

**Target pattern:**
```dart
// Success
ErrorDisplayService.showSuccess('Lagret');

// Warning (validation, non-critical)
ErrorDisplayService.showWarning('Feltet kan ikke være tomt');

// Error (with optional retry)
ErrorDisplayService.showError(
  exception, // AppException
  onRetry: () => _performAction(),
);

// Info
ErrorDisplayService.showInfo('Dataene er synkronisert');
```

**Migration strategy:**
1. Search for `ScaffoldMessenger.of(context)`
2. Replace with appropriate ErrorDisplayService method
3. Ensure error messages are in Norwegian
4. Add retry callbacks where appropriate

### CONS-05: API Response Envelopes

**Current inconsistencies:**
- Raw arrays: `resp.ok(teams)`
- Raw objects: `resp.ok(team.toJson())`
- Success wrappers: `resp.ok({'success': true})`
- Named envelopes: `resp.ok({'rules': rules})`

**Analysis:**
- Frontend expects raw data (no envelope) based on current usage
- `{'success': true}` wrappers provide no value (200 status already indicates success)
- Named envelopes are inconsistent (some endpoints use, some don't)

**Target pattern:**
```dart
// Single object - return raw
return resp.ok(team.toJson());

// Collection - return raw array
return resp.ok(teams.map((t) => t.toJson()).toList());

// Empty success - use 204 No Content or minimal object
return Response(204); // Preferred for DELETE, PATCH with no body
// OR
return resp.ok({'message': 'Operasjon fullført'}); // If message needed
```

**Do NOT:**
- Wrap in `{success: true}` (redundant with HTTP 200)
- Wrap in `{data: ...}` unless pagination metadata needed
- Use inconsistent envelope names

### CONS-06: Frontend Spacing/Padding

**Current state:** 16 different padding patterns, no theme constants.

**Target: Add spacing constants to theme**

```dart
// app/lib/core/theme.dart
class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

// Usage patterns
class SpacingPatterns {
  // Screen padding
  static const screenPadding = EdgeInsets.all(AppSpacing.lg); // 16

  // List padding
  static const listPadding = EdgeInsets.all(AppSpacing.lg); // 16

  // Card content padding
  static const cardPadding = EdgeInsets.all(AppSpacing.md); // 12

  // Item spacing
  static const itemSpacing = SizedBox(height: AppSpacing.sm); // 8

  // Section spacing
  static const sectionSpacing = SizedBox(height: AppSpacing.xl); // 24

  // Horizontal item spacing
  static const horizontalItemPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
  ); // 8
}
```

**Standardization rules:**
- Use AppSpacing constants, not hard-coded values
- Prefer named patterns (SpacingPatterns.screenPadding)
- Use 8px grid (2, 4, 8, 12, 16, 24, 32, 48)
- Avoid odd values (5, 10, 15) unless absolutely necessary

## Common Pitfalls

### Pitfall 1: Over-standardizing Response Envelopes

**What goes wrong:** Adding `{data: ..., meta: ...}` wrappers to all endpoints for "future flexibility"

**Why it happens:** Desire for API consistency leads to premature abstraction

**How to avoid:**
- Only add envelopes when pagination/metadata is actually needed
- Keep simple endpoints simple (raw object/array)
- Frontend doesn't need envelope parsing for basic CRUD

**Warning signs:**
- Every endpoint has `{data: ...}` wrapper
- Envelope structure changes per endpoint
- Frontend has complex unwrapping logic

### Pitfall 2: Inconsistent Error Message Languages

**What goes wrong:** Mix of Norwegian and English error messages

**Why it happens:** Copy-paste from examples, developer preference, inconsistent review

**How to avoid:**
- All user-facing messages in Norwegian (requirement I18N-02)
- Code comments and technical logs can be English
- Search for English error messages before completion

**Warning signs:**
- `grep -r "error" backend/lib/api | grep -v "//"`
- Mixed language in error_display_service calls

### Pitfall 3: Hard-coding Spacing Values

**What goes wrong:** Spacing values drift over time, hard to maintain consistency

**Why it happens:** No spacing constants available, easier to type `16` than import constant

**How to avoid:**
- Add AppSpacing to theme.dart
- Use named patterns (SpacingPatterns.screenPadding)
- Lint rule to detect hard-coded EdgeInsets values

**Warning signs:**
- `EdgeInsets.all(17)` (non-standard value)
- Same logical spacing with different values across screens
- Difficulty maintaining visual consistency

### Pitfall 4: Pattern Erosion Over Time

**What goes wrong:** New code doesn't follow established patterns, consistency degrades

**Why it happens:** Patterns not documented, new developers unaware, tight deadlines

**How to avoid:**
- Document patterns in CLAUDE.md
- Add custom lint rules where possible
- Code review checklist for consistency
- Periodic audits (grep for anti-patterns)

**Warning signs:**
- New handlers skip auth checks
- New screens use raw SnackBar instead of ErrorDisplayService
- Spacing values outside 8px grid

## Architecture Patterns

### Pattern 1: Handler Template

**What:** Standardized structure for all backend handlers

**When to use:** Every new handler, every handler refactor

**Structure:**
```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/feature_service.dart';
import '../services/team_service.dart';
import 'helpers/auth_helpers.dart';
import 'helpers/request_helpers.dart';
import 'helpers/response_helpers.dart' as resp;
import '../helpers/parsing_helpers.dart';

class FeatureHandler {
  final FeatureService _featureService;
  final TeamService _teamService;

  FeatureHandler(this._featureService, this._teamService);

  Router get router {
    final router = Router();

    // Public routes (no auth)
    // router.get('/public', _publicHandler);

    // Authenticated routes
    router.get('/feature', _getFeatures);
    router.post('/feature', _createFeature);

    // Team-scoped routes
    router.get('/team/<teamId>/features', _getTeamFeatures);

    return router;
  }

  // Handler methods follow auth flow pattern
  Future<Response> _handlerName(Request request) async {
    try {
      final userId = getUserId(request);
      if (userId == null) {
        return resp.unauthorized();
      }

      // Business logic

      return resp.ok(result);
    } catch (e) {
      return resp.serverError('Norwegian error message');
    }
  }
}
```

### Pattern 2: Screen Template

**What:** Standardized structure for screens with async data

**When to use:** All screens that display lists, details, or fetched data

**Structure:**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/extensions/async_value_extensions.dart';
import '../../../shared/widgets/widgets.dart';
import '../providers/feature_provider.dart';

class FeatureScreen extends ConsumerWidget {
  final String requiredParam;

  const FeatureScreen({super.key, required this.requiredParam});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(featureProvider(requiredParam));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Norwegian Title'),
        actions: [_buildActions()],
      ),
      body: dataAsync.when2(
        onRetry: () => ref.invalidate(featureProvider(requiredParam)),
        data: (data) {
          if (data.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'Norwegian title',
              subtitle: 'Norwegian explanation',
              action: _buildEmptyAction(),
            );
          }

          return _buildContent(data);
        },
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildContent(List<Item> data) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh logic
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16), // Use AppSpacing.lg
        itemCount: data.length,
        itemBuilder: (context, index) => _buildItem(data[index]),
      ),
    );
  }
}
```

### Pattern 3: Error Feedback Template

**What:** Consistent error handling in async operations

**When to use:** All provider mutations, all async UI operations

**Structure:**
```dart
// In provider
Future<void> performAction() async {
  state = const AsyncLoading();

  state = await AsyncValue.guard(() async {
    final result = await _repository.performAction();

    // Invalidate related providers
    ref.invalidate(relatedProvider);

    return result;
  });

  // Show success feedback if needed
  if (state.hasValue) {
    ErrorDisplayService.showSuccess('Operasjon fullført');
  }
}

// In UI
ElevatedButton(
  onPressed: () async {
    try {
      await ref.read(featureProvider.notifier).performAction();

      if (context.mounted) {
        ErrorDisplayService.showSuccess('Lagret');
        Navigator.of(context).pop();
      }
    } catch (e) {
      ErrorDisplayService.showWarning('Kunne ikke lagre');
    }
  },
  child: const Text('Lagre'),
)
```

## Code Examples

### Backend: Standard Handler Method

**Source:** Combination of teams_handler and fines_handler patterns

```dart
Future<Response> _getTeamFeatures(Request request, String teamId) async {
  try {
    // Step 1: Authentication
    final userId = getUserId(request);
    if (userId == null) {
      return resp.unauthorized();
    }

    // Step 2: Team membership
    final team = await requireTeamMember(_teamService, teamId, userId);
    if (team == null) {
      return resp.forbidden('Ingen tilgang til dette laget');
    }

    // Step 3: Authorization (if restricted)
    if (!isAdmin(team)) {
      return resp.forbidden('Kun administratorer kan se denne informasjonen');
    }

    // Step 4: Query parameters (optional)
    final activeOnly = request.url.queryParameters['active'] == 'true';

    // Step 5: Business logic
    final features = await _featureService.getFeatures(
      teamId: teamId,
      activeOnly: activeOnly,
    );

    // Step 6: Response
    return resp.ok(features.map((f) => f.toJson()).toList());
  } catch (e) {
    return resp.serverError('Kunne ikke hente data');
  }
}
```

### Frontend: Standard Screen with Empty State

**Source:** achievements_screen.dart pattern

```dart
class FeaturesScreen extends ConsumerWidget {
  final String teamId;

  const FeaturesScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresAsync = ref.watch(featuresProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Funksjoner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(featuresProvider(teamId)),
          ),
        ],
      ),
      body: featuresAsync.when2(
        onRetry: () => ref.invalidate(featuresProvider(teamId)),
        data: (features) {
          if (features.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'Ingen funksjoner',
              subtitle: 'Det er ingen funksjoner å vise',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(featuresProvider(teamId));
              await ref.read(featuresProvider(teamId).future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return _FeatureCard(feature: feature);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

### Frontend: Spacing with Constants

**Source:** New pattern to establish

```dart
// Before (hard-coded values)
Container(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      Text('Title'),
      const SizedBox(height: 8),
      Text('Subtitle'),
      const SizedBox(height: 24),
      _buildContent(),
    ],
  ),
)

// After (using constants)
Container(
  padding: SpacingPatterns.screenPadding,
  child: Column(
    children: [
      Text('Title'),
      SpacingPatterns.itemSpacing,
      Text('Subtitle'),
      SpacingPatterns.sectionSpacing,
      _buildContent(),
    ],
  ),
)
```

## State of the Art

| Pattern Area | Established Phase | Current State | Gaps |
|--------------|-------------------|---------------|------|
| Auth helpers | Fase 1 | ✅ In all handlers | Formatting inconsistency (single vs multi-line) |
| Response helpers | Fase 1 | ✅ In all handlers | Message text varies, no centralized list |
| Error handling (backend) | Fase 14 | ✅ No `$e` in responses | Some TODO comments for permission checks |
| when2() extension | Fase 6 | ✅ In 54 files | Not used in all async screens |
| EmptyStateWidget | Fase 6 | ✅ In 22 files | 16 screens without empty states |
| ErrorDisplayService | Fase 18 | ✅ In 18 files | 34 files still use raw SnackBar |
| Spacing constants | None | ❌ Not defined | Hard-coded values everywhere |
| API envelopes | None | ⚠️ Inconsistent | Mix of raw, wrappers, named envelopes |

**Deprecated/outdated:**
- Raw SnackBar usage (should use ErrorDisplayService)
- Manual `.isLoading` checks (should use when2())
- Hard-coded spacing values (should use AppSpacing constants)

## Open Questions

1. **API Response Envelope Standard**
   - What we know: Currently inconsistent (raw, wrappers, named envelopes)
   - What's unclear: Should we standardize on raw responses, or add pagination envelope for future?
   - Recommendation: Start with raw responses, add pagination envelope only when implementing pagination

2. **Permission Helper Usage**
   - What we know: `permission_helpers.dart` exists but only used in fines_handler
   - What's unclear: Should all handlers use these helpers, or keep inline checks?
   - Recommendation: Use helpers for complex permission logic (fine_boss + admin), inline checks for simple admin-only

3. **Spacing Constant Adoption**
   - What we know: Need to define AppSpacing constants
   - What's unclear: How to migrate 300+ hard-coded EdgeInsets values?
   - Recommendation: Define constants, migrate incrementally (new code first, then high-traffic screens)

4. **Custom Lint Rules**
   - What we know: Could catch raw SnackBar usage, hard-coded spacing
   - What's unclear: Complexity vs benefit of writing custom lint rules
   - Recommendation: Start with grep-based audits, add custom lints if violations persist

## Sources

### Primary (HIGH confidence)

**Project inspection:**
- `/backend/lib/api/helpers/` - auth_helpers.dart, response_helpers.dart, permission_helpers.dart
- `/app/lib/core/extensions/async_value_extensions.dart` - when2() pattern
- `/app/lib/shared/widgets/empty_state_widget.dart` - EmptyStateWidget
- `/app/lib/core/services/error_display_service.dart` - Error feedback
- `/app/lib/core/theme.dart` - Current theme constants
- `CLAUDE.md` - Documented patterns from prior phases
- `.planning/REQUIREMENTS.md` - Phase 7 requirements (CONS-01 through CONS-06)

**Code analysis:**
- `grep -r "getUserId(" backend/lib/api` - 251 occurrences across 32 files
- `grep -r "requireTeamMember(" backend/lib/api` - 116 occurrences across 25 files
- `grep -r "when2(" app/lib` - 71 occurrences across 54 files
- `grep -r "EmptyStateWidget" app/lib` - 26 occurrences across 22 files
- `grep -r "ErrorDisplayService" app/lib` - 82 occurrences across 18 files
- `grep -r "SnackBar(" app/lib` - 34 files with raw SnackBar usage
- `grep -rh "EdgeInsets\." app/lib` - Spacing pattern analysis

### Secondary (MEDIUM confidence)

**Prior phase documentation:**
- Fase 1: Established auth middleware and response helpers
- Fase 6: Established when2() and EmptyStateWidget patterns
- Fase 14: Removed `$e` from all error responses
- Fase 18: Introduced ErrorDisplayService, replaced 14 raw SnackBars

## Metadata

**Confidence breakdown:**
- Backend patterns: HIGH - All patterns established and in use, gaps are formatting/consistency
- Frontend patterns: HIGH - when2(), EmptyStateWidget, ErrorDisplayService established and working
- API envelopes: MEDIUM - Current state clear, optimal standard requires decision
- Spacing constants: HIGH - Analysis complete, implementation straightforward

**Research date:** 2026-02-09
**Valid until:** 60 days (patterns stable, no external dependencies)

**Key finding:** This is not a "define new patterns" phase - it's "enforce established patterns and eliminate variations." The hard work of pattern design was done in phases 1-22. This phase is about consistency auditing and standardization.
