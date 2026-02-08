# Codebase Structure

**Analysis Date:** 2026-02-08

## Directory Layout

```
Core - Idrett/
├── app/                          # Flutter frontend application
│   ├── lib/
│   │   ├── main.dart            # App entry point
│   │   ├── core/                # Cross-cutting concerns
│   │   │   ├── router.dart      # GoRouter configuration with all routes
│   │   │   ├── theme.dart       # Material theme definitions
│   │   │   ├── config.dart      # App configuration (API base URL)
│   │   │   ├── core.dart        # Barrel export
│   │   │   ├── errors/          # Exception hierarchy and handlers
│   │   │   ├── extensions/      # Dart extensions (async_value_extensions.dart)
│   │   │   ├── services/        # Core services (error display, supabase, connectivity)
│   │   │   └── utils/           # Utilities (api_response_parser.dart)
│   │   ├── data/                # Shared data layer
│   │   │   ├── api/
│   │   │   │   └── api_client.dart    # Dio-based HTTP client with error mapping
│   │   │   ├── models/          # Shared data models (activity, team, fine, etc.)
│   │   │   └── repositories/    # Placeholder (repositories in features)
│   │   ├── features/            # Feature modules (18 total)
│   │   │   ├── absence/         # Absence reporting and management
│   │   │   ├── achievements/    # Achievement system
│   │   │   ├── activities/      # Activities, training, matches
│   │   │   ├── auth/            # Login, register, token management
│   │   │   ├── chat/            # Team chat and direct messages
│   │   │   ├── documents/       # File upload/download
│   │   │   ├── export/          # Data export functionality
│   │   │   ├── fines/           # Fine system and rules
│   │   │   ├── mini_activities/ # Mini-activities, games, drills
│   │   │   ├── notifications/   # Push notifications
│   │   │   ├── points/          # Points configuration
│   │   │   ├── profile/         # User profile
│   │   │   ├── settings/        # App settings (theme, etc.)
│   │   │   ├── statistics/      # Leaderboards, attendance, player stats
│   │   │   ├── teams/           # Team management and selection
│   │   │   └── tests/           # Physical tests (løpetest, spenst, etc.)
│   │   └── shared/              # Reusable widgets and utilities
│   │       ├── widgets/         # Common widgets (EmptyStateWidget, ErrorWidget)
│   │       └── utils/           # Shared utility functions
│   ├── test/                    # Widget and integration tests
│   │   ├── features/            # Feature-based tests (mirror lib/features structure)
│   │   ├── flows/               # Integration/flow tests
│   │   └── helpers/             # Test utilities (TestApp, TestScenario, test data factories)
│   ├── pubspec.yaml             # Frontend dependencies
│   └── analysis_options.yaml    # Dart analysis configuration
│
├── backend/                      # Dart Shelf backend API
│   ├── bin/
│   │   └── server.dart          # Server entry point (middleware setup, port config)
│   ├── lib/
│   │   ├── api/                 # HTTP layer (37 handler files)
│   │   │   ├── router.dart      # Main router with DI setup
│   │   │   ├── *_handler.dart   # Request handlers (one per resource)
│   │   │   ├── helpers/         # Shared helpers (auth, response, validation, request)
│   │   │   └── middleware/      # Auth middleware
│   │   ├── services/            # Business logic (36 service files)
│   │   ├── models/              # Data models (split by resource)
│   │   ├── db/                  # Database abstraction
│   │   │   └── database.dart    # Supabase client wrapper
│   │   └── helpers/             # Utility helpers
│   ├── pubspec.yaml             # Backend dependencies
│   └── analysis_options.yaml    # Dart analysis configuration
│
├── database/                    # Database migrations and setup
│   ├── migrations/              # SQL migration files (001-027.sql)
│   └── setup.sh                 # Database initialization script
│
├── .github/                     # GitHub configuration
│   └── workflows/               # CI/CD workflows
│
└── .planning/                   # Planning and analysis documents
    └── codebase/                # This directory (ARCHITECTURE.md, STRUCTURE.md, etc.)
```

## Directory Purposes

### Core (`/app/lib/core`)

**Purpose:** Cross-cutting infrastructure and global configuration

**Key Files:**
- `router.dart`: GoRouter setup with all 30+ named routes, auth redirect logic
- `theme.dart`: Material Design theme (light/dark modes)
- `config.dart`: AppConfig class with API base URL
- `services/`: Error display, Supabase realtime, connectivity checking
- `errors/`: Exception types and feature-specific error handlers
- `extensions/`: AsyncValue extensions (when2 builder, error helpers)
- `utils/`: API response parsing utilities

### Data/API (`/app/lib/data`)

**Purpose:** API communication and shared data models

**Key Files:**
- `api/api_client.dart`: Dio-based HTTP client (one instance, all requests routed here)
- `models/`: Enums and classes for Activity, Team, Fine, MiniActivity, etc. (35+ files)
  - Shared between frontend and backend (backend mirrors these)
  - Include fromJson/toJson for serialization
  - Include enums for types (ActivityType.training, RecurrenceType.weekly, etc.)

### Features (`/app/lib/features/<feature>`)

**Standard Structure per Feature:**
```
features/<name>/
├── data/
│   └── <name>_repository.dart       # API calls for this feature
├── providers/
│   ├── <name>_providers.dart        # FutureProviders for data
│   ├── <name>_mutation_notifier.dart # AsyncNotifierProvider for mutations
│   └── <name>_provider.dart          # Single-resource provider
├── presentation/
│   ├── <name>_screen.dart            # Main screen
│   ├── <name>_detail_screen.dart     # Detail view (if applicable)
│   ├── create_<name>_screen.dart     # Creation form (if applicable)
│   ├── edit_<name>_screen.dart       # Edit form (if applicable)
│   └── widgets/                      # Feature-specific widgets
│       ├── widgets.dart              # Barrel export
│       └── <component>_widget.dart   # Individual widgets
```

**18 Features:**
- `absence`: Absence reporting and management screen
- `achievements`: Achievement system, admin management
- `activities`: Training/matches with scheduling and responses
- `auth`: Login/register screens, token management
- `chat`: Unified chat (team + DMs), message display
- `documents`: Team file management
- `export`: Data export functionality
- `fines`: Fine rules, payments, team accounting
- `mini_activities`: Games/drills within activities, scoring
- `notifications`: Push notification management
- `points`: Points configuration per team
- `profile`: User profile viewing and editing
- `settings`: App-level settings (theme, locale)
- `statistics`: Leaderboards, attendance rates, player profiles
- `teams`: Team list, creation, detail views, member management
- `tests`: Physical test tracking (løpetest, spenst, etc.)

### Shared (`/app/lib/shared`)

**Purpose:** Reusable widgets and utilities across features

**Key Files:**
- `widgets/`:
  - `widgets.dart`: Barrel export
  - `empty_state_widget.dart`: Consistent empty state UI
  - `error_widget.dart`: Error display widget
  - Other shared UI components
- `utils/`: Formatting, parsing utilities shared across features

### Shared Test Helpers (`/app/test/helpers`)

**Purpose:** Reusable test infrastructure and mock data

**Key Files:**
- `test_app.dart`: TestApp builder, TestScenario setup helper
- `test_data.dart`: Factory classes for creating test objects (TestTeamFactory, TestUserFactory, etc.)
- `mock_repositories.dart`: Mock implementations of all repositories
- `mock_api_client.dart`: Mock ApiClient for testing

**Pattern - TestScenario:**
```dart
late TestScenario scenario;
setUp(() {
  scenario = TestScenario();
  scenario.setupLoggedIn();  // Pre-populate auth state
  scenario.setupWithTeams(teamCount: 2);  // Set up team list
});
```

### Backend API Handlers (`/backend/lib/api`)

**Purpose:** HTTP request routing and parameter handling

**Files (37 handlers):**
- Core: `auth_handler.dart`, `router.dart`
- Team resources: `teams_handler.dart`, `team_settings_handler.dart`
- Activity resources: `activities_handler.dart`, `activity_instances_handler.dart`
- Mini-activities: `mini_activities_handler.dart`, `mini_activity_scoring_handler.dart`, `mini_activity_statistics_handler.dart`, `mini_activity_teams_handler.dart`
- Statistics: `statistics_handler.dart`, `leaderboards_handler.dart`, `leaderboard_entries_handler.dart`
- Fines: `fines_handler.dart`
- Messages: `messages_handler.dart`
- Documents: `documents_handler.dart`
- Tests: `tests_handler.dart`, `test_results_handler.dart`
- Tournaments: `tournaments_handler.dart`, `tournament_groups_handler.dart`, `tournament_matches_handler.dart`, `tournament_rounds_handler.dart`
- More: achievements, absences, points, exports, notifications, seasons, stopwatch, etc.

**Handler Pattern:**
```dart
class TeamsHandler {
  final TeamService _teamService;
  Router get router => _buildRouter();

  Router _buildRouter() {
    final r = Router();
    r.get('/all', (request) { ... });
    r.get('/<teamId>', (request) { ... });
    r.post('/', (request) { ... });
    return r;
  }
}
```

### Backend Services (`/backend/lib/services`)

**Purpose:** Business logic and database orchestration

**Files (36 services):**
- Core: `auth_service.dart`, `user_service.dart`, `team_service.dart`
- Activity: `activity_service.dart`, `activity_instance_service.dart`
- Mini-activities: `mini_activity_service.dart`, `mini_activity_template_service.dart`, `mini_activity_division_service.dart`, `mini_activity_result_service.dart`, `mini_activity_statistics_service.dart`
- Statistics: `statistics_service.dart`, `leaderboard_service.dart`, `leaderboard_entry_service.dart`, `player_rating_service.dart`, `match_stats_service.dart`
- Fines: `fine_service.dart`
- Messages: `message_service.dart`, `team_chat_service.dart`, `direct_message_service.dart`
- Documents: `document_service.dart`, `export_service.dart`
- Tests: `test_service.dart`
- Tournaments: `tournament_service.dart`, `tournament_group_service.dart`
- More: achievements, points, absences, notifications, seasons, dashboard, stopwatch, etc.

**Service Pattern:**
```dart
class ActivityService {
  final Database db;
  ActivityService(this.db);

  Future<List<Activity>> getActivitiesForTeam(String teamId) async {
    final rows = await db.client.from('activities')
      .select()
      .eq('team_id', teamId)
      .execute();
    return rows.map((row) => Activity.fromJson(row)).toList();
  }
}
```

### Backend Models (`/backend/lib/models`)

**Purpose:** Data structures and serialization

**Organization:**
- Split by resource (activity, team, fine, etc.)
- Each resource may have: main model, enums, sub-models
- All include fromJson/toJson for REST API serialization

### Backend Helpers (`/backend/lib/api/helpers`)

**Files:**
- `response_helpers.dart`: ok(), unauthorized(), forbidden(), badRequest(), notFound(), serverError() functions
- `auth_helpers.dart`: getUserId(), requireTeamMember(), isAdmin()
- `validation_helpers.dart`: Input validation utilities
- `request_helpers.dart`: Request parsing utilities

### Database (`/database`)

**Purpose:** Database schema and migrations

**Files:**
- `migrations/001-027.sql`: Sequential SQL migrations (create tables, add columns, constraints)
- `setup.sh`: Database initialization script for development

## Key File Locations

### Entry Points

- `app/lib/main.dart`: Flutter app initialization (SharedPreferences cache, Supabase init, runApp)
- `backend/bin/server.dart`: Backend server initialization (DB connect, router creation, middleware pipeline)

### Configuration

- `app/lib/core/config.dart`: API base URL (`AppConfig.apiBaseUrl`)
- `app/pubspec.yaml`: Frontend dependencies (flutter_riverpod, go_router, dio, etc.)
- `backend/pubspec.yaml`: Backend dependencies (shelf, shelf_router, supabase, etc.)

### Core Logic

- **Frontend:**
  - `app/lib/core/router.dart`: All 30+ routes and auth redirect
  - `app/lib/data/api/api_client.dart`: HTTP client with interceptors and error mapping
  - `app/lib/core/errors/app_exceptions.dart`: Exception hierarchy
  - `app/lib/core/services/error_display_service.dart`: Global error display

- **Backend:**
  - `backend/lib/api/router.dart`: Route mounting, service DI setup
  - `backend/lib/db/database.dart`: Supabase client wrapper
  - `backend/lib/api/middleware/auth_middleware.dart`: Token validation
  - `backend/lib/api/helpers/response_helpers.dart`: Standardized response format

### Testing

- `app/test/helpers/test_app.dart`: TestApp widget builder
- `app/test/helpers/test_data.dart`: Factory classes for test objects
- `app/test/features/`: Feature test files (mirror lib/features structure)

## Naming Conventions

### Files

**Frontend:**
- Screens: `<feature>_screen.dart` (e.g., `teams_screen.dart`, `activity_detail_screen.dart`)
- Widgets: `<component>_widget.dart` (e.g., `error_widget.dart`)
- Providers: `<feature>_providers.dart`, `<feature>_provider.dart`, `<feature>_notifier.dart`
- Repositories: `<feature>_repository.dart`
- Models: `<model>.dart` or in `models/` directory
- Services: `<service>_service.dart` in `core/services/`

**Backend:**
- Handlers: `<resource>_handler.dart` (e.g., `teams_handler.dart`, `activities_handler.dart`)
- Services: `<resource>_service.dart`
- Models: `<resource>.dart`
- Helpers: `<function_group>_helpers.dart` (e.g., `response_helpers.dart`)

### Directories

- **Feature modules:** lowercase with underscores: `mini_activities`, `team_detail` (NOT camelCase)
- **Data layer:** `data/`, `repositories/`, `models/`
- **Presentation layer:** `presentation/`, `widgets/`
- **State management:** `providers/`, not `view_models/`
- **Backend resources:** plural for collections: `teams/`, `activities/`; singular in routes: `/teams/:id`

### Classes

- **Enums:** PascalCase (e.g., `ActivityType`, `RecurrenceType`, `ResponseType`)
- **Classes:** PascalCase (e.g., `Activity`, `Team`, `ApiClient`)
- **Exceptions:** PascalCase ending with 'Exception' (e.g., `NetworkException`, `TokenExpiredException`)

### Functions and Variables

- **Functions:** camelCase (e.g., `getActivitiesForTeam()`, `requireTeamMember()`)
- **Variables:** camelCase (e.g., `userId`, `teamId`, `isAdmin`)
- **Constants:** UPPER_SNAKE_CASE for package-level (rare in this codebase)

## Where to Add New Code

### New Feature

**Step 1: Create feature structure**
```
app/lib/features/<feature>/
├── data/
│   └── <feature>_repository.dart
├── providers/
│   ├── <feature>_providers.dart
│   └── <feature>_notifier.dart
├── presentation/
│   ├── <feature>_screen.dart
│   └── widgets/
│       └── <component>_widget.dart
```

**Step 2: Add routes**
- Edit: `app/lib/core/router.dart`
- Add GoRoute with path, name, builder

**Step 3: Add repository methods**
- Edit or create: `app/lib/features/<feature>/data/<feature>_repository.dart`
- Call `_apiClient.get('/endpoint')` with appropriate serialization

**Step 4: Add providers**
- Edit: `app/lib/features/<feature>/providers/<feature>_providers.dart`
- Create FutureProvider or AsyncNotifierProvider wrapping repository

**Step 5: Add screens and widgets**
- Create: `app/lib/features/<feature>/presentation/<feature>_screen.dart`
- Watch providers with `ref.watch(provider)`
- Use `when2()` for AsyncValue handling
- Extract complex UI to `widgets/` subdirectory

**Backend:**
- Create: `backend/lib/api/<feature>_handler.dart` (HTTP routing)
- Create: `backend/lib/services/<feature>_service.dart` (business logic)
- Create: `backend/lib/models/<feature>.dart` (data structures)
- Edit: `backend/lib/api/router.dart` (add handler mounting with middleware)

### New Screen/Page

**Location:** `app/lib/features/<feature>/presentation/<screen_name>_screen.dart`

**Template:**
```dart
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(someProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Title')),
      body: data.when2(
        data: (items) => ListView(...),
        error: (error, retry) => ErrorWidget(error: error),
      ),
    );
  }
}
```

### New Widget Component

**Location:** `app/lib/features/<feature>/presentation/widgets/<component>_widget.dart`

**or (shared across features):** `app/lib/shared/widgets/<component>_widget.dart`

**Template:**
```dart
class MyWidget extends ConsumerWidget {
  const MyWidget({required this.data, super.key});

  final SomeData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(...);
  }
}
```

### New Provider

**Location:** `app/lib/features/<feature>/providers/<feature>_providers.dart`

**For read-only data:**
```dart
final myDataProvider = FutureProvider.family<List<Item>, String>((ref, id) async {
  final repo = ref.watch(myRepositoryProvider);
  return repo.fetchItems(id);
});
```

**For mutations:**
```dart
final myMutationProvider = StateNotifierProvider<MyNotifier, AsyncValue<Result>>((ref) {
  return MyNotifier(ref.watch(myRepositoryProvider));
});

class MyNotifier extends StateNotifier<AsyncValue<Result>> {
  MyNotifier(this._repo) : super(const AsyncValue.data(null));
  final MyRepository _repo;

  Future<void> doSomething() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.create(...));
  }
}
```

### New API Endpoint (Backend)

**Step 1: Create handler**
- File: `backend/lib/api/<resource>_handler.dart`
- Define routes using Router

**Step 2: Create service**
- File: `backend/lib/services/<resource>_service.dart`
- Implement business logic and database queries

**Step 3: Create models**
- File: `backend/lib/models/<resource>.dart`
- Add fromJson/toJson for serialization

**Step 4: Register in router**
- Edit: `backend/lib/api/router.dart`
- Instantiate service
- Mount handler: `router.mount('/resource', const Pipeline().addMiddleware(auth).addHandler(handler).call)`

**Step 5: Add database migration (if needed)**
- File: `database/migrations/NNN-description.sql`
- Create tables, add columns, set up constraints

### Utilities and Helpers

**Shared across features:** `app/lib/shared/utils/`

**Feature-specific:** `app/lib/features/<feature>/` (no subdirectory needed if small)

**Backend helpers:** `backend/lib/api/helpers/` or `backend/lib/helpers/`

## Special Directories

### Generated Code

**Location:** `app/build/`, `backend/.dart_tool/`

**Status:** Not committed (in .gitignore)

**Regenerate:** Run `flutter pub get` or `dart pub get`

### Environment Files

**Status:** `.env` files not committed (secrets)

**Frontend:** Passed via `--dart-define` at build time (see CLAUDE.md)

**Backend:** Required: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`, `JWT_SECRET`

---

*Structure analysis: 2026-02-08*
