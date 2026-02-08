# Coding Conventions

**Analysis Date:** 2026-02-08

## Naming Patterns

**Files:**
- Screens: `{feature_name}_screen.dart` (e.g., `login_screen.dart`, `team_detail_screen.dart`)
- Widgets: `{widget_name}_widget.dart` or `{feature_name}.dart` (e.g., `error_widget.dart`, `team_invite_dialog.dart`)
- Providers: `{feature_name}_provider.dart` (e.g., `auth_provider.dart`, `team_provider.dart`)
- Repositories: `{entity}_repository.dart` (e.g., `auth_repository.dart`, `team_repository.dart`)
- Services: `{entity}_service.dart` (e.g., `team_service.dart`, `error_display_service.dart`)
- Models: `{entity}.dart` (e.g., `user.dart`, `team.dart`, `activity.dart`)
- Handlers (backend): `{plural_entity}_handler.dart` (e.g., `teams_handler.dart`, `activities_handler.dart`)
- Test files: `{feature_name}_test.dart` (e.g., `login_test.dart`, `complete_auth_flow_test.dart`)

**Functions & Methods:**
- camelCase for function names: `getTeams()`, `createActivity()`, `handleTokenExpiration()`
- Private methods prefixed with underscore: `_handleTokenExpiration()`, `_getTeams(Request request)`
- Test functions use `testWidgets()` for UI tests, `group()` for test organization
- Async operations: `Future<T>` return type (e.g., `Future<User> getCurrentUser()`)
- Callback handlers prefixed with underscore and action verb: `_getTeams()`, `_createTeam()`, `_updateMember()`

**Variables & Parameters:**
- camelCase for local variables: `final userId = getUserId(request);`
- camelCase for parameters: `required String email`, `String? inviteCode`
- Private fields prefixed with underscore: `final ApiClient _apiClient;`, `late final AuthRepository _repository;`
- Test data factories use PascalCase: `TestUserFactory`, `TestTeamFactory`, `TestActivityInstanceFactory`

**Types & Classes:**
- PascalCase for class names: `User`, `TeamMember`, `ActivityInstance`, `AuthRepository`
- Enum values in camelCase: `ActivityType.training`, `ResponseType.yesNo`, `UserResponse.yes`
- Exception classes end with `Exception`: `AppException`, `InvalidCredentialsException`, `TokenExpiredException`
- Provider names in camelCase: `authStateProvider`, `teamDetailProvider`, `leaderboardProvider`
- Notifier classes end with `Notifier`: `AuthNotifier`, `RecordMatchStatsNotifier`
- Handler classes end with `Handler`: `TeamsHandler`, `ActivitiesHandler`, `SeasonsHandler`

## Code Style

**Formatting:**
- Uses Flutter/Dart standards via `flutter_lints`
- Line length: Follows Dart conventions (typically ~80 chars, Flutter can extend)
- Indentation: 2 spaces
- Import organization: Standard Dart (package imports, then relative)

**Linting:**
- Tool: `flutter_lints` v6.0.0 (frontend)
- Tool: `lints` v6.1.0 (backend)
- Analysis: `flutter analyze` for frontend, `dart analyze` for backend
- Key active rules: Standard flutter_lints package rules applied

## Import Organization

**Order:**
1. `dart:` imports (e.g., `import 'dart:async';`, `import 'dart:convert';`)
2. `package:flutter/` imports (e.g., `import 'package:flutter/material.dart';`)
3. `package:` imports from pub.dev (e.g., `import 'package:flutter_riverpod/flutter_riverpod.dart';`)
4. Relative imports starting with `../` (e.g., `import '../../../data/api/api_client.dart';`)

**Path Aliases:**
- No path aliases configured; uses relative imports throughout
- Common relative import patterns:
  - From screens: `import '../../../core/extensions/async_value_extensions.dart';`
  - From providers: `import '../../../data/models/user.dart';`
  - From handlers: `import '../models/team.dart';`

## Error Handling

**Patterns:**
- All custom errors inherit from `AppException` base class in `app/lib/core/errors/app_exceptions.dart`
- Error hierarchy: `AppException` → specific category (e.g., `NetworkException`, `AuthException`, `ResourceException`) → specific type (e.g., `NoInternetException`, `TokenExpiredException`, `InvalidCredentialsException`)
- Backend handlers use response helpers for consistent error responses:
  - `resp.unauthorized()` for 401 (auth failures, no userId)
  - `resp.forbidden()` for 403 (auth success but no permission to resource)
  - `resp.badRequest(message)` for 400 (input validation)
  - `resp.serverError()` for 500 (never include `$e` in message — use generic Norwegian text)
  - `resp.notFound()` for 404 (resource not found)
- Frontend repository/handler pattern: Repositories catch errors and let them propagate to providers; providers handle errors with `AsyncValue.error(e, st)`
- Auth helpers in backend: `getUserId(request)` returns null if not authenticated, `requireTeamMember(teamService, teamId, userId)` returns null if user not in team
- Frontend error display: Use `ErrorDisplayService.showWarning()` for user-facing error messages (from `app/lib/core/services/error_display_service.dart`)
- Never log or include raw exception details (`$e`) in user-facing error messages — use generic Norwegian error strings

## Logging

**Framework:** `console` (print-based, no external logging library)

**Patterns:**
- Backend: No explicit logging framework; errors caught silently and generic messages returned to client
- Frontend: No structured logging; debug output via `print()` when needed (development only)
- All errors that reach user should have user-friendly Norwegian messages

## Comments

**When to Comment:**
- Complex business logic with non-obvious intent
- Workarounds for bugs or limitations
- TODOs for incomplete features
- Comments in Norwegian for user-facing messages and UI strings

**JSDoc/TSDoc:**
- Dart uses `///` for doc comments on public APIs
- Doc comments on public classes, methods, and functions:
  ```dart
  /// Create a test widget with provider overrides for testing.
  Widget createTestWidget(
    Widget widget, {
    List<Object> overrides = const [],
  })
  ```
- Library-level doc comments: `library;` declarations at top of file

## Function Design

**Size:**
- Private handler methods keep business logic minimal; delegate to services
- Services contain the bulk of business logic (e.g., queries, transformations, validation)
- Repositories are thin wrappers around API client or database access
- Providers are thin wrappers around repositories or services

**Parameters:**
- Named parameters for functions with multiple arguments: `createTeam({required String name, String? sport})`
- Required parameters marked with `required` keyword
- Optional parameters nullable with `?` or given default values
- Callback parameters use `Function` type or functional signature: `void Function()? callback`

**Return Values:**
- Async operations return `Future<T>`
- Nullable returns explicitly typed: `Future<User?>`, `List<Team>?`
- Repositories return domain models (e.g., `Future<User>`, `Future<List<Team>>`)
- Services return domain models or raw maps from DB
- Error handling via exceptions (thrown, not nullable returns)

## Module Design

**Exports:**
- Barrel file pattern: Each feature has a main `{feature_name}_provider.dart` that defines all public providers
- Handlers export `Router get router` getter
- Each service defines its constructor dependencies
- Models define `fromJson()` factory and `toJson()` method (backend and frontend models mirror each other)

**Barrel Files:**
- Frontend: `app/lib/core/errors/errors.dart` re-exports all exception types
- Frontend: `app/lib/core/errors/handlers/handlers.dart` re-exports all error handlers
- Frontend: `app/lib/core/services/services.dart` re-exports all core services
- Backend: Main `router.dart` instantiates all services and wires them into handlers

**Dependency Injection:**
- Backend: Constructor injection via handler classes; router instantiates all services at startup
- Frontend: Riverpod providers for dependency injection; `final authRepositoryProvider = Provider<AuthRepository>((ref) { ... })`
- Services depend on other services or database client; passed via constructor
- No global singletons

## State Management (Frontend)

**Provider Pattern:**
- Simple async state: `FutureProvider.family<T, Param>` or `AsyncNotifierProvider<Notifier, AsyncValue<T>>`
- Mutable state: `NotifierProvider<Notifier, AsyncValue<T>>` with custom notifier class
- Provider invalidation after mutations: `ref.invalidate(relatedProvider)` to refresh dependent data
- Use `.select()` on `ref.watch()` to watch specific fields: `ref.watch(teamDetailProvider(teamId).select((t) => t.name))`
- All async values wrapped in `AsyncValue<T>` from riverpod
- Loading state: `AsyncValue.loading()`; Error state: `AsyncValue.error(e, st)`; Data state: `AsyncValue.data(value)`

**Widget Pattern:**
- `ConsumerWidget` or `ConsumerStatefulWidget` for components that need `ref`
- Use `ref.watch()` to read providers; `ref.invalidate()` to refresh
- Use `ref.read()` for one-off reads (e.g., calling methods on notifiers)
- Never watch the same provider multiple times in a single widget (use `.select()`)

## Backend Handler Pattern

**Structure:**
- Handlers extend functionality via `Router get router` getter
- Route definitions map HTTP methods and paths to handler methods
- Sub-handlers mounted via `router.mount('/', subHandler.router.call)`
- Request validation in handler; business logic delegated to service
- All handler methods: `Future<Response> _methodName(Request request, [pathParams...])`
- Error handling: try-catch wrapping all async operations; generic Norwegian error responses

**Auth Pattern:**
- Extract userId: `final userId = getUserId(request);`
- Check null immediately: `if (userId == null) return resp.unauthorized();`
- Check team membership: `final team = await requireTeamMember(teamService, teamId, userId); if (team == null) return resp.forbidden();`
- Check admin: `if (!isAdmin(team)) return resp.forbidden();`

---

*Convention analysis: 2026-02-08*
