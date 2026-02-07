# Refactoring Plan — Fase 14-22

## Overview
Phases 1-13 covered structural cleanup (splitting, dedup, patterns).
Phases 14-22 cover **quality, performance, and architecture** improvements.

Each phase is designed for one session (~8-15 files), independent of other phases unless noted.

---

## Fase 14: Backend Auth & Error Response Consistency
**Priority: HIGH (Security)**
**Files: ~15 handler files**
**Status: DONE** (commit ae455c4)

### Problem
1. 60+ places use `resp.forbidden('Ikke autorisert')` when `userId == null` — should be `resp.unauthorized()` (HTTP 401, not 403)
2. 30+ handlers leak exception details to clients via `resp.serverError('...: $e')` — security risk

### Changes
- All handler files in `backend/lib/api/`: Replace `resp.forbidden('Ikke autorisert')` with `resp.unauthorized()` when checking `getUserId(request) == null`
- All handler catch blocks: Replace `resp.serverError('message: $e')` with `resp.serverError('message')` (remove `$e`)

### Affected Files
- `fines_handler.dart` (15 occurrences)
- `tournament_matches_handler.dart` (9)
- `tournament_groups_handler.dart` (14)
- `achievement_awards_handler.dart` (7)
- `achievements_handler.dart` (5)
- `tournament_rounds_handler.dart` (3)
- `statistics_handler.dart` (5)
- `tournaments_handler.dart` (6)
- `test_results_handler.dart` (7 error leaks)
- `points_config_handler.dart` (9 error leaks)
- `leaderboard_entries_handler.dart` (4 error leaks)
- All other handlers for error message cleanup

### Verification
```bash
cd backend && dart analyze
# Grep to verify no remaining patterns:
grep -r "forbidden('Ikke autorisert')" lib/api/
grep -rn "serverError.*\$e" lib/api/
```

---

## Fase 15: Backend Input Validation & Type Safety
**Priority: HIGH (Crash prevention)**
**Files: ~12 files**
**Status: DONE** (commit 225b5de)

### Problem
1. 12+ unsafe `body['key'] as Type` casts without null checks — crash on missing fields
2. 4 `DateTime.parse()` calls without try-catch — crash on malformed dates
3. 15+ unsafe `.first` calls on lists — crash on empty results

### Changes

#### A. Unsafe body casts → add null checks + badRequest responses
- `leaderboard_entries_handler.dart:120,133` — `body['user_id'] as String` without null check
- `points_config_handler.dart:306-309` — 4 unsafe casts (`user_id`, `activity_type`, `base_points`, `weighted_points`)
- `fines_handler.dart:81,176,312` — `body['amount'] as num` without null check
- `team_settings_handler.dart:142-143` — unsafe `.toDouble()` on nullable num

#### B. DateTime.parse() → wrap in try-catch
- `activities_handler.dart:94` — `recurrence_end_date` parse
- `activities_handler.dart:149-150` — `from` and `to` query params
- `activity_instances_handler.dart` — date parsing if present

#### C. Unsafe .first → use firstOrNull or isEmpty check
- `achievement_progress_service.dart:72,79,244,249`
- `mini_activity_statistics_service.dart:36,201,425,519`
- `points_config_service.dart:49,61,246,394`

### Verification
```bash
cd backend && dart analyze
grep -rn "\.first[^O]" lib/services/ | grep -v "isEmpty"
```

---

## Fase 16: Backend N+1 Query Fixes
**Priority: HIGH (Performance)**
**Files: ~6 service files**
**Status: DONE** (commit 8201190)

### Problem
1. `mini_activity_service.dart:462-489` — getHistory() loops N queries for teams (50 items = 51 queries)
2. `message_service.dart:237-240` — getConversations() fetches ALL messages then filters in memory
3. `activity_service.dart:506-530` — double query for same response data
4. `leaderboard_service.dart:570-596` — syncTotalLeaderboard O(n*m) queries per user
5. `mini_activity_result_service.dart:100-142` — 4 sequential queries for one teamId lookup

### Changes

#### A. mini_activity_service.dart — Batch fetch teams
```dart
// Instead of: for each mini_activity -> query teams
// Do: collect all IDs, single query, group in memory
final allMaIds = miniActivities.map((m) => m['id'] as String).toList();
final allTeams = await _db.client.select('mini_activity_teams',
  filters: {'mini_activity_id': 'in.(${allMaIds.join(',')})'});
final teamsByMa = groupBy(allTeams, (t) => t['mini_activity_id']);
```

#### B. message_service.dart — Add DB-level filtering
- Add `user_id` or `team_id` filter to getConversations() query
- Remove in-memory filtering

#### C. activity_service.dart — Merge double response query
- Fetch all responses once, filter user's responses in memory

#### D. leaderboard_service.dart — Batch category lookups
- Fetch all category entries for all users at once, then distribute

#### E. mini_activity_result_service.dart — Reduce 4-query chain
- Use single query with select/join or cache teamId

### Verification
```bash
cd backend && dart analyze && dart test
```

---

## Fase 17: Backend Service Boundaries
**Priority: MEDIUM (Architecture)**
**Files: ~8-10 files**
**Status: DONE** (commit f54cbcc)

### Problem
1. `TeamService.getDashboardData()` is 150+ lines aggregating 4 unrelated concerns
2. `LeaderboardService` mostly wraps `LeaderboardEntryService` — unnecessary indirection
3. No shared pagination or counting utilities
4. Inconsistent auth patterns across handlers

### Changes

#### A. Extract DashboardService
- Move `getDashboardData()` from `team_service.dart` to new `dashboard_service.dart`
- Inject as dependency in `teams_handler.dart`
- Update `router.dart` DI

#### B. Simplify LeaderboardService
- Evaluate which methods are pure forwarding
- Either merge into LeaderboardEntryService or keep as facade with clear purpose

#### C. Extract shared utilities
- `PaginationHelper` or add limit/offset params consistently
- `groupByCount()` utility for the repeated counting pattern

#### D. Standardize auth check pattern
- Document when to use `requireTeamMember()` vs service-level null return
- Make consistent across all handlers

### Verification
```bash
cd backend && dart analyze && dart test
```

---

## Fase 18: Frontend Error Handling
**Priority: HIGH (User experience)**
**Files: ~8-10 files**
**Status: DONE** (commit ae455c4)

### Problem
1. Chat provider silently swallows errors (4 catch blocks return false/nothing)
2. Auth provider loses stack traces, swallows login errors
3. Mutation notifiers return null/false on error without UI feedback
4. Screens show raw exception.toString() instead of user-friendly messages

### Changes

#### A. Chat provider — proper error state
- `chat_provider.dart:67-69,84-86,104-106,150-155` — Update state to AsyncError on failure
- Add error feedback via errorDisplayService

#### B. Auth provider — preserve stack traces
- `auth_provider.dart:67` — Change `catch (e)` to `catch (e, st)` and use `AsyncError(e, st)`

#### C. Mutation feedback pattern
- Standardize: mutations should either update state to AsyncError OR call errorDisplayService
- Apply to: `activity_mutation_notifier.dart`, `fine_operations_notifier.dart`, `mini_activity_results_notifier.dart`

#### D. User-friendly error messages
- Replace `SnackBar(content: Text('Kunne ikke lagre: $e'))` with proper error handler
- Use `ref.read(errorDisplayServiceProvider).showError()` pattern from CLAUDE.md

### Verification
```bash
cd app && flutter analyze
```

---

## Fase 19: Frontend Navigation Consistency
**Priority: MEDIUM (Maintainability)**
**Files: ~15 files**
**Status: DONE** (commit 225b5de)

### Problem
1. Mixed use of `context.pushNamed()` (named routes) vs `context.push('/path')` (path-based)
2. Route paths are string-interpolated throughout — typo risk, no compile-time safety
3. Route parameters extracted with `!` operator without validation

### Changes

#### A. Create route constants file
- New file: `app/lib/core/router/route_names.dart`
- Define all route names and path builders as static constants

#### B. Standardize on named routes
- Convert all `context.push('/teams/$teamId/...')` to `context.pushNamed('name', pathParameters: {...})`
- Apply across all screens

#### C. Route parameter validation
- Add null-safety to route parameter extraction in `router.dart`

### Verification
```bash
cd app && flutter analyze
grep -rn "context.push('/" lib/features/
```

---

## Fase 20: Frontend Provider Optimization
**Priority: MEDIUM (Performance)**
**Files: ~10-12 files**
**Status: DONE** (commit 8201190)

### Problem
1. Widgets watch entire providers when only needing one field (e.g., `isAdmin`)
2. Mutation providers both update state AND return values — inconsistent
3. 347 `ref.invalidate()` calls with no clear strategy

### Changes

#### A. Add .select() for single-field watches
```dart
// Before:
final teamAsync = ref.watch(teamDetailProvider(teamId));
final isAdmin = teamAsync.value?.userIsAdmin ?? false;

// After:
final isAdmin = ref.watch(
  teamDetailProvider(teamId).select((t) => t.valueOrNull?.userIsAdmin ?? false)
);
```
- Apply to: `activities_screen.dart`, `activity_detail_screen.dart`, `team_detail_screen.dart`, `chat_screen.dart`

#### B. Standardize mutation notifier pattern
- Choose: Either update state OR return value, not both
- Document chosen pattern in CLAUDE.md

#### C. Document invalidation strategy
- Group related invalidations into helper methods on notifiers
- Reduce duplicated invalidation lists

### Verification
```bash
cd app && flutter analyze
```

---

## Fase 21: Frontend Widget Extraction (Round 2)
**Priority: MEDIUM (Maintainability)**
**Files: ~10 files**
**Status: DONE** (commit f54cbcc)

### Problem
6 screens still 450+ lines with large build methods:
1. `points_config_screen.dart` — 486 lines, 300+ line build method, 7 TextEditingControllers
2. `create_edit_achievement_sheet.dart` — 486 lines
3. `documents_screen.dart` — 480 lines
4. `edit_instance_screen.dart` — 479 lines
5. `achievement_admin_screen.dart` — 477 lines

### Changes
- Extract form sections into sub-widgets
- Extract dialog functions into separate files
- Move controllers/state into providers where appropriate

### Verification
```bash
cd app && flutter analyze
```

---

## Fase 22: Frontend Performance & Image Caching
**Priority: MEDIUM (Performance/UX)**
**Files: ~10-15 files**
**Status: DONE** (commit f54cbcc)

### Problem
1. 25+ files use `NetworkImage` without error handling or caching
2. ListView.builder without keys — inefficient rebuilds
3. Chat screen rebuilds entire message list on any change
4. Widget state in ChatScreen/PointsConfigScreen should be in providers

### Changes

#### A. Add cached_network_image package
- Add `cached_network_image` to pubspec.yaml
- Replace `NetworkImage(url)` with `CachedNetworkImageProvider(url)` across:
  - `message_widgets.dart`, `mini_activity_team_card.dart`, `add_participant_sheet.dart`
  - `leaderboard_widgets.dart`, `profile_screen.dart`, `team_division_sheet.dart`
  - All other avatar usages

#### B. Add ValueKey to dynamic lists
- `chat_screen.dart` — Add `key: ValueKey(message.id)` to message items
- Activity lists, leaderboard items, team member lists

#### C. Move ChatScreen widget state to provider
- `_replyingTo`, `_editingMessage` → chat provider state
- Enables persistence across navigation

### Verification
```bash
cd app && flutter pub get && flutter analyze
```

---

## Execution Strategy

### Priority Order
1. **Fase 14** — Auth & error consistency (security, quick wins)
2. **Fase 15** — Input validation (crash prevention)
3. **Fase 16** — N+1 queries (performance, backend)
4. **Fase 18** — Frontend error handling (UX)
5. **Fase 17** — Service boundaries (architecture)
6. **Fase 20** — Provider optimization (performance)
7. **Fase 19** — Navigation consistency (maintainability)
8. **Fase 21** — Widget extraction round 2 (maintainability)
9. **Fase 22** — Image caching & performance (polish)

### Session Pattern
Each session:
1. Read this plan → pick next TODO phase
2. Execute with sub-agents where possible
3. Run `dart analyze` / `flutter analyze`
4. Commit & push
5. Mark phase as DONE in this document

### Parallelization
These phases can run in parallel within a session:
- Fase 14 + Fase 18 (backend auth + frontend errors)
- Fase 15 + Fase 19 (backend validation + frontend navigation)
- Fase 16 + Fase 20 (backend queries + frontend providers)
- Fase 21 + Fase 22 (frontend widget + frontend performance)
