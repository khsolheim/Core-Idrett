# Codebase Concerns

**Analysis Date:** 2026-02-08

## Tech Debt

**Large Service Files (800+ LOC):**
- Issue: Multiple service files have exceeded maintainability thresholds
- Files:
  - `backend/lib/services/tournament_service.dart` (757 LOC)
  - `backend/lib/services/leaderboard_service.dart` (701 LOC)
  - `backend/lib/services/fine_service.dart` (614 LOC)
  - `backend/lib/services/activity_service.dart` (576 LOC)
  - `backend/lib/services/export_service.dart` (540 LOC)
- Impact: Difficult to test, reuse, and maintain. Single responsibility principle violated
- Fix approach: Continue pattern from Fase 3-9 — split by logical domain (e.g., tournament_service → tournament_crud_service, tournament_generation_service)

**Large Widget/Screen Files (400+ LOC):**
- Issue: Presentation layer files difficult to reason about and test
- Files:
  - `app/lib/features/chat/presentation/widgets/message_widgets.dart` (482 LOC)
  - `app/lib/features/tests/presentation/test_detail_screen.dart` (476 LOC)
  - `app/lib/features/export/presentation/export_screen.dart` (470 LOC)
  - `app/lib/features/activities/presentation/activity_detail_screen.dart` (456 LOC)
  - `app/lib/features/mini_activities/presentation/widgets/mini_activity_detail_content.dart` (436 LOC)
  - `app/lib/features/mini_activities/presentation/widgets/stats_widgets.dart` (429 LOC)
  - `app/lib/features/teams/presentation/widgets/edit_team_members_tab.dart` (423 LOC)
  - `app/lib/features/teams/presentation/widgets/dashboard_info_widgets.dart` (420 LOC)
- Impact: Hard to test in isolation; widget reusability limited
- Fix approach: Extract sub-widgets following pattern from Fase 21 (5 screens already split, 9 new widget files created). Extract list items, cards, detail sections into separate stateless widgets

**Casting Without Null Checks:**
- Issue: Multiple database query results use unsafe `as String` casts without pre-validation
- Files: `backend/lib/services/tournament_service.dart`, `backend/lib/services/achievement_definition_service.dart`, `backend/lib/services/test_service.dart`
- Example: `return result.first['team_id'] as String?;` — `.first` throws on empty list
- Impact: Runtime crashes if queries return unexpected structure
- Fix approach: Add existence checks before `.first`; use `.firstOrNull` where available in Dart 3.0+. Validate database schema matches code expectations

**Unvalidated Type Casts Throughout Backend:**
- Issue: Widespread use of `as String`, `as int`, `as Map` without null-coalescing or error handling
- Count: 20+ direct casts in service layer
- Example locations:
  - `backend/lib/services/team_service.dart` — multiple `as String` casts
  - `backend/lib/services/player_rating_service.dart` — map casting without validation
- Impact: Brittle to schema changes; crashes instead of graceful errors
- Fix approach: Create `cast<T>(value, fieldName)` helper in `backend/lib/db/` that throws `BadRequestException` on type mismatch. Replace all unsafe casts

## Known Bugs

**Firebase Messaging Token Registration Silently Fails:**
- Symptoms: Token registration errors are caught and silently ignored
- Files: `app/lib/features/notifications/providers/notification_provider.dart` (line 60-62)
- Code: `catch (e) { // Token registration failed - will retry on next app start }`
- Trigger: Offline or API failure during `_registerToken()`
- Workaround: App restart will retry. Log visible in Firebase console if token not synced.
- Problem: No retry logic exists; "retry on next app start" is unreliable if app auto-starts background services
- Fix approach: Implement exponential backoff in token registration; log failures for debugging

**Unsubscribe Race Condition in Realtime:**
- Symptoms: Potential memory leak or stale callbacks if provider disposes before channel unsubscribe completes
- Files: `app/lib/features/activities/providers/activity_instance_notifier.dart` (lines 109-115)
- Code: `ref.onDispose(() { ... supabaseService.unsubscribe(channel); });`
- Issue: `unsubscribe()` is async but not awaited; disposal continues immediately
- Impact: Channel may still be active after provider disposed, holding memory/listeners
- Fix approach: Use `ref.onDispose.addCallback()` if async support exists, or ensure unsubscribe is synchronous. Test with profiler for leaked listeners

**Foreground FCM Message Handler Does Nothing:**
- Symptoms: Push notifications while app in foreground are not displayed
- Files: `app/lib/features/notifications/providers/notification_provider.dart` (lines 65-73)
- Code: `void _handleForegroundMessage(RemoteMessage message) { ... // Could trigger... }`
- Impact: Users miss notifications that arrive while app is active. Comments indicate feature was planned but not implemented
- Fix approach: Implement local notification display or in-app banner for foreground messages. Use `flutter_local_notifications` package

**Export Screen Pagination Hardcoded:**
- Symptoms: Export history shows hardcoded `.take(10)` without pagination controls
- Files: `app/lib/features/export/presentation/export_screen.dart` (line 92)
- Code: `itemCount: history.take(10).length,`
- Impact: Users with 10+ exports cannot see older exports in UI
- Fix approach: Add pagination with limit/offset parameters; show page controls or "Load more" button

## Security Considerations

**Admin Role Check Uses Backwards Compatibility Fallback:**
- Risk: Dual check for `user_is_admin` OR `user_role == 'admin'` could allow privilege escalation if flag gets out of sync with role
- Files: `backend/lib/api/helpers/auth_helpers.dart` (line 20)
- Code: `return team['user_is_admin'] == true || team['user_role'] == 'admin';`
- Current mitigation: Schema enforces consistency, but dual-check pattern is fragile
- Recommendations:
  - Document in CLAUDE.md why dual check exists (migration artifact?)
  - Add validation query: audit `team_members` for mismatched `(user_is_admin, role)` pairs
  - Plan deprecation timeline for `user_is_admin` field
  - Add integration test that verifies consistency

**Missing Fine_Boss Permission Checks:**
- Risk: Some handlers accept fine modifications but only check `isAdmin()`; fine_boss role cannot be validated
- Files: `backend/lib/api/` handlers for fines (need audit)
- Current mitigation: Database role-based access control (RBAC) in Supabase, but application layer should also validate
- Recommendations:
  - Add `isFineAdmin(Map<String, dynamic> team)` helper that checks both admin and fine_boss
  - Apply to all fine mutation endpoints
  - Add audit log for fine changes to `fine_logs` table

**FCM Token Stored Without Device Fingerprint:**
- Risk: Stolen FCM tokens could impersonate user for push notifications
- Files: `app/lib/features/notifications/providers/notification_provider.dart` + backend token storage
- Current mitigation: Token expires periodically (Firebase standard)
- Recommendations:
  - Store device identifier (UUID) alongside token
  - Validate token against stored device on notification receipt
  - Add token rotation policy (30-day max lifetime)
  - Implement token binding to app instance (prevent sideload attacks)

**Export Data Has No Rate Limiting:**
- Risk: Malicious admin could repeatedly export full team data, overwhelming database
- Files: `backend/lib/api/exports_handler.dart`, `backend/lib/services/export_service.dart`
- Impact: Denial of service for other users; no audit of data exports
- Recommendations:
  - Implement rate limiting (1 export per user per 5 minutes)
  - Add to `export_logs` table: who exported, when, what type
  - Alert team admins if unusual export patterns detected (>5 in 1 hour)
  - Require explicit confirmation for large exports (1000+ records)

**Integer Overflow in Scoring Systems:**
- Risk: Leaderboard points and fine amounts stored as integers without bounds
- Files: Database schema (`database/migrations/`) — check point column types
- Potential issue: Accumulative point systems could overflow (Dart `int` is 64-bit, but database may be 32-bit)
- Recommendations:
  - Validate in database: `CONSTRAINT points_range CHECK (points >= -999999 AND points <= 999999)`
  - Add input validation in `backend/lib/api/helpers/validation_helpers.dart` for point mutations
  - Test with fuzz input: extremely large point values

**Realtime Subscriptions Not Filtered by User Role:**
- Risk: Subscription to `activity_responses` table updates sends all changes to all subscribers in team
- Files: `app/lib/core/services/supabase_service.dart` (lines 44-64)
- Issue: Supabase Row-Level Security (RLS) not explicitly mentioned; if RLS is off, all users see all responses
- Current mitigation: Frontend only subscribes for teams user is member of (application-layer)
- Recommendations:
  - Verify Supabase RLS policies are ENABLED for `activity_responses` table
  - Test with non-member account trying to subscribe
  - Document that realtime requires RLS; add startup check in `supabase_service.dart`

## Performance Bottlenecks

**Leaderboard Query N+1 Pattern (Partially Fixed):**
- Problem: Computing leaderboards for multiple categories may batch-fetch users but still inefficient
- Files: `backend/lib/services/leaderboard_service.dart` (701 LOC)
- Status: Fase 16 reduced N+1 but worth auditing post-fix
- Cause: Category leaderboards iterate over entries, each entry may fetch user/team data separately
- Improvement path:
  - Profile with `EXPLAIN ANALYZE` on: `SELECT ... FROM leaderboard_entries WHERE leaderboard_id IN (...)`
  - Ensure indexes on `(leaderboard_id, points)` for sort
  - Batch-fetch user data once, pass as map to entry builders
  - Cache category leaderboard list for 5 minutes (rarely changes)

**Tournament Bracket Generation Not Cached:**
- Problem: Large tournaments (50+ participants) regenerate bracket structure on every fetch
- Files: `backend/lib/services/tournament_service.dart`
- Cause: No caching layer; bracket computed from rules each request
- Impact: Slow responses for tournament view screens; blocking UI
- Improvement path:
  - Store computed bracket structure in `tournaments.bracket_json` (computed once at setup)
  - Regenerate only on config changes (seeding, participant add/remove)
  - Add `cache_key` to tournament and increment on changes

**Message Thread Loading Unbounded:**
- Problem: Loading all messages in a conversation without pagination
- Files: `backend/lib/services/message_service.dart` — check conversation loading
- Impact: Large conversations (1000+ messages) load entire history into memory
- Improvement path:
  - Implement cursor-based pagination (load 50 messages, get cursor for older)
  - Frontend loads incrementally as user scrolls up
  - Cache latest 100 messages in memory; fetch older on demand

**Statistics Queries Full Table Scan:**
- Problem: `statistics_service.dart` may compute stats without table-level filters
- Files: `backend/lib/services/statistics_service.dart` (447 LOC)
- Impact: Scales poorly as team grows; blocks activity during reporting
- Improvement path:
  - Add indexes: `(team_id, created_at)` on activity and response tables
  - Implement date range filtering (default last 30 days for leaderboards)
  - Use database views for common queries (attendance %, top scorer)

**Image Caching Enabled But No Cache Invalidation:**
- Problem: `cached_network_image` caches indefinitely (Fase 22 added it, but no invalidation)
- Files: 37 replacements in `app/lib/` (from MEMORY.md)
- Impact: User/team avatars don't update until app restart or manual cache clear
- Improvement path:
  - Add `CacheKey` to image URLs that includes timestamp or version
  - Example: `${url}?v=${user.updatedAt.millisecondsSinceEpoch}`
  - Call `imageCache.clear()` on profile update event

## Fragile Areas

**Mini-Activity Statistics Computation:**
- Files: `backend/lib/services/mini_activity_statistics_service.dart` (533 LOC), `backend/lib/services/mini_activity_result_service.dart` (419 LOC)
- Why fragile:
  - Complex aggregation logic across multiple mini-activity types (game, drill, stopwatch)
  - Points calculation varies by type; easy to miss edge cases
  - Division/handicap system adds conditional logic branches
  - Sorting and ranking logic prone to off-by-one errors
- Safe modification:
  - Add test for each mini-activity type with 10+ scenarios
  - Test ranking with ties, zero scores, negative scores
  - Verify before/after totals with database audits
- Test coverage: Likely incomplete for edge cases
- Recommendations:
  - Extract `PointsCalculator` interface with type-specific implementations
  - Unit test each calculator independently
  - Add snapshot tests for ranking output

**Activity Instance State Transitions:**
- Files: `backend/lib/services/activity_instance_service.dart` (485 LOC), `backend/lib/api/activity_instances_handler.dart`
- Why fragile:
  - Instance statuses (pending → active → done → cancelled) have complex rules
  - Cancellation prevents attendance point awards; must happen atomically
  - Recurring activities create instances; off-by-one on date math causes issues
- Safe modification:
  - State machine test: verify all valid transitions (diagram in test file)
  - Test recurring schedule with timezones (UTC vs local)
  - Verify cancelled instances don't create responses
- Test coverage: Limited for recurring schedule edge cases

**Tournament Match Resolution:**
- Files: `backend/lib/services/tournament_service.dart` (tournament bracket generation), `backend/lib/api/tournament_matches_handler.dart`
- Why fragile:
  - Bracket structure sensitive to participant count (powers of 2, byes)
  - Match seeding affects results fairness
  - Advancing winners/losers to next round has off-by-one risks
  - Bronze final logic branches
- Safe modification:
  - Implement round-robin validation: each round's matches must use round.previous outputs
  - Test all bracket types: single elim, double elim, round-robin with 3, 4, 8, 16 participants
  - Verify loser progression in double-elim (no participant lost before semifinals)
- Test coverage: Incomplete for double-elimination edge cases

**Fine Payment & Rules Interaction:**
- Files: `backend/lib/services/fine_service.dart` (614 LOC)
- Why fragile:
  - Rules can be retroactively created (apply to past violations)
  - Payment clearing must prevent double-payment
  - Team accounting (balance) relies on transaction ordering
- Safe modification:
  - Payment reconciliation test: force payment twice, verify idempotency
  - Rules retroactivity test: create rule, verify past violations caught
  - Audit test: sum(payments) + unpaid amount == total assessed
- Test coverage: Need integration tests linking fine creation → payment → balance

**Firebase Token Management:**
- Files: `app/lib/features/notifications/providers/notification_provider.dart`
- Why fragile:
  - Silent failure on token registration (line 60-62)
  - No persistent storage of last-known-good token
  - `_initialized` flag prevents re-initialization even if failed
- Safe modification:
  - Add persistent state: last token, last sync timestamp
  - Retry logic: check if token changed/expired on each app resume
  - Add error logging to console for debugging

## Scaling Limits

**Leaderboard Database Growth:**
- Current capacity: Works for ~1000 entries per leaderboard
- Limit: Sorts become slow beyond 10,000 entries per leaderboard (single-season scale)
- Scaling path:
  - Add time-based partitioning: `leaderboard_entries_season_Y` tables
  - Implement archival: move old season leaderboards to read-only
  - Denormalize: pre-compute monthly summaries, only show current month by default

**Real-time Subscriber Count:**
- Current capacity: ~100 concurrent subscriptions per team (Supabase default)
- Limit: Broadcast amplification with large teams (1000 members all subscribe to activity_responses)
- Scaling path:
  - Implement lazy subscription: subscribe only when viewing activity screen
  - Use presence channels to track viewing users (prevent redundant updates)
  - Batch updates: debounce to 1 update per second (current: 500ms)

**File Storage (Documents Feature):**
- Current capacity: Depends on Supabase storage limits (likely 10GB+ free tier)
- Limit: No per-team or per-user quota; runaway uploads possible
- Scaling path:
  - Implement quota: `team_documents.total_size_mb` with trigger
  - Add cleanup: auto-delete documents older than 1 year
  - Implement approval workflow: admin reviews large uploads

**Message History Unbounded Growth:**
- Current capacity: ~100k messages per team before UI lags on load
- Limit: Full conversation load time becomes unacceptable beyond 50k messages
- Scaling path:
  - Archive old conversations (older than 6 months) to separate table
  - Implement cursor-based pagination (50 messages per fetch)
  - Add search index on `messages.content` for full-text search

## Dependencies at Risk

**Firebase Messaging Plugin:**
- Risk: Package requires native setup (iOS entitlements, Android service); breaks easily on Flutter/Dart SDK updates
- Impact: Push notifications fail if plugin out of sync with Firebase SDK version
- Migration plan:
  - Consider OneSignal (more stable plugin, better analytics)
  - Or implement via webhook + server-side FCM (less dependency on client plugin)

**SharePlus Package (Deprecated Warnings):**
- Risk: CLAUDE.md notes "use_build_context_synchronously" warning from SharePlus
- Impact: Build warning noise; may break on future Flutter versions
- Migration plan:
  - Check if new version of share_plus resolves warning
  - Consider native implementation for export sharing

**Supabase Flutter SDK:**
- Risk: Realtime requires specific SDK version alignment; breaking changes between versions
- Current: No version constraint visible in this context
- Impact: Realtime subscriptions fail silently on version mismatch
- Recommendations:
  - Pin Supabase SDK version in `pubspec.yaml` with comment explaining why
  - Test realtime on every SDK update before releasing

## Missing Critical Features

**Export Data Lacks Encryption:**
- Problem: Exported files (CSV/JSON) sent plaintext to device share sheet; no encryption
- Blocks: Compliance with GDPR (if EU users); data protection requirements
- Fix approach:
  - Implement client-side AES encryption before export
  - Send encrypted file + separate password sheet
  - Add password-protected ZIP export option

**Audit Logging Incomplete:**
- Problem: No comprehensive audit trail for sensitive operations (fine changes, role changes, exports)
- Blocks: Forensic investigation of data access; compliance audits
- Fix approach:
  - Create `audit_logs` table: `(user_id, action, resource, old_value, new_value, created_at)`
  - Log on fine mutations, role changes, exports, message deletes, document access
  - Add admin-only audit view; export audit logs monthly

**Offline Support Non-Existent:**
- Problem: App requires internet connection; no offline queue or cached data
- Blocks: Usage in areas with poor connectivity
- Fix approach:
  - Implement `drift` (SQL-based local cache)
  - Queue mutations (responses, fine reports) offline; sync on reconnect
  - Show sync status indicator

**Input Rate Limiting Missing:**
- Problem: No protection against spam (e.g., 1000 messages in 1 second)
- Blocks: Defense against abuse; system stability
- Fix approach:
  - Backend: Rate limit per user per endpoint (e.g., 10 messages/minute)
  - Frontend: Disable buttons during request; show "please wait" state

## Test Coverage Gaps

**Export Feature Untested:**
- What's not tested: Export generation for all 7 types; file format validation; large data export performance
- Files: `app/lib/features/export/presentation/export_screen.dart`, `backend/lib/services/export_service.dart`
- Risk: Export could silently corrupt data, omit records, or crash
- Priority: HIGH — users rely on export for data backup

**Tournament Bracket Generation Untested:**
- What's not tested: All bracket types (single-elim, double-elim, round-robin) with edge cases (3, 5, 7 participants, etc.)
- Files: `backend/lib/services/tournament_service.dart`
- Risk: Unfair bracket seeding; matches missing; silent failures
- Priority: HIGH — affects competition fairness

**Fine Payment Reconciliation Untested:**
- What's not tested: Payment idempotency; retroactive rule application; balance calculations
- Files: `backend/lib/services/fine_service.dart`
- Risk: Double-charging; incorrect team balance; lost payments
- Priority: HIGH — financial system

**Chat Realtime Integration Untested:**
- What's not tested: Message delivery with realtime; undelivered message queue; offline fallback
- Files: `app/lib/features/chat/`, realtime subscription logic
- Risk: Messages lost; duplicates; missed notifications
- Priority: MEDIUM — critical for user engagement

**Statistics Calculation Untested for Edge Cases:**
- What's not tested: Zero attendance; all-zero scores; users with no activities; season boundaries
- Files: `backend/lib/services/leaderboard_service.dart`, `backend/lib/services/statistics_service.dart`
- Risk: Division by zero; NULL handling errors; incorrect rankings
- Priority: MEDIUM

**Notification Delivery Untested:**
- What's not tested: FCM token lifecycle; token refresh; failed token registration recovery
- Files: `app/lib/features/notifications/`
- Risk: Users don't receive notifications; token leaks; orphaned subscriptions
- Priority: MEDIUM

---

*Concerns audit: 2026-02-08*
