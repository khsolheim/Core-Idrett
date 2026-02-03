-- Team Points Configuration
-- Migration: 022_team_points_config
-- Enhanced point system configuration per team/season

-- ============================================
-- TEAM POINTS CONFIG
-- ============================================

-- Team-specific point configuration (extends team_settings)
CREATE TABLE team_points_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    season_id UUID REFERENCES seasons(id) ON DELETE CASCADE,

    -- Attendance points per activity type
    training_points INTEGER DEFAULT 1,
    match_points INTEGER DEFAULT 2,
    social_points INTEGER DEFAULT 1,

    -- Weight multipliers for weighted total calculation
    training_weight DECIMAL(4,2) DEFAULT 1.0,
    match_weight DECIMAL(4,2) DEFAULT 1.5,
    social_weight DECIMAL(4,2) DEFAULT 0.5,
    competition_weight DECIMAL(4,2) DEFAULT 1.0,

    -- Mini-activity point distribution default
    mini_activity_distribution VARCHAR(50) DEFAULT 'top_three',

    -- Auto-award settings
    auto_award_attendance BOOLEAN DEFAULT TRUE,

    -- Visibility settings
    visibility VARCHAR(50) DEFAULT 'all',

    -- Allow players to opt-out of leaderboard
    allow_opt_out BOOLEAN DEFAULT FALSE,

    -- Absence handling
    require_absence_reason BOOLEAN DEFAULT FALSE,
    require_absence_approval BOOLEAN DEFAULT FALSE,
    exclude_valid_absence_from_percentage BOOLEAN DEFAULT TRUE,

    -- New player handling
    new_player_start_mode VARCHAR(50) DEFAULT 'from_join',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_visibility CHECK (visibility IN ('all', 'ranking_only', 'own_only')),
    CONSTRAINT valid_distribution CHECK (mini_activity_distribution IN ('winner_only', 'top_three', 'all_participants')),
    CONSTRAINT valid_new_player_mode CHECK (new_player_start_mode IN ('from_join', 'full_season', 'admin_choice')),
    CONSTRAINT unique_team_season UNIQUE (team_id, season_id)
);

CREATE INDEX idx_points_config_team ON team_points_config(team_id);
CREATE INDEX idx_points_config_season ON team_points_config(season_id) WHERE season_id IS NOT NULL;

-- Create default config for existing teams
INSERT INTO team_points_config (team_id, season_id)
SELECT t.id, s.id
FROM teams t
LEFT JOIN seasons s ON s.team_id = t.id AND s.is_active = TRUE
ON CONFLICT (team_id, season_id) DO NOTHING;

-- ============================================
-- ATTENDANCE POINTS TRACKING
-- ============================================

-- Track attendance points per activity instance
-- This provides granular tracking separate from leaderboard_point_sources
CREATE TABLE attendance_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    instance_id UUID NOT NULL REFERENCES activity_instances(id) ON DELETE CASCADE,
    season_id UUID REFERENCES seasons(id) ON DELETE SET NULL,

    activity_type VARCHAR(50) NOT NULL,
    base_points INTEGER NOT NULL DEFAULT 0,
    weighted_points DECIMAL(10,2) NOT NULL DEFAULT 0,

    awarded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_activity_type CHECK (activity_type IN ('training', 'match', 'social', 'other')),
    CONSTRAINT unique_user_instance UNIQUE (user_id, instance_id)
);

CREATE INDEX idx_attendance_points_team ON attendance_points(team_id);
CREATE INDEX idx_attendance_points_user ON attendance_points(user_id);
CREATE INDEX idx_attendance_points_instance ON attendance_points(instance_id);
CREATE INDEX idx_attendance_points_season ON attendance_points(season_id) WHERE season_id IS NOT NULL;
CREATE INDEX idx_attendance_points_type ON attendance_points(team_id, activity_type);

-- ============================================
-- LEADERBOARD OPT-OUT
-- ============================================

-- Add opt-out column to team_members
ALTER TABLE team_members
    ADD COLUMN IF NOT EXISTS leaderboard_opt_out BOOLEAN DEFAULT FALSE;

-- ============================================
-- LEADERBOARD CATEGORY
-- ============================================

-- Add category to leaderboards for filtering
ALTER TABLE leaderboards
    ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'total';

-- Update constraint if exists, or add it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'valid_category'
    ) THEN
        ALTER TABLE leaderboards
            ADD CONSTRAINT valid_category CHECK (category IN (
                'total',
                'attendance',
                'competition',
                'training',
                'match',
                'social'
            ));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_leaderboards_category ON leaderboards(team_id, category);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE team_points_config IS 'Team-specific configuration for the points and leaderboard system';
COMMENT ON COLUMN team_points_config.training_points IS 'Base points awarded for attending a training session';
COMMENT ON COLUMN team_points_config.match_points IS 'Base points awarded for attending a match';
COMMENT ON COLUMN team_points_config.social_points IS 'Base points awarded for attending a social event';
COMMENT ON COLUMN team_points_config.training_weight IS 'Weight multiplier for training points in total calculation';
COMMENT ON COLUMN team_points_config.match_weight IS 'Weight multiplier for match points in total calculation';
COMMENT ON COLUMN team_points_config.social_weight IS 'Weight multiplier for social points in total calculation';
COMMENT ON COLUMN team_points_config.competition_weight IS 'Weight multiplier for mini-activity competition points';
COMMENT ON COLUMN team_points_config.visibility IS 'all=everyone sees all, ranking_only=see ranks not points, own_only=only own stats';
COMMENT ON COLUMN team_points_config.new_player_start_mode IS 'from_join=count from join date, full_season=all activities count, admin_choice=admin decides';

COMMENT ON TABLE attendance_points IS 'Granular tracking of attendance points per user per activity instance';
COMMENT ON COLUMN attendance_points.base_points IS 'Raw points before weight multiplier';
COMMENT ON COLUMN attendance_points.weighted_points IS 'Points after applying activity type weight';

COMMENT ON COLUMN team_members.leaderboard_opt_out IS 'If true, user is hidden from leaderboards but still tracked';
COMMENT ON COLUMN leaderboards.category IS 'Category for filtering: total, attendance, competition, training, match, social';
