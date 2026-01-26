# Core - Idrett

A sports team management app built with Flutter (frontend) and Dart (backend).

## Features

- **Team Management**: Create and manage sports teams with customizable settings
- **Activities**: Schedule training sessions, matches, and events with recurring options
- **Attendance Tracking**: Track member attendance with response options (yes/no/maybe)
- **Mini-Activities**: Create sub-activities within events (e.g., team games, drills)
- **Statistics & Leaderboard**: Track player points, attendance rates, and rankings
- **Fine System**: Manage team fines with customizable rules and payment tracking
- **Role-Based Access**: Admin, Fine Boss, and Player roles with different permissions
- **Theme Support**: Light, dark, and system theme options

## Project Structure

```
Core-Idrett/
├── app/                    # Flutter mobile/web app
│   ├── lib/
│   │   ├── core/          # Theme, router, config
│   │   ├── data/          # Models and API client
│   │   └── features/      # Feature modules
│   │       ├── auth/
│   │       ├── teams/
│   │       ├── activities/
│   │       ├── mini_activities/
│   │       ├── statistics/
│   │       ├── fines/
│   │       └── settings/
│   └── pubspec.yaml
├── backend/               # Dart backend server
│   ├── bin/
│   │   └── server.dart   # Entry point
│   ├── lib/
│   │   ├── api/          # HTTP handlers
│   │   ├── db/           # Database client
│   │   ├── models/       # Data models
│   │   └── services/     # Business logic
│   └── pubspec.yaml
└── database/             # SQL migrations
    └── migrations/
```

## Getting Started

### Prerequisites

- Flutter SDK (3.10+)
- Dart SDK (3.0+)
- Supabase account (for database)

### Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Install dependencies:
   ```bash
   dart pub get
   ```

3. Set environment variables:
   ```bash
   export SUPABASE_URL=your_supabase_url
   export SUPABASE_ANON_KEY=your_anon_key
   export JWT_SECRET=your_jwt_secret
   ```

4. Run the server:
   ```bash
   dart run bin/server.dart
   ```

### Frontend Setup

1. Navigate to the app directory:
   ```bash
   cd app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Update the API URL in `lib/core/config.dart`

4. Run the app:
   ```bash
   flutter run
   ```

### Database Setup

Run the SQL migrations in order from the `database/migrations/` folder in your Supabase project.

## API Endpoints

### Authentication
- `POST /auth/register` - Register new user
- `POST /auth/login` - Login
- `POST /auth/invite/:code` - Register with invite code
- `GET /auth/me` - Get current user
- `PATCH /auth/profile` - Update profile

### Teams
- `GET /teams` - List user's teams
- `POST /teams` - Create team
- `GET /teams/:id` - Get team details
- `PATCH /teams/:id` - Update team
- `GET /teams/:id/members` - List members
- `GET /teams/:id/settings` - Get team settings
- `PATCH /teams/:id/settings` - Update settings

### Activities
- `GET /activities/team/:teamId` - List activities
- `POST /activities/team/:teamId` - Create activity
- `PATCH /activities/:id` - Update activity
- `DELETE /activities/:id` - Delete activity
- `POST /activities/instances/:id/respond` - Respond to activity

### Statistics
- `GET /statistics/team/:teamId/leaderboard` - Get leaderboard
- `GET /statistics/team/:teamId/attendance` - Get attendance stats

### Fines
- `GET /fines/team/:teamId` - List fines
- `POST /fines/team/:teamId` - Report fine
- `GET /fines/team/:teamId/rules` - List fine rules

## Tech Stack

- **Frontend**: Flutter, Riverpod, Go Router
- **Backend**: Dart, Shelf
- **Database**: Supabase (PostgreSQL)
- **Authentication**: JWT

## License

This project is private and not licensed for public use.
