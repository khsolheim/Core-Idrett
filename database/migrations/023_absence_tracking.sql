-- Absence Tracking System
-- Migration: 023_absence_tracking
-- Categories and registration for valid absences

-- ============================================
-- ABSENCE CATEGORIES
-- ============================================

-- Team-specific absence categories
CREATE TABLE absence_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    description TEXT,

    -- Does this category require admin approval?
    requires_approval BOOLEAN DEFAULT FALSE,

    -- Does this count as "valid" absence (excluded from percentage)?
    counts_as_valid BOOLEAN DEFAULT TRUE,

    -- Is this category active?
    is_active BOOLEAN DEFAULT TRUE,

    -- Display order
    sort_order INTEGER DEFAULT 0,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT unique_category_name UNIQUE (team_id, name)
);

CREATE INDEX idx_absence_categories_team ON absence_categories(team_id);
CREATE INDEX idx_absence_categories_active ON absence_categories(team_id, is_active) WHERE is_active = TRUE;

-- Insert default categories for existing teams
INSERT INTO absence_categories (team_id, name, description, requires_approval, counts_as_valid, sort_order)
SELECT t.id, 'Sykdom', 'Syk eller skadet', FALSE, TRUE, 1
FROM teams t
ON CONFLICT (team_id, name) DO NOTHING;

INSERT INTO absence_categories (team_id, name, description, requires_approval, counts_as_valid, sort_order)
SELECT t.id, 'Jobb/Skole', 'Jobb- eller skoleforpliktelser', FALSE, TRUE, 2
FROM teams t
ON CONFLICT (team_id, name) DO NOTHING;

INSERT INTO absence_categories (team_id, name, description, requires_approval, counts_as_valid, sort_order)
SELECT t.id, 'Familie', 'Familieforpliktelser', FALSE, TRUE, 3
FROM teams t
ON CONFLICT (team_id, name) DO NOTHING;

INSERT INTO absence_categories (team_id, name, description, requires_approval, counts_as_valid, sort_order)
SELECT t.id, 'Reise', 'Bortreist', FALSE, TRUE, 4
FROM teams t
ON CONFLICT (team_id, name) DO NOTHING;

INSERT INTO absence_categories (team_id, name, description, requires_approval, counts_as_valid, sort_order)
SELECT t.id, 'Annet', 'Andre grunner', TRUE, FALSE, 5
FROM teams t
ON CONFLICT (team_id, name) DO NOTHING;

-- ============================================
-- ABSENCE RECORDS
-- ============================================

-- Individual absence registrations
CREATE TABLE absence_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    instance_id UUID NOT NULL REFERENCES activity_instances(id) ON DELETE CASCADE,
    category_id UUID REFERENCES absence_categories(id) ON DELETE SET NULL,

    -- Free-text reason (optional)
    reason TEXT,

    -- Approval workflow
    status VARCHAR(50) DEFAULT 'pending',
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejection_reason TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    CONSTRAINT valid_status CHECK (status IN ('pending', 'approved', 'rejected', 'auto_approved')),
    CONSTRAINT unique_user_instance UNIQUE (user_id, instance_id)
);

CREATE INDEX idx_absence_records_user ON absence_records(user_id);
CREATE INDEX idx_absence_records_instance ON absence_records(instance_id);
CREATE INDEX idx_absence_records_category ON absence_records(category_id);
CREATE INDEX idx_absence_records_status ON absence_records(status);
CREATE INDEX idx_absence_records_pending ON absence_records(status) WHERE status = 'pending';

-- ============================================
-- HELPER VIEW
-- ============================================

-- View for absence records with full details
CREATE OR REPLACE VIEW v_absence_details AS
SELECT
    ar.id,
    ar.user_id,
    u.name AS user_name,
    ar.instance_id,
    ai.date AS activity_date,
    a.title AS activity_title,
    a.activity_type,
    ar.category_id,
    ac.name AS category_name,
    ac.counts_as_valid,
    ar.reason,
    ar.status,
    ar.approved_by,
    approver.name AS approver_name,
    ar.approved_at,
    ar.rejection_reason,
    ar.created_at,
    a.team_id
FROM absence_records ar
JOIN users u ON u.id = ar.user_id
JOIN activity_instances ai ON ai.id = ar.instance_id
JOIN activities a ON a.id = ai.activity_id
LEFT JOIN absence_categories ac ON ac.id = ar.category_id
LEFT JOIN users approver ON approver.id = ar.approved_by;

-- ============================================
-- UPDATE FUNCTION
-- ============================================

-- Trigger to auto-approve absences that don't require approval
CREATE OR REPLACE FUNCTION auto_approve_absence()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the category requires approval
    IF NEW.category_id IS NOT NULL THEN
        DECLARE
            needs_approval BOOLEAN;
        BEGIN
            SELECT requires_approval INTO needs_approval
            FROM absence_categories
            WHERE id = NEW.category_id;

            -- If category doesn't require approval, auto-approve
            IF needs_approval = FALSE THEN
                NEW.status := 'auto_approved';
                NEW.approved_at := NOW();
            END IF;
        END;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_auto_approve_absence
    BEFORE INSERT ON absence_records
    FOR EACH ROW
    EXECUTE FUNCTION auto_approve_absence();

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE absence_categories IS 'Team-specific categories for absence reasons';
COMMENT ON COLUMN absence_categories.requires_approval IS 'If true, admin must approve absences with this category';
COMMENT ON COLUMN absence_categories.counts_as_valid IS 'If true, absence is excluded from attendance percentage calculation';

COMMENT ON TABLE absence_records IS 'Individual absence registrations linked to activity instances';
COMMENT ON COLUMN absence_records.status IS 'pending=awaiting approval, approved=accepted, rejected=denied, auto_approved=approved automatically';

COMMENT ON VIEW v_absence_details IS 'Comprehensive view of absence records with user, activity, and category details';
