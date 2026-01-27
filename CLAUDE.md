# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Core - Idrett is a Norwegian sports team management application with a Flutter frontend and Dart backend, using Supabase (PostgreSQL) for the database.

## Development Commands

### Backend (from `/backend`)
```bash
dart pub get              # Install dependencies
./run.sh                  # Run server with .env loaded (requires .env file)
dart run bin/server.dart  # Run server directly (requires env vars exported)
dart analyze              # Run static analysis
dart test                 # Run backend tests
```

### Frontend (from `/app`)
```bash
flutter pub get           # Install dependencies
flutter run               # Run app (debug mode)
flutter analyze           # Run static analysis
flutter test              # Run all widget tests
flutter test test/features/auth/  # Run tests for a specific feature
flutter test integration_test/app_test.dart  # Run integration tests
```

### Database
SQL migrations are in `/database/migrations/` (files 001-009). Apply sequentially via Supabase dashboard or the setup script in `/database/setup.sh`.

## Architecture

### Frontend (`/app/lib`)
- **Clean Architecture with Riverpod** for state management
- **Feature-based structure**: Each feature in `/features/` contains:
  - `data/` - repositories, data sources
  - `providers/` - Riverpod providers (state + notifiers)
  - `presentation/` - screens and widgets
- **Core layer** (`/core`): router (GoRouter), theme, config, services, error handling
- **Data layer** (`/data`): shared models, API client (Dio-based), base repositories

### Backend (`/backend/lib`)
- **Shelf framework** for HTTP handling
- **Handler → Service → Database** layered pattern
- `api/` - HTTP route handlers
- `services/` - business logic
- `models/` - data models (mirror frontend models)
- `db/` - Supabase client wrapper

### Data Flow
UI → Riverpod Providers → Repositories → API Client (Dio) → Backend Handlers → Services → Supabase

## Key Patterns

### State Management
All async state uses `AsyncValue<T>` from Riverpod. Providers are typically `AsyncNotifierProvider` for mutable state.

### Error Handling
Feature-specific error handlers in `/app/lib/core/errors/handlers/` transform API errors into user-friendly messages. Use `ref.read(errorDisplayServiceProvider).showError()` to display errors.

### Testing
- Test helpers in `/app/test/helpers/`: `TestApp`, `TestScenario`, `MockProviders`
- Use `TestScenario` to set up common test states (logged in, with teams, etc.)
- Mock repositories in `mock_repositories.dart`, test data factories in `test_data.dart`

## Environment Variables (Backend)
Required in `/backend/.env`:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `JWT_SECRET`

## API Base URL
Frontend API URL is configured in `/app/lib/core/config.dart` (defaults to `http://localhost:8080`).
