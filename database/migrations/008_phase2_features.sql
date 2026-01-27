-- Phase 2: Seasons, Multiple Leaderboards, Improved Mini-Activities
-- Migration: 008_phase2_features

-- ============================================
-- SEASONS
-- ============================================

-- Seasons table
CREATE TABLE seasons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,  -- e.g., "2024/2025", "Var 2025"
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, name)
);

CREATE INDEX idx_seasons_team ON seasons(team_id);
CREATE INDEX idx_seasons_active ON seasons(team_id, is_active) WHERE is_active = TRUE;

-- Create default season for existing teams
INSERT INTO seasons (team_id, name, is_active, start_date, end_date)
SELECT id,
       EXTRACT(YEAR FROM NOW())::TEXT || '/' || (EXTRACT(YEAR FROM NOW()) + 1)::TEXT,
       TRUE,
       DATE_TRUNC('year', NOW()),
       DATE_TRUNC('year', NOW()) + INTERVAL '1 year' - INTERVAL '1 day'
FROM teams;

-- Add season_id to activity_instances
ALTER TABLE activity_instances
    ADD COLUMN season_id UUID REFERENCES seasons(id) ON DELETE SET NULL;

-- Link existing instances to current season
UPDATE activity_instances ai
SET season_id = (
    SELECT s.id FROM seasons s
    WHERE s.team_id = (
        SELECT a.team_id FROM activities a WHERE a.id = ai.activity_id
    ) AND s.is_active = TRUE
    LIMIT 1
);

-- ============================================
-- MULTIPLE LEADERBOARDS
-- ============================================

-- Leaderboards table
CREATE TABLE leaderboards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    season_id UUID REFERENCES seasons(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    is_main BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, season_id, name)
);

CREATE INDEX idx_leaderboards_team ON leaderboards(team_id);
CREATE INDEX idx_leaderboards_season ON leaderboards(season_id);
CREATE INDEX idx_leaderboards_main ON leaderboards(team_id, is_main) WHERE is_main = TRUE;

-- Leaderboard entries (points per user)
CREATE TABLE leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    leaderboard_id UUID NOT NULL REFERENCES leaderboards(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(leaderboard_id, user_id)
);

CREATE INDEX idx_leaderboard_entries_board ON leaderboard_entries(leaderboard_id);
CREATE INDEX idx_leaderboard_entries_user ON leaderboard_entries(user_id);
CREATE INDEX idx_leaderboard_entries_points ON leaderboard_entries(leaderboard_id, points DESC);

-- Create main leaderboard for each team's active season
INSERT INTO leaderboards (team_id, season_id, name, is_main, sort_order)
SELECT t.id, s.id, 'Hovedranking', TRUE, 0
FROM teams t
JOIN seasons s ON s.team_id = t.id AND s.is_active = TRUE;

-- Migrate existing player_ratings to leaderboard_entries
INSERT INTO leaderboard_entries (leaderboard_id, user_id, points)
SELECT l.id, pr.user_id, COALESCE(pr.wins * 3 + pr.draws, 0)
FROM player_ratings pr
JOIN leaderboards l ON l.team_id = pr.team_id AND l.is_main = TRUE;

-- ============================================
-- MINI-ACTIVITY POINT CONFIGURATION
-- ============================================

-- Point distribution configuration for mini-activities
CREATE TABLE mini_activity_point_config (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mini_activity_id UUID NOT NULL REFERENCES mini_activities(id) ON DELETE CASCADE,
    leaderboard_id UUID NOT NULL REFERENCES leaderboards(id) ON DELETE CASCADE,
    distribution_type VARCHAR(50) NOT NULL DEFAULT 'winner_only',
    points_first INTEGER DEFAULT 5,
    points_second INTEGER DEFAULT 3,
    points_third INTEGER DEFAULT 1,
    points_participation INTEGER DEFAULT 0,
    CONSTRAINT valid_distribution CHECK (distribution_type IN ('winner_only', 'top_three', 'all_participants', 'custom')),
    UNIQUE(mini_activity_id, leaderboard_id)
);

CREATE INDEX idx_mini_point_config_mini ON mini_activity_point_config(mini_activity_id);
CREATE INDEX idx_mini_point_config_board ON mini_activity_point_config(leaderboard_id);

-- ============================================
-- IMPROVED MINI-ACTIVITY DIVISION METHODS
-- ============================================

-- Update mini_activities to support new division methods
ALTER TABLE mini_activities
    DROP CONSTRAINT IF EXISTS valid_division_method;

ALTER TABLE mini_activities
    ADD CONSTRAINT valid_division_method
    CHECK (division_method IS NULL OR division_method IN ('random', 'ranked', 'age', 'gmo', 'cup', 'manual'));

-- Add number of teams for CUP mode
ALTER TABLE mini_activities
    ADD COLUMN num_teams INTEGER DEFAULT 2;

-- ============================================
-- TEST TEMPLATES (for individual tests/drills)
-- ============================================

-- Test templates (reusable test definitions)
CREATE TABLE test_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    unit VARCHAR(50) NOT NULL,  -- "sekunder", "meter", "repetisjoner", "poeng"
    higher_is_better BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, name)
);

CREATE INDEX idx_test_templates_team ON test_templates(team_id);

-- Test results (individual test scores)
CREATE TABLE test_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    test_template_id UUID NOT NULL REFERENCES test_templates(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    instance_id UUID REFERENCES activity_instances(id) ON DELETE SET NULL,
    value DECIMAL(10,3) NOT NULL,  -- The score/time/distance
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes TEXT
);

CREATE INDEX idx_test_results_template ON test_results(test_template_id);
CREATE INDEX idx_test_results_user ON test_results(user_id);
CREATE INDEX idx_test_results_instance ON test_results(instance_id);
CREATE INDEX idx_test_results_date ON test_results(recorded_at DESC);

-- ============================================
-- ADD COMMENTS
-- ============================================

COMMENT ON TABLE seasons IS 'Seasons for organizing activities and statistics per time period';
COMMENT ON TABLE leaderboards IS 'Multiple leaderboards per team for tracking different competition types';
COMMENT ON TABLE leaderboard_entries IS 'User points in each leaderboard';
COMMENT ON TABLE mini_activity_point_config IS 'Configuration for how points are distributed from mini-activities to leaderboards';
COMMENT ON TABLE test_templates IS 'Reusable templates for individual tests (running times, strength tests, etc.)';
COMMENT ON TABLE test_results IS 'Individual test results for tracking progress over time';
COMMENT ON COLUMN mini_activities.division_method IS 'random=tilfeldig, ranked=etter rating, age=etter alder, gmo=gamle mot unge, cup=flere lag, manual=manuell';
COMMENT ON COLUMN mini_activities.num_teams IS 'Number of teams for CUP mode (default 2)';
