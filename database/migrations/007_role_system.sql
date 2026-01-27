-- Role system improvements for Core - Idrett
-- Migration: 007_role_system
--
-- Changes the role system from single-role to flag-based:
-- - All members are "members" (base role)
-- - is_admin flag for admin privileges
-- - is_fine_boss flag for fine management
-- - trainer_type_id for optional trainer role
-- - is_active for soft delete

-- Trainer types table (custom trainer roles per team)
CREATE TABLE trainer_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(team_id, name)
);

CREATE INDEX idx_trainer_types_team ON trainer_types(team_id);

-- Insert default trainer types for existing teams
INSERT INTO trainer_types (team_id, name, display_order)
SELECT id, 'Hovedtrener', 1 FROM teams
UNION ALL
SELECT id, 'Assistenttrener', 2 FROM teams
UNION ALL
SELECT id, 'Keepertrener', 3 FROM teams
UNION ALL
SELECT id, 'Fysioterapeut', 4 FROM teams;

-- Add new columns to team_members
ALTER TABLE team_members
    ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN is_fine_boss BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN trainer_type_id UUID REFERENCES trainer_types(id) ON DELETE SET NULL,
    ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- Migrate existing roles to new structure
UPDATE team_members SET is_admin = TRUE WHERE role = 'admin';
UPDATE team_members SET is_fine_boss = TRUE WHERE role = 'fine_boss';

-- Create index for active members lookup
CREATE INDEX idx_team_members_active ON team_members(team_id, is_active);
CREATE INDEX idx_team_members_trainer ON team_members(trainer_type_id) WHERE trainer_type_id IS NOT NULL;

-- Drop the old role constraint (we'll keep the column for backwards compatibility during transition)
ALTER TABLE team_members DROP CONSTRAINT IF EXISTS valid_role;

-- Add a comment explaining the migration
COMMENT ON COLUMN team_members.role IS 'DEPRECATED: Use is_admin, is_fine_boss, and trainer_type_id instead. Kept for backwards compatibility.';
COMMENT ON COLUMN team_members.is_admin IS 'Whether this member has admin privileges for the team';
COMMENT ON COLUMN team_members.is_fine_boss IS 'Whether this member can manage fines (Botesjef)';
COMMENT ON COLUMN team_members.trainer_type_id IS 'Optional trainer role (FK to trainer_types)';
COMMENT ON COLUMN team_members.is_active IS 'Soft delete flag - FALSE means member has been deactivated';

-- Add birth_date to users for age-based features (GMO team division, etc.)
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS birth_date DATE;

COMMENT ON COLUMN users.birth_date IS 'User birth date for age-based features like GMO team division';
