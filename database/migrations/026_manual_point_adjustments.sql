-- Manual Point Adjustments
-- Migration: 026_manual_point_adjustments
-- Admin ability to manually adjust user points (bonus/penalty/correction)

-- ============================================
-- MANUAL POINT ADJUSTMENTS TABLE
-- ============================================

-- Track manual point adjustments by admins
CREATE TABLE manual_point_adjustments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    season_id UUID REFERENCES seasons(id) ON DELETE SET NULL,

    -- Adjustment details
    points INTEGER NOT NULL,
    adjustment_type VARCHAR(50) NOT NULL,
    reason TEXT NOT NULL,

    -- Who made the adjustment
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_adjustment_type CHECK (adjustment_type IN ('bonus', 'penalty', 'correction'))
);

CREATE INDEX idx_manual_adjustments_team ON manual_point_adjustments(team_id);
CREATE INDEX idx_manual_adjustments_user ON manual_point_adjustments(user_id);
CREATE INDEX idx_manual_adjustments_season ON manual_point_adjustments(season_id) WHERE season_id IS NOT NULL;
CREATE INDEX idx_manual_adjustments_date ON manual_point_adjustments(created_at DESC);

-- ============================================
-- VIEW FOR MANUAL ADJUSTMENTS WITH USER NAMES
-- ============================================

CREATE OR REPLACE VIEW v_manual_point_adjustments AS
SELECT
    mpa.id,
    mpa.team_id,
    mpa.user_id,
    u.name AS user_name,
    u.avatar_url AS user_avatar_url,
    mpa.season_id,
    mpa.points,
    mpa.adjustment_type,
    mpa.reason,
    mpa.created_by,
    cb.name AS created_by_name,
    mpa.created_at
FROM manual_point_adjustments mpa
JOIN users u ON u.id = mpa.user_id
JOIN users cb ON cb.id = mpa.created_by;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE manual_point_adjustments IS 'Manual point adjustments made by admins for bonus, penalty, or corrections';
COMMENT ON COLUMN manual_point_adjustments.points IS 'Points to add (positive) or subtract (negative)';
COMMENT ON COLUMN manual_point_adjustments.adjustment_type IS 'Type: bonus (reward), penalty (punishment), correction (fix error)';
COMMENT ON COLUMN manual_point_adjustments.reason IS 'Required explanation for the adjustment';
COMMENT ON COLUMN manual_point_adjustments.created_by IS 'Admin who made the adjustment';
