-- Migration: Fine Settings
-- Adds appeal fee and game day multiplier settings to team_settings
-- Adds is_game_day flag to fines table

-- Add fine settings columns to team_settings
ALTER TABLE team_settings
    ADD COLUMN IF NOT EXISTS appeal_fee DECIMAL(10, 2) DEFAULT 0,
    ADD COLUMN IF NOT EXISTS game_day_multiplier DECIMAL(4, 2) DEFAULT 1.0;

-- Add is_game_day flag to fines
ALTER TABLE fines
    ADD COLUMN IF NOT EXISTS is_game_day BOOLEAN DEFAULT FALSE;

-- Add comments for documentation
COMMENT ON COLUMN team_settings.appeal_fee IS 'Fee automatically added when an appeal is rejected';
COMMENT ON COLUMN team_settings.game_day_multiplier IS 'Multiplier applied to fines on game day (e.g., 2.0 = double)';
COMMENT ON COLUMN fines.is_game_day IS 'Whether this fine was issued on a game day (multiplier applied)';
