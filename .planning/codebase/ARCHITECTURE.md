# Architecture

**Analysis Date:** 2026-02-08

## Pattern Overview

**Overall:** Clean Architecture with layered separation for both frontend and backend. Frontend uses Riverpod state management with feature-based modules. Backend uses Handler → Service → Database layering with dependency injection.

**Key Characteristics:**
- Feature-based module structure (frontend)
- Clear separation of data, business logic, and presentation layers
- Middleware-based authentication and request handling (backend)
- API client abstraction with error mapping (frontend)
- Database abstraction via Supabase with REST API calls (backend)

## Layers

### Frontend (`/app/lib`)

**Presentation Layer:**
- Purpose: UI components, screens, and widgets
- Location: `features/*/presentation/` and `shared/widgets/`
- Contains: Screens, dialogs, widget components, user interactions
- Depends on: Providers (for state), Core services (routing, error display)
- Used by: Feature routes defined in `core/router.dart`

**State Management Layer:**
- Purpose: Async data handling and state mutations
- Location: `features/*/providers/`
- Contains: Riverpod `AsyncNotifierProvider`, `FutureProvider`, mutation notifiers
- Depends on: Data repositories, Core error handling
- Used by: Presentation widgets via `ref.watch()` and `ref.read()`

**Data Layer:**
- Purpose: API communication and data transformation
- Location: `data/` and `features/*/data/`
- Contains: API client (`ApiClient` in `data/api/`), repositories per feature
- Depends on: Supabase client configuration, shared models
- Used by: Providers for data fetching

**Core Layer:**
- Purpose: Cross-cutting concerns and infrastructure
- Location: `core/`
- Contains: Router, theme, config, services, error handling, utilities
- Depends on: Flutter and external packages
- Used by: All layers (router, error display, auth state)

**Shared Layer:**
- Purpose: Reusable widgets and utilities across features
- Location: `shared/`
- Contains: Common widgets (EmptyStateWidget, ErrorWidget), utility functions
- Depends on: Core layer
- Used by: Multiple feature modules

### Backend (`/backend/lib`)

**Handler Layer:**
- Purpose: HTTP request routing and parameter extraction
- Location: `api/` (37 handler files)
- Contains: Shelf Router definitions, request parsing, response formatting
- Depends on: Services, helpers (auth, response, validation)
- Used by: Main router in `bin/server.dart`

**Service Layer:**
- Purpose: Business logic and orchestration
- Location: `services/` (36 service files)
- Contains: Team management, activity orchestration, statistics calculation, fine logic, etc.
- Depends on: Database client, other services (DI in router)
- Used by: Handlers for processing requests

**Database Layer:**
- Purpose: Supabase client abstraction
- Location: `db/`
- Contains: `Database` class wrapping Supabase REST client
- Depends on: Supabase SDK, environment configuration
- Used by: All services for data operations

**Models Layer:**
- Purpose: Data structures and serialization
- Location: `models/` (split across multiple files: activity, team, fine, etc.)
- Contains: Data classes with `fromJson()` and `toJson()` methods
- Depends on: Dart core types
- Used by: Services and handlers for type safety

**Helpers Layer:**
- Purpose: Shared utility functions and middleware
- Location: `api/helpers/` and `api/middleware/`
- Contains: `auth_helpers.dart` (getUserId, requireTeamMember, isAdmin), `response_helpers.dart` (ok, forbidden, unauthorized, etc.), `validation_helpers.dart`
- Depends on: Services (auth, team), Shelf framework
- Used by: Handlers and middleware

## Data Flow

### Frontend Data Flow (Example: Activity List)

1. **User navigates to activities screen**
   - Router: `context.goNamed('activities', params: {'teamId': '123'})`
   - Location: `core/router.dart` → `TeamsScreen`

2. **Screen builds and watches provider**
   - Code: `ref.watch(teamActivitiesProvider(teamId))`
   - Location: `features/activities/presentation/activities_screen.dart`

3. **Provider triggers repository call**
   - Code: `repository.getActivitiesForTeam(teamId)`
   - Location: `features/activities/providers/activity_providers.dart`

4. **Repository makes API call**
   - Code: `_apiClient.get('/activities/team/$teamId')`
   - Location: `features/activities/data/activity_repository.dart`

5. **ApiClient sends HTTP request with auth**
   - Headers: `Authorization: Bearer <token>` (injected by interceptor)
   - Base URL: From `AppConfig.apiBaseUrl`
   - Location: `data/api/api_client.dart`

6. **Backend receives and processes request**
   - Handler extracts teamId from path
   - Middleware validates auth token
   - Handler calls service method
   - Location: `backend/lib/api/activities_handler.dart`

7. **Service performs business logic**
   - Queries database via Supabase REST API
   - Returns typed data (List<Activity>)
   - Location: `backend/lib/services/activity_service.dart`

8. **Handler formats response**
   - Response: JSON array of activities
   - Uses: `resp.ok(data)` helper
   - Location: `backend/lib/api/helpers/response_helpers.dart`

9. **ApiClient receives and maps response**
   - Parses JSON to List<Activity>
   - Returns to repository
   - Location: `data/api/api_client.dart`

10. **Repository transforms and returns**
    - Parses response data using `parseListResponse()`
    - Maps to Activity objects
    - Location: `features/activities/data/activity_repository.dart`

11. **Provider returns AsyncValue<List<Activity>>**
    - Widget rebuilds with data
    - Location: `features/activities/providers/activity_providers.dart`

12. **Screen renders activities**
    - Uses `when2()` to handle loading/error/data states
    - Location: `features/activities/presentation/activities_screen.dart`

### Backend Data Flow (Example: Get Activities)

1. **Request arrives at server**
   - Path: `GET /activities/team/:teamId`
   - Headers: `Authorization: Bearer <token>`
   - Location: `bin/server.dart`

2. **Pipeline processes middleware**
   - Logger middleware: Logs request
   - CORS middleware: Adds CORS headers
   - Content-Type middleware: Ensures JSON response
   - Auth middleware: Validates token and extracts userId
   - Location: `bin/server.dart` + `api/middleware/auth_middleware.dart`

3. **Router matches handler**
   - Mounts: `router.mount('/activities', activitiesHandler)`
   - Delegates to: `ActivitiesHandler`
   - Location: `api/router.dart`

4. **Handler parses and delegates**
   - Extracts `teamId` from path
   - Calls: `activityService.getActivitiesForTeam(teamId, userId)`
   - Location: `api/activities_handler.dart`

5. **Service queries database**
   - Uses: `db.client.from('activities').select(...).execute()`
   - Filters by team and active status
   - Returns: List of activity rows from Supabase
   - Location: `services/activity_service.dart`

6. **Service transforms response**
   - Maps database rows to Activity models via `Activity.fromJson()`
   - Location: `services/activity_service.dart`

7. **Handler formats response**
   - Uses: `resp.ok(activities)` to wrap in JSON and set headers
   - Location: `api/activities_handler.dart`

8. **Response sent to client**
   - Status: 200 OK
   - Body: JSON array of activities
   - Headers: Content-Type: application/json

## State Management

**Frontend State:**
- All async state uses `AsyncValue<T>` from Riverpod
- Providers are typically `FutureProvider` (read-only) or `AsyncNotifierProvider` (mutable)
- Mutations invalidate related providers to refresh data
- Example: After creating activity, `ref.invalidate(teamActivitiesProvider(teamId))`

**Backend State:**
- Stateless request-response model
- Services maintain no state between requests
- All mutable operations use database transactions (via Supabase)
- Dependency injection in router ensures single instances of services across requests

## Key Abstractions

### Error Handling (Frontend)

**Exception Hierarchy:**
- Base: `AppException` in `core/errors/app_exceptions.dart`
- Categories:
  - `NetworkException` - connectivity issues
  - `AuthException` → `TokenExpiredException`, `InvalidCredentialsException`
  - `ResourceException` → `ResourceNotFoundException`, `PermissionException`
  - `ValidationException` - invalid input data

**Error Mapping:**
- `ApiClient._mapDioError()` converts HTTP status codes to domain exceptions
- 400 → `ValidationException`
- 401 → `TokenExpiredException` (triggers logout and token refresh)
- 403 → `PermissionException`
- 404 → `ResourceNotFoundException`
- Location: `data/api/api_client.dart`

**Feature-Specific Handlers:**
- `ActivityErrorHandler` - handles activity cancellations, deadlines
- `AuthErrorHandler` - token expiration, credential errors
- `FineErrorHandler` - fine-specific errors
- `TeamErrorHandler` - team access and role errors
- `GlobalErrorHandler` - fallback for unmapped errors
- Location: `core/errors/handlers/`

### Response Handling (Backend)

**Standard Response Format:**
```dart
// Success
resp.ok(data)  // 200 with JSON body

// Errors
resp.unauthorized('Ikke autentisert')     // 401
resp.forbidden('Ingen tilgang')           // 403
resp.badRequest('Invalid input')          // 400
resp.notFound('Ressurs ikke funnet')      // 404
resp.serverError('En feil oppstod')       // 500
```

**Location:** `api/helpers/response_helpers.dart`

### Authentication (Backend)

**Middleware:**
- `requireAuth()` - validates Bearer token, extracts userId, blocks on invalid
- `optionalAuth()` - validates Bearer token if present, allows through regardless
- Location: `api/middleware/auth_middleware.dart`

**Helpers:**
- `getUserId(request)` - extract userId from request context
- `requireTeamMember(teamService, teamId, userId)` - verify membership
- `isAdmin(team)` - check admin flag from team data
- Location: `api/helpers/auth_helpers.dart`

### API Client (Frontend)

**ApiClient Features:**
- Manages Dio HTTP client with base URL and timeout
- Injects Bearer token via interceptor
- Handles token expiration with callback
- Maps errors to AppException types
- Location: `data/api/api_client.dart`

**Token Lifecycle:**
- Stored in SharedPreferences via `AuthLocalDataSource`
- Loaded at app startup
- Injected as `Authorization: Bearer <token>` header
- On 401 response: token cleared, `onTokenExpired` callback triggered

### Routing (Frontend)

**Router Pattern:**
- Uses GoRouter with named routes
- Auth guard redirects unauthenticated users to login
- Routes organized by feature with path parameters
- Location: `core/router.dart`

**Example Route:**
```dart
GoRoute(
  path: '/teams/:teamId/activities/:activityId',
  name: 'activity-detail',
  builder: (context, state) => ActivityDetailScreen(
    teamId: state.pathParameters['teamId']!,
    activityId: state.pathParameters['activityId']!,
  ),
)
```

## Entry Points

### Frontend Entry Point

**Location:** `app/lib/main.dart`

**Initialization:**
1. Pre-cache SharedPreferences (auth tokens, settings)
2. Initialize date formatting for Norwegian locale
3. Initialize Supabase service (non-blocking, realtime features optional)
4. Run app with ProviderScope wrapper

**App Root:** `CoreIdrettApp` (ConsumerWidget)
- Watches `routerProvider` for navigation
- Watches `themeModeProvider` for dark/light mode
- Sets up MaterialApp.router with GoRouter config

### Backend Entry Point

**Location:** `backend/bin/server.dart`

**Initialization:**
1. Connect to Supabase via Database class
2. Create router with dependency injection
3. Build middleware pipeline:
   - Logger middleware
   - CORS middleware
   - Content-Type middleware
4. Start Shelf server on port 8080 (or env var PORT)

**Middleware Order:**
```dart
const Pipeline()
  .addMiddleware(logRequests())
  .addMiddleware(_corsMiddleware())
  .addMiddleware(_jsonContentType())
  .addHandler(app.call)
```

## Error Handling

### Frontend Strategy

**AsyncValue Handling:**
- All async operations return `AsyncValue<T>` (loading, data, error states)
- `when2()` extension automatically maps errors to AppException
- Provides retry callbacks for retriable errors
- Location: `core/extensions/async_value_extensions.dart`

**Error Display:**
- `ErrorDisplayService.showError()` for critical errors (snackbar)
- `ErrorDisplayService.showWarning()` for non-critical errors
- Globalkey for scaffold messenger: `ErrorDisplayService.scaffoldKey`
- Location: `core/services/error_display_service.dart`

**Error Recovery:**
- Network errors marked as retriable
- Token expiration triggers auth flow
- Feature-specific handlers navigate or dialog as appropriate

### Backend Strategy

**Auth Failures:**
- 401 Unauthorized: Invalid or missing token
- 403 Forbidden: Valid auth but insufficient permissions
- Both formatted with Norwegian messages, no error details exposed
- Location: `api/helpers/response_helpers.dart`

**Validation Failures:**
- 400 Bad Request: Missing or invalid input
- Message includes field-level errors
- Location: `api/handlers/*.dart`

**Server Errors:**
- 500 Internal Server Error: Unexpected exception
- Message: Generic Norwegian message ('En feil oppstod') - no stack traces
- No `$e` interpolation in responses (security)
- Location: All handlers with try-catch

## Cross-Cutting Concerns

**Logging:**
- Backend: Shelf `logRequests()` middleware logs HTTP requests/responses
- Frontend: Debug build uses `kDebugMode` print statements

**Validation:**
- Backend: `validation_helpers.dart` with null checks, DateTime parsing, .first safety
- Frontend: Input widgets validate before submission, API errors provide feedback

**Authentication:**
- Backend: `requireAuth` middleware on all protected routes (mounted with Pipeline)
- Frontend: `authStateProvider` triggers redirect to login if token expired
- Shared: JWT token validation, 401 response handling

**Authorization:**
- Backend: `isAdmin()` and role checks via `team['user_role']`
- Frontend: Role-gated UI elements based on `userRole` in team data
- Pattern: Request includes userId (from auth middleware), handler calls `getTeamById(teamId, userId)` which enforces membership

**Caching:**
- Frontend: SharedPreferences for auth tokens and settings
- Frontend: Cached network images via `cached_network_image` package
- Backend: No client-side caching; all data fresh from Supabase

---

*Architecture analysis: 2026-02-08*
