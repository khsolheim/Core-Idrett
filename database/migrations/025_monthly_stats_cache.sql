-- Monthly Statistics Cache
-- Migration: 025_monthly_stats_cache
-- Cached statistics per user per month for faster leaderboard queries

-- ============================================
-- MONTHLY USER STATS
-- ============================================

-- Cached monthly statistics per user
CREATE TABLE monthly_user_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    season_id UUID REFERENCES seasons(id) ON DELETE SET NULL,

    -- Attendance counts by type
    training_attended INTEGER DEFAULT 0,
    training_possible INTEGER DEFAULT 0,
    match_attended INTEGER DEFAULT 0,
    match_possible INTEGER DEFAULT 0,
    social_attended INTEGER DEFAULT 0,
    social_possible INTEGER DEFAULT 0,

    -- Valid absences (excluded from percentage)
    valid_absences INTEGER DEFAULT 0,

    -- Points breakdown
    attendance_points INTEGER DEFAULT 0,
    competition_points INTEGER DEFAULT 0,
    bonus_points INTEGER DEFAULT 0,
    penalty_points INTEGER DEFAULT 0,

    -- Weighted totals
    weighted_attendance_points DECIMAL(10,2) DEFAULT 0,
    weighted_total_points DECIMAL(10,2) DEFAULT 0,

    -- Calculated rates
    attendance_rate DECIMAL(5,2), -- Overall attendance percentage
    training_rate DECIMAL(5,2),
    match_rate DECIMAL(5,2),
    social_rate DECIMAL(5,2),

    -- Streaks (at end of month)
    current_attendance_streak INTEGER DEFAULT 0,
    current_win_streak INTEGER DEFAULT 0,

    -- Achievements earned this month
    achievements_earned INTEGER DEFAULT 0,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_month CHECK (month >= 1 AND month <= 12),
    CONSTRAINT unique_monthly_stats UNIQUE (team_id, user_id, year, month)
);

CREATE INDEX idx_monthly_stats_team ON monthly_user_stats(team_id);
CREATE INDEX idx_monthly_stats_user ON monthly_user_stats(user_id);
CREATE INDEX idx_monthly_stats_period ON monthly_user_stats(year, month);
CREATE INDEX idx_monthly_stats_season ON monthly_user_stats(season_id) WHERE season_id IS NOT NULL;
CREATE INDEX idx_monthly_stats_points ON monthly_user_stats(team_id, weighted_total_points DESC);
CREATE INDEX idx_monthly_stats_attendance ON monthly_user_stats(team_id, attendance_rate DESC);

-- ============================================
-- SEASON USER STATS (aggregated from monthly)
-- ============================================

-- Aggregated season statistics (materialized from monthly data)
CREATE TABLE season_user_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    season_id UUID NOT NULL REFERENCES seasons(id) ON DELETE CASCADE,

    -- Total attendance
    total_attended INTEGER DEFAULT 0,
    total_possible INTEGER DEFAULT 0,
    valid_absences INTEGER DEFAULT 0,

    -- By type
    training_attended INTEGER DEFAULT 0,
    training_possible INTEGER DEFAULT 0,
    match_attended INTEGER DEFAULT 0,
    match_possible INTEGER DEFAULT 0,
    social_attended INTEGER DEFAULT 0,
    social_possible INTEGER DEFAULT 0,

    -- Points
    total_attendance_points INTEGER DEFAULT 0,
    total_competition_points INTEGER DEFAULT 0,
    total_bonus_points INTEGER DEFAULT 0,
    total_penalty_points INTEGER DEFAULT 0,
    weighted_total_points DECIMAL(10,2) DEFAULT 0,

    -- Rates
    attendance_rate DECIMAL(5,2),
    training_rate DECIMAL(5,2),
    match_rate DECIMAL(5,2),
    social_rate DECIMAL(5,2),

    -- Best streaks
    best_attendance_streak INTEGER DEFAULT 0,
    best_win_streak INTEGER DEFAULT 0,
    current_attendance_streak INTEGER DEFAULT 0,

    -- Achievements
    total_achievements INTEGER DEFAULT 0,

    -- Ranking
    rank INTEGER,
    rank_change INTEGER DEFAULT 0, -- Change from last month

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT unique_season_stats UNIQUE (team_id, user_id, season_id)
);

CREATE INDEX idx_season_stats_team ON season_user_stats(team_id);
CREATE INDEX idx_season_stats_user ON season_user_stats(user_id);
CREATE INDEX idx_season_stats_season ON season_user_stats(season_id);
CREATE INDEX idx_season_stats_points ON season_user_stats(team_id, season_id, weighted_total_points DESC);
CREATE INDEX idx_season_stats_rank ON season_user_stats(team_id, season_id, rank);

-- ============================================
-- VIEWS
-- ============================================

-- View for user attendance across all activities
CREATE OR REPLACE VIEW v_user_attendance AS
SELECT
    tm.team_id,
    tm.user_id,
    u.name AS user_name,
    s.id AS season_id,
    s.name AS season_name,

    -- Training
    COUNT(CASE WHEN a.activity_type = 'training' AND ar.response = 'yes' THEN 1 END) AS training_attended,
    COUNT(CASE WHEN a.activity_type = 'training' THEN 1 END) AS training_possible,

    -- Match
    COUNT(CASE WHEN a.activity_type = 'match' AND ar.response = 'yes' THEN 1 END) AS match_attended,
    COUNT(CASE WHEN a.activity_type = 'match' THEN 1 END) AS match_possible,

    -- Social
    COUNT(CASE WHEN a.activity_type = 'social' AND ar.response = 'yes' THEN 1 END) AS social_attended,
    COUNT(CASE WHEN a.activity_type = 'social' THEN 1 END) AS social_possible,

    -- Total
    COUNT(CASE WHEN ar.response = 'yes' THEN 1 END) AS total_attended,
    COUNT(ai.id) AS total_possible,

    -- Rate
    ROUND(
        COUNT(CASE WHEN ar.response = 'yes' THEN 1 END)::DECIMAL /
        NULLIF(COUNT(ai.id), 0) * 100, 2
    ) AS attendance_rate

FROM team_members tm
JOIN users u ON u.id = tm.user_id
JOIN activities a ON a.team_id = tm.team_id
JOIN activity_instances ai ON ai.activity_id = a.id AND ai.date <= CURRENT_DATE
LEFT JOIN seasons s ON s.team_id = tm.team_id AND s.is_active = TRUE
LEFT JOIN activity_responses ar ON ar.instance_id = ai.id AND ar.user_id = tm.user_id
WHERE tm.leaderboard_opt_out = FALSE OR tm.leaderboard_opt_out IS NULL
GROUP BY tm.team_id, tm.user_id, u.name, s.id, s.name;

-- View for leaderboard with ranking and attendance tiebreaker
CREATE OR REPLACE VIEW v_leaderboard_ranked AS
SELECT
    le.leaderboard_id,
    l.team_id,
    l.season_id,
    l.category,
    le.user_id,
    u.name AS user_name,
    le.points,
    COALESCE(sus.attendance_rate, 0) AS attendance_rate,
    COALESCE(sus.current_attendance_streak, 0) AS current_streak,
    tm.leaderboard_opt_out,
    RANK() OVER (
        PARTITION BY le.leaderboard_id
        ORDER BY le.points DESC, COALESCE(sus.attendance_rate, 0) DESC
    ) AS rank
FROM leaderboard_entries le
JOIN leaderboards l ON l.id = le.leaderboard_id
JOIN users u ON u.id = le.user_id
LEFT JOIN team_members tm ON tm.user_id = le.user_id AND tm.team_id = l.team_id
LEFT JOIN season_user_stats sus ON sus.user_id = le.user_id
    AND sus.team_id = l.team_id
    AND sus.season_id = l.season_id
WHERE tm.leaderboard_opt_out = FALSE OR tm.leaderboard_opt_out IS NULL;

-- View for monthly trends (comparing current to previous month)
CREATE OR REPLACE VIEW v_monthly_trends AS
SELECT
    current.team_id,
    current.user_id,
    u.name AS user_name,
    current.year,
    current.month,
    current.weighted_total_points AS current_points,
    previous.weighted_total_points AS previous_points,
    (current.weighted_total_points - COALESCE(previous.weighted_total_points, 0)) AS point_change,
    current.attendance_rate AS current_rate,
    previous.attendance_rate AS previous_rate,
    (current.attendance_rate - COALESCE(previous.attendance_rate, 0)) AS rate_change,
    CASE
        WHEN current.weighted_total_points > COALESCE(previous.weighted_total_points, 0) THEN 'up'
        WHEN current.weighted_total_points < COALESCE(previous.weighted_total_points, 0) THEN 'down'
        ELSE 'same'
    END AS trend
FROM monthly_user_stats current
JOIN users u ON u.id = current.user_id
LEFT JOIN monthly_user_stats previous ON previous.user_id = current.user_id
    AND previous.team_id = current.team_id
    AND (previous.year = current.year AND previous.month = current.month - 1
         OR previous.year = current.year - 1 AND previous.month = 12 AND current.month = 1);

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to refresh monthly stats for a user
CREATE OR REPLACE FUNCTION refresh_monthly_user_stats(
    p_team_id UUID,
    p_user_id UUID,
    p_year INTEGER,
    p_month INTEGER
) RETURNS VOID AS $$
DECLARE
    v_season_id UUID;
    v_config team_points_config%ROWTYPE;
    v_training_attended INTEGER;
    v_training_possible INTEGER;
    v_match_attended INTEGER;
    v_match_possible INTEGER;
    v_social_attended INTEGER;
    v_social_possible INTEGER;
    v_attendance_points INTEGER;
    v_competition_points INTEGER;
    v_bonus_points INTEGER;
    v_penalty_points INTEGER;
BEGIN
    -- Get active season
    SELECT id INTO v_season_id
    FROM seasons
    WHERE team_id = p_team_id AND is_active = TRUE
    LIMIT 1;

    -- Get point config
    SELECT * INTO v_config
    FROM team_points_config
    WHERE team_id = p_team_id AND (season_id = v_season_id OR season_id IS NULL)
    ORDER BY season_id NULLS LAST
    LIMIT 1;

    -- Calculate attendance counts
    SELECT
        COUNT(CASE WHEN a.activity_type = 'training' AND ar.response = 'yes' THEN 1 END),
        COUNT(CASE WHEN a.activity_type = 'training' THEN 1 END),
        COUNT(CASE WHEN a.activity_type = 'match' AND ar.response = 'yes' THEN 1 END),
        COUNT(CASE WHEN a.activity_type = 'match' THEN 1 END),
        COUNT(CASE WHEN a.activity_type = 'social' AND ar.response = 'yes' THEN 1 END),
        COUNT(CASE WHEN a.activity_type = 'social' THEN 1 END)
    INTO v_training_attended, v_training_possible, v_match_attended, v_match_possible, v_social_attended, v_social_possible
    FROM activities a
    JOIN activity_instances ai ON ai.activity_id = a.id
    LEFT JOIN activity_responses ar ON ar.instance_id = ai.id AND ar.user_id = p_user_id
    WHERE a.team_id = p_team_id
      AND EXTRACT(YEAR FROM ai.date) = p_year
      AND EXTRACT(MONTH FROM ai.date) = p_month
      AND ai.date <= CURRENT_DATE;

    -- Calculate points from attendance_points table
    SELECT COALESCE(SUM(base_points), 0) INTO v_attendance_points
    FROM attendance_points
    WHERE team_id = p_team_id AND user_id = p_user_id
      AND EXTRACT(YEAR FROM awarded_at) = p_year
      AND EXTRACT(MONTH FROM awarded_at) = p_month;

    -- Calculate competition points
    SELECT COALESCE(SUM(lps.points), 0) INTO v_competition_points
    FROM leaderboard_point_sources lps
    JOIN leaderboard_entries le ON le.id = lps.leaderboard_entry_id
    JOIN leaderboards l ON l.id = le.leaderboard_id
    WHERE l.team_id = p_team_id AND lps.user_id = p_user_id
      AND lps.source_type = 'mini_activity'
      AND EXTRACT(YEAR FROM lps.recorded_at) = p_year
      AND EXTRACT(MONTH FROM lps.recorded_at) = p_month;

    -- Calculate bonus/penalty points
    SELECT
        COALESCE(SUM(CASE WHEN lps.source_type = 'bonus' THEN lps.points ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN lps.source_type = 'penalty' THEN ABS(lps.points) ELSE 0 END), 0)
    INTO v_bonus_points, v_penalty_points
    FROM leaderboard_point_sources lps
    JOIN leaderboard_entries le ON le.id = lps.leaderboard_entry_id
    JOIN leaderboards l ON l.id = le.leaderboard_id
    WHERE l.team_id = p_team_id AND lps.user_id = p_user_id
      AND lps.source_type IN ('bonus', 'penalty')
      AND EXTRACT(YEAR FROM lps.recorded_at) = p_year
      AND EXTRACT(MONTH FROM lps.recorded_at) = p_month;

    -- Upsert monthly stats
    INSERT INTO monthly_user_stats (
        team_id, user_id, year, month, season_id,
        training_attended, training_possible,
        match_attended, match_possible,
        social_attended, social_possible,
        attendance_points, competition_points, bonus_points, penalty_points,
        weighted_attendance_points,
        weighted_total_points,
        attendance_rate, training_rate, match_rate, social_rate,
        updated_at
    ) VALUES (
        p_team_id, p_user_id, p_year, p_month, v_season_id,
        v_training_attended, v_training_possible,
        v_match_attended, v_match_possible,
        v_social_attended, v_social_possible,
        v_attendance_points, v_competition_points, v_bonus_points, v_penalty_points,
        (v_training_attended * COALESCE(v_config.training_points, 1) * COALESCE(v_config.training_weight, 1.0) +
         v_match_attended * COALESCE(v_config.match_points, 2) * COALESCE(v_config.match_weight, 1.5) +
         v_social_attended * COALESCE(v_config.social_points, 1) * COALESCE(v_config.social_weight, 0.5)),
        (v_training_attended * COALESCE(v_config.training_points, 1) * COALESCE(v_config.training_weight, 1.0) +
         v_match_attended * COALESCE(v_config.match_points, 2) * COALESCE(v_config.match_weight, 1.5) +
         v_social_attended * COALESCE(v_config.social_points, 1) * COALESCE(v_config.social_weight, 0.5) +
         v_competition_points * COALESCE(v_config.competition_weight, 1.0) +
         v_bonus_points - v_penalty_points),
        ROUND(
            (v_training_attended + v_match_attended + v_social_attended)::DECIMAL /
            NULLIF(v_training_possible + v_match_possible + v_social_possible, 0) * 100, 2
        ),
        ROUND(v_training_attended::DECIMAL / NULLIF(v_training_possible, 0) * 100, 2),
        ROUND(v_match_attended::DECIMAL / NULLIF(v_match_possible, 0) * 100, 2),
        ROUND(v_social_attended::DECIMAL / NULLIF(v_social_possible, 0) * 100, 2),
        NOW()
    )
    ON CONFLICT (team_id, user_id, year, month) DO UPDATE SET
        season_id = EXCLUDED.season_id,
        training_attended = EXCLUDED.training_attended,
        training_possible = EXCLUDED.training_possible,
        match_attended = EXCLUDED.match_attended,
        match_possible = EXCLUDED.match_possible,
        social_attended = EXCLUDED.social_attended,
        social_possible = EXCLUDED.social_possible,
        attendance_points = EXCLUDED.attendance_points,
        competition_points = EXCLUDED.competition_points,
        bonus_points = EXCLUDED.bonus_points,
        penalty_points = EXCLUDED.penalty_points,
        weighted_attendance_points = EXCLUDED.weighted_attendance_points,
        weighted_total_points = EXCLUDED.weighted_total_points,
        attendance_rate = EXCLUDED.attendance_rate,
        training_rate = EXCLUDED.training_rate,
        match_rate = EXCLUDED.match_rate,
        social_rate = EXCLUDED.social_rate,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE monthly_user_stats IS 'Cached monthly statistics per user for faster queries';
COMMENT ON TABLE season_user_stats IS 'Aggregated season statistics derived from monthly data';
COMMENT ON VIEW v_user_attendance IS 'Real-time view of user attendance across activities';
COMMENT ON VIEW v_leaderboard_ranked IS 'Leaderboard with ranking and attendance tiebreaker';
COMMENT ON VIEW v_monthly_trends IS 'Monthly comparison showing point and attendance trends';
COMMENT ON FUNCTION refresh_monthly_user_stats IS 'Refreshes cached monthly stats for a specific user';
