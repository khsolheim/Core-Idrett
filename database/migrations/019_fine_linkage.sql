-- Fine Linkage to Mini-Activities
-- Migration: 019_fine_linkage
-- Tasks: DB-067

-- ============================================
-- FINE TO MINI-ACTIVITY LINK (DB-067)
-- ============================================

-- DB-067: Add mini_activity_id column to fines table
ALTER TABLE fines
    ADD COLUMN mini_activity_id UUID REFERENCES mini_activities(id) ON DELETE SET NULL;

COMMENT ON COLUMN fines.mini_activity_id IS 'Link to mini-activity that generated this fine (if any)';

CREATE INDEX idx_fines_mini_activity ON fines(mini_activity_id) WHERE mini_activity_id IS NOT NULL;

-- ============================================
-- MINI-ACTIVITY AUTO-FINE RULES (BONUS)
-- ============================================

-- Table for auto-fine rules linked to mini-activities
CREATE TABLE mini_activity_fine_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    fine_rule_id UUID NOT NULL REFERENCES fine_rules(id) ON DELETE CASCADE,
    trigger_type VARCHAR(50) NOT NULL,
    trigger_placement INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, fine_rule_id, trigger_type)
);

COMMENT ON TABLE mini_activity_fine_rules IS 'Rules for automatically creating fines based on mini-activity results';

-- Add trigger_type constraint
ALTER TABLE mini_activity_fine_rules
    ADD CONSTRAINT valid_trigger_type
    CHECK (trigger_type IN (
        'last_place',
        'specific_placement',
        'below_average',
        'losing_streak',
        'no_show'
    ));

CREATE INDEX idx_mini_fine_rules_team ON mini_activity_fine_rules(team_id);
CREATE INDEX idx_mini_fine_rules_rule ON mini_activity_fine_rules(fine_rule_id);

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON COLUMN mini_activity_fine_rules.trigger_type IS 'When to trigger: last_place, specific_placement, below_average, losing_streak, no_show';
COMMENT ON COLUMN mini_activity_fine_rules.trigger_placement IS 'For specific_placement trigger: which placement (1=first, 2=second, etc.)';
