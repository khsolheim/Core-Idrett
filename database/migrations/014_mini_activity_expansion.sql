-- Mini-Activity Expansion: Foundation, Templates, Adjustments, Handicaps
-- Migration: 014_mini_activity_expansion
-- Tasks: DB-001 to DB-026

-- ============================================
-- MINI-ACTIVITY FOUNDATION EXTENSIONS (DB-001 to DB-014)
-- ============================================

-- DB-001: Add team_id column for standalone mini-activities
ALTER TABLE mini_activities
    ADD COLUMN team_id UUID REFERENCES teams(id) ON DELETE CASCADE;

-- DB-002: Add leaderboard_id for direct leaderboard connection
ALTER TABLE mini_activities
    ADD COLUMN leaderboard_id UUID REFERENCES leaderboards(id) ON DELETE SET NULL;

-- DB-003: Add enable_leaderboard flag
ALTER TABLE mini_activities
    ADD COLUMN enable_leaderboard BOOLEAN DEFAULT TRUE;

-- DB-004: Add win_points (configurable per activity)
ALTER TABLE mini_activities
    ADD COLUMN win_points INTEGER DEFAULT 3;

-- DB-005: Add draw_points
ALTER TABLE mini_activities
    ADD COLUMN draw_points INTEGER DEFAULT 1;

-- DB-006: Add loss_points
ALTER TABLE mini_activities
    ADD COLUMN loss_points INTEGER DEFAULT 0;

-- DB-007: Add description field
ALTER TABLE mini_activities
    ADD COLUMN description TEXT;

-- DB-008: Add max_participants limit
ALTER TABLE mini_activities
    ADD COLUMN max_participants INTEGER;

-- DB-009: Add handicap_enabled flag
ALTER TABLE mini_activities
    ADD COLUMN handicap_enabled BOOLEAN DEFAULT FALSE;

-- DB-010: Add archived_at for soft delete/archive
ALTER TABLE mini_activities
    ADD COLUMN archived_at TIMESTAMP WITH TIME ZONE;

-- DB-011: Make instance_id nullable for standalone activities
ALTER TABLE mini_activities
    ALTER COLUMN instance_id DROP NOT NULL;

-- DB-012: Add check constraint requiring either instance_id or team_id
ALTER TABLE mini_activities
    ADD CONSTRAINT mini_activity_has_parent
    CHECK (instance_id IS NOT NULL OR team_id IS NOT NULL);

-- DB-013: Add index on team_id for efficient queries
CREATE INDEX idx_mini_activities_team ON mini_activities(team_id) WHERE team_id IS NOT NULL;

-- DB-014: Add index on archived_at for filtering
CREATE INDEX idx_mini_activities_archived ON mini_activities(archived_at) WHERE archived_at IS NOT NULL;

-- ============================================
-- TEMPLATE EXTENSIONS (DB-015 to DB-023)
-- ============================================

-- DB-015: Add description to templates
ALTER TABLE activity_templates
    ADD COLUMN description TEXT;

-- DB-016: Add instructions for rich text instructions
ALTER TABLE activity_templates
    ADD COLUMN instructions TEXT;

-- DB-017: Add sport_type categorization
ALTER TABLE activity_templates
    ADD COLUMN sport_type VARCHAR(50);

-- DB-018: Add suggested_rules as JSONB
ALTER TABLE activity_templates
    ADD COLUMN suggested_rules JSONB;

-- DB-019: Add is_favorite flag
ALTER TABLE activity_templates
    ADD COLUMN is_favorite BOOLEAN DEFAULT FALSE;

-- DB-020: Add win_points default
ALTER TABLE activity_templates
    ADD COLUMN win_points INTEGER DEFAULT 3;

-- DB-021: Add draw_points default
ALTER TABLE activity_templates
    ADD COLUMN draw_points INTEGER DEFAULT 1;

-- DB-022: Add loss_points default
ALTER TABLE activity_templates
    ADD COLUMN loss_points INTEGER DEFAULT 0;

-- DB-023: Add leaderboard_id for default leaderboard
ALTER TABLE activity_templates
    ADD COLUMN leaderboard_id UUID REFERENCES leaderboards(id) ON DELETE SET NULL;

-- ============================================
-- BONUS/PENALTY ADJUSTMENTS (DB-024 to DB-025)
-- ============================================

-- DB-024: Create mini_activity_adjustments table
CREATE TABLE mini_activity_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mini_activity_id UUID NOT NULL REFERENCES mini_activities(id) ON DELETE CASCADE,
    team_id UUID REFERENCES mini_activity_teams(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    reason TEXT,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT adjustment_has_target CHECK (team_id IS NOT NULL OR user_id IS NOT NULL)
);

COMMENT ON TABLE mini_activity_adjustments IS 'Bonus/penalty point adjustments for mini-activities';

-- DB-025: Add indexes to adjustments
CREATE INDEX idx_adjustments_mini ON mini_activity_adjustments(mini_activity_id);
CREATE INDEX idx_adjustments_team ON mini_activity_adjustments(team_id) WHERE team_id IS NOT NULL;
CREATE INDEX idx_adjustments_user ON mini_activity_adjustments(user_id) WHERE user_id IS NOT NULL;

-- ============================================
-- HANDICAP SYSTEM (DB-026)
-- ============================================

-- DB-026: Create mini_activity_handicaps table
CREATE TABLE mini_activity_handicaps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mini_activity_id UUID NOT NULL REFERENCES mini_activities(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    handicap_value DECIMAL(5,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(mini_activity_id, user_id)
);

COMMENT ON TABLE mini_activity_handicaps IS 'Handicap values for players in specific mini-activities';

CREATE INDEX idx_handicaps_mini ON mini_activity_handicaps(mini_activity_id);
CREATE INDEX idx_handicaps_user ON mini_activity_handicaps(user_id);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON COLUMN mini_activities.team_id IS 'Team ID for standalone mini-activities not linked to activity instances';
COMMENT ON COLUMN mini_activities.leaderboard_id IS 'Direct connection to a specific leaderboard for points';
COMMENT ON COLUMN mini_activities.enable_leaderboard IS 'Whether this activity contributes to leaderboard points';
COMMENT ON COLUMN mini_activities.win_points IS 'Points awarded for winning (default 3)';
COMMENT ON COLUMN mini_activities.draw_points IS 'Points awarded for a draw (default 1)';
COMMENT ON COLUMN mini_activities.loss_points IS 'Points awarded for losing (default 0)';
COMMENT ON COLUMN mini_activities.description IS 'Optional description of the activity';
COMMENT ON COLUMN mini_activities.max_participants IS 'Maximum number of participants allowed';
COMMENT ON COLUMN mini_activities.handicap_enabled IS 'Whether handicap adjustments are enabled';
COMMENT ON COLUMN mini_activities.archived_at IS 'Timestamp when activity was archived (soft delete)';
COMMENT ON COLUMN activity_templates.description IS 'Description of the template';
COMMENT ON COLUMN activity_templates.instructions IS 'Rich text instructions for the activity';
COMMENT ON COLUMN activity_templates.sport_type IS 'Sport category (fotball, innebandy, etc.)';
COMMENT ON COLUMN activity_templates.suggested_rules IS 'JSONB containing suggested rules configuration';
COMMENT ON COLUMN activity_templates.is_favorite IS 'Whether template is marked as favorite';
