# External Integrations

**Analysis Date:** 2026-02-08

## APIs & External Services

**Supabase (Database & Realtime):**
- PostgreSQL database backend via Supabase REST API
- Realtime subscriptions for activity response changes
  - SDK: `supabase_flutter` 2.8.0 (frontend), custom REST client (backend)
  - Auth: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`
  - Frontend implementation: `app/lib/core/services/supabase_service.dart`
  - Backend implementation: `backend/lib/db/supabase_client.dart` (custom HTTP-based wrapper)

**Backend HTTP API (Internal):**
- Custom Shelf-based REST API
- Hostname/port: Configured via `API_BASE_URL` env var (defaults to `http://localhost:8080`)
- Frontend client: `app/lib/data/api/api_client.dart` (Dio-based)
- Authentication: Bearer token in `Authorization` header
- Error mapping: HTTP status codes (400, 401, 403, 404, 409) mapped to domain exceptions

## Data Storage

**Databases:**
- **Supabase PostgreSQL**
  - Connection: Via Supabase REST API (not direct SQL connection)
  - Base URL: `${SUPABASE_URL}/rest/v1/`
  - Service key authentication: `Authorization: Bearer ${SUPABASE_SERVICE_KEY}`
  - Anon key authentication: `Authorization: Bearer ${SUPABASE_ANON_KEY}`
  - 27 SQL migrations in `/database/migrations/001-027_*.sql`
  - Tables include: teams, users, team_members, activities, activity_responses, mini_activities, fines, messages, tournaments, achievements, absences, documents, statistics, and more
  - Frontend ORM: None (direct REST API calls via `supabase_flutter` for realtime)
  - Backend client: Custom `SupabaseClient` class using `http` package for REST calls

**File Storage:**
- Not integrated - documents uploaded but storage backend not explicitly configured
- File picker: `file_picker` 10.3.10
- Potential: Supabase Storage (not currently visible in integrations)

**Caching:**
- **Local caching (frontend):**
  - `cached_network_image` 3.3.1 - Caches images on disk
  - `shared_preferences` 2.2.0 - Caches auth tokens, user settings
  - Example: `app/lib/features/notifications/providers/notification_provider.dart` registers FCM token in local state

- **Backend caching:**
  - In-memory via Dart (no Redis, no distributed cache)
  - Database-level caching via Supabase connection pooling

## Authentication & Identity

**Auth Provider:**
- Custom implementation (not Firebase Auth, not Auth0)
- JWT tokens stored locally on device

**Token Lifecycle:**
- Login endpoint: `POST /auth/login` - Returns JWT token
- Token storage: `SharedPreferences` via `AuthLocalDataSource` (from `CLAUDE.md`)
- Token injection: `Authorization: Bearer <token>` header by `ApiClient` (line 31 in `api_client.dart`)
- Token validation: Backend validates via `JWT_SECRET` env var (via `dart_jsonwebtoken` package)
- Expiration handling: 401 responses trigger logout, token cleared from storage
- Implementation: `backend/lib/services/auth_service.dart`, `backend/lib/api/middleware/auth_middleware.dart`

**Password Security:**
- Hashing: `bcrypt` 1.1.3 (backend only)
- Implemented in `AuthService` (backend)

**Endpoints:**
- `POST /auth/register` - User registration
- `POST /auth/login` - User login (returns JWT)
- `GET /auth/me` - Current user (requires valid token)
- `PUT /auth/profile` - Update user profile
- `POST /auth/invite/:code` - Accept team invite

## Push Notifications

**Service Provider:**
- Firebase Cloud Messaging (FCM)
- SDK: `firebase_messaging` 16.1.1, `firebase_core` 4.4.0 (frontend only)

**Implementation:**
- File: `app/lib/features/notifications/providers/notification_provider.dart`
- FCM token registration on app launch
- Token refresh listening via `messaging.onTokenRefresh`
- Platform detection: iOS vs Android (`Platform.isIOS`)
- Foreground message handling: `FirebaseMessaging.onMessage` listener
- Token management: Registered to backend via `NotificationRepository.registerToken()` and removed on logout

**Notification Types:**
From database schema:
- New activity
- Activity reminder
- Activity cancelled
- New fine
- Fine decision
- Team message

**Configuration:**
- Firebase credentials: Not committed to git (added to `.gitignore` per commit `af52de1`)
- Notification preferences: Stored per user/team in `notification_preferences` table

## Monitoring & Observability

**Error Tracking:**
- Not integrated with external service (Sentry, Rollbar, etc.)
- Backend errors logged via `print()` statements
- Frontend errors handled via `ErrorDisplayService.showWarning()` (from `CLAUDE.md`)

**Logs:**
- Backend: Standard output via `print()` and middleware logging
- Middleware: `logRequests()` from Shelf (in `bin/server.dart`)
- Frontend: Debug logs via `print()` with `kDebugMode` guard (line 26 in `main.dart`)

**Debugging:**
- VSCode launch config: `.vscode/launch.json` (app, app profile/release, backend)

## CI/CD & Deployment

**Hosting:**
- Not specified in codebase
- Backend: Typical deployment to Linux server (port-configurable)
- Frontend: App stores (iOS App Store, Google Play) or web platform

**CI Pipeline:**
- Not detected in codebase
- No GitHub Actions workflows (would be in `.github/workflows/`)
- Manual build/deployment

**Build Artifacts:**
- Frontend: Flutter APK (Android), IPA (iOS), app bundle
- Backend: Compiled Dart executable

## Environment Configuration

**Critical env vars (required for operation):**

Backend:
- `SUPABASE_URL` - Database API endpoint
- `SUPABASE_SERVICE_KEY` - Service role authentication
- `JWT_SECRET` - Token signing key (server fails to start without this)
- `PORT` - Server listening port (default 8080)

Frontend (compile-time):
- `API_BASE_URL` - Backend API URL (default `http://localhost:8080`)
- `SUPABASE_URL` - Realtime database URL (optional, realtime disabled if missing)
- `SUPABASE_ANON_KEY` - Realtime authentication (optional, realtime disabled if missing)

**Optional env vars:**
- Firebase credentials (auto-detected from platform files, not in .env)

**Secrets location:**
- Backend: `.env` file (Git-ignored via `.gitignore`)
- Frontend: Compile-time `--dart-define` flags (not persisted)
- Signing keys: Git-ignored per commit `af52de1`
- Firebase config: Git-ignored per commit `af52de1`

**Config files:**
- `.env` and `.env.example` - Backend only
- No `.env.local` or environment-specific configs detected
- `CLAUDE.md` documents all required configuration

## Webhooks & Callbacks

**Incoming Webhooks:**
- None detected
- No webhook endpoints in API handlers

**Outgoing Webhooks:**
- None detected
- Firebase Cloud Messaging is push-based (server sends to FCM, not via webhooks)

**Real-time Events:**
- Supabase PostgreSQL Change Events (frontend only)
- Implementation: `SupabaseService.subscribeToActivityResponses()` in `app/lib/core/services/supabase_service.dart`
- Subscribes to: `activity_responses` table changes
- Callback: Invalidates Riverpod providers to refresh UI

## API Response Handling

**Error Responses:**
Backend returns JSON error format:
```json
{
  "error": true,
  "message": "User-facing error message",
  "code": "ERROR_CODE"
}
```

Frontend mapping (from `api_client.dart` lines 58-130):
- 400 → `ValidationException`
- 401 → `TokenExpiredException`
- 403 → `PermissionException`
- 404 → `ResourceNotFoundException`
- 409 → `ConflictException`
- 500+ → `ServerException`

**CORS:**
- Enabled via middleware: `_corsMiddleware()` in `bin/server.dart`
- All methods allowed (`OPTIONS`, `POST`, `GET`, etc.)

## Rate Limiting

**Rate Limiting:**
- Not detected in codebase
- No rate limiting middleware on backend
- Supabase may enforce rate limits at database/API level

---

*Integration audit: 2026-02-08*
