-- Achievement System
-- Migration: 024_achievements
-- Badges and achievements for player recognition

-- ============================================
-- ACHIEVEMENT DEFINITIONS
-- ============================================

-- Achievement templates (can be global or team-specific)
CREATE TABLE achievement_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID REFERENCES teams(id) ON DELETE CASCADE, -- NULL = global achievement

    -- Identification
    code VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Display
    icon VARCHAR(100), -- emoji or icon name
    color VARCHAR(50), -- hex color or predefined color name
    tier VARCHAR(50) DEFAULT 'bronze', -- bronze, silver, gold, platinum

    -- Categorization
    category VARCHAR(50) NOT NULL,

    -- Criteria (JSONB for flexibility)
    -- Examples:
    -- {"type": "attendance_streak", "threshold": 10}
    -- {"type": "total_points", "threshold": 100}
    -- {"type": "attendance_rate", "threshold": 90, "period": "season"}
    -- {"type": "mini_activity_wins", "threshold": 5}
    -- {"type": "first_place_count", "threshold": 3}
    criteria JSONB NOT NULL,

    -- Reward
    bonus_points INTEGER DEFAULT 0,

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_secret BOOLEAN DEFAULT FALSE, -- Hidden until earned

    -- Repeatable?
    is_repeatable BOOLEAN DEFAULT FALSE,
    repeat_cooldown_days INTEGER, -- Days before can earn again

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_category CHECK (category IN (
        'attendance',
        'competition',
        'milestone',
        'streak',
        'social',
        'special'
    )),
    CONSTRAINT valid_tier CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
    CONSTRAINT unique_achievement_code UNIQUE (team_id, code)
);

CREATE INDEX idx_achievement_defs_team ON achievement_definitions(team_id);
CREATE INDEX idx_achievement_defs_category ON achievement_definitions(category);
CREATE INDEX idx_achievement_defs_active ON achievement_definitions(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_achievement_defs_global ON achievement_definitions(id) WHERE team_id IS NULL;

-- ============================================
-- USER ACHIEVEMENTS
-- ============================================

-- Awarded achievements per user
CREATE TABLE user_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievement_definitions(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    season_id UUID REFERENCES seasons(id) ON DELETE SET NULL,

    -- Points awarded for this achievement
    points_awarded INTEGER DEFAULT 0,

    -- When earned
    awarded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- For repeatable achievements
    times_earned INTEGER DEFAULT 1,
    last_earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    -- Reference to what triggered the achievement (optional)
    trigger_reference JSONB, -- e.g., {"instance_id": "...", "type": "attendance"}

    CONSTRAINT unique_user_achievement UNIQUE (user_id, achievement_id, team_id, season_id)
);

CREATE INDEX idx_user_achievements_user ON user_achievements(user_id);
CREATE INDEX idx_user_achievements_achievement ON user_achievements(achievement_id);
CREATE INDEX idx_user_achievements_team ON user_achievements(team_id);
CREATE INDEX idx_user_achievements_season ON user_achievements(season_id) WHERE season_id IS NOT NULL;
CREATE INDEX idx_user_achievements_date ON user_achievements(awarded_at DESC);

-- ============================================
-- ACHIEVEMENT PROGRESS (for tracking towards achievements)
-- ============================================

-- Track progress towards achievements
CREATE TABLE achievement_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id UUID NOT NULL REFERENCES achievement_definitions(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    season_id UUID REFERENCES seasons(id) ON DELETE SET NULL,

    -- Progress tracking
    current_value INTEGER DEFAULT 0,
    target_value INTEGER NOT NULL,
    progress_percent DECIMAL(5,2) GENERATED ALWAYS AS (
        LEAST(100.0, (current_value::DECIMAL / NULLIF(target_value, 0)) * 100)
    ) STORED,

    -- Last activity that contributed to progress
    last_contribution_at TIMESTAMP WITH TIME ZONE,

    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT unique_achievement_progress UNIQUE (user_id, achievement_id, team_id, season_id)
);

CREATE INDEX idx_achievement_progress_user ON achievement_progress(user_id);
CREATE INDEX idx_achievement_progress_team ON achievement_progress(team_id);
CREATE INDEX idx_achievement_progress_near_complete ON achievement_progress(progress_percent DESC)
    WHERE progress_percent >= 75;

-- ============================================
-- DEFAULT GLOBAL ACHIEVEMENTS
-- ============================================

-- Insert default global achievements
INSERT INTO achievement_definitions (team_id, code, name, description, icon, tier, category, criteria, bonus_points, is_active) VALUES
-- Attendance streaks
(NULL, 'streak_5', 'Dedikert', '5 aktiviteter på rad', '🔥', 'bronze', 'streak', '{"type": "attendance_streak", "threshold": 5}', 5, TRUE),
(NULL, 'streak_10', 'Standhaftig', '10 aktiviteter på rad', '🔥', 'silver', 'streak', '{"type": "attendance_streak", "threshold": 10}', 15, TRUE),
(NULL, 'streak_25', 'Ustoppelig', '25 aktiviteter på rad', '🔥', 'gold', 'streak', '{"type": "attendance_streak", "threshold": 25}', 50, TRUE),

-- Point milestones
(NULL, 'points_50', 'Nybegynner', 'Nådd 50 poeng', '⭐', 'bronze', 'milestone', '{"type": "total_points", "threshold": 50}', 0, TRUE),
(NULL, 'points_100', 'Erfaren', 'Nådd 100 poeng', '⭐', 'silver', 'milestone', '{"type": "total_points", "threshold": 100}', 0, TRUE),
(NULL, 'points_250', 'Veteran', 'Nådd 250 poeng', '⭐', 'gold', 'milestone', '{"type": "total_points", "threshold": 250}', 0, TRUE),
(NULL, 'points_500', 'Legende', 'Nådd 500 poeng', '⭐', 'platinum', 'milestone', '{"type": "total_points", "threshold": 500}', 0, TRUE),

-- Attendance rate
(NULL, 'attendance_90', 'Pålitelig', '90% oppmøte i en sesong', '✅', 'silver', 'attendance', '{"type": "attendance_rate", "threshold": 90, "period": "season"}', 25, TRUE),
(NULL, 'attendance_100', 'Perfekt oppmøte', '100% oppmøte i en sesong', '🏆', 'gold', 'attendance', '{"type": "attendance_rate", "threshold": 100, "period": "season"}', 100, TRUE),

-- Competition
(NULL, 'wins_5', 'Vinner', '5 seire i mini-aktiviteter', '🥇', 'bronze', 'competition', '{"type": "mini_activity_wins", "threshold": 5}', 10, TRUE),
(NULL, 'wins_25', 'Mester', '25 seire i mini-aktiviteter', '🥇', 'silver', 'competition', '{"type": "mini_activity_wins", "threshold": 25}', 30, TRUE),
(NULL, 'wins_100', 'Legende', '100 seire i mini-aktiviteter', '🥇', 'gold', 'competition', '{"type": "mini_activity_wins", "threshold": 100}', 75, TRUE),

-- Special
(NULL, 'first_activity', 'Velkommen!', 'Deltatt på din første aktivitet', '👋', 'bronze', 'special', '{"type": "first_attendance"}', 1, TRUE),
(NULL, 'team_player', 'Lagspiller', 'Deltatt på 10 sosiale arrangementer', '🎉', 'silver', 'social', '{"type": "social_attendance", "threshold": 10}', 20, TRUE)

ON CONFLICT (team_id, code) DO NOTHING;

-- ============================================
-- HELPER VIEW
-- ============================================

-- View for user achievements with details
CREATE OR REPLACE VIEW v_user_achievements_detail AS
SELECT
    ua.id,
    ua.user_id,
    u.name AS user_name,
    ua.achievement_id,
    ad.code,
    ad.name AS achievement_name,
    ad.description,
    ad.icon,
    ad.tier,
    ad.category,
    ad.bonus_points,
    ua.points_awarded,
    ua.team_id,
    t.name AS team_name,
    ua.season_id,
    ua.awarded_at,
    ua.times_earned
FROM user_achievements ua
JOIN users u ON u.id = ua.user_id
JOIN achievement_definitions ad ON ad.id = ua.achievement_id
JOIN teams t ON t.id = ua.team_id;

-- View for achievement progress
CREATE OR REPLACE VIEW v_achievement_progress_detail AS
SELECT
    ap.id,
    ap.user_id,
    u.name AS user_name,
    ap.achievement_id,
    ad.code,
    ad.name AS achievement_name,
    ad.icon,
    ad.tier,
    ap.current_value,
    ap.target_value,
    ap.progress_percent,
    ap.team_id,
    ap.season_id,
    ap.updated_at
FROM achievement_progress ap
JOIN users u ON u.id = ap.user_id
JOIN achievement_definitions ad ON ad.id = ap.achievement_id;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE achievement_definitions IS 'Templates for achievements that players can earn';
COMMENT ON COLUMN achievement_definitions.team_id IS 'NULL means global achievement available to all teams';
COMMENT ON COLUMN achievement_definitions.criteria IS 'JSONB criteria for earning the achievement';
COMMENT ON COLUMN achievement_definitions.is_secret IS 'If true, achievement is hidden until earned';
COMMENT ON COLUMN achievement_definitions.is_repeatable IS 'If true, can be earned multiple times';

COMMENT ON TABLE user_achievements IS 'Tracks which achievements each user has earned';
COMMENT ON COLUMN user_achievements.trigger_reference IS 'JSONB reference to what triggered the achievement';

COMMENT ON TABLE achievement_progress IS 'Tracks progress towards achievements that have thresholds';
COMMENT ON COLUMN achievement_progress.progress_percent IS 'Computed percentage of completion';
