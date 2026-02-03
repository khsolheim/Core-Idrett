-- Migration 021: Add winner_team_id column to mini_activities table
-- This column was referenced in backend code but never created in database

-- Add winner_team_id column to mini_activities table
ALTER TABLE mini_activities
    ADD COLUMN IF NOT EXISTS winner_team_id UUID REFERENCES mini_activity_teams(id) ON DELETE SET NULL;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_mini_activities_winner_team_id ON mini_activities(winner_team_id);
