# Phase 3: Backend Service Splitting - Research

**Researched:** 2026-02-09
**Domain:** Dart service architecture, file organization, dependency injection patterns
**Confidence:** HIGH

## Summary

Phase 3 addresses file size and complexity issues in the Core - Idrett backend where 8 service files exceed 400 LOC (ranging from 488 to 758 lines). Large service files mix multiple concerns (CRUD operations, business logic, complex queries, aggregations) making them difficult to maintain and test. The codebase has already demonstrated successful service splitting in Fase 9 (achievement→3, statistics→3, message→3), but those splits did NOT use barrel exports, requiring router.dart to import each service individually.

**Current state:** The project uses manual dependency injection in `router.dart` where all services are instantiated at startup with constructor injection. Services follow a consistent pattern: Database dependency + optional service dependencies. The existing Fase 9 splits created separate service classes (e.g., `AchievementDefinitionService`, `AchievementProgressService`, `AchievementService`) without barrel exports.

**Phase 3 requirement:** Unlike Fase 9, this phase explicitly requires **barrel exports maintaining existing import paths** (per ROADMAP.md success criteria #5). This means handlers and other consumers continue importing from a single file (e.g., `services/tournament_service.dart`) while the implementation splits across multiple files behind a barrel export.

**Primary recommendation:** Split large services by concern/feature area (CRUD, queries, aggregations, business logic) into focused sub-services, create a barrel export file maintaining the original import path, update router.dart DI to instantiate sub-services and inject them where needed. Verify no import changes required outside the services/ directory.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Dart 3.10+ | 3.10+ | Module system with `export` directive | Native barrel export support |
| Shelf | Current | HTTP framework | Already used throughout backend |
| Supabase client | Current | Database access | Core dependency injected into services |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| uuid | Current | ID generation | Already used in all services |
| N/A | N/A | No additional packages needed | Dart core exports are sufficient |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Barrel exports | Individual imports in router.dart | Breaking change to all handlers; maintenance burden |
| Service factories | get_it or injectable DI | Adds complexity; manual DI works fine for ~40 services |
| Service inheritance | Composition with sub-services | Inheritance creates tight coupling; composition preferred |

**Installation:**
```bash
# No new dependencies required - using existing Dart and project packages
```

## Architecture Patterns

### Recommended Service Structure (with barrel export)

For a service being split (e.g., `tournament_service.dart` → 4 files):

```
backend/lib/services/
├── tournament_service.dart              # Barrel export (maintains import path)
├── tournament/
│   ├── tournament_crud_service.dart     # CRUD operations
│   ├── tournament_rounds_service.dart   # Round management
│   ├── tournament_matches_service.dart  # Match management
│   └── tournament_bracket_service.dart  # Bracket generation
```

**Barrel export pattern (`tournament_service.dart`):**
```dart
// Tournament Services - Barrel export
// Maintains existing import: import '../services/tournament_service.dart';

export 'tournament/tournament_crud_service.dart';
export 'tournament/tournament_rounds_service.dart';
export 'tournament/tournament_matches_service.dart';
export 'tournament/tournament_bracket_service.dart';
```

### Pattern 1: Service Splitting by Concern

**What:** Decompose large services into focused sub-services organized by feature area or responsibility
**When to use:** When a service exceeds 400 LOC or handles >3 distinct concerns
**Example:**

```dart
// tournament/tournament_crud_service.dart
// Responsibility: Basic tournament CRUD operations
class TournamentCrudService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentCrudService(this._db);

  Future<Tournament> createTournament({...}) async { ... }
  Future<Tournament?> getTournamentById(String id) async { ... }
  Future<void> updateTournamentStatus(String id, TournamentStatus status) async { ... }
  Future<void> deleteTournament(String id) async { ... }
}

// tournament/tournament_rounds_service.dart
// Responsibility: Tournament round management
class TournamentRoundsService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentRoundsService(this._db);

  Future<TournamentRound> createRound({...}) async { ... }
  Future<List<TournamentRound>> getRoundsForTournament(String tournamentId) async { ... }
  Future<void> updateRoundStatus(String roundId, MatchStatus status) async { ... }
}

// tournament/tournament_matches_service.dart
// Responsibility: Tournament match operations
class TournamentMatchesService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentMatchesService(this._db);

  Future<TournamentMatch> createMatch({...}) async { ... }
  Future<void> recordMatchResult({...}) async { ... }
  Future<void> setWalkover({...}) async { ... }
}

// tournament/tournament_bracket_service.dart
// Responsibility: Bracket generation and complex logic
class TournamentBracketService {
  final Database _db;
  final TournamentRoundsService _roundsService;
  final TournamentMatchesService _matchesService;

  TournamentBracketService(
    this._db,
    this._roundsService,
    this._matchesService,
  );

  Future<List<TournamentMatch>> generateSingleEliminationBracket({...}) async {
    // Uses _roundsService and _matchesService for complex bracket creation
    ...
  }
}
```

**Splitting guidelines:**
1. **CRUD operations** → Separate service (create, read, update, delete)
2. **Business logic** → Separate service (complex calculations, workflows)
3. **Query/aggregation** → Separate service (statistics, summaries, reports)
4. **Related entity management** → Separate service (child entities like rounds, matches)

### Pattern 2: Router DI Update Pattern

**What:** Update router.dart to instantiate sub-services and wire dependencies
**When to use:** After splitting any service file
**Example:**

```dart
// router.dart BEFORE (Fase 9 pattern - no barrel export):
final tournamentService = TournamentService(db, tournamentGroupService);

// router.dart AFTER (Phase 3 pattern - with barrel export):
// Instantiate sub-services
final tournamentCrudService = TournamentCrudService(db);
final tournamentRoundsService = TournamentRoundsService(db);
final tournamentMatchesService = TournamentMatchesService(db);
final tournamentBracketService = TournamentBracketService(
  db,
  tournamentRoundsService,
  tournamentMatchesService,
);

// Handler still receives what it needs (might be all sub-services or just some)
final tournamentsHandler = TournamentsHandler(
  tournamentCrudService,
  tournamentRoundsService,
  tournamentMatchesService,
  tournamentBracketService,
  tournamentGroupService,
  teamService,
);
```

**Key principles:**
- Sub-services inject Database + any sub-service dependencies
- Complex services (like BracketService) depend on simpler services (CRUD, Rounds, Matches)
- Handlers receive all sub-services they need (no aggregator wrapper)
- Import path stays the same: `import '../services/tournament_service.dart';` now exports all sub-services

### Pattern 3: Dependency Flow for Split Services

**What:** Establish clear dependency direction to avoid circular references
**When to use:** When sub-services need to call each other
**Example:**

```
┌─────────────────────────────────────────┐
│         TournamentBracketService        │  ← Complex logic layer
│  (depends on Rounds + Matches services) │
└─────────────────────────────────────────┘
             ↓              ↓
┌────────────────────┐  ┌──────────────────────┐
│ TournamentRounds   │  │ TournamentMatches    │  ← Domain operations
│ Service            │  │ Service              │
└────────────────────┘  └──────────────────────┘
             ↓                    ↓
┌─────────────────────────────────────────┐
│         TournamentCrudService           │  ← Base CRUD layer
└─────────────────────────────────────────┘
             ↓
┌─────────────────────────────────────────┐
│            Database                     │  ← Data layer
└─────────────────────────────────────────┘
```

**Rules:**
1. CRUD services only depend on Database
2. Domain services (Rounds, Matches) only depend on Database (not each other if possible)
3. Business logic services depend on Domain/CRUD services
4. No circular dependencies between sub-services
5. If cross-dependency needed, extract shared logic to a separate service

### Anti-Patterns to Avoid

- **God object wrapper:** Don't create a TournamentService that just delegates to sub-services — use barrel export instead
- **Circular dependencies:** Sub-services calling each other bidirectionally (extract shared logic instead)
- **Partial splitting:** Don't split only part of a service — commit to full decomposition
- **Breaking imports:** Don't require handlers to change imports — barrel export must maintain path
- **Over-splitting:** Don't create services with <50 LOC — aim for 150-350 LOC focused modules

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DI container | Custom service locator | Manual constructor injection in router.dart | Simple, explicit, ~40 services is manageable |
| Export aggregation | Custom export mechanism | Dart `export` directive | Native, zero-cost, IDE-supported |
| Service discovery | Reflection-based wiring | Explicit instantiation in router.dart | Type-safe, compile-time checked |

**Key insight:** Dart's module system handles barrel exports natively. The `export` directive is zero-cost at runtime and fully supported by IDEs for code completion and navigation.

## Common Pitfalls

### Pitfall 1: Forgetting to Update Handler Constructors
**What goes wrong:** After splitting services, handlers still expect old single-service parameter
**Why it happens:** Router.dart updated but handler constructor signature not updated
**How to avoid:**
1. First update handler constructor to accept sub-services
2. Then update router.dart instantiation
3. Verify with `dart analyze` (shows constructor parameter mismatches)
**Warning signs:** Compilation errors in router.dart about parameter count/type

### Pitfall 2: Circular Dependencies Between Sub-Services
**What goes wrong:** Service A depends on Service B which depends on Service A
**Why it happens:** Two feature areas share logic but were split into separate services
**How to avoid:**
1. Draw dependency graph before splitting
2. Shared logic goes into a common/core sub-service
3. Keep dependency flow unidirectional (CRUD → Domain → Business Logic)
**Warning signs:** Import cycle errors during compilation

### Pitfall 3: Over-Granular Splitting
**What goes wrong:** Service split into 10+ tiny files with <50 LOC each
**Why it happens:** Splitting every method into its own service
**How to avoid:**
1. Target 150-350 LOC per sub-service (focused but not microscopic)
2. Group related operations (all round operations together)
3. Split by cohesive feature area, not by individual methods
**Warning signs:** More service files than actual features; services with 1-2 methods only

### Pitfall 4: Breaking Existing Imports
**What goes wrong:** Handlers/other services must update imports after splitting
**Why it happens:** No barrel export created, or barrel export in wrong location
**How to avoid:**
1. Always create barrel export at original file location (e.g., `tournament_service.dart`)
2. Test that `import '../services/tournament_service.dart';` still works
3. Verify no imports changed outside services/ directory
**Warning signs:** Import errors in handlers; grep for service imports shows changed paths

### Pitfall 5: Sub-Service Not Exported from Barrel
**What goes wrong:** Handler can't access a sub-service class even though it's split
**Why it happens:** Forgot to add `export` line in barrel file
**How to avoid:**
1. Add export line immediately when creating new sub-service file
2. Verify by importing barrel file and checking available classes
3. Run `dart analyze` to catch missing exports
**Warning signs:** "Undefined class" errors in handlers despite file existing

## Code Examples

Verified patterns from Dart documentation and existing codebase:

### Complete Service Splitting Example: Tournament Service (758 LOC → 4 files)

**Step 1: Identify concerns in current service**
```
Current tournament_service.dart (758 LOC):
- Lines 14-136: Tournament CRUD (create, get, update, delete) — ~122 LOC
- Lines 138-210: Round management (create, get, update rounds) — ~72 LOC
- Lines 212-443: Match operations (create, update, complete, walkover) — ~231 LOC
- Lines 445-523: Game management (best-of series) — ~78 LOC
- Lines 554-697: Bracket generation (complex algorithm) — ~143 LOC
- Lines 722-758: Tournament detail aggregation — ~36 LOC
```

**Step 2: Create sub-service files**

```dart
// services/tournament/tournament_crud_service.dart
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/tournament.dart';
import '../helpers/parsing_helpers.dart';

class TournamentCrudService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentCrudService(this._db);

  Future<Tournament> createTournament({...}) async { ... }
  Future<Tournament?> getTournamentById(String tournamentId) async { ... }
  Future<Tournament?> getTournamentForMiniActivity(String miniActivityId) async { ... }
  Future<String?> getTeamIdForTournament(String tournamentId) async { ... }
  Future<void> updateTournamentStatus(String tournamentId, TournamentStatus status) async { ... }
  Future<Tournament> updateTournament({...}) async { ... }
  Future<void> deleteTournament(String tournamentId) async { ... }
}
```

```dart
// services/tournament/tournament_rounds_service.dart
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/tournament.dart';

class TournamentRoundsService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentRoundsService(this._db);

  Future<TournamentRound> createRound({...}) async { ... }
  Future<List<TournamentRound>> getRoundsForTournament(String tournamentId) async { ... }
  Future<void> updateRoundStatus(String roundId, MatchStatus status) async { ... }
  Future<TournamentRound> updateRound({...}) async { ... }
}
```

```dart
// services/tournament/tournament_matches_service.dart
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/tournament.dart';
import '../helpers/parsing_helpers.dart';

class TournamentMatchesService {
  final Database _db;
  final _uuid = const Uuid();

  TournamentMatchesService(this._db);

  Future<TournamentMatch> createMatch({...}) async { ... }
  Future<TournamentMatch> updateMatch({...}) async { ... }
  Future<TournamentMatch> startMatch(String matchId) async { ... }
  Future<TournamentMatch> completeMatch(String matchId, String winnerId) async { ... }
  Future<TournamentMatch> declareWalkover({...}) async { ... }
  Future<List<TournamentMatch>> getMatchesForRound(String roundId) async { ... }
  Future<List<TournamentMatch>> getMatchesForTournament(String tournamentId, {String? roundId}) async { ... }
  Future<TournamentMatch?> getMatchById(String matchId) async { ... }
  Future<void> recordMatchResult({...}) async { ... }
  Future<void> setWalkover({...}) async { ... }

  // Match games (best-of series)
  Future<MatchGame> createGame({...}) async { ... }
  Future<List<MatchGame>> getGamesForMatch(String matchId) async { ... }
  Future<void> recordGameResult({...}) async { ... }
  Future<MatchGame> recordGame({...}) async { ... }
  Future<MatchGame> updateGame({...}) async { ... }
}
```

```dart
// services/tournament/tournament_bracket_service.dart
import 'package:uuid/uuid.dart';
import '../db/database.dart';
import '../models/tournament.dart';
import 'tournament_crud_service.dart';
import 'tournament_rounds_service.dart';
import 'tournament_matches_service.dart';

class TournamentBracketService {
  final Database _db;
  final TournamentCrudService _crudService;
  final TournamentRoundsService _roundsService;
  final TournamentMatchesService _matchesService;

  TournamentBracketService(
    this._db,
    this._crudService,
    this._roundsService,
    this._matchesService,
  );

  Future<List<TournamentMatch>> generateSingleEliminationBracket({...}) async {
    // Complex bracket generation using other services
    final rounds = await _roundsService.getRoundsForTournament(tournamentId);
    final match = await _matchesService.createMatch(...);
    await _crudService.updateTournamentStatus(tournamentId, TournamentStatus.inProgress);
    ...
  }

  List<String> _generateRoundNames(int numRounds, bool hasBronze) { ... }
}
```

**Step 3: Create barrel export at original location**

```dart
// services/tournament_service.dart
// Tournament Services - Barrel export
// Maintains existing import path for handlers and other consumers

export 'tournament/tournament_crud_service.dart';
export 'tournament/tournament_rounds_service.dart';
export 'tournament/tournament_matches_service.dart';
export 'tournament/tournament_bracket_service.dart';
```

**Step 4: Update router.dart DI**

```dart
// api/router.dart
import '../services/tournament_service.dart'; // Barrel export - all sub-services available

Router createRouter(Database db) {
  // ... other services ...

  final tournamentGroupService = TournamentGroupService(db);

  // Tournament sub-services
  final tournamentCrudService = TournamentCrudService(db);
  final tournamentRoundsService = TournamentRoundsService(db);
  final tournamentMatchesService = TournamentMatchesService(db);
  final tournamentBracketService = TournamentBracketService(
    db,
    tournamentCrudService,
    tournamentRoundsService,
    tournamentMatchesService,
  );

  // Handler receives all sub-services it needs
  final tournamentsHandler = TournamentsHandler(
    tournamentCrudService,
    tournamentRoundsService,
    tournamentMatchesService,
    tournamentBracketService,
    tournamentGroupService,
    teamService,
  );

  router.mount('/tournaments',
    const Pipeline().addMiddleware(auth).addHandler(tournamentsHandler.router.call).call);

  // ... rest of router ...
}
```

**Step 5: Update handler to accept sub-services**

```dart
// api/tournaments_handler.dart
import '../services/tournament_service.dart'; // Barrel import - unchanged

class TournamentsHandler {
  final TournamentCrudService _crudService;
  final TournamentRoundsService _roundsService;
  final TournamentMatchesService _matchesService;
  final TournamentBracketService _bracketService;
  final TournamentGroupService _groupService;
  final TeamService _teamService;

  TournamentsHandler(
    this._crudService,
    this._roundsService,
    this._matchesService,
    this._bracketService,
    this._groupService,
    this._teamService,
  );

  Router get router {
    final router = Router();

    router.post('/team/<teamId>', (Request request, String teamId) async {
      // Use specific sub-service
      final tournament = await _crudService.createTournament(...);
      final bracket = await _bracketService.generateSingleEliminationBracket(...);
      return resp.created(tournament.toJson());
    });

    return router;
  }
}
```

### Verification Checklist After Splitting

```bash
# 1. Verify imports unchanged outside services/
cd backend
grep -r "import.*tournament_service" lib/api/ lib/models/
# Should show: import '../services/tournament_service.dart'
# NOT: import '../services/tournament/tournament_crud_service.dart'

# 2. Verify all sub-services exported
grep "^export" lib/services/tournament_service.dart
# Should list all 4 sub-service files

# 3. Run static analysis
dart analyze
# Should show no new errors

# 4. Run tests (if any exist)
dart test
# Should all pass

# 5. Verify LOC reduction
wc -l lib/services/tournament/*.dart
# Each should be 150-350 LOC
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Monolithic services | Split services without barrel exports (Fase 9) | Jan 2025 | Router.dart imports individual services |
| Split services without exports | **Split services WITH barrel exports** (Phase 3) | Feb 2025 (this phase) | Handlers maintain single import, no breaking changes |
| Manual service wiring | Manual DI in router.dart | Current | Explicit, type-safe, ~40 services manageable |

**Deprecated/outdated:**
- **Service locator pattern:** Dart community moved to explicit dependency injection (more testable, easier to trace)
- **Inheritance-based service composition:** Replaced by composition (sub-services as dependencies)

## Open Questions

1. **Should handlers receive individual sub-services or an aggregator object?**
   - What we know: Fase 9 used individual services in handler constructors
   - What's unclear: Phase 3 requires barrel exports but doesn't specify handler signature pattern
   - Recommendation: Pass individual sub-services to handlers (more explicit, easier to test, clearer dependencies). Barrel export is for imports, not for runtime aggregation.

2. **How to handle shared utility methods between sub-services?**
   - What we know: Current services have shared private helper methods (e.g., `_generateRoundNames`)
   - What's unclear: Where do shared helpers go when service splits?
   - Recommendation: Keep truly private helpers in the service that uses them. Extract shared helpers to a separate `tournament_helpers.dart` file in the `tournament/` directory (not exported from barrel, used internally).

3. **Should existing tests (if any) be split along with services?**
   - What we know: Project has 25 backend tests, but service-level tests may not exist
   - What's unclear: Whether to split test files matching service splits
   - Recommendation: If service tests exist, split them to match service structure. If none exist, don't create new tests (out of scope for this phase). Verify existing tests still pass.

## Sources

### Primary (HIGH confidence)
- Dart Language Tour - Exports: https://dart.dev/language/libraries#exporting-libraries (official docs)
- Shelf framework docs: https://pub.dev/packages/shelf (project's HTTP framework)
- Core - Idrett codebase - Existing Fase 9 service splits: `backend/lib/services/achievement_*.dart`, `message_service.dart`, `statistics_service.dart`
- Core - Idrett codebase - Existing model barrel exports: `backend/lib/models/tournament.dart`, `achievement.dart`, `mini_activity.dart`

### Secondary (MEDIUM confidence)
- ROADMAP.md Phase 3 success criteria: "All split services use barrel exports maintaining existing import paths"
- router.dart current DI pattern: Manual instantiation with constructor injection for ~40 services

### Tertiary (LOW confidence)
- N/A - All findings verified from official Dart docs and existing codebase patterns

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using existing Dart language features and project dependencies
- Architecture: HIGH - Patterns verified in existing codebase (Fase 8 model barrel exports, Fase 9 service splits)
- Pitfalls: HIGH - Based on common Dart refactoring issues and project constraints (maintain imports)

**Research date:** 2026-02-09
**Valid until:** 60 days (Dart module system is stable, project patterns established)
