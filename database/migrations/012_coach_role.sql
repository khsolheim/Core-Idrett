-- Coach role for Core - Idrett
-- Migration: 012_coach_role
--
-- Adds is_coach flag to team_members for activity management privileges
-- Coaches can:
-- - Create/edit/delete activities (like admin)
-- - Create/edit/delete mini-activities on activities
-- - But cannot change team settings or manage members

-- Add is_coach flag to team_members
ALTER TABLE team_members
    ADD COLUMN IF NOT EXISTS is_coach BOOLEAN NOT NULL DEFAULT FALSE;

-- Create index for coach lookup
CREATE INDEX IF NOT EXISTS idx_team_members_coach ON team_members(team_id, is_coach) WHERE is_coach = TRUE;

COMMENT ON COLUMN team_members.is_coach IS 'Whether this member has coach privileges (can manage activities and mini-activities)';
