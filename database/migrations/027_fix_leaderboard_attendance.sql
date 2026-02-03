-- Migration: 027_fix_leaderboard_attendance.sql
-- Fix: Use v_user_attendance for real-time attendance calculation
-- instead of season_user_stats which has NULL join issues
--
-- Problem: The original view joined on sus.season_id = l.season_id
-- When season_id is NULL on both sides, NULL = NULL evaluates to FALSE in SQL
-- This caused attendance_rate to always be 0 for "Total" leaderboards

CREATE OR REPLACE VIEW v_leaderboard_ranked AS
SELECT
    le.leaderboard_id,
    l.team_id,
    l.season_id,
    l.category,
    le.user_id,
    u.name AS user_name,
    le.points,
    COALESCE(vua.attendance_rate, 0) AS attendance_rate,
    0 AS current_streak, -- Simplified: streak tracking moved to separate feature
    tm.leaderboard_opt_out,
    RANK() OVER (
        PARTITION BY le.leaderboard_id
        ORDER BY le.points DESC, COALESCE(vua.attendance_rate, 0) DESC
    ) AS rank
FROM leaderboard_entries le
JOIN leaderboards l ON l.id = le.leaderboard_id
JOIN users u ON u.id = le.user_id
LEFT JOIN team_members tm ON tm.user_id = le.user_id AND tm.team_id = l.team_id
LEFT JOIN v_user_attendance vua ON vua.user_id = le.user_id
    AND vua.team_id = l.team_id
WHERE tm.leaderboard_opt_out = FALSE OR tm.leaderboard_opt_out IS NULL;

-- Update comment
COMMENT ON VIEW v_leaderboard_ranked IS 'Leaderboard with ranking and real-time attendance from v_user_attendance';
