-- Migration: 020_injured_status
-- Description: Add injured status to team members for activity auto-response logic
-- When a member is marked as injured:
-- 1. They are excluded from auto-responses for opt_out activities
-- 2. Their existing future opt_out responses are deleted
-- When they become healthy again:
-- 1. Auto-responses are created for future opt_out activity instances

-- Add is_injured column to team_members
ALTER TABLE team_members ADD COLUMN is_injured BOOLEAN DEFAULT FALSE;

-- Create partial index for efficient queries on active, injured members per team
CREATE INDEX idx_team_members_injured
ON team_members(team_id, is_injured)
WHERE is_active = TRUE;

-- Comment explaining the column purpose
COMMENT ON COLUMN team_members.is_injured IS 'Whether the member is currently injured. Injured members are excluded from auto-responses for opt_out activities.';
