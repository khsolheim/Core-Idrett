-- Migration: 028_security_rls_and_views.sql
-- Fix Supabase Security Linter findings:
--   1. Convert SECURITY DEFINER views → SECURITY INVOKER
--   2. Enable RLS on all public tables (blocks anon/authenticated PostgREST access)
--   3. Add one anon SELECT policy for realtime on activity_responses
--   4. Document sensitive column protection on device_tokens
--
-- Safety: The backend uses service_role (bypasses RLS entirely).
--         Only the mobile app's realtime subscription needs anon access,
--         and only to activity_responses.

-- ============================================================
-- STEP 1: Fix SECURITY DEFINER views → SECURITY INVOKER
-- ============================================================
-- These views currently bypass the querying user's RLS policies.
-- Setting security_invoker = on makes them respect the caller's permissions.

ALTER VIEW v_absence_details          SET (security_invoker = on);
ALTER VIEW v_user_achievements_detail SET (security_invoker = on);
ALTER VIEW v_achievement_progress_detail SET (security_invoker = on);
ALTER VIEW v_user_attendance          SET (security_invoker = on);
ALTER VIEW v_leaderboard_ranked       SET (security_invoker = on);
ALTER VIEW v_monthly_trends           SET (security_invoker = on);
ALTER VIEW v_manual_point_adjustments SET (security_invoker = on);
ALTER VIEW v_player_win_rates         SET (security_invoker = on);

-- ============================================================
-- STEP 2: Enable RLS on ALL public tables
-- ============================================================
-- ALTER TABLE ... ENABLE ROW LEVEL SECURITY is idempotent.
-- With no policies, this blocks all anon/authenticated access via PostgREST.
-- The backend (service_role) is unaffected.

-- Core
ALTER TABLE users                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members              ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_settings             ENABLE ROW LEVEL SECURITY;

-- Activities
ALTER TABLE activities                ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_instances        ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_responses        ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_templates        ENABLE ROW LEVEL SECURITY;

-- Mini-activities
ALTER TABLE mini_activities           ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_teams       ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_adjustments ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_handicaps   ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_point_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_player_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_head_to_head ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_team_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE mini_activity_fine_rules  ENABLE ROW LEVEL SECURITY;

-- Fines
ALTER TABLE fine_rules                ENABLE ROW LEVEL SECURITY;
ALTER TABLE fines                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE fine_appeals              ENABLE ROW LEVEL SECURITY;
ALTER TABLE fine_payments             ENABLE ROW LEVEL SECURITY;

-- Statistics & Leaderboards
ALTER TABLE match_stats               ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_ratings            ENABLE ROW LEVEL SECURITY;
ALTER TABLE season_stats              ENABLE ROW LEVEL SECURITY;
ALTER TABLE seasons                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboards              ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_entries       ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_point_sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE monthly_user_stats        ENABLE ROW LEVEL SECURITY;
ALTER TABLE season_user_stats         ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_points         ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_points_config        ENABLE ROW LEVEL SECURITY;
ALTER TABLE manual_point_adjustments  ENABLE ROW LEVEL SECURITY;

-- Chat
ALTER TABLE messages                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reads             ENABLE ROW LEVEL SECURITY;

-- Notifications
ALTER TABLE device_tokens             ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences  ENABLE ROW LEVEL SECURITY;

-- Tests & Templates
ALTER TABLE trainer_types             ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_templates            ENABLE ROW LEVEL SECURITY;
ALTER TABLE test_results              ENABLE ROW LEVEL SECURITY;

-- Absence
ALTER TABLE absence_categories        ENABLE ROW LEVEL SECURITY;
ALTER TABLE absence_records           ENABLE ROW LEVEL SECURITY;

-- Achievements
ALTER TABLE achievement_definitions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements         ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievement_progress      ENABLE ROW LEVEL SECURITY;

-- Documents & Export
ALTER TABLE documents                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE export_logs               ENABLE ROW LEVEL SECURITY;

-- Tournaments
ALTER TABLE tournaments               ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_rounds         ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_matches        ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_games               ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_groups         ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_standings           ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_matches             ENABLE ROW LEVEL SECURITY;
ALTER TABLE qualification_rounds      ENABLE ROW LEVEL SECURITY;
ALTER TABLE qualification_results     ENABLE ROW LEVEL SECURITY;

-- Match Recording
ALTER TABLE match_periods             ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_events              ENABLE ROW LEVEL SECURITY;

-- Stopwatch
ALTER TABLE stopwatch_sessions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE stopwatch_times           ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- STEP 3: Anon SELECT policy for realtime on activity_responses
-- ============================================================
-- The mobile app uses the anon key to subscribe to realtime changes
-- on activity_responses (app/lib/core/services/supabase_service.dart:50-61).
-- It only uses the event as a signal to re-fetch via the backend —
-- the payload data (user_id, response, comment) is low-sensitivity.

DROP POLICY IF EXISTS "anon_select_activity_responses" ON activity_responses;
CREATE POLICY "anon_select_activity_responses"
  ON activity_responses
  FOR SELECT
  TO anon
  USING (true);

-- ============================================================
-- STEP 4: Document sensitive column protection
-- ============================================================
-- device_tokens.token is now protected by RLS (no policies = no anon access).

COMMENT ON TABLE device_tokens IS
  'Push notification device tokens. RLS-protected — no anon/authenticated access policies. Only accessible via service_role (backend).';

COMMENT ON COLUMN device_tokens.token IS
  'FCM/APNs device token. Sensitive — protected by RLS with no public access policies.';
