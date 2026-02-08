# Technology Stack

**Analysis Date:** 2026-02-08

## Languages

**Primary:**
- Dart 3.10+ - Both frontend (Flutter) and backend (Shelf)
- SQL - Database migrations and queries via Supabase REST API

**Secondary:**
- YAML - Configuration files (pubspec.yaml, analysis_options.yaml)
- Bash - Build/deployment scripts (`run.sh`)

## Runtime

**Frontend:**
- Flutter 3.10+ (specified in `/app/pubspec.yaml` as `sdk: ^3.10.4`)
- Runs on iOS, Android, macOS, web

**Backend:**
- Dart Runtime (native executable)
- Shelf HTTP framework serves on configurable port (default 8080, from `/backend/bin/server.dart`)

**Package Manager:**
- Pub (Dart package manager)
- Lockfiles: `pubspec.lock` (frontend and backend)

## Frameworks

**Frontend:**
- **Flutter** - UI framework
- **Riverpod** 3.2.0 - State management and provider pattern (`flutter_riverpod`)
- **GoRouter** 17.1.0 - Navigation and deep linking (`go_router`)
- **Dio** 5.4.0 - HTTP client for backend communication

**Backend:**
- **Shelf** 1.4.2 - HTTP framework and request routing
- **Shelf Router** 1.1.4 - Route handler organization
- **HTTP** 1.2.0 - Supabase REST API client (via `http` package)

**Testing:**
- **Flutter Test** - Widget and integration tests
- **Mocktail** 1.0.0 - Mocking framework (frontend)
- **Dart Test** 1.25.0 - Backend unit tests (from `dev_dependencies`)

**Build/Dev:**
- **Flutter Lints** 6.0.0 - Lint rules for code quality
- **Dart Lints** 6.1.0 - Backend lint rules

## Key Dependencies

**Critical:**

Frontend:
- `supabase_flutter` 2.8.0 - Realtime database subscriptions (optional, disabled if env vars missing)
- `firebase_messaging` 16.1.1 - Push notifications via Firebase Cloud Messaging
- `firebase_core` 4.4.0 - Firebase SDK initialization
- `cached_network_image` 3.3.1 - Image caching and optimization
- `shared_preferences` 2.2.0 - Local persistent storage (auth tokens, settings)

Backend:
- `bcrypt` 1.1.3 - Password hashing (in `auth_service.dart`)
- `dart_jsonwebtoken` 3.3.1 - JWT token generation and validation
- `uuid` 4.4.0 - UUID generation for IDs

**Infrastructure:**

Frontend:
- `connectivity_plus` 7.0.0 - Network connectivity monitoring
- `path_provider` 2.1.0 - File system access for documents
- `file_picker` 10.3.10 - File selection for document uploads
- `share_plus` 12.0.1 - Share files functionality
- `intl` 0.20.2 - Internationalization (date formatting with Norwegian locale `nb_NO`)
- `table_calendar` 3.1.2 - Calendar widget for activity scheduling
- `cupertino_icons` 1.0.8 - iOS-style icons

## Configuration

**Backend Environment:**
File: `/backend/.env` (example in `/backend/.env.example`)
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_KEY=your-service-key
JWT_SECRET=your-jwt-secret-change-in-production
PORT=8080
```

Required for backend startup:
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_SERVICE_KEY` - Service role key for authenticated REST API calls
- `JWT_SECRET` - Secret for signing authentication tokens (required, server fails fast if missing)
- `PORT` - Server port (defaults to 8080)

**Frontend Environment:**
Passed at build/run via `--dart-define` flags (from `CLAUDE.md`):
```bash
--dart-define=SUPABASE_URL=https://your-project.supabase.co
--dart-define=SUPABASE_ANON_KEY=your-anon-key
--dart-define=API_BASE_URL=http://localhost:8080  # Optional, defaults to localhost:8080
```

Configuration loaded in:
- `app/lib/core/config.dart` - AppConfig class with String.fromEnvironment() calls

**Analysis Configuration:**
- `app/analysis_options.yaml` - Flutter lint rules (extends `package:flutter_lints/flutter.yaml`)

## Platform Requirements

**Development:**
- Dart SDK 3.10+ (installed via Flutter SDK or standalone)
- Flutter SDK 3.10+ (for frontend development)
- Git (for version control)
- Bash shell (for `run.sh` scripts)

**Production:**

Frontend:
- iOS 11+ (minimum deployment target)
- Android 21+ (minimum API level)
- macOS 10.11+ (desktop)
- Web browser with modern JavaScript support

Backend:
- Linux/macOS/Windows server with Dart runtime
- Network access to Supabase PostgreSQL API endpoint
- Network access to Firebase Cloud Messaging (for push notifications)

**Deployment:**
Backend deployment targets not explicitly specified in codebase. Port configuration suggests containerization support (Dockerfile not present in repo, typically managed separately).

## Build Configuration

**Frontend Build:**
- Dart compiler (Flutter/Dart built-in)
- iOS: Xcode compilation for iOS/macOS targets
- Android: Gradle compilation
- Web: Dart JS compiler

**Backend Build:**
- Dart compiler produces native executable
- Typical: `dart compile exe bin/server.dart -o server`

**Lock Files:**
Both frontend and backend committed with `pubspec.lock` to ensure reproducible builds.

## Version Pinning

**Frontend:**
- Most dependencies use `^` caret constraints (e.g., `^5.4.0`)
- Allows patch/minor updates, prevents breaking major versions

**Backend:**
- Same caret constraint approach
- More minimal dependency set (core HTTP/auth packages only)

---

*Stack analysis: 2026-02-08*
